import 'dart:convert';
import 'dart:io';

/// SSE 建连阶段 HTTP 非 2xx（含响应体与 `x-trace-id`）。
class SseHttpException implements Exception {
  SseHttpException({
    required this.statusCode,
    required this.uri,
    this.body,
    this.traceId,
    this.code,
    this.reason,
    this.message,
  });

  final int statusCode;
  final Uri uri;
  final String? body;
  final String? traceId;
  final Object? code;
  final String? reason;
  final String? message;

  /// 给用户 / SnackBar 的短句。
  String get displayMessage {
    final m = message?.trim();
    if (m != null && m.isNotEmpty) return m;
    return '请求失败 (HTTP $statusCode)';
  }

  @override
  String toString() {
    final parts = <String>['SSE HTTP $statusCode'];
    if (traceId != null && traceId!.isNotEmpty) {
      parts.add('x-trace-id=$traceId');
    }
    if (code != null) parts.add('code=$code');
    if (reason != null && reason!.isNotEmpty) parts.add('reason=$reason');
    if (message != null && message!.isNotEmpty) parts.add('message=$message');
    return parts.join(' ');
  }

  static String? readTraceId(HttpHeaders headers) {
    final v = headers.value('x-trace-id') ?? headers.value('X-Trace-Id');
    if (v == null) return null;
    final t = v.trim();
    return t.isEmpty ? null : t;
  }

  static ({Object? code, String? reason, String? message})? parseErrorBody(
    String raw,
  ) {
    final t = raw.trim();
    if (t.isEmpty) return null;
    try {
      final o = jsonDecode(t);
      if (o is! Map) return null;
      final m = o is Map<String, dynamic> ? o : Map<String, dynamic>.from(o);
      return (
        code: m['code'],
        reason: m['reason']?.toString(),
        message: m['message']?.toString(),
      );
    } catch (_) {
      return null;
    }
  }
}
