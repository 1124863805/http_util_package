import 'package:flutter/material.dart';

/// 年月日快速切换选择器
class DateSelector extends StatelessWidget {
  final DateTime date;
  final ValueChanged<DateTime> onChanged;

  const DateSelector({super.key, required this.date, required this.onChanged});

  static const int _baseYear = 1900;
  static const int _endYear = 2099;

  int _dayCount(int year, int month) => DateTime(year, month + 1, 0).day;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text('快速切换：', style: theme.textTheme.bodyMedium),
          _Dropdown<int>(
            value: date.year,
            items: List.generate(
              _endYear - _baseYear + 1,
              (i) => DropdownMenuItem(
                value: _baseYear + i,
                child: Text('${_baseYear + i}年'),
              ),
            ),
            onChanged: (v) {
              if (v != null) {
                final d = date.day.clamp(1, _dayCount(v, date.month));
                onChanged(DateTime(v, date.month, d));
              }
            },
          ),
          const SizedBox(width: 4),
          _Dropdown<int>(
            value: date.month,
            items: List.generate(
              12,
              (i) => DropdownMenuItem(value: i + 1, child: Text('${i + 1}月')),
            ),
            onChanged: (v) {
              if (v != null) {
                final d = date.day.clamp(1, _dayCount(date.year, v));
                onChanged(DateTime(date.year, v, d));
              }
            },
          ),
          const SizedBox(width: 4),
          _Dropdown<int>(
            value: date.day,
            items: List.generate(
              _dayCount(date.year, date.month),
              (i) => DropdownMenuItem(value: i + 1, child: Text('${i + 1}日')),
            ),
            onChanged: (v) {
              if (v != null) onChanged(DateTime(date.year, date.month, v));
            },
          ),
        ],
      ),
    );
  }
}

class _Dropdown<T> extends StatelessWidget {
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const _Dropdown({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outline),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          items: items,
          onChanged: onChanged,
          isDense: true,
        ),
      ),
    );
  }
}
