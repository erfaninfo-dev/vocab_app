/// No-op on platforms without `dart:io` (e.g. web).
class ApiDiskCache {
  ApiDiskCache._();
  static final ApiDiskCache instance = ApiDiskCache._();

  Future<void> init() async {}

  Future<String?> read(String key) async => null;

  Future<void> write(
    String key,
    String body, {
    required Duration ttl,
  }) async {}

  Future<void> clearAll() async {}

  Future<void> remove(String key) async {}
}
