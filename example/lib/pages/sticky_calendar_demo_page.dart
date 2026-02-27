import 'package:flutter/material.dart';

import '../calendar/calendar.dart';

/// 吸顶日历演示：滑动吸顶、自动收起为周视图
class StickyCalendarDemoPage extends StatefulWidget {
  const StickyCalendarDemoPage({super.key});

  @override
  State<StickyCalendarDemoPage> createState() => _StickyCalendarDemoPageState();
}

class _StickyCalendarDemoPageState extends State<StickyCalendarDemoPage> {
  late DateTime _date;

  @override
  void initState() {
    super.initState();
    _date = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('吸顶日历演示'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: StickyPerpetualCalendar(
        selectedDate: _date,
        onDateSelected: (d) => setState(() => _date = d),
        children: _buildListItems(),
      ),
    );
  }

  List<Widget> _buildListItems() {
    final theme = Theme.of(context);
    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Text(
          '向下滑动，日历吸顶后自动收起为周视图',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
      ...List.generate(
        20,
        (i) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Card(
            child: ListTile(
              leading: CircleAvatar(child: Text('${i + 1}')),
              title: Text('列表项 ${i + 1}'),
              subtitle: const Text('吸顶时自动收起，仅显示周数据'),
            ),
          ),
        ),
      ),
      const SizedBox(height: 24),
    ];
  }
}
