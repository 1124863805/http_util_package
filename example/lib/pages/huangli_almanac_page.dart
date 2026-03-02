import 'package:flutter/material.dart';

import '../tyme4/tyme.dart';

/// 传统黄历页面：纸质黄历风格，宜忌冲煞神方位
class HuangliAlmanacPage extends StatefulWidget {
  const HuangliAlmanacPage({super.key});

  @override
  State<HuangliAlmanacPage> createState() => _HuangliAlmanacPageState();
}

class _HuangliAlmanacPageState extends State<HuangliAlmanacPage> {
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
  }

  SixtyCycleDay get _scDay => SixtyCycleDay.fromSolarDay(
    SolarDay.fromYmd(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    ),
  );

  static const _paperBg = Color(0xFFF0E6D8);
  static const _accent = Color(0xFF8B4513);

  @override
  Widget build(BuildContext context) {
    final scDay = _scDay;
    final solarDay = scDay.getSolarDay();
    final lunarDay = solarDay.getLunarDay();
    final lunarYear = LunarYear.fromYear(lunarDay.getYear());
    final lunarMonth = lunarDay.getLunarMonth();
    final isToday = _selectedDate.year == DateTime.now().year &&
        _selectedDate.month == DateTime.now().month &&
        _selectedDate.day == DateTime.now().day;

    return Scaffold(
      backgroundColor: _paperBg,
      appBar: AppBar(
        title: const Text('老黄历'),
        backgroundColor: _accent,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton.icon(
            onPressed: () {
              if (!isToday) setState(() => _selectedDate = DateTime.now());
            },
            icon: Icon(Icons.today, size: 16, color: isToday ? Colors.white70 : Colors.white),
            label: const Text('今', style: TextStyle(color: Colors.white, fontSize: 13)),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: _AlmanacCard(
            solarDay: solarDay,
            lunarYear: lunarYear,
            lunarMonth: lunarMonth,
            lunarDay: lunarDay,
            isToday: isToday,
            scDay: scDay,
            onPrev: () => setState(() => _selectedDate = _selectedDate.subtract(const Duration(days: 1))),
            onNext: () => setState(() => _selectedDate = _selectedDate.add(const Duration(days: 1))),
          ),
        ),
      ),
    );
  }
}

class _AlmanacCard extends StatelessWidget {
  final SolarDay solarDay;
  final LunarYear lunarYear;
  final LunarMonth lunarMonth;
  final LunarDay lunarDay;
  final bool isToday;
  final SixtyCycleDay scDay;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  const _AlmanacCard({
    required this.solarDay,
    required this.lunarYear,
    required this.lunarMonth,
    required this.lunarDay,
    required this.isToday,
    required this.scDay,
    required this.onPrev,
    required this.onNext,
  });

  static const _ink = Color(0xFF2C1810);
  static const _accent = Color(0xFF8B4513);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildDateHeader(),
          _buildDivider(),
          Padding(
            padding: const EdgeInsets.all(20),
            child: _HuangliContent(scDay: scDay, solarDay: solarDay),
          ),
        ],
      ),
    );
  }

  Widget _buildDateHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 12),
      child: Row(
        children: [
          _NavButton(icon: Icons.chevron_left, onTap: onPrev),
          Expanded(
            child: Column(
              children: [
                Text(
                  '${solarDay.getYear()}年${solarDay.getMonth()}月${solarDay.getDay()}日',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: _ink),
                ),
                const SizedBox(height: 4),
                Text(
                  '${lunarYear.getSixtyCycle().getName()}年 ${lunarMonth.getName()}${lunarDay.getName()}',
                  style: TextStyle(fontSize: 13, color: _ink.withValues(alpha: 0.75)),
                ),
                if (isToday)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _accent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text('今日', style: TextStyle(fontSize: 11, color: _accent, fontWeight: FontWeight.w500)),
                    ),
                  ),
              ],
            ),
          ),
          _NavButton(icon: Icons.chevron_right, onTap: onNext),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(height: 1, thickness: 1, color: _accent.withValues(alpha: 0.15));
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _NavButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, color: const Color(0xFF2C1810), size: 28),
        ),
      ),
    );
  }
}

class _HuangliContent extends StatelessWidget {
  final SixtyCycleDay scDay;
  final SolarDay solarDay;

  const _HuangliContent({required this.scDay, required this.solarDay});

  static const _inkRed = Color(0xFFB22222);
  static const _inkBlack = Color(0xFF2C1810);
  static const _inkGray = Color(0xFF5D4E37);
  static const _accent = Color(0xFF8B4513);

  @override
  Widget build(BuildContext context) {
    final hours = scDay.getHours();
    final rec = scDay.getRecommends().map((t) => t.getName()).toList();
    final av = scDay.getAvoids().map((t) => t.getName()).toList();
    final recList = rec.isNotEmpty ? rec : [Taboo.fromName('馀事勿取').getName()];
    final gods = scDay.getGods();
    final auspicious = gods.where((g) => g.getLuck().getIndex() == 0).toList();
    final inauspicious = gods.where((g) => g.getLuck().getIndex() == 1).toList();
    final huangdiYear = solarDay.getYear() + 2698;
    final heavenStem = scDay.getSixtyCycle().getHeavenStem();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionBlock(
          title: '纪年',
          showTopDivider: false,
          child: Center(
            child: Text(
              '黄帝纪年$huangdiYear年',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _inkBlack),
            ),
          ),
        ),
        _SectionBlock(
          title: '基础',
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _kvChip('五行', scDay.getSixtyCycle().getSound().getName()),
              _kvChip('黑道', '${scDay.getTwelveStar().getName()}${scDay.getTwelveStar().getEcliptic().getName()}'),
              _kvChip('节气', solarDay.getTermDay().getSolarTerm().getName()),
              _kvChip('七十二候', solarDay.getPhenology().getName()),
            ],
          ),
        ),
        _SectionBlock(
          title: '吉时',
          child: Wrap(
            spacing: 10,
            runSpacing: 8,
            children: hours.map((h) {
              final luck = h.getTwelveStar().getEcliptic().getLuck();
              return _hourChip(
                h.getSixtyCycle().getName(),
                luck.getName(),
                luck.getIndex() == 0,
              );
            }).toList(),
          ),
        ),
        _SectionBlock(
          title: '吉方',
          child: Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              _directionChip('财神', heavenStem.getWealthDirection().getName(), isGood: true),
              _directionChip('福神', heavenStem.getMascotDirection().getName(), isGood: true),
              _directionChip('喜神', heavenStem.getJoyDirection().getName(), isGood: true),
              _directionChip('阳贵', heavenStem.getYangDirection().getName(), isGood: false),
            ],
          ),
        ),
        _SectionBlock(
          title: '神煞',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _kvRow('建除', scDay.getDuty().getName()),
              _kvRow('吉神', auspicious.isNotEmpty ? auspicious.map((g) => g.getName()).join(' ') : '-', color: _inkRed),
              _kvRow('胎神', scDay.getFetusDay().getName()),
              _kvRow('凶神', inauspicious.isNotEmpty ? inauspicious.map((g) => g.getName()).join(' ') : '-'),
              _kvRow('星宿', '${scDay.getTwentyEightStar().getName()}${scDay.getTwentyEightStar().getSevenStar().getName()}${scDay.getTwentyEightStar().getAnimal().getName()}'),
            ],
          ),
        ),
        _YiJiBlock(title: '宜', items: recList, color: _inkRed),
        _YiJiBlock(title: '忌', items: av, color: _inkBlack),
        _SectionBlock(
          title: '彭祖百忌',
          child: Text(
            PengZu.fromSixtyCycle(scDay.getSixtyCycle()).getName(),
            style: TextStyle(fontSize: 13, color: _inkGray, height: 1.5),
          ),
        ),
      ],
    );
  }

  Widget _kvChip(String k, String v) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: _accent.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: _accent.withValues(alpha: 0.25)),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(k, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _accent)),
        const SizedBox(height: 2),
        Text(v, style: TextStyle(fontSize: 12, color: _inkBlack)),
      ],
    ),
  );

  Widget _hourChip(String ganZhi, String luck, bool isGood) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: isGood ? _inkRed.withValues(alpha: 0.12) : _inkGray.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(ganZhi, style: TextStyle(fontSize: 10, color: _inkGray)),
        Text(
          luck,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isGood ? _inkRed : _inkBlack,
          ),
        ),
      ],
    ),
  );

  Widget _directionChip(String label, String value, {required bool isGood}) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: isGood ? _inkRed.withValues(alpha: 0.08) : _inkGray.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      '$label$value',
      style: TextStyle(fontSize: 12, color: isGood ? _inkRed : _inkGray, fontWeight: FontWeight.w500),
    ),
  );

  Widget _kvRow(String label, String value, {Color? color}) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 40,
          child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _inkGray)),
        ),
        Expanded(
          child: Text(value, style: TextStyle(fontSize: 12, color: color ?? _inkBlack, height: 1.4)),
        ),
      ],
    ),
  );
}

class _SectionBlock extends StatelessWidget {
  final String title;
  final Widget child;
  final bool showTopDivider;

  const _SectionBlock({required this.title, required this.child, this.showTopDivider = true});

  static final _divider = Divider(height: 24, thickness: 1, color: const Color(0xFF8B4513).withValues(alpha: 0.12));

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showTopDivider) _divider,
        _SectionTitle(title),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF8B4513).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF8B4513),
        ),
      ),
    );
  }
}

class _YiJiBlock extends StatelessWidget {
  final String title;
  final List<String> items;
  final Color color;

  const _YiJiBlock({required this.title, required this.items, required this.color});

  static final _divider = Divider(height: 24, thickness: 1, color: const Color(0xFF8B4513).withValues(alpha: 0.12));

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _divider,
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.15)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: color),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 6,
                children: items.map((s) => Text(s, style: TextStyle(fontSize: 13, color: color))).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
