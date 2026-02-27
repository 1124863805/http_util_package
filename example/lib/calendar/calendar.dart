import 'package:flutter/material.dart';

import 'constants.dart';
import 'grid.dart';

/// 控制器：供外部调用 goPrevMonth、goNextMonth、showYearMonthPicker、toggleCollapsed
class PerpetualCalendarController {
  PerpetualCalendarState? _state;

  void _attach(PerpetualCalendarState state) => _state = state;
  void _detach() => _state = null;

  void toggleCollapsed() => _state?.toggleCollapsed();
  void goPrevMonth() => _state?.goPrevMonth();
  void goNextMonth() => _state?.goNextMonth();
  void goToDate(DateTime date) => _state?.goToDate(date);
  Future<void> showYearMonthPicker() =>
      _state?.showYearMonthPicker() ?? Future.value();
}

/// 万年历组件（可嵌入任意页面），范围 1900-2099，左右滑动切月
class PerpetualCalendar extends StatefulWidget {
  final DateTime? initialDate;
  final DateTime? selectedDate;
  final ValueChanged<DateTime>? onDateSelected;
  final double? maxHeight;
  final PerpetualCalendarController? controller;

  const PerpetualCalendar({
    super.key,
    this.initialDate,
    this.selectedDate,
    this.onDateSelected,
    this.maxHeight,
    this.controller,
  });

  @override
  State<PerpetualCalendar> createState() => PerpetualCalendarState();
}

/// 供外部通过 GlobalKey 调用：goPrevMonth、goNextMonth、showYearMonthPicker
class PerpetualCalendarState extends State<PerpetualCalendar> {
  static const int _baseYear = 1900;
  static const int _endYear = 2099;
  static final DateTime _weekEpoch = DateTime(1899, 12, 31);
  static const int _totalMonths = (_endYear - _baseYear + 1) * 12;
  static final int _totalWeeks = DateTime(_endYear, 12, 31)
      .difference(_weekEpoch)
      .inDays ~/ 7;
  static const List<String> _weekdays = ['日', '一', '二', '三', '四', '五', '六'];
  static const double _calendarMaxHeight = 400;
  static double get _collapsedRowHeight => calendarRowHeight;

  late PageController _pageController;
  late PageController _weekPageController;
  late DateTime _selectedDate;
  late DateTime _viewDate;
  bool _collapsed = false;
  bool _showBadge = true;
  bool _isToggling = false;

  DateTime get _effectiveSelectedDate => widget.selectedDate ?? _selectedDate;

  (int year, int month) _pageToYearMonth(int index) {
    return (_baseYear + index ~/ 12, index % 12 + 1);
  }

  DateTime _weekPageToStartDate(int index) {
    return _weekEpoch.add(Duration(days: index * 7));
  }

  int get _monthPage =>
      ((_viewDate.year - _baseYear) * 12 + _viewDate.month - 1).clamp(
        0,
        _totalMonths - 1,
      );

  int get _weekPage => _dateToWeekPageIndex(_viewDate);

  int _dateToWeekPageIndex(DateTime date) {
    final sun = date.subtract(Duration(days: date.weekday % 7));
    final days = sun.difference(_weekEpoch).inDays;
    final idx = days ~/ 7;
    return idx.clamp(0, _totalWeeks - 1);
  }

  void _setViewDateFromMonthPage(int page) {
    final (y, m) = _pageToYearMonth(page);
    _viewDate = DateTime(y, m, 1);
  }

  void _setViewDateFromWeekPage(int page) {
    _viewDate = _weekPageToStartDate(page);
  }

  /// 收起时显示的周：优先级 选中 > 今天 > 当月第一周
  DateTime _computeViewDateForCollapse() {
    final selected = _effectiveSelectedDate;
    final now = DateTime.now();
    final vy = _viewDate.year;
    final vm = _viewDate.month;
    if (selected.year == vy && selected.month == vm) return selected;
    if (now.year == vy && now.month == vm) return now;
    return DateTime(vy, vm, 1);
  }

  @override
  void initState() {
    super.initState();
    final init = widget.initialDate ?? widget.selectedDate ?? DateTime.now();
    _selectedDate = init;
    _viewDate = init;
    _pageController = PageController(initialPage: _monthPage);
    _weekPageController = PageController(initialPage: _weekPage);
    widget.controller?._attach(this);
    _schedulePrefetch(_monthPage);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_pageController.hasClients) {
        final page = _pageController.page?.round() ?? _monthPage;
        _setViewDateFromMonthPage(page.clamp(0, _totalMonths - 1));
      }
    });
  }

  @override
  void didUpdateWidget(covariant PerpetualCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?._detach();
      widget.controller?._attach(this);
    }
  }

  void _schedulePrefetch(int pageIndex) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final (y, m) = _pageToYearMonth(pageIndex);
      prefetchMonthData(y, m);
      if (pageIndex > 0) {
        final (py, pm) = _pageToYearMonth(pageIndex - 1);
        prefetchMonthData(py, pm);
      }
      if (pageIndex < _totalMonths - 1) {
        final (ny, nm) = _pageToYearMonth(pageIndex + 1);
        prefetchMonthData(ny, nm);
      }
    });
  }

  @override
  void dispose() {
    widget.controller?._detach();
    _pageController.dispose();
    _weekPageController.dispose();
    super.dispose();
  }

  void _onSelectDate(DateTime date) {
    if (widget.onDateSelected != null) {
      widget.onDateSelected!(date);
    } else {
      setState(() => _selectedDate = date);
    }
    _viewDate = date;
    final targetMonthPage = (date.year - _baseYear) * 12 + (date.month - 1);
    final page = targetMonthPage.clamp(0, _totalMonths - 1);
    if (_collapsed) {
      if (_weekPageController.hasClients) {
        final weekPage = _dateToWeekPageIndex(date);
        _weekPageController.animateToPage(
          weekPage,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeInOut,
        );
      }
    } else {
      final currentPage = _pageController.page?.round();
      if (_pageController.hasClients &&
          (currentPage == null || page != currentPage)) {
        _pageController.animateToPage(
          page,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  static const _collapseDuration = Duration(milliseconds: 380);

  void toggleCollapsed() {
    if (_isToggling) return;
    _isToggling = true;
    Future.delayed(_collapseDuration, () {
      if (mounted) setState(() => _isToggling = false);
    });
    setState(() {
      if (!_collapsed) {
        if (_pageController.hasClients) {
          final page = _pageController.page?.round() ?? _monthPage;
          _setViewDateFromMonthPage(page.clamp(0, _totalMonths - 1));
        }
        _viewDate = _computeViewDateForCollapse();
      } else {
        if (_weekPageController.hasClients) {
          final page = _weekPageController.page?.round() ?? _weekPage;
          _setViewDateFromWeekPage(page.clamp(0, _totalWeeks - 1));
          final selected = _effectiveSelectedDate;
          if (selected.year != _viewDate.year ||
              selected.month != _viewDate.month) {
            _viewDate = selected;
          }
        }
      }
      _collapsed = !_collapsed;
      _showBadge = false;
    });
    Future.delayed(_collapseDuration, () {
      if (mounted) setState(() => _showBadge = true);
    });
    void tryJump([int retry = 0]) {
      if (!mounted || retry > 5) return;
      if (_collapsed) {
        if (_weekPageController.hasClients) {
          _weekPageController.jumpToPage(_weekPage);
          prefetchWeekData(_weekPageToStartDate(_weekPage));
        } else {
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => tryJump(retry + 1),
          );
        }
      } else {
        if (_pageController.hasClients) {
          _pageController.jumpToPage(_monthPage);
        } else {
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => tryJump(retry + 1),
          );
        }
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => tryJump());
  }

  void goToDate(DateTime date) {
    _viewDate = date;
    if (_pageController.hasClients) {
      final page = (date.year - _baseYear) * 12 + date.month - 1;
      _pageController.jumpToPage(page.clamp(0, _totalMonths - 1));
    }
    if (_weekPageController.hasClients) {
      _weekPageController.jumpToPage(_dateToWeekPageIndex(date));
    }
  }

  void goPrevMonth() {
    if (!_pageController.hasClients || _monthPage <= 0) return;
    _pageController.animateToPage(
      _monthPage - 1,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOut,
    );
  }

  void goNextMonth() {
    if (!_pageController.hasClients || _monthPage >= _totalMonths - 1) return;
    _pageController.animateToPage(
      _monthPage + 1,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOut,
    );
  }

  Future<void> showYearMonthPicker() async {
    final (year, month) = _pageToYearMonth(_monthPage);
    final theme = Theme.of(context);
    final picked = await showDialog<(int year, int month)>(
      context: context,
      builder: (context) {
        int selYear = year;
        int selMonth = month;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('选择年月', style: theme.textTheme.titleLarge),
              content: SizedBox(
                width: 220,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<int>(
                      initialValue: selYear,
                      decoration: InputDecoration(labelText: '年'),
                      dropdownColor: theme.colorScheme.surface,
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
                    SizedBox(height: calendarVerticalPadding * 2),
                    DropdownButtonFormField<int>(
                      value: selMonth,
                      decoration: InputDecoration(labelText: '月'),
                      dropdownColor: theme.colorScheme.surface,
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
    _setViewDateFromMonthPage(index);
    _schedulePrefetch(index);
  }

  void _onWeekPageChanged(int index) {
    _setViewDateFromWeekPage(index);
    final weekStart = _weekPageToStartDate(index);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      prefetchWeekData(weekStart);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final calTheme = CalendarTheme.of(theme.brightness);
    final maxH = widget.maxHeight ?? _calendarMaxHeight;

    return AnimatedSize(
      duration: _collapseDuration,
      curve: Curves.easeInOutCubic,
      alignment: Alignment.topCenter,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: toggleCollapsed,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                calendarHorizontalPadding,
                calendarVerticalPadding,
                calendarHorizontalPadding,
                calendarVerticalPadding / 2,
              ),
              child: Row(
                children: [
                  for (int i = 0; i < _weekdays.length; i++) ...[
                    if (i > 0) const SizedBox(width: calendarCrossSpacing),
                    Expanded(
                      child: Center(
                        child: Text(
                          _weekdays[i],
                          style: TextStyle(
                            fontSize: weekdayFontSize,
                            fontWeight: FontWeight.w500,
                            letterSpacing: weekdayLetterSpacing,
                            color: (i == 0 || i == 6)
                                ? calTheme.weekdayColorWeekend
                                : calTheme.weekdayColor,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          ClipRect(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, animation) =>
                  FadeTransition(opacity: animation, child: child),
              child: SizedBox(
                key: ValueKey(_collapsed),
                height: _collapsed
                    ? calendarCollapsedHeight - calendarHeaderHeight
                    : calendarExpandedHeight - calendarHeaderHeight,
                child: LayoutBuilder(
                  builder: (_, constraints) {
                    final w = constraints.maxWidth;
                    final h = _collapsed
                        ? _collapsedRowHeight
                        : (calendarExpandedHeight - calendarHeaderHeight).clamp(
                            0.0,
                            maxH,
                          );
                    if (_collapsed) {
                      return PageView.builder(
                        controller: _weekPageController,
                        itemCount: _totalWeeks,
                        onPageChanged: _onWeekPageChanged,
                        physics: const _SensitivePageScrollPhysics(),
                        itemBuilder: (context, index) {
                          final weekStart = _weekPageToStartDate(index);
                          return RepaintBoundary(
                            child: CalendarWeekRow(
                              key: ValueKey('w$index'),
                              weekStart: weekStart,
                              selectedDate: _effectiveSelectedDate,
                              onSelectDate: _onSelectDate,
                              availableHeight: h,
                              availableWidth: w,
                              showBadge: _showBadge,
                            ),
                          );
                        },
                      );
                    }
                    return PageView.builder(
                      controller: _pageController,
                      itemCount: _totalMonths,
                      onPageChanged: _onPageChanged,
                      physics: const _SensitivePageScrollPhysics(),
                      itemBuilder: (context, index) {
                        final (y, m) = _pageToYearMonth(index);
                        return RepaintBoundary(
                          child: CalendarMonthGrid(
                            key: ValueKey('m$index'),
                            year: y,
                            month: m,
                            selectedDate: _effectiveSelectedDate,
                            onSelectDate: _onSelectDate,
                            availableHeight: h,
                            availableWidth: w,
                            dayRows: 6,
                            showWatermark: true,
                            showBadge: _showBadge,
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 提高滑动灵敏度：相同手指移动距离产生更大滚动位移
class _SensitivePageScrollPhysics extends PageScrollPhysics {
  const _SensitivePageScrollPhysics({super.parent});

  static const double _sensitivity = 2.25;

  @override
  _SensitivePageScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return _SensitivePageScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  double applyPhysicsToUserOffset(ScrollMetrics position, double offset) {
    return offset * _sensitivity;
  }
}
