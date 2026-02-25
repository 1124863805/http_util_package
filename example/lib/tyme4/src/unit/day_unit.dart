import 'month_unit.dart';

/// 日
///
/// Author: 6tail
abstract class DayUnit extends MonthUnit {
  /// 日
  final int day;

  DayUnit(int year, int month, this.day) : super(year, month);

  /// 日
  int getDay() => day;
}
