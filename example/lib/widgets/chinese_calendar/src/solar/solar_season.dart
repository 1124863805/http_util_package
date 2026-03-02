import '../unit/year_unit.dart';
import 'solar_month.dart';
import 'solar_year.dart';

/// 公历季度
///
/// Author: 6tail
class SolarSeason extends YearUnit {
  static const List<String> names = ['一季度', '二季度', '三季度', '四季度'];

  /// 索引，0-3
  final int index;

  SolarSeason(int year, this.index) : super(year) {
    validate(year, index);
  }

  static validate(int year, int index) {
    if (index < 0 || index > 3) {
      throw ArgumentError('illegal solar season index: $index');
    }
    SolarYear.validate(year);
  }

  SolarSeason.fromIndex(int year, int index) : this(year, index);

  /// 公历年
  SolarYear getSolarYear() => SolarYear(year);

  /// 索引，0-3
  int getIndex() => index;

  @override
  String getName() => names[index];

  @override
  String toString() => '${getSolarYear()}${getName()}';

  @override
  SolarSeason next(int n) {
    int i = index + n;
    return SolarSeason((getYear() * 4 + i) ~/ 4, indexOfSize(i, 4));
  }

  /// 月份列表，1季度有3个月。
  List<SolarMonth> getMonths() {
    List<SolarMonth> l = [];
    for (int i = 1; i < 4; i++) {
      l.add(SolarMonth.fromYm(year, index * 3 + i));
    }
    return l;
  }
}
