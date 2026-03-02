import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'constants.dart';

/// 休/班角标：小圆形，不遮挡内容
class RestWorkBadge extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color textColor;

  const RestWorkBadge({
    super.key,
    required this.label,
    required this.backgroundColor,
    this.textColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: badgeSize,
      height: badgeSize,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: backgroundColor.withValues(alpha: 0.4),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: badgeFontSize,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }
}

/// 单日格子：公历数字 + 副标题（节日/节气/农历）+ 干支 + 休/班/今角标
class CalendarDayCell extends StatelessWidget {
  final int year;
  final int month;
  final int day;
  final String subtitle;
  final int subtitleType;
  final String ganZhi;
  final bool showRest;
  final bool showWork;
  final bool isWeekend;
  final bool isOtherMonth;
  final bool isToday;
  final bool isSelected;
  final bool showBadge;
  /// 选中效果强度 0~1，切换视图时淡出侧可传入 <1 以弱化选中，避免双高亮
  final double selectionTransitionFactor;
  final VoidCallback onTap;

  const CalendarDayCell({
    super.key,
    required this.year,
    required this.month,
    required this.day,
    required this.subtitle,
    required this.subtitleType,
    required this.ganZhi,
    required this.showRest,
    required this.showWork,
    required this.isWeekend,
    required this.isOtherMonth,
    required this.isToday,
    required this.isSelected,
    this.showBadge = true,
    this.selectionTransitionFactor = 1.0,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final calTheme = CalendarTheme.of(theme.brightness);
    final bool todaySelected = isToday && isSelected;
    final Color dayColor = todaySelected
        ? calTheme.cellBorderSelected
        : isOtherMonth
        ? calTheme.dayNumberColorOtherMonth
        : isToday
        ? calTheme.dayNumberColorToday
        : isWeekend
        ? calTheme.dayNumberColorWeekend
        : calTheme.dayNumberColor;
    final dayStyle = TextStyle(
      fontSize: dayNumberFontSize,
      fontWeight: todaySelected ? FontWeight.w800 : FontWeight.w700,
      color: dayColor,
    );

    double subtitleSize = subtitleFontSizeLunar;
    FontWeight subtitleWeight = FontWeight.w500;
    Color subtitleColor;
    if (subtitleType == subtitleTypeFestival) {
      subtitleSize = subtitleFontSizeFestival;
      subtitleWeight = todaySelected ? FontWeight.w800 : FontWeight.w700;
      subtitleColor = todaySelected
          ? calTheme.cellBorderSelected
          : (isOtherMonth
                ? calTheme.subtitleColorOtherMonth
                : calTheme.subtitleColorFestival);
    } else if (subtitleType == subtitleTypeTerm) {
      subtitleSize = subtitleFontSizeTerm;
      subtitleWeight = todaySelected ? FontWeight.w800 : FontWeight.w600;
      subtitleColor = todaySelected
          ? calTheme.cellBorderSelected
          : (isOtherMonth
                ? calTheme.subtitleColorOtherMonth
                : calTheme.subtitleColorTerm);
    } else {
      subtitleSize = subtitleFontSizeLunar;
      subtitleWeight = todaySelected ? FontWeight.w800 : FontWeight.w500;
      subtitleColor = todaySelected
          ? calTheme.cellBorderSelected
          : (isOtherMonth
                ? calTheme.subtitleColorOtherMonth
                : calTheme.subtitleColor);
    }

    final radius = BorderRadius.all(Radius.circular(cellBorderRadius));
    final selectionStrength = isSelected ? selectionTransitionFactor : 0.0;
    final borderColor = selectionStrength > 0 && showBadge
        ? Color.lerp(
            Colors.transparent,
            calTheme.cellBorderSelected,
            selectionStrength,
          )!
        : Colors.transparent;
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
          child: AnimatedContainer(
            duration: cellSelectionTransitionDuration,
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              borderRadius: radius,
              // 休/今/选中背景：休用低透明度(0.5)不遮挡水印；今和选中用 0.85
              color: todaySelected && selectionTransitionFactor > 0
                  ? calTheme.cellBgSelected
                      .withValues(alpha: 0.85 * selectionTransitionFactor)
                  : (isToday
                        ? calTheme.cellBgToday.withValues(alpha: 0.85)
                        : (showRest
                              ? calTheme.cellBgRest.withValues(alpha: 0.5)
                              : null)),
              border: Border.all(
                color: borderColor,
                width: cellBorderWidth,
              ),
            ),
            child: Stack(
              clipBehavior: Clip.hardEdge,
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
                              color: todaySelected
                                  ? calTheme.cellBorderSelected
                                  : subtitleColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        if (ganZhi.isNotEmpty)
                          Text(
                            ganZhi,
                            style: TextStyle(
                              fontSize: ganZhiFontSize,
                              fontWeight: FontWeight.w400,
                              color: todaySelected
                                  ? calTheme.cellBorderSelected
                                  : (isOtherMonth
                                        ? calTheme.subtitleColorOtherMonth
                                        : calTheme.subtitleColor),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                      ],
                    ),
                  ),
                ),
                // 休/班/今/周 统一右上角，只显示一个，优先级：今 > 休 > 班 > 周；动画中延迟显示
                if (showBadge && isToday)
                  Positioned(
                    top: badgeInset,
                    right: badgeInset,
                    child: Text(
                      '今',
                      style: TextStyle(
                        fontSize: todayLabelFontSize,
                        fontWeight: FontWeight.w700,
                        color: todaySelected
                            ? calTheme.cellBorderSelected
                            : calTheme.dayNumberColorToday,
                      ),
                    ),
                  )
                else if (showBadge && showRest)
                  Positioned(
                    top: badgeInset,
                    right: badgeInset,
                    child: RestWorkBadge(
                      label: '休',
                      backgroundColor: calTheme.badgeRestBg,
                      textColor: calTheme.badgeTextColor,
                    ),
                  )
                else if (showBadge && showWork)
                  Positioned(
                    top: badgeInset,
                    right: badgeInset,
                    child: RestWorkBadge(
                      label: '班',
                      backgroundColor: calTheme.badgeWorkBg,
                      textColor: calTheme.badgeTextColor,
                    ),
                  )
                else if (showBadge && isWeekend)
                  Positioned(
                    top: badgeInset,
                    right: badgeInset,
                    child: RestWorkBadge(
                      label: '周',
                      backgroundColor: calTheme.badgeWeekendBg,
                      textColor: calTheme.badgeTextColor,
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
    if (ganZhi.isNotEmpty) parts.add(ganZhi);
    if (showRest) parts.add('休');
    if (showWork) parts.add('班');
    if (isWeekend && !showRest && !showWork) parts.add('周末');
    if (isSelected && !isToday) parts.add('已选中');
    return parts.join(' ');
  }
}
