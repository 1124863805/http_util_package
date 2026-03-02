import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// 隐私协议弹窗配置
class PrivacyAgreementConfig {
  const PrivacyAgreementConfig({
    this.title = '用户协议与隐私政策',
    this.content =
        '欢迎使用本应用！我们非常重视您的个人信息和隐私保护。'
        '请您务必审慎阅读、充分理解《用户协议》和《隐私政策》各条款。'
        '您点击「同意」即表示您已阅读并同意上述协议。',
    this.userAgreementUrl,
    this.privacyPolicyUrl,
    this.acceptText = '同意',
    this.rejectText = '不同意',
  });

  final String title;
  final String content;
  final String? userAgreementUrl;
  final String? privacyPolicyUrl;
  final String acceptText;
  final String rejectText;
}

/// 隐私协议弹窗
class PrivacyAgreementDialog extends StatelessWidget {
  const PrivacyAgreementDialog({
    super.key,
    this.config = const PrivacyAgreementConfig(),
  });

  final PrivacyAgreementConfig config;

  static const TextStyle _baseStyle = TextStyle(
    height: 1.65,
    fontSize: 15,
    color: Colors.black87,
    letterSpacing: 0.2,
  );
  static const TextStyle _linkStyle = TextStyle(
    height: 1.65,
    fontSize: 15,
    color: Color(0xFF1976D2),
    letterSpacing: 0.2,
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340, maxHeight: 420),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                config.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                  height: 1.3,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 14),
              Flexible(
                child: SingleChildScrollView(
                  child: Text.rich(
                    TextSpan(
                      style: _baseStyle,
                      children: _buildContentSpans(context),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: FilledButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(config.acceptText),
              ),
              const SizedBox(height: 10),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(false),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.grey.shade200,
                  foregroundColor: Colors.black87,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(config.rejectText),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<InlineSpan> _buildContentSpans(BuildContext context) {
    final content = config.content;
    final spans = <InlineSpan>[];
    int lastEnd = 0;

    final userPattern = '《用户协议》';
    final privacyPattern = '《隐私政策》';
    final regex = RegExp('($userPattern|$privacyPattern)');

    for (final match in regex.allMatches(content)) {
      spans.add(
        TextSpan(
          text: content.substring(lastEnd, match.start),
          style: _baseStyle,
        ),
      );
      final text = match.group(1)!;
      if (text == userPattern && config.userAgreementUrl != null) {
        spans.add(
          TextSpan(
            text: text,
            style: _linkStyle,
            recognizer: TapGestureRecognizer()
              ..onTap = () =>
                  _openUrl(context, config.userAgreementUrl!, '用户协议'),
          ),
        );
      } else if (text == privacyPattern && config.privacyPolicyUrl != null) {
        spans.add(
          TextSpan(
            text: text,
            style: _linkStyle,
            recognizer: TapGestureRecognizer()
              ..onTap = () =>
                  _openUrl(context, config.privacyPolicyUrl!, '隐私政策'),
          ),
        );
      } else {
        spans.add(TextSpan(text: text, style: _baseStyle));
      }
      lastEnd = match.end;
    }
    spans.add(TextSpan(text: content.substring(lastEnd), style: _baseStyle));
    return spans;
  }

  void _openUrl(BuildContext context, String url, String title) {
    if (!context.mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _AgreementWebViewPage(url: url, title: title),
      ),
    );
  }
}

class _AgreementWebViewPage extends StatefulWidget {
  const _AgreementWebViewPage({required this.url, required this.title});
  final String url;
  final String title;

  @override
  State<_AgreementWebViewPage> createState() => _AgreementWebViewPageState();
}

class _AgreementWebViewPageState extends State<_AgreementWebViewPage> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}
