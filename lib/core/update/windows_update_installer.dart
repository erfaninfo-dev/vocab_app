import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../network/resolve_update_url.dart';

const _kDownloadUserAgent =
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';

const _kWindowsZipFileName = 'erfan_academy_update.zip';
const _kWindowsExeFileName = 'erfan_academy_update.exe';
const _kUpdaterScriptName = 'erfan_academy_updater.ps1';
const _kUpdaterBatchName = 'erfan_academy_updater.cmd';
const _kUpdaterLogName = 'erfan_academy_update.log';

/// Primary log: next to the running exe (easy to find). Fallback: system temp.
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
  final scriptPath = '${tempDir.path}\\$_kUpdaterScriptName';
  final batchPath = '${tempDir.path}\\$_kUpdaterBatchName';
  final logPaths = await windowsUpdateLogPaths();
  final logPath = logPaths.first;

  await _appendUpdaterLog(logPath, 'Dart: install requested');
  await _appendUpdaterLog(logPath, 'Dart: zip=$zipPath');
  await _appendUpdaterLog(logPath, 'Dart: target=$installDir');
  await _appendUpdaterLog(logPath, 'Dart: exe=$exePath');
  await _appendUpdaterLog(logPath, 'Dart: pid=$processId');

  const scriptTemplate = r'''
param(
  [string]$ZipPath,
  [string]$TargetDir,
  [string]$ExePath,
  [int]$WaitPid,
  [string]$LogFile
)

function Log([string]$Msg) {
  try {
    Add-Content -LiteralPath $LogFile -Value "$(Get-Date -Format o) $Msg"
  } catch {}
}

$ErrorActionPreference = "Continue"
Log "PowerShell updater started"
Log "Zip=$ZipPath"
Log "Target=$TargetDir"
Log "Exe=$ExePath"
Log "WaitPid=$WaitPid"

try {
  Wait-Process -Id $WaitPid -ErrorAction SilentlyContinue
} catch {
  Log "Wait-Process: $_"
}

$exeName = [System.IO.Path]::GetFileNameWithoutExtension($ExePath)
for ($i = 0; $i -lt 45; $i++) {
  $running = Get-Process -Name $exeName -ErrorAction SilentlyContinue
  if (-not $running) { break }
  Start-Sleep -Seconds 1
}
Start-Sleep -Seconds 3
Log "App process ended"

$temp = Join-Path $env:TEMP "erfan_academy_update_extract"
try {
  if (Test-Path -LiteralPath $temp) {
    Remove-Item -LiteralPath $temp -Recurse -Force -ErrorAction SilentlyContinue
  }
  New-Item -ItemType Directory -Path $temp -Force | Out-Null
  Expand-Archive -LiteralPath $ZipPath -DestinationPath $temp -Force
  $src = $temp
  $releaseDir = Join-Path $temp "Release"
  if (Test-Path -LiteralPath $releaseDir) { $src = $releaseDir }
  Log "Extracted to $src"

  $copied = $false
  for ($attempt = 1; $attempt -le 8; $attempt++) {
    $robocopy = Get-Command robocopy -ErrorAction SilentlyContinue
    if ($robocopy) {
      $null = & robocopy $src $TargetDir /E /COPY:DAT /R:5 /W:2 /NFL /NDL /NJH /NJS /NP
      $code = $LASTEXITCODE
      if ($code -ge 0 -and $code -le 7) {
        Log "robocopy ok (code $code) attempt $attempt"
        $copied = $true
        break
      }
      Log "robocopy code $code attempt $attempt"
    } else {
      try {
        Copy-Item -Path (Join-Path $src '*') -Destination $TargetDir -Recurse -Force -ErrorAction Stop
        Log "Copy-Item ok attempt $attempt"
        $copied = $true
        break
      } catch {
        Log "Copy-Item failed attempt $attempt: $_"
      }
    }
    Start-Sleep -Seconds 2
  }
  if (-not $copied) {
    Log "Copy did not succeed; will still try relaunch"
  }
} catch {
  Log "Extract/copy error: $_"
}

Log "Relaunching $ExePath"
$relaunched = $false
try {
  Start-Process -LiteralPath $ExePath -WorkingDirectory $TargetDir
  Log "Start-Process ok"
  $relaunched = $true
} catch {
  Log "Start-Process failed: $_"
}

if (-not $relaunched) {
  try {
    $arg = 'start "" /D "' + $TargetDir + '" "' + $ExePath + '"'
    Start-Process -FilePath "cmd.exe" -ArgumentList '/c', $arg -WindowStyle Hidden
    Log "cmd start ok"
    $relaunched = $true
  } catch {
    Log "cmd start failed: $_"
  }
}

if (-not $relaunched) {
  try {
    $shell = New-Object -ComObject WScript.Shell
    $shell.WorkingDirectory = $TargetDir
    $null = $shell.Run('"' + $ExePath + '"', 1, $false)
    Log "WScript.Shell Run ok"
  } catch {
    Log "WScript.Shell failed: $_"
  }
}

try {
  if (Test-Path -LiteralPath $temp) {
    Remove-Item -LiteralPath $temp -Recurse -Force -ErrorAction SilentlyContinue
  }
} catch {}

Log "Updater finished"
''';

  await File(scriptPath).writeAsString(scriptTemplate, flush: true);

  // Batch wrapper logs immediately and spawns PowerShell via quoted paths (spaces-safe).
  final batchContent = '''
@echo off
set "LOG=$logPath"
set "PS1=$scriptPath"
set "ZIP=$zipPath"
set "DIR=$installDir"
set "EXE=$exePath"
echo [%date% %time%] Updater.cmd started >> "%LOG%"
powershell.exe -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File "%PS1%" -ZipPath "%ZIP%" -TargetDir "%DIR%" -ExePath "%EXE%" -WaitPid $processId -LogFile "%LOG%"
echo [%date% %time%] Updater.cmd finished (exit %ERRORLEVEL%) >> "%LOG%"
''';

  await File(batchPath).writeAsString(batchContent, flush: true);
  await _appendUpdaterLog(logPath, 'Dart: wrote script and batch');

  try {
  // `start` creates a process that survives parent exit (unlike detached PowerShell alone).
    final result = await Process.run(
      'cmd.exe',
      [
        '/c',
        'start',
        '""',
        '/min',
        batchPath,
      ],
      runInShell: false,
    );
    await _appendUpdaterLog(
      logPath,
      'Dart: cmd start exit=${result.exitCode} stderr=${result.stderr}',
    );
    if (result.exitCode != 0) {
      return WindowsUpdateLaunchStatus.failed;
    }
    return WindowsUpdateLaunchStatus.launched;
  } catch (e) {
    await _appendUpdaterLog(logPath, 'Dart: cmd start failed: $e');
    return WindowsUpdateLaunchStatus.failed;
  }
}
