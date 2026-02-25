import '../culture/direction.dart';
import '../culture/duty.dart';
import '../culture/element.dart';
import '../culture/fetus/fetus_day.dart';
import '../culture/god.dart';
import '../culture/phase.dart';
import '../culture/phase_day.dart';
import '../culture/ren/minor_ren.dart';
import '../culture/star/nine/nine_star.dart';
import '../culture/star/six/six_star.dart';
import '../culture/star/twelve/twelve_star.dart';
import '../culture/star/twentyeight/twenty_eight_star.dart';
import '../culture/taboo.dart';
import '../culture/week.dart';
import '../festival/lunar_festival.dart';
import '../sixtycycle/earth_branch.dart';
import '../sixtycycle/heaven_stem.dart';
import '../sixtycycle/sixty_cycle.dart';
import '../sixtycycle/sixty_cycle_day.dart';
import '../sixtycycle/three_pillars.dart';
import '../solar/solar_day.dart';
import '../solar/solar_term.dart';
import '../unit/day_unit.dart';
import 'lunar_hour.dart';
import 'lunar_month.dart';

/// 农历日
///
/// Author: 6tail
class LunarDay extends DayUnit {
  static const List<String> names = ["初一", "初二", "初三", "初四", "初五", "初六", "初七", "初八", "初九", "初十", "十一", "十二", "十三", "十四", "十五", "十六", "十七", "十八", "十九", "二十", "廿一", "廿二", "廿三", "廿四", "廿五", "廿六", "廿七", "廿八", "廿九", "三十"];

  /// 使用[year]农历年、[month]农历月(闰月为负)、[day]农历日初始化
  LunarDay(int year, int month, int day): super(year, month, day) {
    validate(year, month, day);
  }

  static validate(int year, int month, int day) {
    if (day < 1) {
      throw ArgumentError('illegal lunar day $day');
    }
    LunarMonth m = LunarMonth(year, month);
    if (day > m.getDayCount()) {
      throw ArgumentError('illegal day $day in $m');
    }
  }

  /// 使用[year]农历年、[month]农历月(闰月为负)、[day]农历日初始化
  LunarDay.fromYmd(int year, int month, int day): this(year, month, day);

  /// 农历月
  LunarMonth getLunarMonth() => LunarMonth(year, month);

  @override
  String getName() => names[day - 1];

  @override
  String toString() => '${getLunarMonth()}${getName()}';

  @override
  LunarDay next(int n) => getSolarDay().next(n).getLunarDay();

  /// 是否在[target]指定农历日之前
  bool isBefore(LunarDay target) {
    if (year != target.year) {
      return year < target.year;
    }
    if (month != target.month) {
      return month.abs() < target.month.abs();
    }
    return day < target.day;
  }

  /// 是否在[target]指定农历日之后
  bool isAfter(LunarDay target) {
    if (year != target.year) {
      return year > target.year;
    }
    if (month != target.month) {
      return month.abs() >= target.month.abs();
    }
    return day > target.day;
  }

  /// 星期
  Week getWeek() => getSolarDay().getWeek();

  /// 干支
  SixtyCycle getSixtyCycle() {
    int offset = getLunarMonth().getFirstJulianDay().next(day - 12).day.toInt();
    return SixtyCycle.fromName('${HeavenStem(offset).getName()}${EarthBranch(offset).getName()}');
  }

  /// 建除十二值神
  Duty getDuty() => getSixtyCycleDay().getDuty();

  /// 黄道黑道十二神
  TwelveStar getTwelveStar() => getSixtyCycleDay().getTwelveStar();

  /// 九星
  NineStar getNineStar() {
    SolarDay d = getSolarDay();
    SolarTerm dongZhi = SolarTerm(d.getYear(), 0);
    SolarDay dongZhiSolar = dongZhi.getSolarDay();
    SolarDay xiaZhiSolar = dongZhi.next(12).getSolarDay();
    SolarDay dongZhiSolar2 = dongZhi.next(24).getSolarDay();
    int dongZhiIndex = dongZhiSolar.getLunarDay().getSixtyCycle().index;
    int xiaZhiIndex = xiaZhiSolar.getLunarDay().getSixtyCycle().index;
    int dongZhiIndex2 = dongZhiSolar2.getLunarDay().getSixtyCycle().index;
    SolarDay solarShunBai = dongZhiSolar.next(dongZhiIndex > 29 ? 60 - dongZhiIndex : -dongZhiIndex);
    SolarDay solarShunBai2 = dongZhiSolar2.next(dongZhiIndex2 > 29 ? 60 - dongZhiIndex2 : -dongZhiIndex2);
    SolarDay solarNiZi = xiaZhiSolar.next(xiaZhiIndex > 29 ? 60 - xiaZhiIndex : -xiaZhiIndex);
    int offset = 0;
    if (!d.isBefore(solarShunBai) && d.isBefore(solarNiZi)) {
      offset = d.subtract(solarShunBai);
    } else if (!d.isBefore(solarNiZi) && d.isBefore(solarShunBai2)) {
      offset = 8 - d.subtract(solarNiZi);
    } else if (!d.isBefore(solarShunBai2)) {
      offset = d.subtract(solarShunBai2);
    } else if (d.isBefore(solarShunBai)) {
      offset = 8 + solarShunBai.subtract(d);
    }
    return NineStar(offset);
  }

  /// 太岁方位
  Direction getJupiterDirection() {
    int index = getSixtyCycle().getIndex();
    return index % 12 < 6 ? Element(index ~/ 12).getDirection() : getLunarMonth().getLunarYear().getJupiterDirection();
  }

  /// 逐日胎神
  FetusDay getFetusDay() => FetusDay.fromLunarDay(this);

  /// 月相第几天
  PhaseDay getPhaseDay() {
    SolarDay today = getSolarDay();
    LunarMonth m = getLunarMonth().next(1);
    Phase p = Phase(m.getYear(), m.getMonthWithLeap(), 0);
    SolarDay d = p.getSolarDay();
    while (d.isAfter(today)) {
      p = p.next(-1);
      d = p.getSolarDay();
    }
    return PhaseDay(p, today.subtract(d));
  }

  /// 月相
  Phase getPhase() => getPhaseDay().getPhase();

  /// 六曜
  SixStar getSixStar() => SixStar((month.abs() + day - 2) % 6);

  /// 公历日
  SolarDay getSolarDay() => getLunarMonth().getFirstJulianDay().next(day - 1).getSolarDay();

  /// 干支日
  SixtyCycleDay getSixtyCycleDay() => getSolarDay().getSixtyCycleDay();

  /// 二十八宿
  TwentyEightStar getTwentyEightStar() => TwentyEightStar([10, 18, 26, 6, 14, 22, 2][getSolarDay().getWeek().getIndex()]).next(-7 * getSixtyCycle().getEarthBranch().index);

  /// 农历传统节日
  LunarFestival? getFestival() => LunarFestival.fromYmd(year, month, day);

  /// 当天的农历时辰列表
  List<LunarHour> getHours() {
    List<LunarHour> l = [];
    l.add(LunarHour.fromYmdHms(year, month, day, 0, 0, 0));
    for (int i = 0; i < 24; i += 2) {
      l.add(LunarHour.fromYmdHms(year, month, day, i + 1, 0, 0));
    }
    return l;
  }

  /// 神煞（吉神宜趋、凶神宜忌）
  List<God> getGods() => getSixtyCycleDay().getGods();

  /// 宜
  List<Taboo> getRecommends() => getSixtyCycleDay().getRecommends();

  /// 忌
  List<Taboo> getAvoids() => getSixtyCycleDay().getAvoids();

  /// 小六壬
  MinorRen getMinorRen() => getLunarMonth().getMinorRen().next(day - 1);

  /// 三柱
  ThreePillars getThreePillars() => getSixtyCycleDay().getThreePillars();
}
