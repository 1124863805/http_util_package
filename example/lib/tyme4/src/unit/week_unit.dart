import 'month_unit.dart';

/// 周
///
/// Author: 6tail
abstract class WeekUnit extends MonthUnit {
  /// 索引，0-5
  final int index;

  /// 起始星期，1234560分别代表星期一至星期天
  final int start;

  WeekUnit(int year, int month, this.index, this.start) : super(year, month);

  /// 索引，0-5
  int getIndex() => index;

  /// 起始星期，1234560分别代表星期一至星期天
  int getStart() => start;

  static validate(int index, int start) {
    if (index < 0 || index > 5) {
      throw ArgumentError('illegal week index: $index');
    }
    if (start < 0 || start > 6) {
      throw ArgumentError('illegal week start: $start');
    }
  }
}
