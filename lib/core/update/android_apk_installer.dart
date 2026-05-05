import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

Future<void> downloadAndOpenAndroidApk(
  String url, {
  void Function(double progress, int received, int total)? onProgress,
}) async {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
    return;
  }

  final uri = Uri.parse(url);
  final dir = await getTemporaryDirectory();
  final path = '${dir.path}/erfan_academy_update.apk';
  final file = File(path);

  final client = http.Client();
  try {
    final request = http.Request('GET', uri);
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

  final result = await OpenFilex.open(path);
  if (result.type != ResultType.done) {
    throw Exception(
      result.message.isNotEmpty ? result.message : 'install_failed',
    );
  }
}
