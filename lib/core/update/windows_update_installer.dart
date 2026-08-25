import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../network/resolve_update_url.dart';

const _kDownloadUserAgent =
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';

const _kWindowsZipFileName = 'erfan_academy_update.zip';
const _kWindowsExeFileName = 'erfan_academy_update.exe';
const _kUpdaterBatchName = 'erfan_academy_updater.cmd';
const _kUpdaterLogName = 'erfan_academy_update.log';

/// Primary log: next to the running exe. Fallback: system temp.
Future<List<String>> windowsUpdateLogPaths() async {
  final exeDir = File(Platform.resolvedExecutable).parent.path;
  final temp = await getTemporaryDirectory();
  return [
    '$exeDir\\$_kUpdaterLogName',
    '${temp.path}\\$_kUpdaterLogName',
  ];
}

Future<void> _appendUpdaterLog(String logPath, String message) async {
  try {
    final file = File(logPath);
    final stamp = DateTime.now().toIso8601String();
    await file.writeAsString('$stamp $message\n', mode: FileMode.append);
  } catch (_) {}
}

enum WindowsUpdateLaunchStatus {
  launched,
  failed,
}

/// Downloads the Windows update package (zip or exe) to a temp file.
Future<String> downloadWindowsUpdate(
  String url, {
  void Function(double progress, int received, int total)? onProgress,
}) async {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.windows) {
    throw UnsupportedError('Windows update download is only supported on Windows');
  }

  final uri = resolveUpdateDownloadUrl(url);
  if (uri == null) {
    throw ArgumentError.value(url, 'url', 'invalid update URL');
  }

  final lowerPath = uri.path.toLowerCase();
  final fileName = lowerPath.endsWith('.exe')
      ? _kWindowsExeFileName
      : _kWindowsZipFileName;

  final dir = await getTemporaryDirectory();
  final path = '${dir.path}\\$fileName';
  final file = File(path);
  if (await file.exists()) {
    try {
      await file.delete();
    } catch (_) {}
  }

  final client = http.Client();
  try {
    final request = http.Request('GET', uri);
    request.headers['User-Agent'] = _kDownloadUserAgent;
    request.headers['Accept'] = '*/*';
    request.headers['Accept-Encoding'] = 'identity';
    final response = await client.send(request);
    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}');
    }

    final total = response.contentLength ?? -1;
    var received = 0;
    final sink = file.openWrite();
    try {
      await for (final chunk in response.stream) {
        received += chunk.length;
        sink.add(chunk);
        if (onProgress != null && total > 0) {
          onProgress(received / total, received, total);
        } else if (onProgress != null) {
          onProgress(-1, received, total);
        }
      }
    } finally {
      await sink.flush();
      await sink.close();
    }
  } finally {
    client.close();
  }

  return path;
}

/// Launches the downloaded Windows update (installer exe or zip + updater).
Future<WindowsUpdateLaunchStatus> launchWindowsUpdate(String filePath) async {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.windows) {
    return WindowsUpdateLaunchStatus.failed;
  }

  final file = File(filePath);
  if (!await file.exists()) return WindowsUpdateLaunchStatus.failed;

  final lower = filePath.toLowerCase();
  if (lower.endsWith('.exe')) {
    return _launchExeInstaller(filePath);
  }
  if (lower.endsWith('.zip')) {
    return _launchZipUpdater(filePath);
  }
  return WindowsUpdateLaunchStatus.failed;
}

Future<WindowsUpdateLaunchStatus> _launchExeInstaller(String exePath) async {
  try {
    await Process.start(
      exePath,
      ['/SILENT', '/CLOSEAPPLICATIONS'],
      mode: ProcessStartMode.detached,
    );
    return WindowsUpdateLaunchStatus.launched;
  } catch (_) {
    try {
      await Process.start(exePath, [], mode: ProcessStartMode.detached);
      return WindowsUpdateLaunchStatus.launched;
    } catch (_) {
      return WindowsUpdateLaunchStatus.failed;
    }
  }
}

Future<WindowsUpdateLaunchStatus> _launchZipUpdater(String zipPath) async {
  final exePath = Platform.resolvedExecutable;
  final installDir = File(exePath).parent.path;
  final processId = pid;

  final tempDir = await getTemporaryDirectory();
  final batchPath = '${tempDir.path}\\$_kUpdaterBatchName';
  final logPaths = await windowsUpdateLogPaths();
  final logPath = logPaths.first;

  await _appendUpdaterLog(logPath, 'Dart: install requested');
  await _appendUpdaterLog(logPath, 'Dart: zip=$zipPath');
  await _appendUpdaterLog(logPath, 'Dart: target=$installDir');
  await _appendUpdaterLog(logPath, 'Dart: exe=$exePath');
  await _appendUpdaterLog(logPath, 'Dart: pid=$processId');

  // Single batch file — no separate .ps1 (avoids -File param / encoding issues).
  const batchTemplate = r'''
@echo off
setlocal EnableDelayedExpansion
set "LOG=%~1"
set "ZIP=%~2"
set "DIR=%~3"
set "EXE=%~4"
set "WAITPID=%~5"
call :WriteLog "Updater.cmd started"
call :WriteLog "ZIP=%ZIP%"
call :WriteLog "DIR=%DIR%"
call :WriteLog "EXE=%EXE%"
call :WriteLog "WAITPID=%WAITPID%"

set /a WAITSEC=0
:WaitLoop
tasklist /FI "PID eq %WAITPID%" 2>NUL | find /I "%WAITPID%" >NUL
if not errorlevel 1 (
  timeout /t 1 /nobreak >NUL
  set /a WAITSEC+=1
  if !WAITSEC! lss 90 goto WaitLoop
)
call :WriteLog "Wait loop done (%WAITSEC%s)"
timeout /t 3 /nobreak >NUL

set "EXTRACT=%TEMP%\erfan_academy_update_extract"
if exist "%EXTRACT%" rd /s /q "%EXTRACT%"
mkdir "%EXTRACT%" 2>NUL
call :WriteLog "Expanding archive..."
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "try { Expand-Archive -Path '%ZIP%' -DestinationPath '%EXTRACT%' -Force; exit 0 } catch { Write-Error $_; exit 1 }" >> "%LOG%" 2>&1
if errorlevel 1 (
  call :WriteLog "Expand-Archive FAILED"
  goto Relaunch
)

set "SRC=%EXTRACT%"
if exist "%EXTRACT%\Release\" set "SRC=%EXTRACT%\Release"
call :WriteLog "Copy source=%SRC%"

set /a COPYTRY=0
:CopyLoop
set /a COPYTRY+=1
robocopy "%SRC%" "%DIR%" /E /COPY:DAT /R:3 /W:2 /NFL /NDL /NJH /NJS /NP >> "%LOG%" 2>&1
set RC=!ERRORLEVEL!
if !RC! geq 0 if !RC! leq 7 (
  call :WriteLog "robocopy ok code=!RC! try=!COPYTRY!"
  goto Relaunch
)
call :WriteLog "robocopy code=!RC! try=!COPYTRY!"
if !COPYTRY! lss 6 (
  timeout /t 2 /nobreak >NUL
  goto CopyLoop
)

:Relaunch
call :WriteLog "Starting app..."
start "" /D "%DIR%" "%EXE%"
call :WriteLog "Updater.cmd finished"
exit /b 0

:WriteLog
echo [%date% %time%] %~1 >> "%LOG%"
exit /b 0
''';

  await File(batchPath).writeAsString(batchTemplate, flush: true);
  await _appendUpdaterLog(logPath, 'Dart: wrote batch $batchPath');

  try {
    // Detached child — do not wait (Process.run + start was blocking UI).
    await Process.start(
      'cmd.exe',
      [
        '/c',
        'start',
        '""',
        '/min',
        'cmd.exe',
        '/c',
        batchPath,
        logPath,
        zipPath,
        installDir,
        exePath,
        '$processId',
      ],
      mode: ProcessStartMode.detached,
    );
    await _appendUpdaterLog(logPath, 'Dart: updater spawned (detached)');
    return WindowsUpdateLaunchStatus.launched;
  } catch (e) {
    await _appendUpdaterLog(logPath, 'Dart: spawn failed: $e');
    return WindowsUpdateLaunchStatus.failed;
  }
}
