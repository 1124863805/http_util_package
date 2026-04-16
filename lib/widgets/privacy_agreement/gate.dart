import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'dialog.dart';
import 'helper.dart';

/// 隐私协议门控：未同意前不构建 [child]。
/// 已同意过则尽快展示 [child]，[onAgreed] 在首帧之后异步执行，不阻塞冷启动。
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

  Future<void> _runOnAgreed() async {
    await widget.onAgreed?.call();
  }

  Future<void> _onGateComplete(BuildContext gateContext) async {
    if (await PrivacyAgreementHelper.hasAgreed()) {
      if (!mounted) return;
      setState(() => _agreed = true);
      // 已同意：先展示主应用，再在首帧之后异步执行 [onAgreed]，避免冷启动被初始化拖慢
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        unawaited(_runOnAgreed());
      });
      return;
    }
    final agreed = await PrivacyAgreementHelper.show(
      gateContext,
      config: widget.config.copyWith(
        onAccept: () async {
          await PrivacyAgreementHelper.markAgreed();
          await widget.onAgreed?.call();
        },
      ),
    );
    if (!gateContext.mounted) return;
    if (agreed != true) {
      SystemNavigator.pop();
      return;
    }
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
    required this.onBuild,
  });

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
    return const Scaffold(
      body: SizedBox.shrink(),
    );
  }
}
