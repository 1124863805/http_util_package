import 'package:dio_http_util/http_util.dart';
import 'package:flutter/material.dart';
import 'http_demo_page.dart';
import 'calendar_demo_page.dart';
import 'sticky_calendar_demo_page.dart';
import 'huangli_almanac_page.dart';

/// 首页：演示入口
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('dio_http_util Demo'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _DemoCard(
            icon: Icons.http,
            title: 'HTTP 演示',
            subtitle: '发送 GET 请求、自定义 Response Parser',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HttpDemoPage()),
            ),
          ),
          const SizedBox(height: 12),
          _DemoCard(
            icon: Icons.calendar_month,
            title: '日历组件演示',
            subtitle: '万年历、收起展开、年月日快速切换',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CalendarDemoPage()),
            ),
          ),
          const SizedBox(height: 12),
          _DemoCard(
            icon: Icons.push_pin,
            title: '吸顶日历演示',
            subtitle: '滑动吸顶、自动收起为周视图',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const StickyCalendarDemoPage()),
            ),
          ),
          const SizedBox(height: 12),
          _DemoCard(
            icon: Icons.menu_book,
            title: '老黄历',
            subtitle: '传统纸质黄历风格、宜忌冲煞神方位',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HuangliAlmanacPage()),
            ),
          ),
          const SizedBox(height: 12),
          _DemoCard(
            icon: Icons.privacy_tip_outlined,
            title: '隐私协议弹窗',
            subtitle: '点击演示弹窗样式',
            onTap: () async {
              await PrivacyAgreementHelper.clearAgreed();
              if (!context.mounted) return;
              final agreed = await PrivacyAgreementHelper.showIfNeeded(
                context,
                config: const PrivacyAgreementConfig(
                  userAgreementUrl: 'https://download.laibuyi.com/agreement.html',
                  privacyPolicyUrl: 'https://download.laibuyi.com/privacy.html',
                ),
              );
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(agreed ? '已同意' : '已拒绝')),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _DemoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _DemoCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 32, color: theme.colorScheme.onPrimaryContainer),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
