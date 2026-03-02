import 'day_unit.dart';

/// 秒
///
/// Author: 6tail
abstract class SecondUnit extends DayUnit {
  /// 时
  final int hour;

  /// 分
  final int minute;

  /// 秒
  final int second;

  SecondUnit(int year, int month, int day, this.hour, this.minute, this.second) : super(year, month, day);

  /// 时
  int getHour() => hour;

  /// 分
  int getMinute() => minute;

  /// 秒
  int getSecond() => second;

  static validate(int hour, int minute, int second) {
    if (hour < 0 || hour > 23) {
      throw ArgumentError('illegal hour: $hour');
    }
    if (minute < 0 || minute > 59) {
      throw ArgumentError('illegal minute: $minute');
    }
    if (second < 0 || second > 59) {
      throw ArgumentError('illegal second: $second');
    }
  }
}
