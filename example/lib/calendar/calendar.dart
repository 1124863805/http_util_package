import 'package:flutter/material.dart';

import 'constants.dart';
import 'grid.dart';

/// 万年历组件（可嵌入任意页面），范围 1900-2099，左右滑动切月
class PerpetualCalendar extends StatefulWidget {
  final DateTime? initialDate;
  final DateTime? selectedDate;
  final ValueChanged<DateTime>? onDateSelected;
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

/// 供外部通过 GlobalKey 调用：goPrevMonth、goNextMonth、showYearMonthPicker
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
    return (_baseYear + index ~/ 12, index % 12 + 1);
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

  void goPrevMonth() {
    if (!_pageController.hasClients || _currentPage <= 0) return;
    _pageController.animateToPage(
      _currentPage - 1,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOut,
    );
  }

  void goNextMonth() {
    if (!_pageController.hasClients || _currentPage >= _totalMonths - 1) return;
    _pageController.animateToPage(
      _currentPage + 1,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOut,
    );
  }

  Future<void> showYearMonthPicker() async {
    final (year, month) = _pageToYearMonth(_currentPage);
    final theme = Theme.of(context);
    final picked = await showDialog<(int year, int month)>(
      context: context,
      builder: (context) {
        int selYear = year;
        int selMonth = month;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                '选择年月',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontFamily: calendarFontFamily,
                ),
              ),
              content: SizedBox(
                width: 220,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<int>(
                      initialValue: selYear,
                      decoration: InputDecoration(
                        labelText: '年',
                        labelStyle: TextStyle(fontFamily: calendarFontFamily),
                      ),
                      dropdownColor: theme.colorScheme.surface,
                      items: List.generate(
                        _endYear - _baseYear + 1,
                        (i) => _baseYear + i,
                      )
                          .map(
                            (y) => DropdownMenuItem(
                              value: y,
                              child: Text('$y年', style: TextStyle(fontFamily: calendarFontFamily)),
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
                      decoration: InputDecoration(
                        labelText: '月',
                        labelStyle: TextStyle(fontFamily: calendarFontFamily),
                      ),
                      dropdownColor: theme.colorScheme.surface,
                      items: List.generate(12, (i) => i + 1)
                          .map(
                            (m) => DropdownMenuItem(
                              value: m,
                              child: Text('$m月', style: TextStyle(fontFamily: calendarFontFamily)),
                            ),
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
                  child: Text('取消', style: TextStyle(fontFamily: calendarFontFamily)),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop((selYear, selMonth)),
                  child: Text('确定', style: TextStyle(fontFamily: calendarFontFamily)),
                ),
              ],
            );
          },
        );
      },
    );
    if (picked != null && mounted && _pageController.hasClients) {
      final page = ((picked.$1 - _baseYear) * 12 + (picked.$2 - 1)).clamp(0, _totalMonths - 1);
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

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
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
                        fontFamily: calendarFontFamily,
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
                    return CalendarMonthGrid(
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
  }
}
