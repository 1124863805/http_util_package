import '../abstract_tyme.dart';

/// 年
///
/// Author: 6tail
abstract class YearUnit extends AbstractTyme {
  /// 年
  final int year;

  YearUnit(this.year);

  /// 年
  int getYear() => year;
}
