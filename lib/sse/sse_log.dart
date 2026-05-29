import 'dart:async';
import 'dart:convert';

import '../http_config.dart';
import 'sse_event.dart';
import 'sse_http_exception.dart';

/// SSE 单次连接日志上下文（对齐 Dio [LogInterceptor] 的 requestId + 耗时统计）。
class SseLogSession {
  SseLogSession({
    required this.requestId,
    required this.startTime,
    required this.method,
    required this.path,
    required this.url,
    this.body,
  });

  final String requestId;
  final DateTime startTime;
  final String method;
  final String path;
  final String url;
  final String? body;

  bool connected = false;
  int? httpStatus;
  String? contentType;
  String? contentTypeWarning;
  String? traceId;

  int eventCount = 0;
  int deltaCount = 0;
  final Map<String, int> eventTypeCounts = <String, int>{};
  String? lastNonDeltaPreview;
  String? lastErrorPreview;

  /// HTTP 建连失败（非 2xx）时的响应摘要。
  int? httpErrorStatus;
  String? httpErrorBody;
  Object? httpErrorCode;
  String? httpErrorReason;
  String? httpErrorMessage;

  Duration get elapsed => DateTime.now().difference(startTime);

  void applyHttpError(Object error) {
    if (error is! SseHttpException) return;
    httpErrorStatus = error.statusCode;
    traceId = error.traceId;
    httpErrorBody = error.body;
    httpErrorCode = error.code;
    httpErrorReason = error.reason;
    httpErrorMessage = error.message;
  }

  void markConnected({required int status, String? contentType}) {
    connected = true;
    httpStatus = status;
    this.contentType = contentType;
  }

  void recordEvent(SSEEvent event) {
    eventCount++;
    var type = (event.event ?? '').trim().toLowerCase();
    if (type.isEmpty) {
      type = _inferEventTypeFromData(event.data);
    }
    if (type == 'delta') {
      deltaCount++;
      return;
    }
    eventTypeCounts[type] = (eventTypeCounts[type] ?? 0) + 1;
    final preview = SseLog._truncate(event.data, SseLog._maxEventPreview);
    lastNonDeltaPreview = '[$type] $preview';
    if (type == 'error') {
      lastErrorPreview = preview;
    }
  }

  static String _inferEventTypeFromData(String data) {
    final t = data.trim();
    if (t.isEmpty) return 'message';
    try {
      final o = jsonDecode(t);
      if (o is Map) {
        final v = o['type'] ?? o['event'];
        if (v != null) return '$v'.trim().toLowerCase();
      }
    } catch (_) {}
    return 'message';
  }

  String eventSummary() {
    if (eventCount == 0) return '0';
    final parts = <String>[];
    if (deltaCount > 0) parts.add('delta×$deltaCount');
    final sorted = eventTypeCounts.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    for (final e in sorted) {
      parts.add('${e.key}×${e.value}');
    }
    return '$eventCount total (${parts.join(', ')})';
  }
}

/// SSE 日志（格式与 [LogInterceptor] / `[HttpUtil]` 保持一致）。
abstract final class SseLog {
  SseLog._();

  static const String tag = '[HttpUtil]';
  static const String _top =
      '┌─────────────────────────────────────────────────────────────';
  static const String _sep =
      '│ ───────────────────────────────────────────────────────────';
  static const String _bottom =
      '└─────────────────────────────────────────────────────────────';

  static const int _maxBodyPreview = 2048;
  static const int _maxEventPreview = 600;
  static const int _maxErrorPreview = 1200;

  static Completer<void> _logLock = Completer<void>()..complete();

  static Future<void> _synchronized(Future<void> Function() action) async {
    final previous = _logLock;
    final current = Completer<void>();
    _logLock = current;
    await previous.future;
    try {
      await action();
    } finally {
      current.complete();
    }
  }

  static void _printBuffer(StringBuffer buffer) {
    for (final line in buffer.toString().split('\n')) {
      if (line.isNotEmpty) print(line);
    }
  }

  static String _formatDuration(Duration d) {
    if (d.inMilliseconds < 1000) return '${d.inMilliseconds}ms';
    return '${(d.inMilliseconds / 1000).toStringAsFixed(2)}s';
  }

  static String _requestId() {
    final ts = DateTime.now().microsecondsSinceEpoch;
    final s = ts.toString();
    final tail = s.length > 6 ? s.substring(s.length - 6) : s;
    return '${tail}_sse';
  }

  static String _truncate(String text, int max) {
    if (text.length <= max) return text;
    return '${text.substring(0, max)}…';
  }

  static String? _formatBody(dynamic data, bool printBody) {
    if (!printBody || data == null) return null;
    try {
      final raw = data is String ? data : jsonEncode(data);
      return _truncate(raw, _maxBodyPreview);
    } catch (_) {
      return _truncate('$data', _maxBodyPreview);
    }
  }

  static SseLogSession begin({
    required String method,
    required String path,
    required String url,
    dynamic data,
    required HttpConfig config,
  }) {
    return SseLogSession(
      requestId: _requestId(),
      startTime: DateTime.now(),
      method: method.toUpperCase(),
      path: path,
      url: url,
      body: _formatBody(data, config.logPrintBody),
    );
  }

  /// 完整链路模式：连接前一行提示（对齐 `→ POST url [id]`）。
  static void logRequestHint(SseLogSession session, HttpConfig config) {
    if (!config.enableLogging) return;
    if (config.logMode != LogMode.complete || !config.logShowRequestHint) {
      return;
    }
    _synchronized(() async {
      print(
        '$tag → ${session.method} ${session.url} (SSE) [${session.requestId}]',
      );
    });
  }

  /// 实时模式：连接瞬间打印请求块。
  static void logRequestRealTime(SseLogSession session, HttpConfig config) {
    if (!config.enableLogging || config.logMode != LogMode.realTime) return;
    _synchronized(() async {
      final b = StringBuffer();
      b.writeln('$tag $_top');
      b.writeln('$tag │ SSE Request: ${session.method} ${session.url}');
      b.writeln('$tag │    Connection-ID: ${session.requestId}');
      if (session.body != null) {
        b.writeln('$tag │    Body:');
        b.writeln('$tag │      ${session.body}');
      }
      b.writeln('$tag $_bottom');
      _printBuffer(b);
    });
  }

  /// 简要模式：仅一行出站。
  static void logRequestBrief(SseLogSession session, HttpConfig config) {
    if (!config.enableLogging || config.logMode != LogMode.brief) return;
    _synchronized(() async {
      print('$tag → ${session.method} ${session.path} (SSE)');
    });
  }

  /// 实时模式：单条非 delta 事件。
  static void logEventRealTime(
    SseLogSession session,
    SSEEvent event,
    HttpConfig config,
  ) {
    if (!config.enableLogging || config.logMode != LogMode.realTime) return;
    var type = (event.event ?? '').trim();
    if (type.isEmpty) {
      type = SseLogSession._inferEventTypeFromData(event.data);
    }
    if (type.toLowerCase() == 'delta') return;

    final preview = _truncate(event.data, _maxEventPreview);
    _synchronized(() async {
      print(
        '$tag │ SSE event [${session.requestId}] '
        '$type id=${event.id ?? '-'} $preview',
      );
    });
  }

  /// 流正常结束：打印完整链路（complete）或简要行（brief）。
  static void logStreamComplete(SseLogSession session, HttpConfig config) {
    if (!config.enableLogging) return;
    switch (config.logMode) {
      case LogMode.complete:
        _logCompleteChain(session, success: true);
      case LogMode.realTime:
        _logStreamEndRealTime(session, success: true);
      case LogMode.brief:
        _logStreamEndBrief(session, success: true);
    }
  }

  /// 连接失败 / 流错误 / HTTP 非 200（**await**，保证在 rethrow 前打完日志）。
  static Future<void> logFailure(
    SseLogSession session,
    Object error,
    HttpConfig config, {
    String phase = 'connect',
  }) async {
    if (!config.enableLogging) return;
    session.applyHttpError(error);
    switch (config.logMode) {
      case LogMode.complete:
        await _logCompleteChain(session, success: false, error: error, phase: phase);
      case LogMode.realTime:
        await _logStreamEndRealTime(session, success: false, error: error);
      case LogMode.brief:
        await _logStreamEndBrief(session, success: false, error: error);
    }
  }

  static Future<void> _logCompleteChain(
    SseLogSession session, {
    required bool success,
    Object? error,
    String phase = 'stream',
  }) {
    return _synchronized(() async {
      final icon = success ? '✅' : '❌';
      final b = StringBuffer();
      b.writeln('$tag $_top');
      b.writeln(
        '$tag │ [SSE链路 #${session.requestId}] ${session.method} '
        '${session.url} (耗时: ${_formatDuration(session.elapsed)}) $icon',
      );
      b.writeln('$tag $_sep');
      b.writeln('$tag │ 📤 Request (SSE):');
      b.writeln('$tag │    Method: ${session.method}');
      b.writeln('$tag │    URL: ${session.url}');
      if (session.body != null) {
        b.writeln('$tag │    Body:');
        b.writeln('$tag │      ${session.body}');
      }
      b.writeln('$tag $_sep');
      if (success) {
        b.writeln('$tag │ 📡 Stream:');
        if (session.connected) {
          b.writeln(
            '$tag │    HTTP: ${session.httpStatus ?? 200} (connected)',
          );
          if (session.contentType != null) {
            b.writeln('$tag │    Content-Type: ${session.contentType}');
          }
          if (session.contentTypeWarning != null) {
            b.writeln('$tag │    ⚠️ ${session.contentTypeWarning}');
          }
          if (session.traceId != null) {
            b.writeln('$tag │    x-trace-id: ${session.traceId}');
          }
          b.writeln('$tag │    Events: ${session.eventSummary()}');
          if (session.lastNonDeltaPreview != null) {
            b.writeln('$tag │    Last event: ${session.lastNonDeltaPreview}');
          }
        } else {
          b.writeln('$tag │    (未建立连接)');
        }
      } else {
        b.writeln('$tag │ ❌ Error:');
        b.writeln('$tag │    Phase: $phase');
        _appendHttpErrorToBuffer(b, session, error);
        if (session.lastErrorPreview != null) {
          b.writeln('$tag │    SSE error event: ${session.lastErrorPreview}');
        }
        if (session.eventCount > 0) {
          b.writeln('$tag │    Events before fail: ${session.eventSummary()}');
        }
      }
      b.writeln('$tag $_bottom');
      _printBuffer(b);
    });
  }

  static void _appendHttpErrorToBuffer(
    StringBuffer b,
    SseLogSession session,
    Object? error,
  ) {
    if (session.httpErrorStatus != null) {
      b.writeln('$tag │    Status: ${session.httpErrorStatus}');
    } else if (error is SseHttpException) {
      b.writeln('$tag │    Status: ${error.statusCode}');
    }
    final trace = session.traceId ??
        (error is SseHttpException ? error.traceId : null);
    if (trace != null && trace.isNotEmpty) {
      b.writeln('$tag │    x-trace-id: $trace');
    }
    if (session.httpErrorCode != null) {
      b.writeln('$tag │    code: ${session.httpErrorCode}');
    }
    if (session.httpErrorReason != null &&
        session.httpErrorReason!.isNotEmpty) {
      b.writeln('$tag │    reason: ${session.httpErrorReason}');
    }
    if (session.httpErrorMessage != null &&
        session.httpErrorMessage!.isNotEmpty) {
      b.writeln('$tag │    message: ${session.httpErrorMessage}');
    } else if (error is SseHttpException) {
      b.writeln('$tag │    message: ${error.displayMessage}');
    } else if (error != null) {
      b.writeln('$tag │    detail: ${_formatError(error)}');
    }
    final body = session.httpErrorBody ??
        (error is SseHttpException ? error.body : null);
    if (body != null && body.trim().isNotEmpty) {
      b.writeln('$tag │    Body:');
      b.writeln('$tag │      ${_truncate(body, _maxErrorPreview)}');
    }
  }

  static Future<void> _logStreamEndRealTime(
    SseLogSession session, {
    required bool success,
    Object? error,
  }) {
    return _synchronized(() async {
      final b = StringBuffer();
      b.writeln('$tag $_top');
      b.writeln(
        '$tag │ SSE ${success ? 'Done' : 'Failed'} '
        '[${session.requestId}] (${_formatDuration(session.elapsed)})',
      );
      b.writeln('$tag │    Events: ${session.eventSummary()}');
      if (!success) {
        _appendHttpErrorToBuffer(b, session, error);
      }
      b.writeln('$tag $_bottom');
      _printBuffer(b);
    });
  }

  static Future<void> _logStreamEndBrief(
    SseLogSession session, {
    required bool success,
    Object? error,
  }) {
    return _synchronized(() async {
      final mark = success ? '←' : '✗';
      final trace = session.traceId != null ? ' trace=${session.traceId}' : '';
      final errBit = !success && error is SseHttpException
          ? ' HTTP${error.statusCode} ${error.displayMessage}$trace'
          : (error != null ? ' ${_formatError(error)}' : '');
      print(
        '$tag $mark SSE ${session.method} ${session.path} '
        '(${_formatDuration(session.elapsed)}) '
        'events=${session.eventCount}$errBit',
      );
    });
  }

  static String _formatError(Object? error) {
    if (error == null) return 'unknown';
    final text = '$error';
    return _truncate(text, _maxErrorPreview);
  }
}
