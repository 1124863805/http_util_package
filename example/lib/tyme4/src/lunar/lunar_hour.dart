import '../culture/ren/minor_ren.dart';
import '../culture/star/nine/nine_star.dart';
import '../culture/star/twelve/twelve_star.dart';
import '../culture/taboo.dart';
import '../eightchar/eight_char.dart';
import '../eightchar/provider/eight_char_provider.dart';
import '../eightchar/provider/impl/default_eight_char_provider.dart';
import '../sixtycycle/earth_branch.dart';
import '../sixtycycle/heaven_stem.dart';
import '../sixtycycle/sixty_cycle.dart';
import '../sixtycycle/sixty_cycle_hour.dart';
import '../solar/solar_day.dart';
import '../solar/solar_term.dart';
import '../solar/solar_time.dart';
import '../unit/second_unit.dart';
import 'lunar_day.dart';

/// 农历时辰
///
/// Author: 6tail
class LunarHour extends SecondUnit {
  /// 八字计算接口
  static EightCharProvider provider = DefaultEightCharProvider();

  LunarHour(int year, int month, int day, int hour, int minute, int second): super(year, month, day, hour, minute, second) {
    validate(year, month, day, hour, minute, second);
  }

  static validate(int year, int month, int day, int hour, int minute, int second) {
    SecondUnit.validate(hour, minute, second);
    LunarDay.validate(year, month, day);
  }

  LunarHour.fromYmdHms(int year, int month, int day, int hour, int minute, int second) : this(year, month, day, hour, minute, second);

  /// 农历日
  LunarDay getLunarDay() => LunarDay(year, month, day);

  @override
  String getName() => '${EarthBranch(getIndexInDay()).getName()}时';

  @override
  String toString() => '${getLunarDay()}${getSixtyCycle().getName()}时';

  /// 位于当天的索引
  int getIndexInDay() => (hour + 1) ~/ 2;

  @override
  LunarHour next(int n) {
    if (n == 0) {
      return LunarHour(year, month, day, hour, minute, second);
    }
    int h = hour + n * 2;
    int diff = h < 0 ? -1 : 1;
    int hours = h.abs();
    int days = hours ~/ 24 * diff;
    hours = (hours % 24) * diff;
    if (hours < 0) {
      hours += 24;
      days--;
    }
    LunarDay d = getLunarDay().next(days);
    return LunarHour(d.getYear(), d.getMonth(), d.getDay(), hours, minute, second);
  }

  /// 是否在[target]指定农历时辰之前
  bool isBefore(LunarHour target) {
    LunarDay aDay = getLunarDay();
    LunarDay bDay = target.getLunarDay();
    if (aDay != bDay) {
      return aDay.isBefore(bDay);
    }
    if (hour != target.hour) {
      return hour < target.hour;
    }
    return minute != target.minute ? minute < target.minute : second < target.second;
  }

  /// 是否在[target]指定农历时辰之后
  bool isAfter(LunarHour target) {
    LunarDay aDay = getLunarDay();
    LunarDay bDay = target.getLunarDay();
    if (aDay != bDay) {
      return aDay.isAfter(bDay);
    }
    if (hour != target.hour) {
      return hour > target.hour;
    }
    return minute != target.minute ? minute > target.minute : second > target.second;
  }

  /// 干支
  SixtyCycle getSixtyCycle() {
    int earthBranchIndex = getIndexInDay() % 12;
    SixtyCycle d = getLunarDay().getSixtyCycle();
    if (hour >= 23) {
      d = d.next(1);
    }
    return SixtyCycle.fromName('${HeavenStem(d.getHeavenStem().index % 5 * 2 + earthBranchIndex).getName()}${EarthBranch(earthBranchIndex).getName()}');
  }

  /// 黄道黑道十二神
  TwelveStar getTwelveStar() => TwelveStar(getSixtyCycle().getEarthBranch().index + (8 - getSixtyCycleHour().getDay().getEarthBranch().index % 6) * 2);

  /// 九星（时家紫白星歌诀：三元时白最为佳，冬至阳生顺莫差，孟日七宫仲一白，季日四绿发萌芽，每把时辰起甲子，本时星耀照光华，时星移入中宫去，顺飞八方逐细查。夏至阴生逆回首，孟归三碧季加六，仲在九宫时起甲，依然掌中逆轮跨。）
  NineStar getNineStar() {
    LunarDay d = getLunarDay();
    SolarDay solar = d.getSolarDay();
    SolarTerm dongZhi = SolarTerm(solar.getYear(), 0);
    int earthBranchIndex = getIndexInDay() % 12;
    int index = [8, 5, 2][d.getSixtyCycle().getEarthBranch().index % 3];
    if (!solar.isBefore(dongZhi.getJulianDay().getSolarDay()) && solar.isBefore(dongZhi.next(12).getJulianDay().getSolarDay())) {
      index = 8 + earthBranchIndex - index;
    } else {
      index -= earthBranchIndex;
    }
    return NineStar.fromIndex(index);
  }

  /// 公历时刻
  SolarTime getSolarTime() {
      SolarDay d = getLunarDay().getSolarDay();
      return SolarTime.fromYmdHms(d.getYear(), d.getMonth(), d.getDay(), hour, minute, second);
  }

  /// 八字
  EightChar getEightChar() => provider.getEightChar(this);

  /// 干支时辰
  SixtyCycleHour getSixtyCycleHour() => getSolarTime().getSixtyCycleHour();

  /// 宜
  List<Taboo> getRecommends() => Taboo.getHourRecommends(getSixtyCycleHour().getDay(), getSixtyCycle());

  /// 忌
  List<Taboo> getAvoids() => Taboo.getHourAvoids(getSixtyCycleHour().getDay(), getSixtyCycle());

  /// 小六壬
  MinorRen getMinorRen() => getLunarDay().getMinorRen().next(getIndexInDay());
}
