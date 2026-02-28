import 'package:flutter/material.dart';

import '../calendar/calendar.dart';
import '../calendar/constants.dart';
import 'widgets/date_selector.dart';

/// 日历组件演示：万年历、收起展开、年月日快速切换
/// 普通模式与吸顶日历逻辑完全一致，仅通过 constrainedHeight 驱动收起/展开
class CalendarDemoPage extends StatefulWidget {
  const CalendarDemoPage({super.key});

  @override
  State<CalendarDemoPage> createState() => _CalendarDemoPageState();
}

class _CalendarDemoPageState extends State<CalendarDemoPage> {
  final _calendarController = PerpetualCalendarController();
  late DateTime _selectedDate;
  bool _collapsed = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
  }

  void _onDateChanged(DateTime date) {
    setState(() => _selectedDate = date);
    _calendarController.goToDate(date);
  }

  @override
  Widget build(BuildContext context) {
    final height = _collapsed ? calendarCollapsedHeight : calendarExpandedHeight;
    return Scaffold(
      appBar: AppBar(
        title: const Text('日历组件演示'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          DateSelector(date: _selectedDate, onChanged: _onDateChanged),
          _CollapseButton(
            collapsed: _collapsed,
            onToggle: () => setState(() => _collapsed = !_collapsed),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 380),
            curve: Curves.easeInOutCubic,
            alignment: Alignment.topCenter,
            child: SizedBox(
              height: height,
              child: PerpetualCalendar(
                controller: _calendarController,
                selectedDate: _selectedDate,
                onDateSelected: _onDateChanged,
                constrainedHeight: height,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CollapseButton extends StatelessWidget {
  final bool collapsed;
  final VoidCallback onToggle;

  const _CollapseButton({
    required this.collapsed,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: TextButton.icon(
        onPressed: onToggle,
        icon: Icon(collapsed ? Icons.unfold_more : Icons.unfold_less, size: 18),
        label: Text(collapsed ? '展开日历' : '收起日历'),
      ),
    );
  }
}
