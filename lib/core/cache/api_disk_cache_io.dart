import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Persists successful GET response bodies (JSON strings) with TTL.
/// Does not cache [words.php] — that is enforced in [ApiService].
class ApiDiskCache {
  ApiDiskCache._();
  static final ApiDiskCache instance = ApiDiskCache._();

  Directory? _dir;

  Future<void> init() async {
    try {
      final root = await getApplicationSupportDirectory();
      _dir = Directory('${root.path}/api_http_cache');
      if (!await _dir!.exists()) {
        await _dir!.create(recursive: true);
      }
    } catch (_) {
      _dir = null;
    }
  }

  String _fileName(String key) {
    var h = 2166136261;
    var h2 = 5381;
    for (final x in utf8.encode(key)) {
      h ^= x;
      h = h * 16777619;
      h2 = ((h2 << 5) + h2) + x;
    }
    return '${h & 0x7fffffff}_${h2 & 0x7fffffff}.json';
  }

  Future<String?> read(String key) async {
    final d = _dir;
    if (d == null) return null;
    try {
      final f = File('${d.path}/${_fileName(key)}');
      if (!await f.exists()) return null;
      final raw = await f.readAsString();
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final exp = map['exp'] as int;
      if (DateTime.now().millisecondsSinceEpoch > exp) {
        await f.delete();
        return null;
      }
      return map['body'] as String?;
    } catch (_) {
      return null;
    }
  }

  Future<void> write(
    String key,
    String body, {
    required Duration ttl,
  }) async {
    final d = _dir;
    if (d == null) return;
    try {
      final exp = DateTime.now().add(ttl).millisecondsSinceEpoch;
      final payload = jsonEncode({'exp': exp, 'body': body});
      final f = File('${d.path}/${_fileName(key)}');
      await f.writeAsString(payload);
    } catch (_) {}
  }

  Future<void> clearAll() async {
    final d = _dir;
    if (d == null) return;
    try {
      if (await d.exists()) {
        await d.delete(recursive: true);
        await d.create(recursive: true);
      }
    } catch (_) {}
  }

  Future<void> remove(String key) async {
    final d = _dir;
    if (d == null) return;
    try {
      final f = File('${d.path}/${_fileName(key)}');
      if (await f.exists()) {
        await f.delete();
      }
    } catch (_) {}
  }
}
