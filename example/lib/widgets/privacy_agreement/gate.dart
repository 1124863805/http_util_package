import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'dialog.dart';
import 'helper.dart';

/// 隐私协议门控：同意前不构建 [child]、不执行 [onAgreed]
class PrivacyGate extends StatefulWidget {
  const PrivacyGate({
    super.key,
    required this.child,
    this.config = const PrivacyAgreementConfig(),
    this.onAgreed,
    this.theme,
  });

  /// 用户同意后展示的子应用
  final Widget child;

  /// 协议弹窗配置
  final PrivacyAgreementConfig config;

  /// 用户同意后执行，用于 SDK 初始化、权限请求等
  final Future<void> Function()? onAgreed;

  /// 弹窗阶段的主题（可选，默认使用 ColorScheme.fromSeed）
  final ThemeData? theme;

  @override
  State<PrivacyGate> createState() => _PrivacyGateState();
}

class _PrivacyGateState extends State<PrivacyGate> {
  bool _agreed = false;
  bool _initializing = true;

  Future<void> _runOnAgreed() async {
    if (mounted) setState(() => _initializing = true);
    await widget.onAgreed?.call();
    if (mounted) setState(() => _initializing = false);
  }

  Future<void> _onGateComplete(BuildContext gateContext) async {
    if (await PrivacyAgreementHelper.hasAgreed()) {
      await _runOnAgreed();
      if (mounted) setState(() => _agreed = true);
      return;
    }
    final agreed = await PrivacyAgreementHelper.show(gateContext, config: widget.config);
    if (!gateContext.mounted) return;
    if (agreed != true) {
      SystemNavigator.pop();
      return;
    }
    await PrivacyAgreementHelper.markAgreed();
    await _runOnAgreed();
    if (mounted) setState(() => _agreed = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_agreed) return widget.child;

    final theme = widget.theme ??
        ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue));
    return MaterialApp(
      theme: theme,
      home: _GateScaffold(
        initializing: _initializing,
        onBuild: (gateContext) {
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => _onGateComplete(gateContext),
          );
        },
      ),
    );
  }
}

class _GateScaffold extends StatefulWidget {
  const _GateScaffold({
    required this.initializing,
    required this.onBuild,
  });

  final bool initializing;
  final void Function(BuildContext context) onBuild;

  @override
  State<_GateScaffold> createState() => _GateScaffoldState();
}

class _GateScaffoldState extends State<_GateScaffold> {
  bool _called = false;

  @override
  Widget build(BuildContext context) {
    if (!_called) {
      _called = true;
      widget.onBuild(context);
    }
    return Scaffold(
      body: Center(
        child: widget.initializing
            ? const CircularProgressIndicator()
            : const SizedBox.shrink(),
      ),
    );
  }
}
