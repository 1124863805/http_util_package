import 'package:flutter/material.dart';

import '../widgets/calendar/calendar.dart';
import '../widgets/calendar/constants.dart';
import '../widgets/date_selector/date_selector.dart';

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

  List<DateTime> get _markedDates {
    final now = DateTime.now();
    return [
      now,
      now.add(const Duration(days: 3)),
      now.add(const Duration(days: 7)),
    ];
  }

  Widget _markedCellBuilder(BuildContext context, CalendarDayData data) {
    final theme = Theme.of(context);
    final calTheme = CalendarTheme.of(theme.brightness);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: data.onTap,
        borderRadius: BorderRadius.circular(cellBorderRadius),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.amber.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(cellBorderRadius),
            border: data.isSelected
                ? Border.all(
                    color: calTheme.cellBorderSelected,
                    width: cellBorderWidth,
                  )
                : null,
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${data.date.day}',
                  style: TextStyle(
                    fontSize: dayNumberFontSize,
                    fontWeight: FontWeight.w700,
                    color: calTheme.markerDotColor,
                  ),
                ),
                if (data.subtitle.isNotEmpty)
                  Text(
                    data.subtitle,
                    style: TextStyle(
                      fontSize: subtitleFontSizeLunar,
                      color: calTheme.subtitleColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onDateChanged(DateTime date) {
    setState(() => _selectedDate = date);
    _calendarController.goToDate(date);
  }

  @override
  Widget build(BuildContext context) {
    final height = _collapsed
        ? calendarCollapsedHeight
        : calendarExpandedHeight;
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
                markedDates: _markedDates,
                markedCellBuilder: _markedCellBuilder,
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

  const _CollapseButton({required this.collapsed, required this.onToggle});

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
