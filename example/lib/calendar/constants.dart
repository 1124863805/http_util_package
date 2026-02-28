import 'package:flutter/material.dart';

// 万年历 UI 常量，供 calendar / cell / grid 共用

const double cellBorderRadius = 8;
const double cellBorderWidth = 1.5;

/// 选中格子边框/背景的过渡时长，与周/月切换一致
const Duration cellSelectionTransitionDuration = Duration(milliseconds: 200);

const double calendarHorizontalPadding = 16;
const double calendarCrossSpacing = 8;
const double calendarVerticalPadding = 6;

const double weekdayFontSize = 14;
const double weekdayLetterSpacing = 0.5;
const double dayNumberFontSize = 20;
const double subtitleFontSizeLunar = 10;
const double subtitleFontSizeTerm = 11;
const double subtitleFontSizeFestival = 12;
const double todayLabelFontSize = 9;
const double badgeSize = 14;
const double badgeFontSize = 8;
const double badgeInset = 2;

const double watermarkFontSize = 96;
const double watermarkOpacity = 0.03;

/// 日历收起/展开时的固定高度，供外部布局使用
const double calendarExpandedHeight = 400;
const double calendarHeaderHeight = 30;
const double calendarRowHeight =
    (calendarExpandedHeight - calendarHeaderHeight) / 6;
const double calendarCollapsedHeight = calendarHeaderHeight + calendarRowHeight;

/// 周视图内容区高度（1 行）
const double calendarWeekContentHeight = calendarRowHeight;
/// 月视图内容区高度（6 行）
const double calendarMonthContentHeight = calendarRowHeight * 6;

const int subtitleTypeFestival = 0;
const int subtitleTypeTerm = 1;
const int subtitleTypeLunar = 2;

/// 日历主题：字体、颜色、背景
class CalendarTheme {
  final Color dayNumberColor;
  final Color dayNumberColorWeekend;
  final Color dayNumberColorOtherMonth;
  final Color dayNumberColorToday;
  final Color subtitleColor;
  final Color subtitleColorFestival;
  final Color subtitleColorTerm;
  final Color subtitleColorOtherMonth;
  final Color cellBgToday;
  final Color cellBgSelected;
  final Color cellBgRest;
  final Color cellBorderSelected;
  final Color weekdayColor;
  final Color weekdayColorWeekend;
  final Color badgeRestBg;
  final Color badgeWorkBg;
  final Color badgeWeekendBg;
  final Color badgeTodayBg;
  final Color badgeTextColor;

  const CalendarTheme({
    required this.dayNumberColor,
    required this.dayNumberColorWeekend,
    required this.dayNumberColorOtherMonth,
    required this.dayNumberColorToday,
    required this.subtitleColor,
    required this.subtitleColorFestival,
    required this.subtitleColorTerm,
    required this.subtitleColorOtherMonth,
    required this.cellBgToday,
    required this.cellBgSelected,
    required this.cellBgRest,
    required this.cellBorderSelected,
    required this.weekdayColor,
    required this.weekdayColorWeekend,
    required this.badgeRestBg,
    required this.badgeWorkBg,
    required this.badgeWeekendBg,
    required this.badgeTodayBg,
    required this.badgeTextColor,
  });

  /// 浅色：蓝主色、休红、班蓝、周末灰，语义清晰不冲突
  static const CalendarTheme freshLight = CalendarTheme(
    dayNumberColor: Color(0xFF37474F),
    dayNumberColorWeekend: Color(0xFF78909C),
    dayNumberColorOtherMonth: Color(0xFFB0BEC5),
    dayNumberColorToday: Color(0xFF1565C0),
    subtitleColor: Color(0xFF607D8B),
    subtitleColorFestival: Color(0xFFC62828),
    subtitleColorTerm: Color(0xFF2E7D32),
    subtitleColorOtherMonth: Color(0xFF90A4AE),
    cellBgToday: Color(0xFFE3F2FD),
    cellBgSelected: Color(0xFFBBDEFB),
    cellBgRest: Color(0xFFFFF5F5),
    cellBorderSelected: Color(0xFF1976D2),
    weekdayColor: Color(0xFF78909C),
    weekdayColorWeekend: Color(0xFF78909C),
    badgeRestBg: Color(0xFFE57373),
    badgeWorkBg: Color(0xFF1976D2),
    badgeWeekendBg: Color(0xFF78909C),
    badgeTodayBg: Color(0xFF1565C0),
    badgeTextColor: Colors.white,
  );

  /// 深色：低饱和、护眼
  static const CalendarTheme freshDark = CalendarTheme(
    dayNumberColor: Color(0xFFECEFF1),
    dayNumberColorWeekend: Color(0xFF90A4AE),
    dayNumberColorOtherMonth: Color(0xFF546E7A),
    dayNumberColorToday: Color(0xFF64B5F6),
    subtitleColor: Color(0xFFB0BEC5),
    subtitleColorFestival: Color(0xFFEF9A9A),
    subtitleColorTerm: Color(0xFF81C784),
    subtitleColorOtherMonth: Color(0xFF90A4AE),
    cellBgToday: Color(0xFF1E3A5F),
    cellBgSelected: Color(0xFF0D47A1),
    cellBgRest: Color(0xFF3E2723),
    cellBorderSelected: Color(0xFF42A5F5),
    weekdayColor: Color(0xFF90A4AE),
    weekdayColorWeekend: Color(0xFF90A4AE),
    badgeRestBg: Color(0xFFE57373),
    badgeWorkBg: Color(0xFF1976D2),
    badgeWeekendBg: Color(0xFF90A4AE),
    badgeTodayBg: Color(0xFF64B5F6),
    badgeTextColor: Colors.white,
  );

  static CalendarTheme of(Brightness brightness) =>
      brightness == Brightness.dark ? freshDark : freshLight;
}

const Map<String, String> solarFestivalShortNames = {
  '五一劳动节': '劳动节',
  '三八妇女节': '妇女节',
  '六一儿童节': '儿童节',
  '五四青年节': '青年节',
  '八一建军节': '建军节',
};
