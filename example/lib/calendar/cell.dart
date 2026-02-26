import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'constants.dart';

/// 休/班角标：小圆形，不遮挡内容
class RestWorkBadge extends StatelessWidget {
  final String label;
  final Color backgroundColor;

  const RestWorkBadge({super.key, required this.label, required this.backgroundColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: badgeSize,
      height: badgeSize,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: backgroundColor, shape: BoxShape.circle),
      child: Text(
        label,
        style: TextStyle(
          fontSize: badgeFontSize,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          fontFamily: calendarFontFamily,
        ),
      ),
    );
  }
}

/// 单日格子：公历数字 + 副标题（节日/节气/农历）+ 休/班/今角标
class CalendarDayCell extends StatelessWidget {
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

  const CalendarDayCell({
    super.key,
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
    final bool todaySelected = isToday && isSelected;
    final Color todayBg = colorScheme.errorContainer;
    final Color onTodayBg = colorScheme.onErrorContainer;
    final Color dayColor = todaySelected
        ? onTodayBg
        : isOtherMonth
            ? colorScheme.onSurface.withValues(alpha: 0.38)
            : isToday
                ? colorScheme.onSurface.withValues(alpha: 0.8)
                : isWeekend
                    ? colorScheme.error
                    : colorScheme.onSurface.withValues(alpha: 0.85);
    final dayStyle = TextStyle(
      fontSize: dayNumberFontSize,
      fontWeight: todaySelected ? FontWeight.w800 : FontWeight.w700,
      color: dayColor,
      fontFamily: calendarFontFamily,
    );

    double subtitleSize = subtitleFontSizeLunar;
    FontWeight subtitleWeight = FontWeight.w500;
    Color subtitleColor = colorScheme.onSurface.withValues(alpha: isOtherMonth ? 0.4 : 0.65);
    if (subtitleType == subtitleTypeFestival) {
      subtitleSize = subtitleFontSizeFestival;
      subtitleWeight = todaySelected ? FontWeight.w800 : FontWeight.w700;
      subtitleColor = todaySelected
          ? onTodayBg
          : (!isOtherMonth && !todaySelected ? colorScheme.error : colorScheme.onSurface.withValues(alpha: 0.45));
    } else if (subtitleType == subtitleTypeTerm) {
      subtitleSize = subtitleFontSizeTerm;
      subtitleWeight = todaySelected ? FontWeight.w800 : FontWeight.w600;
      subtitleColor = todaySelected
          ? onTodayBg
          : (!isOtherMonth ? const Color(0xFF2E7D32) : colorScheme.onSurface.withValues(alpha: 0.42));
    } else {
      subtitleSize = subtitleFontSizeLunar;
      subtitleWeight = todaySelected ? FontWeight.w800 : FontWeight.w500;
      subtitleColor = todaySelected ? onTodayBg : colorScheme.onSurface.withValues(alpha: 0.65);
    }

    final radius = BorderRadius.all(Radius.circular(cellBorderRadius));
    return Semantics(
      label: _semanticsLabel(),
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
              border: Border.all(
                color: isSelected ? colorScheme.error : Colors.transparent,
                width: cellBorderWidth,
              ),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
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
                              color: todaySelected ? onTodayBg : subtitleColor,
                              fontFamily: calendarFontFamily,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                      ],
                    ),
                  ),
                ),
                if (showRest)
                  Positioned(
                    top: badgeInset,
                    left: badgeInset,
                    child: RestWorkBadge(label: '休', backgroundColor: colorScheme.error),
                  ),
                if (showWork)
                  Positioned(
                    top: badgeInset,
                    right: badgeInset,
                    child: RestWorkBadge(label: '班', backgroundColor: colorScheme.primary),
                  ),
                if (isToday)
                  Positioned(
                    top: badgeInset,
                    right: showWork ? badgeSize + badgeInset : badgeInset,
                    child: Text(
                      '今',
                      style: TextStyle(
                        fontSize: todayLabelFontSize,
                        fontWeight: FontWeight.w700,
                        color: todaySelected
                            ? onTodayBg
                            : colorScheme.onSurface.withValues(alpha: 0.7),
                        fontFamily: calendarFontFamily,
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

  String _semanticsLabel() {
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
