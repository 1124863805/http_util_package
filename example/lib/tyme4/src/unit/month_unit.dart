import 'year_unit.dart';

/// 月
///
/// Author: 6tail
abstract class MonthUnit extends YearUnit {
  /// 月
  final int month;

  MonthUnit(int year, this.month) : super(year);

  /// 月
  int getMonth() => month;
}
