import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'privacy_prefs.dart';
import 'webview_page.dart';

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
    this.onAccept,
  });

  final String title;
  final String content;
  final String? userAgreementUrl;
  final String? privacyPolicyUrl;
  final String acceptText;
  final String rejectText;

  /// 点击「同意」后执行；完成后关闭弹窗并返回 true。
  /// 为 null 时默认 [PrivacyPrefs.markAgreed]。
  final Future<void> Function()? onAccept;

  PrivacyAgreementConfig copyWith({
    String? title,
    String? content,
    String? userAgreementUrl,
    String? privacyPolicyUrl,
    String? acceptText,
    String? rejectText,
    Future<void> Function()? onAccept,
  }) {
    return PrivacyAgreementConfig(
      title: title ?? this.title,
      content: content ?? this.content,
      userAgreementUrl: userAgreementUrl ?? this.userAgreementUrl,
      privacyPolicyUrl: privacyPolicyUrl ?? this.privacyPolicyUrl,
      acceptText: acceptText ?? this.acceptText,
      rejectText: rejectText ?? this.rejectText,
      onAccept: onAccept ?? this.onAccept,
    );
  }
}

/// 隐私协议弹窗
class PrivacyAgreementDialog extends StatefulWidget {
  const PrivacyAgreementDialog({
    super.key,
    this.config = const PrivacyAgreementConfig(),
  });

  final PrivacyAgreementConfig config;

  @override
  State<PrivacyAgreementDialog> createState() => _PrivacyAgreementDialogState();
}

class _PrivacyAgreementDialogState extends State<PrivacyAgreementDialog> {
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

  bool _accepting = false;

  Future<void> _onAccept() async {
    if (_accepting) return;
    setState(() => _accepting = true);
    try {
      final fn = widget.config.onAccept ?? PrivacyPrefs.markAgreed;
      await fn();
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) setState(() => _accepting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final config = widget.config;

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
                onPressed: _accepting ? null : _onAccept,
                style: FilledButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _accepting
                    ? SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: colorScheme.onPrimary,
                        ),
                      )
                    : Text(config.acceptText),
              ),
              const SizedBox(height: 10),
              FilledButton(
                onPressed: _accepting ? null : () => Navigator.of(context).pop(false),
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
    final content = widget.config.content;
    final spans = <InlineSpan>[];
    int lastEnd = 0;

    const userPattern = '《用户协议》';
    const privacyPattern = '《隐私政策》';
    final regex = RegExp('($userPattern|$privacyPattern)');
    final cfg = widget.config;

    for (final match in regex.allMatches(content)) {
      spans.add(
        TextSpan(
          text: content.substring(lastEnd, match.start),
          style: _baseStyle,
        ),
      );
      final text = match.group(1)!;
      if (text == userPattern && cfg.userAgreementUrl != null) {
        spans.add(
          TextSpan(
            text: text,
            style: _linkStyle,
            recognizer: TapGestureRecognizer()
              ..onTap = () =>
                  _openUrl(context, cfg.userAgreementUrl!, '用户协议'),
          ),
        );
      } else if (text == privacyPattern && cfg.privacyPolicyUrl != null) {
        spans.add(
          TextSpan(
            text: text,
            style: _linkStyle,
            recognizer: TapGestureRecognizer()
              ..onTap = () =>
                  _openUrl(context, cfg.privacyPolicyUrl!, '隐私政策'),
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
    AgreementWebViewPage.open(context, url: url, title: title);
  }
}
