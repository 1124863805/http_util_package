import '../culture/phase.dart';
import '../culture/phenology/phenology.dart';
import '../jd/julian_day.dart';
import '../lunar/lunar_day.dart';
import '../lunar/lunar_hour.dart';
import '../lunar/lunar_month.dart';
import '../sixtycycle/sixty_cycle_hour.dart';
import '../unit/second_unit.dart';
import 'solar_day.dart';
import 'solar_term.dart';

/// 公历时刻
///
/// Author: 6tail
class SolarTime extends SecondUnit {

  SolarTime(int year, int month, int day, int hour, int minute, int second): super(year, month, day, hour, minute, second) {
    validate(year, month, day, hour, minute, second);
  }

  static validate(int year, int month, int day, int hour, int minute, int second) {
    SecondUnit.validate(hour, minute, second);
    SolarDay.validate(year, month, day);
  }

  SolarTime.fromYmdHms(int year, int month, int day, int hour, int minute, int second) : this(year, month, day, hour, minute, second);

  /// 公历日
  SolarDay getSolarDay() => SolarDay(year, month, day);

  @override
  String getName() => '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}:${second.toString().padLeft(2, '0')}';

  @override
  String toString() => '${getSolarDay()} ${getName()}';

  /// 是否在[target]指定公历时刻之前
  bool isBefore(SolarTime target) {
    SolarDay aDay = getSolarDay();
    SolarDay bDay = target.getSolarDay();
    if (aDay != bDay) {
      return aDay.isBefore(bDay);
    }
    if (hour != target.getHour()) {
      return hour < target.getHour();
    }
    return minute != target.getMinute() ? minute < target.getMinute() : second < target.getSecond();
  }

  /// 是否在[target]指定公历时刻之后
  bool isAfter(SolarTime target) {
    SolarDay aDay = getSolarDay();
    SolarDay bDay = target.getSolarDay();
    if (aDay != bDay) {
      return aDay.isAfter(bDay);
    }
    if (hour != target.getHour()) {
      return hour > target.getHour();
    }
    return minute != target.getMinute() ? minute > target.getMinute() : second > target.getSecond();
  }

  /// 儒略日
  JulianDay getJulianDay() => JulianDay.fromYmdHms(year, month, day, hour, minute, second);

  /// 与[target]公历时刻相减，获得相差秒数
  int subtract(SolarTime target) {
    int days = getSolarDay().subtract(target.getSolarDay());
    int cs = hour * 3600 + minute * 60 + second;
    int ts = target.hour * 3600 + target.minute * 60 + target.second;
    int seconds = cs - ts;
    if (seconds < 0) {
      seconds += 86400;
      days--;
    }
    seconds += days * 86400;
    return seconds;
  }

  /// 推移[n]秒
  @override
  SolarTime next(int n) {
    if (n == 0) {
      return SolarTime.fromYmdHms(year, month, day, hour, minute, second);
    }
    int ts = second + n;
    int tm = minute + (ts / 60).floor();
    ts = ts % 60;
    if (ts < 0) {
      ts += 60;
      tm -= 1;
    }
    int th = hour + (tm / 60).floor();
    tm = tm % 60;
    if (tm < 0) {
      tm += 60;
      th -= 1;
    }
    int td = (th / 24).floor();
    th = th % 24;
    if (th < 0) {
      th += 24;
      td -= 1;
    }

    SolarDay d = getSolarDay().next(td);
    return SolarTime.fromYmdHms(d.getYear(), d.getMonth(), d.getDay(), th, tm, ts);
  }

  /// 农历时辰
  LunarHour getLunarHour() {
    LunarDay d = getSolarDay().getLunarDay();
    return LunarHour.fromYmdHms(d.getYear(), d.getMonth(), d.getDay(), hour, minute, second);
  }

  /// 候
  Phenology getPhenology() {
    Phenology p = getSolarDay().getPhenology();
    if (isBefore(p.getJulianDay().getSolarTime())) {
      p = p.next(-1);
    }
    return p;
  }

  /// 干支时辰
  SixtyCycleHour getSixtyCycleHour() => SixtyCycleHour.fromSolarTime(this);

  /// 节气
  SolarTerm getTerm() {
    SolarTerm term = getSolarDay().getTerm();
    if (isBefore(term.getJulianDay().getSolarTime())) {
      term = term.next(-1);
    }
    return term;
  }

  /// 月相
  Phase getPhase() {
    LunarMonth lunarMonth = getLunarHour().getLunarDay().getLunarMonth().next(1);
    Phase p = Phase.fromIndex(lunarMonth.getYear(), lunarMonth.getMonthWithLeap(), 0);
    while (p.getSolarTime().isAfter(this)) {
      p = p.next(-1);
    }
    return p;
  }
}
