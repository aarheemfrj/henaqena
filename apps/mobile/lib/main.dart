import 'package:flutter/material.dart';

const teal = Color(0xFF0D8F8A);
const deepTeal = Color(0xFF085E5A);
const gold = Color(0xFFE9B44C);
const paper = Color(0xFFF7F6F2);
const ink = Color(0xFF1F2933);
const muted = Color(0xFF66737A);

class AppMotion {
  static const quick = Duration(milliseconds: 180);
  static const standard = Duration(milliseconds: 240);
  static const gentle = Duration(milliseconds: 320);
}

void main() => runApp(const HenaQenaApp());

class HenaQenaApp extends StatelessWidget {
  const HenaQenaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'هنا قنا',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: paper,
        colorScheme: ColorScheme.fromSeed(seedColor: teal, brightness: Brightness.light).copyWith(
          primary: teal,
          onPrimary: Colors.white,
          secondary: gold,
          surface: Colors.white,
          onSurface: ink,
        ),
        fontFamily: 'Tajawal',
        textTheme: const TextTheme(
          headlineMedium: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700, color: deepTeal),
          headlineSmall: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700, color: deepTeal),
          titleLarge: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700, color: deepTeal),
          titleMedium: TextStyle(fontWeight: FontWeight.w500, color: ink),
          bodyLarge: TextStyle(fontWeight: FontWeight.w400, color: ink),
          bodyMedium: TextStyle(fontWeight: FontWeight.w400, color: ink),
          labelLarge: TextStyle(fontWeight: FontWeight.w500),
        ),
        navigationBarTheme: NavigationBarThemeData(
          labelTextStyle: WidgetStatePropertyAll(TextStyle(fontFamily: 'Tajawal', fontSize: 11, fontWeight: FontWeight.w500, color: muted)),
          height: 72,
        ),
        appBarTheme: const AppBarTheme(backgroundColor: paper, foregroundColor: deepTeal, elevation: 0),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          hintStyle: const TextStyle(color: muted),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE0E8E6))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: teal, width: 1.5)),
        ),
      ),
      home: const WelcomeScreen(),
    );
  }
}

class LogoMark extends StatelessWidget {
  const LogoMark({super.key, this.dark = false, this.size = 52});
  final bool dark;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: dark ? Colors.white.withValues(alpha: .12) : Colors.white, borderRadius: BorderRadius.circular(size * .28)),
      child: Stack(alignment: Alignment.center, children: [
        Icon(Icons.location_on_outlined, size: size * .72, color: dark ? Colors.white : deepTeal),
        Container(width: size * .18, height: size * .18, decoration: const BoxDecoration(color: gold, shape: BoxShape.circle)),
      ]),
    );
  }
}

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  void _begin(BuildContext context) => Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const SetupFlow()));

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              const Spacer(),
              Center(child: Column(children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: .86, end: 1),
                  duration: AppMotion.gentle,
                  curve: Curves.easeOutBack,
                  builder: (_, value, child) => Transform.scale(scale: value, child: child),
                  child: const LogoMark(size: 82),
                ),
                const SizedBox(height: 18),
                Text('هنا قنا', style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: deepTeal, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                const Text('أهلًا بيك.. قنا كلها هنا', style: TextStyle(color: muted, fontSize: 16)),
              ])),
              const Spacer(),
              FilledButton(onPressed: () => _begin(context), style: FilledButton.styleFrom(backgroundColor: teal, minimumSize: const Size.fromHeight(52), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))), child: const Text('ابدأ الآن', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700))),
              const SizedBox(height: 10),
              OutlinedButton(onPressed: () => _begin(context), style: OutlinedButton.styleFrom(foregroundColor: deepTeal, minimumSize: const Size.fromHeight(52), side: const BorderSide(color: teal), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))), child: const Text('تسجيل الدخول', style: TextStyle(fontSize: 15))),
              TextButton(onPressed: () => Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const HomeShell())), child: const Text('التكملة كزائر', style: TextStyle(color: deepTeal))),
              const SizedBox(height: 10),
              const Text('كل ما تحتاجه.. قريب منك', textAlign: TextAlign.center, style: TextStyle(color: muted, fontSize: 12)),
            ]),
          ),
        ),
      ),
    );
  }
}

class SetupFlow extends StatefulWidget {
  const SetupFlow({super.key});
  @override
  State<SetupFlow> createState() => _SetupFlowState();
}

class _SetupFlowState extends State<SetupFlow> {
  int step = 0;
  final areas = <String>{};
  final interests = <String>{};
  String age = '';
  String gender = '';
  final areaOptions = ['قنا كلها', 'وسط البلد', 'مدينة العمال', 'الشؤون', 'المساكن', 'نجع سعيد', 'المعنى', 'الحميدات', 'الأحوال', 'عمر فندي', 'المنشية'];
  final interestOptions = ['خدمات طبية', 'مطاعم وكافيهات', 'صيانة وفنيين', 'سوبر ماركت', 'تعليم ودروس', 'ترفيه ومناسبات', 'عقارات', 'سيارات'];

  void next() {
    if (step < 3) {
      setState(() => step++);
    } else {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const HomeShell()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final titles = ['اختار منطقتك', 'خلّينا نعرفك أكتر', 'إيه اللي يهمك؟', 'جاهز تبدأ؟'];
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: Text('${step + 1} من 4', style: const TextStyle(fontSize: 14)), actions: [TextButton(onPressed: () => Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const HomeShell())), child: const Text('تخطي'))]),
        body: Padding(padding: const EdgeInsets.fromLTRB(20, 12, 20, 20), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          LinearProgressIndicator(value: (step + 1) / 4, minHeight: 5, borderRadius: BorderRadius.circular(8), color: teal, backgroundColor: const Color(0xFFDDE9E7)),
          const SizedBox(height: 28),
          Text(titles[step], style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: deepTeal, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(step == 0 ? 'اختار الأماكن اللي بتتواجد فيها علشان نرشح لك الأقرب.' : step == 1 ? 'اختيارات بسيطة تساعدنا نحسن الترشيحات. تقدر تتخطاها.' : step == 2 ? 'اختار لحد 5 اهتمامات، وإحنا نرتب لك الفئات.' : 'اختار طريقة الدخول المناسبة ليك.', style: const TextStyle(color: muted, height: 1.5)),
          const SizedBox(height: 20),
          Expanded(child: AnimatedSwitcher(
            duration: AppMotion.standard,
            switchInCurve: Curves.easeOutCubic,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(begin: const Offset(.035, 0), end: Offset.zero).animate(animation),
                child: child,
              ),
            ),
            child: KeyedSubtree(key: ValueKey(step), child: _stepBody()),
          )),
          FilledButton(onPressed: next, style: FilledButton.styleFrom(backgroundColor: teal, minimumSize: const Size.fromHeight(52), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))), child: Text(step == 3 ? 'دخول للتطبيق' : 'كمّل')),
        ])),
      ),
    );
  }

  Widget _stepBody() {
    if (step == 0) {
      return ListView(children: [
        OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.my_location_outlined), label: const Text('استخدم موقعي الحالي'), style: OutlinedButton.styleFrom(foregroundColor: deepTeal, alignment: Alignment.centerRight, padding: const EdgeInsets.all(15), side: const BorderSide(color: teal), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)))),
        const SizedBox(height: 10),
        ...areaOptions.map((area) => _choiceTile(area, areas.contains(area), () => setState(() { if (areas.contains(area)) { areas.remove(area); } else if (areas.length < 3) { areas.add(area); } }))),
        const Padding(padding: EdgeInsets.only(top: 8), child: Text('تحديثات قادمة: مناطق سنضيفها قريبًا', style: TextStyle(color: muted, fontSize: 12))),
      ]);
    }
    if (step == 1) {
      return ListView(children: [
        const Text('السن', style: TextStyle(color: deepTeal, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: ['أقل من 18', '18–24', '25–34', '35–49', '50 أو أكثر', 'أفضل عدم الإفصاح'].map((item) => ChoiceChip(label: Text(item), selected: age == item, onSelected: (_) => setState(() => age = item), selectedColor: const Color(0xFFD8EFEC))).toList()),
        const SizedBox(height: 24),
        const Text('النوع', style: TextStyle(color: deepTeal, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: ['رجل', 'امرأة', 'أفضل عدم الإفصاح'].map((item) => ChoiceChip(label: Text(item), selected: gender == item, onSelected: (_) => setState(() => gender = item), selectedColor: const Color(0xFFD8EFEC))).toList()),
      ]);
    }
    if (step == 2) {
      return ListView(children: interestOptions.map((interest) => _choiceTile(interest, interests.contains(interest), () => setState(() {
        if (interests.contains(interest)) {
          interests.remove(interest);
        } else if (interests.length < 5) {
          interests.add(interest);
        }
      }))).toList());
    }
    return ListView(children: [
      _authChoice(Icons.person_add_alt_1, 'إنشاء حساب', 'اسم، رقم هاتف، وكلمة مرور'),
      _authChoice(Icons.login, 'تسجيل الدخول', 'ادخل على حسابك الحالي'),
      _authChoice(Icons.g_mobiledata, 'المتابعة باستخدام Google', 'بدون كلمة مرور'),
      _authChoice(Icons.apple, 'المتابعة باستخدام Apple', 'بدون كلمة مرور'),
      _authChoice(Icons.explore_outlined, 'التكملة كزائر', 'تصفح التطبيق بدون حساب'),
    ]);
  }

  Widget _choiceTile(String label, bool selected, VoidCallback onTap) => Card(color: selected ? const Color(0xFFD8EFEC) : Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: selected ? teal : const Color(0xFFE0E8E6))), child: ListTile(onTap: onTap, leading: Icon(selected ? Icons.check_circle : Icons.circle_outlined, color: selected ? teal : muted), title: Text(label), trailing: label == 'قنا كلها' ? const Text('المدينة', style: TextStyle(color: muted, fontSize: 12)) : null));
  Widget _authChoice(IconData icon, String title, String subtitle) => Card(elevation: 0, color: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: Color(0xFFE0E8E6))), child: ListTile(leading: Icon(icon, color: teal), title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)), subtitle: Text(subtitle, style: const TextStyle(color: muted, fontSize: 12)), trailing: const Icon(Icons.chevron_left, color: muted)));
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int index = 0;
  final pages = const [HomePage(), DirectoryPage(), PricesPage(), NowPage(), ListingsPage()];
  final labels = const ['الرئيسية', 'مين؟', 'بكام؟', 'دلوقتي', 'عندك؟'];
  final icons = const [Icons.home_outlined, Icons.person_search_outlined, Icons.sell_outlined, Icons.bolt_outlined, Icons.campaign_outlined];

  @override
  Widget build(BuildContext context) {
    return Directionality(textDirection: TextDirection.rtl, child: Scaffold(
      body: AnimatedSwitcher(
        duration: AppMotion.standard,
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(begin: const Offset(0.025, 0), end: Offset.zero)
                .animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
            child: child,
          ),
        ),
        child: KeyedSubtree(key: ValueKey(index), child: pages[index]),
      ),
      bottomNavigationBar: NavigationBar(selectedIndex: index, onDestinationSelected: (value) => setState(() => index = value), backgroundColor: Colors.white, indicatorColor: const Color(0xFFD8EFEC), destinations: [for (var i = 0; i < labels.length; i++) NavigationDestination(icon: Icon(icons[i]), selectedIcon: Icon(icons[i], color: deepTeal), label: labels[i])]),
    ));
  }
}

class BasePage extends StatelessWidget {
  const BasePage({super.key, required this.child, this.title});
  final Widget child;
  final String? title;
  @override
  Widget build(BuildContext context) => SafeArea(child: RefreshIndicator(color: teal, onRefresh: () async { await Future<void>.delayed(const Duration(milliseconds: 500)); }, child: ListView(padding: const EdgeInsets.fromLTRB(18, 12, 18, 24), children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [if (title != null) Text(title!, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: deepTeal)) else const BrandText(), Row(children: [IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_none, color: deepTeal)), IconButton(onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AccountPage())), icon: const CircleAvatar(radius: 15, backgroundColor: deepTeal, child: Text('م', style: TextStyle(color: Colors.white, fontSize: 12))))])]), const SizedBox(height: 12), child])));
}

class BrandText extends StatelessWidget { const BrandText({super.key}); @override Widget build(BuildContext context) => const Text('هنا قنا', style: TextStyle(color: deepTeal, fontSize: 20, fontWeight: FontWeight.w700)); }

class HomePage extends StatelessWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context) => BasePage(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    Row(children: [const Icon(Icons.location_on_outlined, size: 18, color: teal), const SizedBox(width: 5), const Text('قنا كلها', style: TextStyle(color: muted)), const Spacer(), TextButton(onPressed: () {}, child: const Text('تغيير'))]),
    const SizedBox(height: 6),
    TextField(decoration: const InputDecoration(prefixIcon: Icon(Icons.search, color: teal), hintText: 'بتدور على إيه؟')),
    const SizedBox(height: 16),
    const HeroBanner(),
    const SizedBox(height: 14),
    const PromoCarousel(),
    const SizedBox(height: 20),
    const SectionTitle(title: 'فئات قريبة منك'),
    const SizedBox(height: 9),
    const SizedBox(height: 2),
    const CategoryRail(items: ['صيدليات', 'مطاعم', 'فنيين', 'سوبر ماركت', 'تعليم', 'ترفيه']),
    const SizedBox(height: 20),
    const SectionTitle(title: 'مختارات قنا'),
    const SizedBox(height: 9),
    MiniItem(icon: Icons.local_pharmacy_outlined, title: 'صيدلية الرحمة', subtitle: 'الحميدات · مفتوح الآن · 4.8 ★', onTap: () => _openDetails(context, 'صيدلية الرحمة', Icons.local_pharmacy_outlined, 'الحميدات · مفتوح الآن · 4.8 ★')),
    MiniItem(icon: Icons.coffee_outlined, title: 'قهوة البلد', subtitle: 'وسط البلد · على بُعد 0.8 كم', onTap: () => _openDetails(context, 'قهوة البلد', Icons.coffee_outlined, 'وسط البلد · مفتوح الآن · 4.7 ★')),
  ]));

  void _openDetails(BuildContext context, String title, IconData icon, String subtitle) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => ProviderDetailPage(title: title, icon: icon, subtitle: subtitle)));
  }
}

class SectionTitle extends StatelessWidget { const SectionTitle({super.key, required this.title}); final String title; @override Widget build(BuildContext context) => Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(title, style: const TextStyle(color: deepTeal, fontSize: 16, fontWeight: FontWeight.w700)), const Text('شوف الكل', style: TextStyle(color: teal, fontSize: 12))]); }
class MotionIn extends StatelessWidget {
  const MotionIn({super.key, required this.child, this.delay = 0});
  final Widget child;
  final int delay;
  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: 1),
    duration: Duration(milliseconds: 280 + delay),
    curve: Curves.easeOutCubic,
    builder: (_, value, child) => Opacity(opacity: value, child: Transform.translate(offset: Offset(0, 10 * (1 - value)), child: child)),
    child: child,
  );
}
class HeroBanner extends StatefulWidget {
  const HeroBanner({super.key});
  @override
  State<HeroBanner> createState() => _HeroBannerState();
}

class _HeroBannerState extends State<HeroBanner> with SingleTickerProviderStateMixin {
  late final AnimationController controller = AnimationController(vsync: this, duration: const Duration(seconds: 5))..repeat(reverse: true);

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (_, child) => Container(
      clipBehavior: Clip.antiAlias,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(22), gradient: LinearGradient(begin: Alignment.topRight, end: Alignment.bottomLeft, colors: [deepTeal, Color.lerp(teal, deepTeal, controller.value * .35)!])),
      child: Stack(children: [
        PositionedDirectional(end: -24 + controller.value * 12, top: -25, child: Container(width: 100, height: 100, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: .07)))),
        PositionedDirectional(end: 38 - controller.value * 8, bottom: -46, child: Container(width: 125, height: 125, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white.withValues(alpha: .08), width: 10)))),
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [Text('قنا كلها هنا', style: TextStyle(color: Color(0xDDF7F6F2), fontSize: 13)), SizedBox(height: 8), Text('كل ما تحتاجه.. قريب منك', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)), SizedBox(height: 5), Text('اكتشف، قارن، واعرف الجديد حواليك', style: TextStyle(color: Color(0xDDF7F6F2)))])),
          Transform.translate(offset: Offset(0, -3 * controller.value), child: const LogoMark(dark: true, size: 47)),
        ]),
      ]),
    ),
  );
}
class PromoCarousel extends StatefulWidget {
  const PromoCarousel({super.key});
  @override
  State<PromoCarousel> createState() => _PromoCarouselState();
}

class _PromoCarouselState extends State<PromoCarousel> {
  final controller = PageController(viewportFraction: .94);
  int active = 0;
  final promos = const [
    ('إعلان مميز', 'خصم خاص لأهل قنا اليوم', Icons.campaign_outlined, gold),
    ('قنا كلها هنا', 'اعرف الجديد والخدمات الأقرب ليك', Icons.explore_outlined, teal),
    ('دلوقتي في قنا', 'تحديثات محلية مهمة من حواليك', Icons.bolt_outlined, deepTeal),
  ];

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(children: [
    SizedBox(
      height: 104,
      child: PageView.builder(
        controller: controller,
        itemCount: promos.length,
        onPageChanged: (value) => setState(() => active = value),
        itemBuilder: (_, index) {
          final promo = promos[index];
          final isGold = promo.$4 == gold;
          return AnimatedScale(
            duration: AppMotion.quick,
            scale: index == active ? 1 : .97,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: isGold ? gold.withValues(alpha: .22) : promo.$4,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(children: [
                Icon(promo.$3, color: isGold ? deepTeal : Colors.white, size: 25),
                const SizedBox(width: 11),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(promo.$1, style: TextStyle(color: isGold ? deepTeal : Colors.white, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(promo.$2, style: TextStyle(color: isGold ? ink : Colors.white.withValues(alpha: .9), fontSize: 13)),
                ])),
                Icon(Icons.chevron_left, color: isGold ? deepTeal : Colors.white),
              ]),
            ),
          );
        },
      ),
    ),
    const SizedBox(height: 7),
    Row(mainAxisAlignment: MainAxisAlignment.center, children: [for (var i = 0; i < promos.length; i++) AnimatedContainer(duration: AppMotion.quick, width: i == active ? 18 : 6, height: 6, margin: const EdgeInsets.symmetric(horizontal: 3), decoration: BoxDecoration(color: i == active ? teal : const Color(0xFFD6E3E0), borderRadius: BorderRadius.circular(6)))]),
  ]);
}
class CategoryRail extends StatelessWidget {
  const CategoryRail({super.key, required this.items});
  final List<String> items;
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 42,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (_, index) => const SizedBox(width: 8),
      itemBuilder: (_, index) => ActionChip(
        onPressed: () {},
        avatar: const Icon(Icons.circle, size: 8, color: gold),
        label: Text(items[index]),
        backgroundColor: Colors.white,
        side: const BorderSide(color: Color(0xFFE0E8E6)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
        padding: const EdgeInsets.symmetric(horizontal: 8),
      ),
    ),
  );
}
class MiniItem extends StatelessWidget {
  const MiniItem({super.key, required this.icon, required this.title, required this.subtitle, this.onTap});
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Card(
    elevation: 0,
    color: Colors.white,
    margin: const EdgeInsets.only(bottom: 8),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: const BorderSide(color: Color(0xFFE0E8E6))),
    child: ListTile(
      onTap: onTap,
      leading: Hero(tag: 'provider-icon-$title', child: CircleAvatar(backgroundColor: const Color(0xFFD8EFEC), child: Icon(icon, color: deepTeal))),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(subtitle, style: const TextStyle(color: muted, fontSize: 12)),
      trailing: const Icon(Icons.chevron_left, color: muted),
    ),
  );
}

class DirectoryPage extends StatelessWidget {
  const DirectoryPage({super.key});
  @override
  Widget build(BuildContext context) => BasePage(title: 'مين؟', child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    const Text('اختار الفئة الأقرب لاحتياجك', style: TextStyle(color: muted)),
    const SizedBox(height: 10),
    const CategoryRail(items: ['خدمات طبية', 'مطاعم وكافيهات', 'صيانة وفنيين', 'سوبر ماركت', 'تعليم ودروس', 'ترفيه']),
    const SizedBox(height: 16),
    const TextField(decoration: InputDecoration(prefixIcon: Icon(Icons.search, color: teal), hintText: 'اكتب اسم الخدمة أو المكان')),
    const SizedBox(height: 10),
    Row(children: [OutlinedButton.icon(onPressed: () => _showFilters(context), icon: const Icon(Icons.tune), label: const Text('فلاتر')), const Spacer(), OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.map_outlined), label: const Text('خريطة'))]),
    MiniItem(icon: Icons.build_outlined, title: 'كهربائي المصباح', subtitle: 'قنا · موثق · 4.8 ★ · مفتوح الآن', onTap: () => _openDetails(context, 'كهربائي المصباح', Icons.build_outlined, 'قنا · موثق · مفتوح الآن · 4.8 ★')),
    MiniItem(icon: Icons.local_hospital_outlined, title: 'مركز الشفاء الطبي', subtitle: 'وسط البلد · 4.6 ★', onTap: () => _openDetails(context, 'مركز الشفاء الطبي', Icons.local_hospital_outlined, 'وسط البلد · مفتوح اليوم · 4.6 ★')),
  ]));

  void _openDetails(BuildContext context, String title, IconData icon, String subtitle) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => ProviderDetailPage(title: title, icon: icon, subtitle: subtitle)));
  }

  void _showFilters(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _FilterSheet(),
    );
  }
}

class _FilterSheet extends StatefulWidget {
  const _FilterSheet();
  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  String sort = 'الأقرب';
  bool openNow = false;
  bool verified = true;
  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: SafeArea(child: Container(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
      decoration: const BoxDecoration(color: paper, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      child: Wrap(children: [
        Center(child: Container(width: 42, height: 4, decoration: BoxDecoration(color: const Color(0xFFD0DAD8), borderRadius: BorderRadius.circular(4)))),
        const SizedBox(height: 18),
        Row(children: [const Expanded(child: Text('فلترة النتائج', style: TextStyle(color: deepTeal, fontSize: 19, fontWeight: FontWeight.w700))), IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close))]),
        const SizedBox(height: 8),
        const Text('الترتيب', style: TextStyle(color: deepTeal, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, children: ['الأقرب', 'الأعلى تقييمًا', 'الأحدث'].map((item) => ChoiceChip(label: Text(item), selected: sort == item, onSelected: (_) => setState(() => sort = item), selectedColor: const Color(0xFFD8EFEC))).toList()),
        const SizedBox(height: 10),
        SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('مفتوح الآن'), value: openNow, onChanged: (value) => setState(() => openNow = value), activeThumbColor: teal),
        SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('أماكن موثقة فقط'), value: verified, onChanged: (value) => setState(() => verified = value), activeThumbColor: teal),
        const SizedBox(height: 8),
        FilledButton(onPressed: () => Navigator.pop(context), style: FilledButton.styleFrom(backgroundColor: teal, minimumSize: const Size.fromHeight(50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))), child: const Text('تطبيق الفلاتر')),
      ]),
    )),
  );
}

class ProviderDetailPage extends StatelessWidget {
  const ProviderDetailPage({super.key, required this.title, required this.icon, required this.subtitle});
  final String title;
  final IconData icon;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      appBar: AppBar(title: const Text('تفاصيل المكان')),
      body: ListView(padding: const EdgeInsets.fromLTRB(18, 8, 18, 30), children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.96, end: 1),
          duration: AppMotion.gentle,
          curve: Curves.easeOutCubic,
          builder: (_, value, child) => Transform.scale(scale: value, child: child),
          child: Card(
            elevation: 0,
            color: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Color(0xFFE0E8E6))),
            child: Padding(padding: const EdgeInsets.all(18), child: Row(children: [
              Hero(tag: 'provider-icon-$title', child: CircleAvatar(radius: 30, backgroundColor: const Color(0xFFD8EFEC), child: Icon(icon, color: deepTeal, size: 30))),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(color: deepTeal, fontSize: 20, fontWeight: FontWeight.w700)), const SizedBox(height: 5), Text(subtitle, style: const TextStyle(color: muted)), const SizedBox(height: 8), const Text('4.8 ★  ·  موثق', style: TextStyle(color: teal, fontWeight: FontWeight.w700))])),
            ])),
          ),
        ),
        const SizedBox(height: 16),
        Row(children: [Expanded(child: FilledButton.icon(onPressed: () {}, icon: const Icon(Icons.phone_outlined), label: const Text('اتصال'))), const SizedBox(width: 8), Expanded(child: OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.chat_outlined), label: const Text('واتساب')))]),
        const SizedBox(height: 20),
        const SectionTitle(title: 'التقييم'),
        const SizedBox(height: 10),
        const _RatingRow(label: 'الجودة', value: '4.9'),
        const _RatingRow(label: 'الالتزام', value: '4.8'),
        const _RatingRow(label: 'السعر', value: '4.6'),
        const SizedBox(height: 18),
        const SectionTitle(title: 'التقييمات الموجودة'),
        const SizedBox(height: 8),
        const MiniItem(icon: Icons.person_outline, title: 'أحمد محمد', subtitle: 'خدمة ممتازة والتعامل محترم · 5 ★'),
        const MiniItem(icon: Icons.person_outline, title: 'مريم علي', subtitle: 'سعر مناسب وملتزمين بالموعد · 4 ★'),
        FilledButton.icon(onPressed: () {}, icon: const Icon(Icons.star_border), label: const Text('أضف تقييمك'), style: FilledButton.styleFrom(backgroundColor: teal, minimumSize: const Size.fromHeight(48), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)))),
      ]),
    ),
  );
}

class _RatingRow extends StatelessWidget {
  const _RatingRow({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(children: [Expanded(child: Text(label)), const Icon(Icons.star, color: gold, size: 18), const SizedBox(width: 4), Text(value, style: const TextStyle(fontWeight: FontWeight.w700, color: deepTeal))]));
}
class PricesPage extends StatefulWidget { const PricesPage({super.key}); @override State<PricesPage> createState() => _PricesPageState(); }
class _PricesPageState extends State<PricesPage> {
  String selected = 'offers';
  @override
  Widget build(BuildContext context) => BasePage(title: 'بكام؟', child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    const Text('العروض أولًا، ثم الأسعار المحدثة', style: TextStyle(color: muted)),
    const SizedBox(height: 14),
    SegmentedButton<String>(segments: const [ButtonSegment(value: 'offers', label: Text('العروض'), icon: Icon(Icons.local_offer_outlined)), ButtonSegment(value: 'prices', label: Text('الأسعار'), icon: Icon(Icons.sell_outlined))], selected: {selected}, onSelectionChanged: (value) => setState(() => selected = value.first)),
    const SizedBox(height: 16),
    AnimatedSwitcher(duration: AppMotion.standard, child: selected == 'offers' ? const Column(key: ValueKey('offers'), children: [MiniItem(icon: Icons.local_offer_outlined, title: 'خصم 15% على الأجهزة', subtitle: 'من نشاط موثق · ينتهي خلال 3 أيام'), MiniItem(icon: Icons.local_offer_outlined, title: 'عرض نهاية الأسبوع', subtitle: 'مطاعم مختارة · ينتهي غدًا')]) : const Column(key: ValueKey('prices'), children: [MiniItem(icon: Icons.shopping_basket_outlined, title: 'زيت عباد الشمس — 1 لتر', subtitle: 'السعر المعتاد 72 جنيه · من 68 إلى 77 · منذ يومين'), MiniItem(icon: Icons.home_repair_service_outlined, title: 'تركيب تكييف', subtitle: 'من 800 إلى 1,200 جنيه · سعر تقريبي')])),
  ]));
}

class NowPage extends StatelessWidget { const NowPage({super.key}); @override Widget build(BuildContext context) => BasePage(title: 'دلوقتي', child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [Row(children: [const Expanded(child: Text('اعرف إيه اللي بيحصل حواليك', style: TextStyle(color: muted))), const LivePulse()]), const SizedBox(height: 14), Wrap(spacing: 8, children: ['الكل', 'خدمات ومرافق', 'طرق ومواصلات', 'فعاليات'].map((x) => ChoiceChip(label: Text(x), selected: x == 'الكل', onSelected: (_) {})).toList()), const SizedBox(height: 14), const MotionIn(child: _AlertCard(title: 'انقطاع مياه مؤقت', subtitle: 'الحميدات · منذ ساعتين · تم التأكيد', icon: Icons.water_drop_outlined, color: teal)), const MotionIn(delay: 80, child: _AlertCard(title: 'فتح شارع جديد', subtitle: 'وسط البلد · منذ 30 دقيقة', icon: Icons.traffic_outlined, color: gold)), const MotionIn(delay: 160, child: _AlertCard(title: 'معرض منتجات قنا', subtitle: 'فعالية محلية · اليوم', icon: Icons.event_outlined, color: deepTeal))])); }
class LivePulse extends StatefulWidget {
  const LivePulse({super.key});
  @override
  State<LivePulse> createState() => _LivePulseState();
}

class _LivePulseState extends State<LivePulse> with SingleTickerProviderStateMixin {
  late final AnimationController controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();
  @override
  void dispose() { controller.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (_, value) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(color: const Color(0xFFE8F5F2), borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 8 + (controller.value * 3), height: 8 + (controller.value * 3), decoration: BoxDecoration(color: teal.withValues(alpha: .32), shape: BoxShape.circle), child: Center(child: Container(width: 6, height: 6, decoration: const BoxDecoration(color: teal, shape: BoxShape.circle)))),
        const SizedBox(width: 5),
        const Text('مباشر', style: TextStyle(color: deepTeal, fontSize: 12, fontWeight: FontWeight.w700)),
      ]),
    ),
  );
}
class _AlertCard extends StatelessWidget { const _AlertCard({required this.title, required this.subtitle, required this.icon, required this.color}); final String title; final String subtitle; final IconData icon; final Color color; @override Widget build(BuildContext context) => Card(elevation: 0, margin: const EdgeInsets.only(bottom: 9), color: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xFFE0E8E6))), child: ListTile(leading: CircleAvatar(backgroundColor: color.withValues(alpha: .14), child: Icon(icon, color: color)), title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)), subtitle: Text(subtitle, style: const TextStyle(color: muted, fontSize: 12)), trailing: OutlinedButton(onPressed: () {}, child: const Text('مفيد')))); }

class ListingsPage extends StatelessWidget { const ListingsPage({super.key}); @override Widget build(BuildContext context) => BasePage(title: 'عندك؟', child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [const Text('اعرض اللي عندك، ودوّر على اللي محتاجه', style: TextStyle(color: muted)), const SizedBox(height: 14), const TextField(decoration: InputDecoration(prefixIcon: Icon(Icons.search, color: teal), hintText: 'ابحث في الإعلانات')), const SizedBox(height: 10), const CategoryRail(items: ['للبيع', 'للإيجار', 'وظائف', 'سيارات', 'عقارات']), const SizedBox(height: 12), const MiniItem(icon: Icons.home_outlined, title: 'شقة للإيجار في قنا الجديدة', subtitle: '7,500 جنيه · قنا الجديدة · منذ يوم'), const MiniItem(icon: Icons.kitchen_outlined, title: 'ثلاجة بحالة ممتازة', subtitle: '3,500 جنيه · الحميدات · منذ 3 أيام'), const SizedBox(height: 8), FilledButton.icon(onPressed: () {}, icon: const Icon(Icons.add), label: const Text('أضف إعلانًا'), style: FilledButton.styleFrom(backgroundColor: gold, foregroundColor: deepTeal, minimumSize: const Size.fromHeight(48), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))))])); }

class AccountPage extends StatelessWidget { const AccountPage({super.key}); @override Widget build(BuildContext context) => Directionality(textDirection: TextDirection.rtl, child: Scaffold(appBar: AppBar(title: const Text('حسابي')), body: ListView(padding: const EdgeInsets.all(18), children: [Card(elevation: 0, color: Colors.white, child: ListTile(leading: const CircleAvatar(backgroundColor: deepTeal, child: Text('م', style: TextStyle(color: Colors.white))), title: const Text('محمد أحمد', style: TextStyle(fontWeight: FontWeight.w700)), subtitle: const Text('قناوي رايق · 74 نقطة', style: TextStyle(color: teal)), trailing: const Icon(Icons.chevron_left))), const SizedBox(height: 10), const ListTile(leading: Icon(Icons.favorite_border, color: teal), title: Text('المفضلة')), const ListTile(leading: Icon(Icons.rate_review_outlined, color: teal), title: Text('تقييماتي ومساهماتي')), const ListTile(leading: Icon(Icons.campaign_outlined, color: teal), title: Text('إعلاناتي')), const Divider(), const ListTile(leading: Icon(Icons.settings_outlined, color: teal), title: Text('الإعدادات')), const ListTile(leading: Icon(Icons.help_outline, color: teal), title: Text('المساعدة والدعم')), const ListTile(leading: Icon(Icons.delete_outline, color: teal), title: Text('حذف الحساب'))]))); }
