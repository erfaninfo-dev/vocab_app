import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// Persists grammar topic PDF files on device after the first download.
///
/// Before reusing a cached file, sends a lightweight HTTP HEAD to compare
/// [ETag] / [Last-Modified] / [Content-Length]. Replacing the PDF on the
/// server (same URL) is enough — no manual MySQL update required.
/// [contentVersion] from `updated_at` is an optional extra signal.
class GrammarTopicPdfCache {
  GrammarTopicPdfCache._();
  static final GrammarTopicPdfCache instance = GrammarTopicPdfCache._();

  Directory? _dir;
  Map<String, _CacheEntry> _index = {};
  final Map<String, Future<String?>> _inFlight = {};

  Future<void> init() async {
    try {
      final root = await getApplicationSupportDirectory();
      _dir = Directory('${root.path}/grammar_topic_pdfs');
      if (!await _dir!.exists()) {
        await _dir!.create(recursive: true);
      }
      await _loadIndex();
      await _migrateLegacyTopicIndex();
    } catch (_) {
      _dir = null;
      _index = {};
    }
  }

  Future<String?> ensureCached({
    required String pdfUrl,
    String? contentVersion,
  }) async {
    final url = pdfUrl.trim();
    if (url.isEmpty) return null;

    final version = (contentVersion ?? '').trim();
    final cacheKey = _cacheKey(url);
    final existing = _inFlight[cacheKey];
    if (existing != null) return existing;

    final future = _ensureCachedImpl(
      cacheKey: cacheKey,
      pdfUrl: url,
      contentVersion: version,
    );
    _inFlight[cacheKey] = future;
    try {
      return await future;
    } finally {
      _inFlight.remove(cacheKey);
    }
  }

  Future<void> invalidate({
    required String pdfUrl,
    String? contentVersion,
  }) async {
    final url = pdfUrl.trim();
    if (url.isEmpty) return;
    final cacheKey = _cacheKey(url);
    final entry = _index.remove(cacheKey);
    if (entry != null) {
      await _deleteFile(entry.fileName);
      await _saveIndex();
    }
  }

  Future<String?> _ensureCachedImpl({
    required String cacheKey,
    required String pdfUrl,
    required String contentVersion,
  }) async {
    final dir = _dir;
    if (dir == null) return null;

    final remoteTag = await _fetchRemoteTag(pdfUrl);
    final cached = _index[cacheKey];
    if (cached != null &&
        cached.pdfUrl == pdfUrl &&
        cached.contentVersion == contentVersion &&
        await _fileExists(cached.fileName) &&
        _isRemoteTagFresh(cached.remoteTag, remoteTag)) {
      return '${dir.path}/${cached.fileName}';
    }

    if (cached != null) {
      await _deleteFile(cached.fileName);
    }

    final fileName = '${_hashKey(pdfUrl)}.pdf';
    final file = File('${dir.path}/$fileName');
    final bytes = await _downloadPdf(pdfUrl);
    await file.writeAsBytes(bytes, flush: true);

    _index[cacheKey] = _CacheEntry(
      pdfUrl: pdfUrl,
      fileName: fileName,
      contentVersion: contentVersion,
      remoteTag: remoteTag ?? _fallbackTagFromBytes(bytes),
    );
    await _saveIndex();
    return file.path;
  }

  bool _isRemoteTagFresh(String? cachedTag, String? remoteTag) {
    if (remoteTag == null || remoteTag.isEmpty) {
      // HEAD unavailable (offline / blocked) — keep local cache.
      return true;
    }
    return cachedTag == remoteTag;
  }

  Future<String?> _fetchRemoteTag(String pdfUrl) async {
    final uri = Uri.tryParse(pdfUrl);
    if (uri == null) return null;
    try {
      final response = await http.head(uri);
      if (response.statusCode < 200 || response.statusCode >= 400) {
        return null;
      }
      return _remoteTagFromHeaders(response.headers);
    } catch (_) {
      return null;
    }
  }

  String? _remoteTagFromHeaders(Map<String, String> headers) {
    final normalized = <String, String>{
      for (final entry in headers.entries)
        entry.key.toLowerCase(): entry.value.trim(),
    };
    final etag = normalized['etag'];
    if (etag != null && etag.isNotEmpty) return 'etag:$etag';
    final lastModified = normalized['last-modified'];
    if (lastModified != null && lastModified.isNotEmpty) {
      return 'lm:$lastModified';
    }
    final length = normalized['content-length'];
    if (length != null && length.isNotEmpty) return 'len:$length';
    return null;
  }

  String _fallbackTagFromBytes(List<int> bytes) => 'bytes:${bytes.length}';

  Future<void> _migrateLegacyTopicIndex() async {
    final next = <String, _CacheEntry>{};
    for (final entry in _index.entries) {
      final value = entry.value;
      next[_cacheKey(value.pdfUrl)] = value;
    }
    if (next.length != _index.length ||
        !next.keys.every(_index.containsKey)) {
      _index = next;
      await _saveIndex();
    }
  }

  Future<void> _loadIndex() async {
    final dir = _dir;
    if (dir == null) return;
    try {
      final indexFile = File('${dir.path}/index.json');
      if (!await indexFile.exists()) {
        _index = {};
        return;
      }
      final raw = await indexFile.readAsString();
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        _index = {};
        return;
      }
      final next = <String, _CacheEntry>{};
      for (final entry in decoded.entries) {
        final value = entry.value;
        if (value is! Map) continue;
        final pdfUrl = (value['pdfUrl'] ?? '').toString();
        final fileName = (value['fileName'] ?? '').toString();
        final contentVersion = (value['contentVersion'] ?? '').toString();
        final remoteTag = (value['remoteTag'] ?? '').toString();
        if (pdfUrl.isEmpty || fileName.isEmpty) continue;
        next[_cacheKey(pdfUrl)] = _CacheEntry(
          pdfUrl: pdfUrl,
          fileName: fileName,
          contentVersion: contentVersion,
          remoteTag: remoteTag.isEmpty ? null : remoteTag,
        );
      }
      _index = next;
    } catch (_) {
      _index = {};
    }
  }

  Future<void> _saveIndex() async {
    final dir = _dir;
    if (dir == null) return;
    try {
      final payload = {
        for (final entry in _index.entries)
          entry.key: {
            'pdfUrl': entry.value.pdfUrl,
            'fileName': entry.value.fileName,
            'contentVersion': entry.value.contentVersion,
            'remoteTag': entry.value.remoteTag,
          },
      };
      final indexFile = File('${dir.path}/index.json');
      await indexFile.writeAsString(jsonEncode(payload));
    } catch (_) {}
  }

  Future<List<int>> _downloadPdf(String pdfUrl) async {
    final uri = Uri.tryParse(pdfUrl);
    if (uri == null) {
      throw Exception('Invalid PDF URL');
    }
    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw Exception('PDF download failed (${response.statusCode})');
    }
    final bytes = response.bodyBytes;
    if (bytes.length < 4 ||
        String.fromCharCodes(bytes.take(4)) != '%PDF') {
      throw Exception('Downloaded file is not a PDF');
    }
    return bytes;
  }

  Future<bool> _fileExists(String fileName) async {
    final dir = _dir;
    if (dir == null) return false;
    return File('${dir.path}/$fileName').exists();
  }

  Future<void> _deleteFile(String fileName) async {
    final dir = _dir;
    if (dir == null) return;
    try {
      final file = File('${dir.path}/$fileName');
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }

  String _cacheKey(String pdfUrl) => 'url|${_hashKey(pdfUrl)}';

  String _hashKey(String input) {
    var h = 2166136261;
    var h2 = 5381;
    for (final x in utf8.encode(input)) {
      h ^= x;
      h = h * 16777619;
      h2 = ((h2 << 5) + h2) + x;
    }
    return '${h & 0x7fffffff}_${h2 & 0x7fffffff}';
  }
}

class _CacheEntry {
  const _CacheEntry({
    required this.pdfUrl,
    required this.fileName,
    required this.contentVersion,
    this.remoteTag,
  });

  final String pdfUrl;
  final String fileName;
  final String contentVersion;
  final String? remoteTag;
}
