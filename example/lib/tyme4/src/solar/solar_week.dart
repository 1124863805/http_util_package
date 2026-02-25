import '../unit/week_unit.dart';
import 'solar_day.dart';
import 'solar_month.dart';

/// 公历周
///
/// Author: 6tail
class SolarWeek extends WeekUnit {
  static const List<String> names = ['第一周', '第二周', '第三周', '第四周', '第五周', '第六周'];

  SolarWeek(int year, int month, int index, int start): super(year, month, index, start) {
    validate(year, month, index, start);
  }

  static validate(int year, int month, int index, int start) {
    WeekUnit.validate(index, start);
    SolarMonth m = SolarMonth(year, month);
    if (index >= m.getWeekCount(start)) {
      throw ArgumentError('illegal solar week index: $index in month: $m');
    }
  }

  SolarWeek.fromYm(int year, int month, int index, int start) : this(year, month, index, start);

  /// 公历月
  SolarMonth getSolarMonth() => SolarMonth(year, month);

  /// 位于当年的索引
  int getIndexInYear() {
    int i = 0;
    SolarDay firstDay = getFirstDay();
    // 今年第1周
    SolarWeek w = SolarWeek.fromYm(year, 1, 0, start);
    while (w.getFirstDay() != firstDay) {
      w = w.next(1);
      i++;
    }
    return i;
  }

  @override
  String getName() => names[index];

  @override
  String toString() => '${getSolarMonth()}${getName()}';

  @override
  SolarWeek next(int n) {
    int d = index;
    SolarMonth m = getSolarMonth();
    if (n > 0) {
      d += n;
      int weekCount = m.getWeekCount(start);
      while (d >= weekCount) {
        d -= weekCount;
        m = m.next(1);
        if (m.getFirstDay().getWeek().getIndex() != start) {
          d += 1;
        }
        weekCount = m.getWeekCount(start);
      }
    } else if (n < 0) {
      d += n;
      while (d < 0) {
        if (m.getFirstDay().getWeek().getIndex() != start) {
          d -= 1;
        }
        m = m.next(-1);
        d += m.getWeekCount(start);
      }
    }
    return SolarWeek(m.getYear(), m.getMonth(), d, start);
  }

  /// 第1天的公历日
  SolarDay getFirstDay() {
    SolarDay firstDay = SolarDay(year, month, 1);
    return firstDay.next(index * 7 - indexOfSize(firstDay.getWeek().getIndex() - start, 7));
  }

  /// 公历日列表
  List<SolarDay> getDays() {
    List<SolarDay> l = [];
    SolarDay d = getFirstDay();
    l.add(d);
    for (int i = 1; i < 7; i++) {
      l.add(d.next(i));
    }
    return l;
  }

  @override
  bool operator ==(Object other) => other is SolarWeek && getFirstDay() == other.getFirstDay();

  @override
  int get hashCode => getFirstDay().hashCode;
}
