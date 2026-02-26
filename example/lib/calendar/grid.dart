import 'package:flutter/material.dart';

import '../tyme4/tyme.dart';
import 'constants.dart';
import 'cell.dart';

/// 优先级：节日 > 节气 > 农历；返回 (副标题, 休, 班, 副标题类型)
(String subtitle, bool showRest, bool showWork, int subtitleType) getSubtitleAndRest(
    SolarDay solarDay) {
  final y = solarDay.getYear();
  final m = solarDay.getMonth();
  final d = solarDay.getDay();
  final legal = LegalHoliday.fromYmd(y, m, d);
  final showRest = legal != null && !legal.isWork();
  final showWork = legal != null && legal.isWork();
  final solarFestival = solarDay.getFestival();
  final lunarDay = solarDay.getLunarDay();
  LunarFestival? lunarFestival;
  try {
    lunarFestival = LunarFestival.fromYmd(
      lunarDay.getYear(),
      lunarDay.getLunarMonth().getMonthWithLeap(),
      lunarDay.getDay(),
    );
  } catch (e, st) {
    assert(() {
      debugPrint('LunarFestival.fromYmd: $e\n$st');
      return true;
    }());
  }
  final termDay = solarDay.getTermDay();
  final isTermDay = termDay.getDayIndex() == 0;
  String subtitle;
  int subtitleType = subtitleTypeLunar;
  if (solarFestival != null) {
    subtitle = solarFestivalShortNames[solarFestival.getName()] ?? solarFestival.getName();
    subtitleType = subtitleTypeFestival;
  } else if (lunarFestival != null) {
    subtitle = lunarFestival.getName();
    subtitleType = subtitleTypeFestival;
  } else if (isTermDay) {
    subtitle = termDay.getSolarTerm().getName();
    subtitleType = subtitleTypeTerm;
  } else {
    subtitle = lunarDay.getName();
  }
  if (subtitleType != subtitleTypeFestival && subtitle.length > 2) {
    subtitle = subtitle.substring(0, 2);
  }
  return (subtitle, showRest, showWork, subtitleType);
}

/// 单月日历：7 列 × 6 行 42 格，用上月/本月/下月补全
class CalendarMonthGrid extends StatelessWidget {
  final int year;
  final int month;
  final DateTime selectedDate;
  final void Function(DateTime date) onSelectDate;
  final double availableHeight;
  final double availableWidth;

  const CalendarMonthGrid({
    super.key,
    required this.year,
    required this.month,
    required this.selectedDate,
    required this.onSelectDate,
    required this.availableHeight,
    required this.availableWidth,
  });

  static const int _cols = 7;
  static const int _dayRows = 6;

  @override
  Widget build(BuildContext context) {
    final solarMonth = SolarMonth.fromYm(year, month);
    final dayCount = solarMonth.getDayCount();
    final firstWeekday = solarMonth.getFirstDay().getWeek().getIndex();
    final prevMonth = solarMonth.next(-1);
    final prevDayCount = prevMonth.getDayCount();
    final nextMonth = solarMonth.next(1);
    final now = DateTime.now();

    final cache = <String, (String, bool, bool, int)>{};
    (String, bool, bool, int) getCached(int y, int m, int d) {
      final k = '$y-$m-$d';
      cache[k] ??= getSubtitleAndRest(SolarDay.fromYmd(y, m, d));
      return cache[k]!;
    }

    bool isSelected(int y, int m, int d) =>
        selectedDate.year == y && selectedDate.month == m && selectedDate.day == d;

    final cells = <Widget>[];
    int cellIndex = 0;

    for (int i = 0; i < firstWeekday; i++) {
      final d = prevDayCount - firstWeekday + 1 + i;
      final py = prevMonth.year;
      final pm = prevMonth.month;
      final (subtitle, showRest, showWork, st) = getCached(py, pm, d);
      cells.add(CalendarDayCell(
        year: py,
        month: pm,
        day: d,
        subtitle: subtitle,
        subtitleType: st,
        showRest: showRest,
        showWork: showWork,
        isWeekend: cellIndex % 7 == 0 || cellIndex % 7 == 6,
        isOtherMonth: true,
        isToday: now.year == py && now.month == pm && now.day == d,
        isSelected: isSelected(py, pm, d),
        onTap: () => onSelectDate(DateTime(py, pm, d)),
      ));
      cellIndex++;
    }
    for (int d = 1; d <= dayCount; d++) {
      final (subtitle, showRest, showWork, st) = getCached(year, month, d);
      cells.add(CalendarDayCell(
        year: year,
        month: month,
        day: d,
        subtitle: subtitle,
        subtitleType: st,
        showRest: showRest,
        showWork: showWork,
        isWeekend: cellIndex % 7 == 0 || cellIndex % 7 == 6,
        isOtherMonth: false,
        isToday: now.year == year && now.month == month && now.day == d,
        isSelected: isSelected(year, month, d),
        onTap: () => onSelectDate(DateTime(year, month, d)),
      ));
      cellIndex++;
    }
    final nextCount = _cols * _dayRows - firstWeekday - dayCount;
    for (int d = 1; d <= nextCount; d++) {
      final ny = nextMonth.year;
      final nm = nextMonth.month;
      final (subtitle, showRest, showWork, st) = getCached(ny, nm, d);
      cells.add(CalendarDayCell(
        year: ny,
        month: nm,
        day: d,
        subtitle: subtitle,
        subtitleType: st,
        showRest: showRest,
        showWork: showWork,
        isWeekend: cellIndex % 7 == 0 || cellIndex % 7 == 6,
        isOtherMonth: true,
        isToday: now.year == ny && now.month == nm && now.day == d,
        isSelected: isSelected(ny, nm, d),
        onTap: () => onSelectDate(DateTime(ny, nm, d)),
      ));
      cellIndex++;
    }

    final contentWidth = availableWidth - calendarHorizontalPadding * 2;
    final cellWidth = (contentWidth - calendarCrossSpacing * (_cols - 1)) / _cols;
    final cellHeight = availableHeight / _dayRows;
    final aspectRatio = cellWidth / cellHeight;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: calendarHorizontalPadding),
      child: SizedBox(
        height: availableHeight,
        child: GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: _cols,
          mainAxisSpacing: 0,
          crossAxisSpacing: calendarCrossSpacing,
          childAspectRatio: aspectRatio,
          children: cells,
        ),
      ),
    );
  }
}
