import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'tyme4/tyme.dart';

/// 万年历使用字体：霞鹜文楷（开源可商用，见 pubspec + assets/fonts）
const String _calendarFontFamily = 'LXGW WenKai';

/// 格子圆角、边框宽度，统一风格
const double _cellBorderRadius = 8;
const double _cellBorderWidth = 1.5;

/// 星期头与格子列对齐：水平外边距、列间距（与 _MonthGrid 一致）
const double _calendarHorizontalPadding = 16;
const double _calendarCrossSpacing = 8;

/// 副标题类型常量，_MonthGrid 与 _DayCell 共用
const int _subtitleTypeFestival = 0;
const int _subtitleTypeTerm = 1;
const int _subtitleTypeLunar = 2;

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

/// 万年历组件（可嵌入任意页面），范围 1900-2099，左右滑动切月
class PerpetualCalendar extends StatefulWidget {
  /// 初始展示的日期，null 为今天
  final DateTime? initialDate;

  /// 当前选中日期，null 则内部维护
  final DateTime? selectedDate;

  /// 选中日期回调；若为 null 则仅内部更新
  final ValueChanged<DateTime>? onDateSelected;

  /// 日历格子区域最大高度
  final double? maxHeight;

  const PerpetualCalendar({
    super.key,
    this.initialDate,
    this.selectedDate,
    this.onDateSelected,
    this.maxHeight,
  });

  @override
  State<PerpetualCalendar> createState() => PerpetualCalendarState();
}

/// 供外部通过 GlobalKey<PerpetualCalendarState> 调用：上一月、下一月、选择年月
class PerpetualCalendarState extends State<PerpetualCalendar> {
  static const int _baseYear = 1900;
  static const int _endYear = 2099;
  static const int _totalMonths = (_endYear - _baseYear + 1) * 12;
  static const List<String> _weekdays = ['日', '一', '二', '三', '四', '五', '六'];
  static const double _calendarMaxHeight = 400;

  late PageController _pageController;
  int _currentPage = 0;
  late DateTime _selectedDate;

  int get _initialPage {
    final date = widget.initialDate ?? DateTime.now();
    final page = (date.year - _baseYear) * 12 + (date.month - 1);
    return page.clamp(0, _totalMonths - 1);
  }

  (int year, int month) _pageToYearMonth(int index) {
    final year = _baseYear + index ~/ 12;
    final month = index % 12 + 1;
    return (year, month);
  }

  DateTime get _effectiveSelectedDate => widget.selectedDate ?? _selectedDate;

  @override
  void initState() {
    super.initState();
    _currentPage = _initialPage;
    _selectedDate = widget.initialDate ?? widget.selectedDate ?? DateTime.now();
    _pageController = PageController(initialPage: _initialPage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onSelectDate(DateTime date) {
    if (widget.onDateSelected != null) {
      widget.onDateSelected!(date);
    } else {
      setState(() => _selectedDate = date);
    }
    final targetPage = (date.year - _baseYear) * 12 + (date.month - 1);
    final page = targetPage.clamp(0, _totalMonths - 1);
    if (page == _currentPage || !_pageController.hasClients) return;
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOut,
    );
  }

  /// 上一月，外部可通过 key.currentState?.goPrevMonth() 调用
  void goPrevMonth() {
    if (!_pageController.hasClients || _currentPage <= 0) return;
    _pageController.animateToPage(
      _currentPage - 1,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOut,
    );
  }

  /// 下一月，外部可通过 key.currentState?.goNextMonth() 调用
  void goNextMonth() {
    if (!_pageController.hasClients || _currentPage >= _totalMonths - 1) return;
    _pageController.animateToPage(
      _currentPage + 1,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOut,
    );
  }

  /// 弹出年月选择器，外部可通过 key.currentState?.showYearMonthPicker() 调用
  Future<void> showYearMonthPicker() async {
    final (year, month) = _pageToYearMonth(_currentPage);
    final picked = await showDialog<(int year, int month)>(
      context: context,
      builder: (context) {
        int selYear = year;
        int selMonth = month;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('选择年月'),
              content: SizedBox(
                width: 220,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<int>(
                      value: selYear,
                      decoration: const InputDecoration(labelText: '年'),
                      items:
                          List.generate(
                                _endYear - _baseYear + 1,
                                (i) => _baseYear + i,
                              )
                              .map(
                                (y) => DropdownMenuItem(
                                  value: y,
                                  child: Text('$y年'),
                                ),
                              )
                              .toList(),
                      onChanged: (v) {
                        if (v != null) setDialogState(() => selYear = v);
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      value: selMonth,
                      decoration: const InputDecoration(labelText: '月'),
                      items: List.generate(12, (i) => i + 1)
                          .map(
                            (m) =>
                                DropdownMenuItem(value: m, child: Text('$m月')),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setDialogState(() => selMonth = v);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('取消'),
                ),
                FilledButton(
                  onPressed: () =>
                      Navigator.of(context).pop((selYear, selMonth)),
                  child: const Text('确定'),
                ),
              ],
            );
          },
        );
      },
    );
    if (picked != null && mounted && _pageController.hasClients) {
      final page = ((picked.$1 - _baseYear) * 12 + (picked.$2 - 1)).clamp(
        0,
        _totalMonths - 1,
      );
      _pageController.animateToPage(
        page,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeInOut,
      );
    }
  }

  void _onPageChanged(int index) {
    setState(() => _currentPage = index);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final maxH = widget.maxHeight ?? _calendarMaxHeight;

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            _calendarHorizontalPadding,
            4,
            _calendarHorizontalPadding,
            2,
          ),
          child: Row(
            children: [
              for (int i = 0; i < _weekdays.length; i++) ...[
                if (i > 0) const SizedBox(width: _calendarCrossSpacing),
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
              final h = constraints.maxHeight.clamp(0.0, maxH);
              return SizedBox(
                height: h,
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _totalMonths,
                  onPageChanged: _onPageChanged,
                  itemBuilder: (context, index) {
                    final (y, m) = _pageToYearMonth(index);
                    return _MonthGrid(
                      year: y,
                      month: m,
                      selectedDate: _effectiveSelectedDate,
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
    );

    return content;
  }
}

/// 示例：单独一页展示万年历（Scaffold + 组件）
class CalendarPage extends StatelessWidget {
  const CalendarPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('万年历'),
        backgroundColor: colorScheme.inversePrimary,
      ),
      body: const PerpetualCalendar(),
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
  static const int _totalDayCells = _cols * _dayRows; // 42

  /// 公历节日显示用缩写，避免格子内字太多（与 SolarFestival.names 对应）
  static const Map<String, String> _solarFestivalShortNames = {
    '五一劳动节': '劳动节',
    '三八妇女节': '妇女节',
    '六一儿童节': '儿童节',
    '五四青年节': '青年节',
    '八一建军节': '建军节',
  };

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
    } catch (e, st) {
      assert(() {
        debugPrint('LunarFestival.fromYmd: $e\n$st');
        return true;
      }());
    }
    final termDay = solarDay.getTermDay();
    final isTermDay = termDay.getDayIndex() == 0;
    String subtitle;
    int subtitleType = _subtitleTypeLunar;
    if (solarFestival != null) {
      final raw = solarFestival.getName();
      subtitle = _solarFestivalShortNames[raw] ?? raw;
      subtitleType = _subtitleTypeFestival;
    } else if (lunarFestival != null) {
      subtitle = lunarFestival.getName();
      subtitleType = _subtitleTypeFestival;
    } else if (isTermDay) {
      subtitle = termDay.getSolarTerm().getName();
      subtitleType = _subtitleTypeTerm;
    } else {
      subtitle = lunarDay.getName();
    }
    if (subtitleType != _subtitleTypeFestival && subtitle.length > 2) {
      subtitle = subtitle.substring(0, 2);
    }
    return (subtitle, showRest, showWork, subtitleType);
  }

  @override
  Widget build(BuildContext context) {
    final solarMonth = SolarMonth.fromYm(year, month);
    final dayCount = solarMonth.getDayCount();
    final firstWeekday = solarMonth.getFirstDay().getWeek().getIndex();
    final prevMonth = solarMonth.next(-1);
    final prevDayCount = prevMonth.getDayCount();
    final nextMonth = solarMonth.next(1);

    final now = DateTime.now();
    final cache =
        <
          String,
          (String subtitle, bool showRest, bool showWork, int subtitleType)
        >{};
    String key(int y, int m, int d) => '$y-$m-$d';
    (String, bool, bool, int) getCached(int y, int m, int d) {
      final k = key(y, m, d);
      if (!cache.containsKey(k)) {
        cache[k] = getSubtitleAndRest(SolarDay.fromYmd(y, m, d));
      }
      final v = cache[k]!;
      return (v.$1, v.$2, v.$3, v.$4);
    }

    final cells = <Widget>[];
    int cellIndex = 0;
    for (int i = 0; i < firstWeekday; i++) {
      final d = prevDayCount - firstWeekday + 1 + i;
      final py = prevMonth.year;
      final pm = prevMonth.month;
      final (subtitle, showRest, showWork, subtitleType) = getCached(py, pm, d);
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
          isToday: now.year == py && now.month == pm && now.day == d,
          isSelected: _isSelected(py, pm, d),
          onTap: () => onSelectDate(DateTime(py, pm, d)),
        ),
      );
      cellIndex++;
    }
    for (int d = 1; d <= dayCount; d++) {
      final (subtitle, showRest, showWork, subtitleType) = getCached(
        year,
        month,
        d,
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
          isToday: now.year == year && now.month == month && now.day == d,
          isSelected: _isSelected(year, month, d),
          onTap: () => onSelectDate(DateTime(year, month, d)),
        ),
      );
      cellIndex++;
    }
    final nextCount = _totalDayCells - firstWeekday - dayCount;
    for (int d = 1; d <= nextCount; d++) {
      final ny = nextMonth.year;
      final nm = nextMonth.month;
      final (subtitle, showRest, showWork, subtitleType) = getCached(ny, nm, d);
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
          isToday: now.year == ny && now.month == nm && now.day == d,
          isSelected: _isSelected(ny, nm, d),
          onTap: () => onSelectDate(DateTime(ny, nm, d)),
        ),
      );
      cellIndex++;
    }

    final double contentWidth = availableWidth - _calendarHorizontalPadding * 2;
    final double cellWidth =
        (contentWidth - _calendarCrossSpacing * (_cols - 1)) / _cols;
    final double cellHeight = availableHeight / _dayRows;
    final double aspectRatio = cellWidth / cellHeight;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: _calendarHorizontalPadding,
      ),
      child: SizedBox(
        height: availableHeight,
        child: GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: _cols,
          mainAxisSpacing: 0,
          crossAxisSpacing: _calendarCrossSpacing,
          childAspectRatio: aspectRatio,
          children: cells,
        ),
      ),
    );
  }

  bool _isSelected(int y, int m, int d) {
    return selectedDate.year == y &&
        selectedDate.month == m &&
        selectedDate.day == d;
  }
}

class _DayCell extends StatelessWidget {
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
    final Color todayBg = theme.colorScheme.errorContainer;
    final Color onTodayBg = theme.colorScheme.onErrorContainer;
    final Color dayColor = todaySelected
        ? onTodayBg
        : isOtherMonth
        ? colorScheme.onSurface.withValues(alpha: 0.38)
        : isToday
        ? colorScheme.onSurface.withValues(alpha: 0.8)
        : isWeekend
        ? colorScheme.error
        : colorScheme.onSurface.withValues(alpha: 0.85);
    final bool isHighlighted = todaySelected;
    final Color highlightTextColor = todaySelected
        ? onTodayBg
        : colorScheme.onSurface.withValues(alpha: 0.85);

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
    if (subtitleType == _subtitleTypeFestival) {
      subtitleSize = 12;
      subtitleWeight = todaySelected ? FontWeight.w800 : FontWeight.w700;
      if (todaySelected) {
        subtitleColor = onTodayBg;
      } else if (!isOtherMonth && !isHighlighted) {
        subtitleColor = colorScheme.error;
      } else if (isOtherMonth) {
        subtitleColor = colorScheme.onSurface.withValues(alpha: 0.45);
      }
    } else if (subtitleType == _subtitleTypeTerm) {
      subtitleSize = 11;
      subtitleWeight = todaySelected ? FontWeight.w800 : FontWeight.w600;
      if (todaySelected) {
        subtitleColor = onTodayBg;
      } else if (!isOtherMonth) {
        subtitleColor = const Color(0xFF2E7D32);
      } else {
        subtitleColor = colorScheme.onSurface.withValues(alpha: 0.42);
      }
    } else {
      subtitleSize = 10;
      subtitleWeight = todaySelected ? FontWeight.w800 : FontWeight.w500;
      if (todaySelected) {
        subtitleColor = onTodayBg;
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
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          borderRadius: radius,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: radius,
              color: todaySelected
                  ? todayBg
                  : (isToday ? colorScheme.surfaceContainerHighest : null),
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
                                  ? onTodayBg
                                  : (isHighlighted
                                        ? highlightTextColor
                                        : subtitleColor),
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
                // 休：左上角；班：右上角，与边框留 2px
                if (showRest)
                  Positioned(
                    top: 2,
                    left: 2,
                    child: _RestWorkBadge(
                      label: '休',
                      backgroundColor: colorScheme.error,
                    ),
                  ),
                if (showWork)
                  Positioned(
                    top: 2,
                    right: 2,
                    child: _RestWorkBadge(
                      label: '班',
                      backgroundColor: colorScheme.primary,
                    ),
                  ),
                if (isToday)
                  Positioned(
                    top: 2,
                    right: showWork ? 18 : 2,
                    child: Text(
                      '今',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: todaySelected
                            ? onTodayBg
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
