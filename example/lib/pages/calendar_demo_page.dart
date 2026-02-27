import 'package:flutter/material.dart';

import '../calendar/calendar.dart';
import 'widgets/date_selector.dart';

/// 日历组件演示：万年历、收起展开、年月日快速切换
class CalendarDemoPage extends StatefulWidget {
  const CalendarDemoPage({super.key});

  @override
  State<CalendarDemoPage> createState() => _CalendarDemoPageState();
}

class _CalendarDemoPageState extends State<CalendarDemoPage> {
  final _calendarController = PerpetualCalendarController();
  late DateTime _selectedDate;

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('日历组件演示'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          DateSelector(date: _selectedDate, onChanged: _onDateChanged),
          _CollapseButton(controller: _calendarController),
          PerpetualCalendar(
            controller: _calendarController,
            selectedDate: _selectedDate,
            onDateSelected: _onDateChanged,
          ),
        ],
      ),
    );
  }
}

class _CollapseButton extends StatelessWidget {
  final PerpetualCalendarController controller;

  const _CollapseButton({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: TextButton.icon(
        onPressed: () => controller.toggleCollapsed(),
        icon: const Icon(Icons.unfold_more, size: 18),
        label: const Text('收起/展开日历'),
      ),
    );
  }
}
