import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// 协议 WebView 页面
///
/// 以全屏对话框形式打开，带加载状态。
class AgreementWebViewPage extends StatefulWidget {
  const AgreementWebViewPage({
    super.key,
    required this.url,
    required this.title,
  });

  final String url;
  final String title;

  /// 打开协议 WebView（底部滑入动画）
  static Future<void> open(
    BuildContext context, {
    required String url,
    required String title,
  }) async {
    if (!context.mounted) return;
    await Navigator.of(context).push(
      PageRouteBuilder<void>(
        fullscreenDialog: true,
        opaque: true,
        barrierDismissible: false,
        transitionDuration: const Duration(milliseconds: 300),
        reverseTransitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (context, animation, secondaryAnimation) =>
            AgreementWebViewPage(url: url, title: title),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          );
        },
      ),
    );
  }

  @override
  State<AgreementWebViewPage> createState() => _AgreementWebViewPageState();
}

class _AgreementWebViewPageState extends State<AgreementWebViewPage> {
  late final WebViewController _controller;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_loading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
