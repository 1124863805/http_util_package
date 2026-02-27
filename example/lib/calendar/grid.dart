import 'package:flutter/material.dart';

import '../tyme4/tyme.dart';
import 'constants.dart';
import 'cell.dart';

/// 全局缓存，避免滑动时重复计算农历/节气/节日（tyme4 计算较重）
const int _subtitleCacheMaxSize = 2000;
final Map<String, (String, bool, bool, int)> _subtitleCache = {};

/// 优先级：节日 > 节气 > 农历；返回 (副标题, 休, 班, 副标题类型)
(String subtitle, bool showRest, bool showWork, int subtitleType)
getSubtitleAndRest(SolarDay solarDay) {
  final y = solarDay.getYear();
  final m = solarDay.getMonth();
  final d = solarDay.getDay();
  final k = '$y-$m-$d';
  final cached = _subtitleCache[k];
  if (cached != null) return cached;

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
    subtitle =
        solarFestivalShortNames[solarFestival.getName()] ??
        solarFestival.getName();
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
  final result = (subtitle, showRest, showWork, subtitleType);
  if (_subtitleCache.length >= _subtitleCacheMaxSize) _subtitleCache.clear();
  _subtitleCache[k] = result;
  return result;
}

/// 预取某月及其相邻月的数据，滑动时命中缓存
void prefetchMonthData(int year, int month) {
  final solarMonth = SolarMonth.fromYm(year, month);
  final dayCount = solarMonth.getDayCount();
  final firstWeekday = solarMonth.getFirstDay().getWeek().getIndex();
  final prevMonth = solarMonth.next(-1);
  final prevDayCount = prevMonth.getDayCount();
  final nextMonth = solarMonth.next(1);
  for (int i = 0; i < firstWeekday; i++) {
    final d = prevDayCount - firstWeekday + 1 + i;
    getSubtitleAndRest(SolarDay.fromYmd(prevMonth.year, prevMonth.month, d));
  }
  for (int d = 1; d <= dayCount; d++) {
    getSubtitleAndRest(SolarDay.fromYmd(year, month, d));
  }
  final nextCount = 42 - firstWeekday - dayCount;
  for (int d = 1; d <= nextCount; d++) {
    getSubtitleAndRest(SolarDay.fromYmd(nextMonth.year, nextMonth.month, d));
  }
}

/// 单月日历：7 列 × N 行，用上月/本月/下月补全
class CalendarMonthGrid extends StatelessWidget {
  final int year;
  final int month;
  final DateTime selectedDate;
  final void Function(DateTime date) onSelectDate;
  final double availableHeight;
  final double availableWidth;
  final int dayRows;
  final int weekIndex;
  final bool showWatermark;
  final bool showBadge;

  const CalendarMonthGrid({
    super.key,
    required this.year,
    required this.month,
    required this.selectedDate,
    required this.onSelectDate,
    required this.availableHeight,
    required this.availableWidth,
    this.dayRows = 6,
    this.weekIndex = 0,
    this.showWatermark = true,
    this.showBadge = true,
  });

  static const int _cols = 7;
  static const int _fullRows = 6;

  @override
  Widget build(BuildContext context) {
    final solarMonth = SolarMonth.fromYm(year, month);
    final dayCount = solarMonth.getDayCount();
    final firstWeekday = solarMonth.getFirstDay().getWeek().getIndex();
    final prevMonth = solarMonth.next(-1);
    final prevDayCount = prevMonth.getDayCount();
    final nextMonth = solarMonth.next(1);
    final now = DateTime.now();

    (String, bool, bool, int) getCached(int y, int m, int d) =>
        getSubtitleAndRest(SolarDay.fromYmd(y, m, d));

    bool isSelected(int y, int m, int d) =>
        selectedDate.year == y &&
        selectedDate.month == m &&
        selectedDate.day == d;

    final cells = <Widget>[];
    int cellIndex = 0;

    for (int i = 0; i < firstWeekday; i++) {
      final d = prevDayCount - firstWeekday + 1 + i;
      final py = prevMonth.year;
      final pm = prevMonth.month;
      final (subtitle, showRest, showWork, st) = getCached(py, pm, d);
      cells.add(
        CalendarDayCell(
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
          showBadge: showBadge,
          onTap: () => onSelectDate(DateTime(py, pm, d)),
        ),
      );
      cellIndex++;
    }
    for (int d = 1; d <= dayCount; d++) {
      final (subtitle, showRest, showWork, st) = getCached(year, month, d);
      cells.add(
        CalendarDayCell(
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
          showBadge: showBadge,
          onTap: () => onSelectDate(DateTime(year, month, d)),
        ),
      );
      cellIndex++;
    }
    final nextCount = _cols * _fullRows - firstWeekday - dayCount;
    for (int d = 1; d <= nextCount; d++) {
      final ny = nextMonth.year;
      final nm = nextMonth.month;
      final (subtitle, showRest, showWork, st) = getCached(ny, nm, d);
      cells.add(
        CalendarDayCell(
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
          showBadge: showBadge,
          onTap: () => onSelectDate(DateTime(ny, nm, d)),
        ),
      );
      cellIndex++;
    }

    final contentWidth = availableWidth - calendarHorizontalPadding * 2;
    final cellWidth =
        (contentWidth - calendarCrossSpacing * (_cols - 1)) / _cols;
    final cellHeight = availableHeight / dayRows;
    final aspectRatio = cellWidth / cellHeight;

    final start = (weekIndex * _cols).clamp(0, cells.length);
    final end = ((weekIndex + 1) * _cols).clamp(0, cells.length);
    final displayCells = dayRows == 1
        ? (start < end ? cells.sublist(start, end) : <Widget>[])
        : cells;

    final watermarkStyle = TextStyle(
      fontSize: watermarkFontSize,
      fontWeight: FontWeight.w700,
      letterSpacing: 2,
      color: Theme.of(
        context,
      ).colorScheme.onSurface.withValues(alpha: watermarkOpacity),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: calendarHorizontalPadding,
      ),
      child: SizedBox(
        height: availableHeight,
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            if (showWatermark)
              Positioned.fill(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$year年',
                          style: watermarkStyle,
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          '${month.toString().padLeft(2, '0')}月',
                          style: watermarkStyle,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: _cols,
              mainAxisSpacing: 0,
              crossAxisSpacing: calendarCrossSpacing,
              childAspectRatio: aspectRatio,
              children: displayCells,
            ),
          ],
        ),
      ),
    );
  }
}
