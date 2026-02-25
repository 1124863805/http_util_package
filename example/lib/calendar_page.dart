import 'package:flutter/material.dart';
import 'tyme4/tyme.dart';

/// 万年历使用字体：霞鹜文楷（开源可商用，见 pubspec + assets/fonts）
const String _calendarFontFamily = 'LXGW WenKai';

/// 格子圆角、边框宽度，统一风格
const double _cellBorderRadius = 8;
const double _cellBorderWidth = 1.5;

/// 休/班角标：小圆形、右上角，不遮挡内容
class _RestWorkBadge extends StatelessWidget {
  final String label;
  final Color backgroundColor;

  const _RestWorkBadge({required this.label, required this.backgroundColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 14,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: backgroundColor, shape: BoxShape.circle),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          fontFamily: _calendarFontFamily,
        ),
      ),
    );
  }
}

/// 基于 tyme4 的公历日历，第一行 日 一 二 三 四 五 六，Grid 布局，左右滑动切换月份
class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  static const int _baseYear = 1970;
  static const int _totalMonths = 1200; // 约 100 年

  late PageController _pageController;
  int _currentPage = 0;

  /// 当前选中的日期，默认今天
  late DateTime _selectedDate;

  int get _initialPage {
    final now = DateTime.now();
    return (now.year - _baseYear) * 12 + (now.month - 1);
  }

  (int year, int month) _pageToYearMonth(int index) {
    final year = _baseYear + index ~/ 12;
    final month = index % 12 + 1;
    return (year, month);
  }

  @override
  void initState() {
    super.initState();
    _currentPage = _initialPage;
    _selectedDate = DateTime.now();
    _pageController = PageController(initialPage: _initialPage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onSelectDate(DateTime date) {
    setState(() => _selectedDate = date);
    final targetPage = (date.year - _baseYear) * 12 + (date.month - 1);
    if (targetPage != _currentPage &&
        targetPage >= 0 &&
        targetPage < _totalMonths &&
        _pageController.hasClients) {
      _pageController.animateToPage(
        targetPage,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeInOut,
      );
    }
  }

  // 标题：日 一 二 三 四 五 六（周日为首，1-6 为文字）；日、六红色
  static const List<String> _weekdays = ['日', '一', '二', '三', '四', '五', '六'];

  /// 日历格子区域最大高度，避免整体过高
  static const double _calendarMaxHeight = 400;

  @override
  Widget build(BuildContext context) {
    final (year, month) = _pageToYearMonth(_currentPage);
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('$year年$month月'),
        backgroundColor: colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          // 星期头与格子列严格对齐；减少上下间距
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 2),
            child: Row(
              children: [
                for (int i = 0; i < _weekdays.length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(
                    child: Center(
                      child: Text(
                        _weekdays[i],
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          fontFamily: _calendarFontFamily,
                          color: (i == 0 || i == 6)
                              ? colorScheme.error
                              : colorScheme.onSurface.withValues(alpha: 0.55),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (_, constraints) {
                final h = constraints.maxHeight.clamp(0.0, _calendarMaxHeight);
                return SizedBox(
                  height: h,
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _totalMonths,
                    onPageChanged: (index) =>
                        setState(() => _currentPage = index),
                    itemBuilder: (context, index) {
                      final (y, m) = _pageToYearMonth(index);
                      return _MonthGrid(
                        year: y,
                        month: m,
                        selectedDate: _selectedDate,
                        onSelectDate: _onSelectDate,
                        availableHeight: h,
                        availableWidth: constraints.maxWidth,
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// 单月日历：第一行 日 一 … 六，下方 6 行用上月/本月/下月补全共 42 格；用格子固定高度撑满，无上下间距
class _MonthGrid extends StatelessWidget {
  final int year;
  final int month;
  final DateTime selectedDate;
  final void Function(DateTime date) onSelectDate;
  final double availableHeight;
  final double availableWidth;

  const _MonthGrid({
    required this.year,
    required this.month,
    required this.selectedDate,
    required this.onSelectDate,
    required this.availableHeight,
    required this.availableWidth,
  });

  static const int _cols = 7;
  static const int _dayRows = 6;
  static const double _horizontalPadding = 16;
  static const double _crossSpacing = 8;
  static const int _totalDayCells = _cols * _dayRows; // 42

  /// 公历节日显示用缩写，避免格子内字太多（与 SolarFestival.names 对应）
  static const Map<String, String> _solarFestivalShortNames = {
    '五一劳动节': '劳动节',
    '三八妇女节': '妇女节',
    '六一儿童节': '儿童节',
    '五四青年节': '青年节',
    '八一建军节': '建军节',
  };

  /// 副标题类型，用于区分样式
  static const int _typeFestival = 0;
  static const int _typeTerm = 1;
  static const int _typeLunar = 2;

  /// 优先级：节日 > 节气 > 农历；节日用缩写，农历用 LunarDay.names 两字；返回 休/班 标记
  static (String subtitle, bool showRest, bool showWork, int subtitleType)
  getSubtitleAndRest(SolarDay solarDay) {
    final y = solarDay.getYear();
    final m = solarDay.getMonth();
    final d = solarDay.getDay();
    final legal = LegalHoliday.fromYmd(y, m, d);
    final showRest = legal != null && !legal.isWork();
    final showWork = legal != null && legal.isWork(); // 调休上班日显示「班」
    final solarFestival = solarDay.getFestival();
    final lunarDay = solarDay.getLunarDay();
    LunarFestival? lunarFestival;
    try {
      lunarFestival = LunarFestival.fromYmd(
        lunarDay.getYear(),
        lunarDay.getLunarMonth().getMonthWithLeap(),
        lunarDay.getDay(),
      );
    } catch (_) {}
    final termDay = solarDay.getTermDay();
    final isTermDay = termDay.getDayIndex() == 0;
    String subtitle;
    int subtitleType = _typeLunar;
    if (solarFestival != null) {
      final raw = solarFestival.getName();
      subtitle = _solarFestivalShortNames[raw] ?? raw;
      subtitleType = _typeFestival;
    } else if (lunarFestival != null) {
      subtitle = lunarFestival.getName();
      subtitleType = _typeFestival;
    } else if (isTermDay) {
      subtitle = termDay.getSolarTerm().getName();
      subtitleType = _typeTerm;
    } else {
      subtitle = lunarDay.getName();
    }
    if (subtitleType != _typeFestival && subtitle.length > 2) {
      subtitle = subtitle.substring(0, 2);
    }
    return (subtitle, showRest, showWork, subtitleType);
  }

  @override
  Widget build(BuildContext context) {
    final solarMonth = SolarMonth.fromYm(year, month);
    final dayCount = solarMonth.getDayCount();
    // 日为首：0=日 1=一 … 6=六（tyme4 的 Week 0=日 1=一…6=六）
    final firstWeekday = solarMonth.getFirstDay().getWeek().getIndex();

    final prevMonth = solarMonth.next(-1);
    final prevDayCount = prevMonth.getDayCount();
    final nextMonth = solarMonth.next(1);

    final cells = <Widget>[];

    int cellIndex = 0;
    // 上月补全：末尾 firstWeekday 天
    for (int i = 0; i < firstWeekday; i++) {
      final d = prevDayCount - firstWeekday + 1 + i;
      final py = prevMonth.year;
      final pm = prevMonth.month;
      final solarDay = SolarDay.fromYmd(py, pm, d);
      final (subtitle, showRest, showWork, subtitleType) = getSubtitleAndRest(
        solarDay,
      );
      cells.add(
        _DayCell(
          year: py,
          month: pm,
          day: d,
          subtitle: subtitle,
          subtitleType: subtitleType,
          showRest: showRest,
          showWork: showWork,
          isWeekend: cellIndex % 7 == 0 || cellIndex % 7 == 6,
          isOtherMonth: true,
          isToday: _isToday(py, pm, d),
          isSelected: _isSelected(py, pm, d),
          onTap: () => onSelectDate(DateTime(py, pm, d)),
        ),
      );
      cellIndex++;
    }

    // 本月 1..dayCount
    for (int d = 1; d <= dayCount; d++) {
      final solarDay = SolarDay.fromYmd(year, month, d);
      final (subtitle, showRest, showWork, subtitleType) = getSubtitleAndRest(
        solarDay,
      );
      cells.add(
        _DayCell(
          year: year,
          month: month,
          day: d,
          subtitle: subtitle,
          subtitleType: subtitleType,
          showRest: showRest,
          showWork: showWork,
          isWeekend: cellIndex % 7 == 0 || cellIndex % 7 == 6,
          isOtherMonth: false,
          isToday: _isToday(year, month, d),
          isSelected: _isSelected(year, month, d),
          onTap: () => onSelectDate(DateTime(year, month, d)),
        ),
      );
      cellIndex++;
    }

    // 下月补全：补足到 42 格
    final nextCount = _totalDayCells - firstWeekday - dayCount;
    for (int d = 1; d <= nextCount; d++) {
      final ny = nextMonth.year;
      final nm = nextMonth.month;
      final solarDay = SolarDay.fromYmd(ny, nm, d);
      final (subtitle, showRest, showWork, subtitleType) = getSubtitleAndRest(
        solarDay,
      );
      cells.add(
        _DayCell(
          year: ny,
          month: nm,
          day: d,
          subtitle: subtitle,
          subtitleType: subtitleType,
          showRest: showRest,
          showWork: showWork,
          isWeekend: cellIndex % 7 == 0 || cellIndex % 7 == 6,
          isOtherMonth: true,
          isToday: _isToday(ny, nm, d),
          isSelected: _isSelected(ny, nm, d),
          onTap: () => onSelectDate(DateTime(ny, nm, d)),
        ),
      );
      cellIndex++;
    }

    final double contentWidth = availableWidth - _horizontalPadding * 2;
    final double cellWidth =
        (contentWidth - _crossSpacing * (_cols - 1)) / _cols;
    final double cellHeight = availableHeight / _dayRows;
    final double aspectRatio = cellWidth / cellHeight;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _horizontalPadding),
      child: SizedBox(
        height: availableHeight,
        child: GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: _cols,
          mainAxisSpacing: 0,
          crossAxisSpacing: _crossSpacing,
          childAspectRatio: aspectRatio,
          children: cells,
        ),
      ),
    );
  }

  bool _isToday(int y, int m, int d) {
    final now = DateTime.now();
    return now.year == y && now.month == m && now.day == d;
  }

  bool _isSelected(int y, int m, int d) {
    return selectedDate.year == y &&
        selectedDate.month == m &&
        selectedDate.day == d;
  }
}

class _DayCell extends StatelessWidget {
  static const int _typeFestival = 0;
  static const int _typeTerm = 1;
  static const Color _todayBg = Color(0xFFD84315); // 和谐红，非纯红
  static const Color _selectedBg = Color(0xFFECEFF1); // 和谐灰

  final int year;
  final int month;
  final int day;
  final String subtitle;
  final int subtitleType;
  final bool showRest;
  final bool showWork;
  final bool isWeekend;
  final bool isOtherMonth;
  final bool isToday;
  final bool isSelected;
  final VoidCallback onTap;

  const _DayCell({
    required this.year,
    required this.month,
    required this.day,
    required this.subtitle,
    required this.subtitleType,
    required this.showRest,
    required this.showWork,
    required this.isWeekend,
    required this.isOtherMonth,
    required this.isToday,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // 选中今天：红底白字；今天未选中：灰底深字无边框；选中其他：仅红框无背景、字体颜色不变
    final bool todaySelected = isToday && isSelected;
    final Color dayColor = todaySelected
        ? Colors.white
        : isOtherMonth
            ? colorScheme.onSurface.withValues(alpha: 0.38)
            : isToday
                ? colorScheme.onSurface.withValues(alpha: 0.8)
                : isWeekend
                    ? colorScheme.error
                    : colorScheme.onSurface.withValues(alpha: 0.85);
    final bool isHighlighted = todaySelected;
    // 今天选中红底必须配白字，不能配深色
    final Color highlightTextColor = todaySelected ? Colors.white : colorScheme.onSurface.withValues(alpha: 0.85);

    // 日期数字：仅选中今天白字加粗，其余固定
    final dayStyle = TextStyle(
      fontSize: 18,
      fontWeight: todaySelected ? FontWeight.w800 : FontWeight.w700,
      color: dayColor,
      fontFamily: _calendarFontFamily,
    );

    // 副标题层级：节日 > 节气 > 农历；节日红、节气青绿、农历灰
    double subtitleSize = 10;
    FontWeight subtitleWeight = FontWeight.w500;
    Color subtitleColor = colorScheme.onSurface.withValues(
      alpha: isOtherMonth ? 0.4 : 0.65,
    );
    if (subtitleType == _typeFestival) {
      subtitleSize = 12;
      subtitleWeight = todaySelected ? FontWeight.w800 : FontWeight.w700;
      if (todaySelected) {
        subtitleColor = Colors.white;
      } else if (!isOtherMonth && !isHighlighted) {
        subtitleColor = colorScheme.error;
      } else if (isOtherMonth) {
        subtitleColor = colorScheme.onSurface.withValues(alpha: 0.45);
      }
    } else if (subtitleType == _typeTerm) {
      subtitleSize = 11;
      subtitleWeight = todaySelected ? FontWeight.w800 : FontWeight.w600;
      if (todaySelected) {
        subtitleColor = Colors.white;
      } else if (!isOtherMonth) {
        subtitleColor = const Color(0xFF2E7D32);
      } else {
        subtitleColor = colorScheme.onSurface.withValues(alpha: 0.42);
      }
    } else {
      // 农历：略小、灰字，层级最低
      subtitleSize = 10;
      subtitleWeight = todaySelected ? FontWeight.w800 : FontWeight.w500;
      if (todaySelected) {
        subtitleColor = Colors.white;
      } else if (!isOtherMonth) {
        subtitleColor = colorScheme.onSurface.withValues(alpha: 0.65);
      }
    }

    final radius = BorderRadius.all(Radius.circular(_cellBorderRadius));
    final String semanticsLabel = _buildCellSemanticsLabel();
    return Semantics(
      label: semanticsLabel,
      button: true,
      selected: isSelected,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: radius,
              color: todaySelected ? _todayBg : (isToday ? _selectedBg : null),
              // 仅选中时红框；未选中今天无边框
              border: Border.all(
                color: isSelected ? colorScheme.error : Colors.transparent,
                width: _cellBorderWidth,
              ),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // 格子主内容：字体大小和位置固定，不受休/班角标影响
                Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('$day', style: dayStyle),
                        if (subtitle.isNotEmpty)
                          Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: subtitleSize,
                              fontWeight: subtitleWeight,
                              color: todaySelected
                                  ? Colors.white
                                  : (isHighlighted ? highlightTextColor : subtitleColor),
                              fontFamily: _calendarFontFamily,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                      ],
                    ),
                  ),
                ),
                // 休/班：负数定位到格子右上角外，小圆形不遮挡
                if (showRest)
                  Positioned(
                    top: 2,
                    right: showWork ? 16 : 0,
                    child: _RestWorkBadge(
                      label: '休',
                      backgroundColor: colorScheme.error,
                    ),
                  ),
                if (showWork)
                  Positioned(
                    top: 2,
                    right: showRest ? 16 : 0,
                    child: _RestWorkBadge(
                      label: '班',
                      backgroundColor: colorScheme.primary,
                    ),
                  ),
                // 今天：「今」角标在右上角；选中今天白字，未选中深字配灰底
                if (isToday)
                  Positioned(
                    top: 2,
                    right: showRest ? 18 : (showWork ? 18 : 2),
                    child: Text(
                      '今',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: todaySelected
                            ? Colors.white
                            : colorScheme.onSurface.withValues(alpha: 0.7),
                        fontFamily: _calendarFontFamily,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _buildCellSemanticsLabel() {
    final parts = <String>[];
    if (isToday) parts.add('今天');
    parts.add('$month月$day日');
    if (subtitle.isNotEmpty) parts.add(subtitle);
    if (showRest) parts.add('休');
    if (showWork) parts.add('班');
    if (isSelected && !isToday) parts.add('已选中');
    return parts.join(' ');
  }
}
