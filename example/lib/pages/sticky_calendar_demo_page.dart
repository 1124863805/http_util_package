import 'package:flutter/material.dart';

import '../widgets/calendar/calendar.dart';
import '../widgets/calendar/constants.dart';

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
            color: calTheme.markerDotColor.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(cellBorderRadius),
            border: data.isSelected
                ? Border.all(color: calTheme.cellBorderSelected, width: cellBorderWidth)
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
        markedDates: _markedDates,
        markedCellBuilder: _markedCellBuilder,
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
