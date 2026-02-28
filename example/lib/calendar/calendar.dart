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
  /// 外部控制收起状态，非 null 时覆盖内部状态并禁用点击切换
  final bool? collapsed;
  /// 吸顶模式下由外部传入的约束高度，用于避免溢出/空白
  final double? constrainedHeight;
  /// 视图变化回调（滑动切月/切周时），用于吸顶场景保持视图状态
  final ValueChanged<DateTime>? onViewDateChanged;

  const PerpetualCalendar({
    super.key,
    this.initialDate,
    this.selectedDate,
    this.onDateSelected,
    this.maxHeight,
    this.controller,
    this.collapsed,
    this.constrainedHeight,
    this.onViewDateChanged,
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

  late PageController _pageController;
  late PageController _weekPageController;
  late DateTime _selectedDate;
  late DateTime _viewDate;
  bool _collapsed = false;
  bool _showBadge = true;
  bool _isToggling = false;

  DateTime get _effectiveSelectedDate => widget.selectedDate ?? _selectedDate;
  bool get _effectiveCollapsed {
    if (widget.constrainedHeight != null) {
      final ch = widget.constrainedHeight! - calendarHeaderHeight;
      return ch < 160;
    }
    return widget.collapsed ?? _collapsed;
  }

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

  int get _weekPage {
    if (widget.constrainedHeight != null) {
      final ch = widget.constrainedHeight! - calendarHeaderHeight;
      if (ch < 160) return _dateToWeekPageIndex(_effectiveSelectedDate);
    }
    return _dateToWeekPageIndex(_viewDate);
  }

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

  /// 收起时显示的周：始终显示选中日期所在周
  DateTime _computeViewDateForCollapse() => _effectiveSelectedDate;

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
    final newInit = widget.initialDate;
    if (newInit != null &&
        (oldWidget.initialDate == null || newInit != oldWidget.initialDate)) {
      final weekChanged = _dateToWeekPageIndex(_viewDate) != _dateToWeekPageIndex(newInit);
      final monthChanged = _viewDate.year != newInit.year || _viewDate.month != newInit.month;
      if (monthChanged || weekChanged) {
        _viewDate = newInit;
        if (_pageController.hasClients) {
          final page = (newInit.year - _baseYear) * 12 + newInit.month - 1;
          _pageController.jumpToPage(page.clamp(0, _totalMonths - 1));
        }
        final targetWeek = _dateToWeekPageIndex(newInit);
        void jumpWeek() {
          if (mounted && _weekPageController.hasClients) {
            _weekPageController.jumpToPage(targetWeek);
          }
        }
        if (_weekPageController.hasClients) {
          jumpWeek();
        } else {
          WidgetsBinding.instance.addPostFrameCallback((_) => jumpWeek());
        }
      }
    }
    final newCh = widget.constrainedHeight;
    final oldCh = oldWidget.constrainedHeight;
    final newCollapsed = newCh != null && (newCh - calendarHeaderHeight) < 160;
    final oldCollapsed = oldCh != null && (oldCh - calendarHeaderHeight) < 160;
    if (widget.collapsed == true && oldWidget.collapsed != true ||
        newCollapsed && !oldCollapsed) {
      _viewDate = _computeViewDateForCollapse();
      final targetWeekPage = _dateToWeekPageIndex(_viewDate);
      void jumpWeek() {
        if (mounted && _weekPageController.hasClients) {
          _weekPageController.jumpToPage(targetWeekPage);
        }
      }
      if (_weekPageController.hasClients) {
        jumpWeek();
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) => jumpWeek());
      }
    }
    if (!newCollapsed && oldCollapsed) {
      _viewDate = _effectiveSelectedDate;
      if (_pageController.hasClients) {
        final page = (_viewDate.year - _baseYear) * 12 + _viewDate.month - 1;
        _pageController.jumpToPage(page.clamp(0, _totalMonths - 1));
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _pageController.hasClients) {
            final page = (_viewDate.year - _baseYear) * 12 + _viewDate.month - 1;
            _pageController.jumpToPage(page.clamp(0, _totalMonths - 1));
          }
        });
      }
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

  void _deferViewDateChanged([DateTime? date]) {
    final d = date ?? _viewDate;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onViewDateChanged?.call(d);
    });
  }

  void _onSelectDate(DateTime date) {
    if (widget.onDateSelected != null) {
      widget.onDateSelected!(date);
    } else {
      setState(() => _selectedDate = date);
    }
    _viewDate = date;
    _deferViewDateChanged(date);
    final targetMonthPage = (date.year - _baseYear) * 12 + (date.month - 1);
    final page = targetMonthPage.clamp(0, _totalMonths - 1);
    if (_effectiveCollapsed) {
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
    _deferViewDateChanged();
    _schedulePrefetch(index);
  }

  void _onWeekPageChanged(int index) {
    _setViewDateFromWeekPage(index);
    _deferViewDateChanged();
    final weekStart = _weekPageToStartDate(index);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      prefetchWeekData(weekStart);
    });
  }

  @override
  Widget build(BuildContext context) {
    final calTheme = CalendarTheme.of(Theme.of(context).brightness);
    final maxH = widget.maxHeight ?? _calendarMaxHeight;
    final useConstraint = widget.constrainedHeight != null;
    final contentHeight = useConstraint
        ? (widget.constrainedHeight! - calendarHeaderHeight).clamp(1.0, double.infinity)
        : (_effectiveCollapsed
            ? calendarCollapsedHeight - calendarHeaderHeight
            : (calendarExpandedHeight - calendarHeaderHeight).clamp(0.0, maxH));

    final body = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: widget.collapsed == null && !useConstraint ? toggleCollapsed : null,
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
          child: SizedBox(
            height: contentHeight,
            child: LayoutBuilder(
                builder: (_, constraints) {
                  final w = constraints.maxWidth;
                  final h = contentHeight;
                  final weekView = PageView.builder(
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
                  final monthView = PageView.builder(
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
                  return IndexedStack(
                    index: _effectiveCollapsed ? 0 : 1,
                    sizing: StackFit.passthrough,
                    children: [weekView, monthView],
                  );
                },
              ),
            ),
        ),
      ],
    );

    if (useConstraint) {
      return SizedBox(height: widget.constrainedHeight, child: body);
    }
    return AnimatedSize(
      duration: _collapseDuration,
      curve: Curves.easeInOutCubic,
      alignment: Alignment.topCenter,
      child: body,
    );
  }
}

/// 吸顶日历：滑动时吸顶并自动收起为周视图，底部为 children
class StickyPerpetualCalendar extends StatefulWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;
  final List<Widget> children;

  const StickyPerpetualCalendar({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
    this.children = const [],
  });

  @override
  State<StickyPerpetualCalendar> createState() => _StickyPerpetualCalendarState();
}

class _StickyPerpetualCalendarState extends State<StickyPerpetualCalendar> {
  final _controller = PerpetualCalendarController();
  late DateTime _viewDate;

  @override
  void initState() {
    super.initState();
    _viewDate = widget.selectedDate;
  }

  @override
  void didUpdateWidget(covariant StickyPerpetualCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedDate != oldWidget.selectedDate) {
      _viewDate = widget.selectedDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      cacheExtent: 150,
      slivers: [
        SliverPersistentHeader(
          pinned: true,
          delegate: _StickyDelegate(
            selectedDate: widget.selectedDate,
            viewDate: _viewDate,
            onDateSelected: widget.onDateSelected,
            onViewDateChanged: (d) => setState(() => _viewDate = d),
            controller: _controller,
          ),
        ),
        SliverList(
          delegate: SliverChildListDelegate(widget.children),
        ),
      ],
    );
  }
}

class _StickyDelegate extends SliverPersistentHeaderDelegate {
  final DateTime selectedDate;
  final DateTime viewDate;
  final ValueChanged<DateTime> onDateSelected;
  final ValueChanged<DateTime> onViewDateChanged;
  final PerpetualCalendarController controller;

  _StickyDelegate({
    required this.selectedDate,
    required this.viewDate,
    required this.onDateSelected,
    required this.onViewDateChanged,
    required this.controller,
  });

  @override
  double get minExtent => calendarCollapsedHeight;

  @override
  double get maxExtent => calendarExpandedHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final h = (maxExtent - shrinkOffset).clamp(minExtent, maxExtent);
    // 收起/展开均以 selectedDate 为基准，确保视图与选中日期一致
    final initial = selectedDate;
    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SizedBox(
        height: h,
        child: PerpetualCalendar(
          key: const ValueKey('sticky_cal'),
          controller: controller,
          initialDate: initial,
          selectedDate: selectedDate,
          onDateSelected: onDateSelected,
          onViewDateChanged: onViewDateChanged,
          constrainedHeight: h,
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _StickyDelegate old) =>
      selectedDate != old.selectedDate || viewDate != old.viewDate;
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
