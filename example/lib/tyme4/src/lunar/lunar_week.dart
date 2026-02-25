import '../unit/week_unit.dart';
import 'lunar_day.dart';
import 'lunar_month.dart';

/// 农历周
///
/// Author: 6tail
class LunarWeek extends WeekUnit {
  static const List<String> names = ["第一周", "第二周", "第三周", "第四周", "第五周", "第六周"];

  LunarWeek(int year, int month, int index, int start): super(year, month, index, start) {
    validate(year, month, index, start);
  }

  static validate(int year, int month, int index, int start) {
    WeekUnit.validate(index, start);
    LunarMonth m = LunarMonth(year, month);
    if (index >= m.getWeekCount(start)) {
      throw ArgumentError('illegal lunar week index: $index in month: $m');
    }
  }

  LunarWeek.fromYm(int year, int month, int index, int start) : this(year, month, index, start);

  /// 农历月
  LunarMonth getLunarMonth() => LunarMonth(year, month);

  @override
  String getName() => names[index];

  @override
  String toString() => '${getLunarMonth()}${getName()}';

  @override
  LunarWeek next(int n) {
    if (n == 0) {
      return LunarWeek(year, month, index, start);
    }
    int d = index + n;
    LunarMonth m = getLunarMonth();
    if (n > 0) {
      int weekCount = m.getWeekCount(start);
      while (d >= weekCount) {
        d -= weekCount;
        m = m.next(1);
        if (m.getFirstDay().getWeek().getIndex() != start) {
          d += 1;
        }
        weekCount = m.getWeekCount(start);
      }
    } else {
      while (d < 0) {
        if (m.getFirstDay().getWeek().getIndex() != start) {
          d -= 1;
        }
        m = m.next(-1);
        d += m.getWeekCount(start);
      }
    }
    return LunarWeek(m.getYear(), m.getMonthWithLeap(), d, start);
  }

  /// 本周第1天的农历日
  LunarDay getFirstDay() {
    LunarDay firstDay = LunarDay(year, month, 1);
    return firstDay.next(index * 7 - indexOfSize(firstDay.getWeek().getIndex() - start, 7));
  }

  /// 本周农历日列表
  List<LunarDay> getDays() {
    List<LunarDay> l = [];
    LunarDay d = getFirstDay();
    l.add(d);
    for (int i = 1; i < 7; i++) {
      l.add(d.next(i));
    }
    return l;
  }

  @override
  bool operator ==(Object other) {
    return other is LunarWeek && getFirstDay() == other.getFirstDay();
  }

  @override
  int get hashCode => getFirstDay().hashCode;
}
