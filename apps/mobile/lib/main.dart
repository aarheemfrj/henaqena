import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'core/theme/app_theme.dart';
import 'core/network/api_client.dart';

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
        pageTransitionsTheme: const PageTransitionsTheme(builders: {
          TargetPlatform.android: SmoothPageTransitionsBuilder(),
          TargetPlatform.iOS: SmoothPageTransitionsBuilder(),
          TargetPlatform.macOS: SmoothPageTransitionsBuilder(),
        }),
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
  const BasePage({super.key, required this.child, this.title, this.onRefresh});
  final Widget child;
  final String? title;
  final Future<void> Function()? onRefresh;
  @override
  Widget build(BuildContext context) {
    final refresh = onRefresh ?? () async => Future<void>.delayed(const Duration(milliseconds: 450));
    return SafeArea(child: RefreshIndicator(
      color: teal,
      displacement: 24,
      onRefresh: refresh,
      child: ListView(padding: const EdgeInsets.fromLTRB(18, 12, 18, 24), children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          if (title != null) Text(title!, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: deepTeal)) else const BrandText(),
          Row(children: [
            IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_none, color: deepTeal)),
            IconButton(onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AccountPage())), icon: const CircleAvatar(radius: 15, backgroundColor: deepTeal, child: Text('م', style: TextStyle(color: Colors.white, fontSize: 12))))
          ])
        ]),
        const SizedBox(height: 12),
        child,
      ]),
    ));
  }
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
class MiniItem extends StatefulWidget {
  const MiniItem({super.key, required this.icon, required this.title, required this.subtitle, this.onTap});
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  @override
  State<MiniItem> createState() => _MiniItemState();
}

class _MiniItemState extends State<MiniItem> {
  bool pressed = false;
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTapDown: widget.onTap == null ? null : (_) => setState(() => pressed = true),
    onTapUp: widget.onTap == null ? null : (_) => setState(() => pressed = false),
    onTapCancel: widget.onTap == null ? null : () => setState(() => pressed = false),
    onTap: widget.onTap,
    child: AnimatedScale(
      scale: pressed ? .975 : 1,
      duration: AppMotion.quick,
      curve: Curves.easeOutCubic,
      child: Card(
        elevation: 0,
        color: Colors.white,
        margin: const EdgeInsets.only(bottom: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: const BorderSide(color: Color(0xFFE0E8E6))),
        child: ListTile(
          leading: Hero(tag: 'provider-icon-${widget.title}', child: CircleAvatar(backgroundColor: const Color(0xFFD8EFEC), child: Icon(widget.icon, color: deepTeal))),
          title: Text(widget.title, style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle: Text(widget.subtitle, style: const TextStyle(color: muted, fontSize: 12)),
          trailing: const Icon(Icons.chevron_left, color: muted),
        ),
      ),
    ),
  );
}

class DirectoryPage extends StatefulWidget {
  const DirectoryPage({super.key});
  @override
  State<DirectoryPage> createState() => _DirectoryPageState();
}

class _DirectoryPageState extends State<DirectoryPage> {
  late Future<List<ProviderSummary>> providersFuture;
  final api = ApiClient();
  @override
  void initState() { super.initState(); providersFuture = api.fetchProviders(); }
  @override
  Widget build(BuildContext context) => BasePage(title: 'مين؟', onRefresh: _reload, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    const Text('اختار الفئة الأقرب لاحتياجك', style: TextStyle(color: muted)),
    const SizedBox(height: 10),
    const CategoryRail(items: ['خدمات طبية', 'مطاعم وكافيهات', 'صيانة وفنيين', 'سوبر ماركت', 'تعليم ودروس', 'ترفيه']),
    const SizedBox(height: 16),
    const TextField(decoration: InputDecoration(prefixIcon: Icon(Icons.search, color: teal), hintText: 'اكتب اسم الخدمة أو المكان')),
    const SizedBox(height: 10),
    Row(children: [OutlinedButton.icon(onPressed: () => _showFilters(context), icon: const Icon(Icons.tune), label: const Text('فلاتر')), const Spacer(), OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.map_outlined), label: const Text('خريطة'))]),
    FutureBuilder<List<ProviderSummary>>(future: providersFuture, builder: (context, snapshot) {
      final fallback = [const ProviderSummary(id: 'local-electrician', name: 'كهربائي المصباح', subtitle: 'قنا · موثق · 4.8 ★ · مفتوح الآن'), const ProviderSummary(id: 'local-medical', name: 'مركز الشفاء الطبي', subtitle: 'وسط البلد · 4.6 ★')];
      final providers = snapshot.hasData && snapshot.data!.isNotEmpty ? snapshot.data! : fallback;
      return Column(children: [if (snapshot.connectionState == ConnectionState.waiting) const LinearProgressIndicator(minHeight: 3, color: teal), if (snapshot.hasError) const Padding(padding: EdgeInsets.only(bottom: 8), child: Text('بيانات تجريبية — سيتم تحديثها عند تشغيل الخادم', style: TextStyle(color: muted, fontSize: 11))), ...providers.asMap().entries.map((entry) { final icon = entry.key == 0 ? Icons.build_outlined : Icons.local_hospital_outlined; final provider = entry.value; return MiniItem(icon: icon, title: provider.name, subtitle: provider.subtitle, onTap: () => _openDetails(context, provider.name, icon, provider.subtitle)); })]);
    }),
  ]));

  Future<void> _reload() async {
    setState(() => providersFuture = api.fetchProviders());
    await providersFuture;
  }

  void _openDetails(BuildContext context, String title, IconData icon, String subtitle) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => ProviderDetailPage(title: title, icon: icon, subtitle: subtitle)));
  }

  void _showFilters(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      sheetAnimationStyle: const AnimationStyle(duration: AppMotion.gentle, reverseDuration: AppMotion.quick),
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
        const MediaGallery(imageCount: 4),
        const SizedBox(height: 14),
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
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(color: deepTeal, fontSize: 20, fontWeight: FontWeight.w700)), const SizedBox(height: 7), Row(children: [Expanded(child: Text(subtitle.replaceAll(RegExp(r' · \d(?:\.\d)? ★'), '').replaceAll('موثق · ', '').replaceAll(' · موثق', ''), style: const TextStyle(color: muted))), const SizedBox(width: 10), const Text('موثق', style: TextStyle(color: teal, fontWeight: FontWeight.w700))])])),
            ])),
          ),
        ),
        const SizedBox(height: 16),
        Row(children: [Expanded(child: FilledButton.icon(onPressed: () {}, icon: const Icon(Icons.phone_outlined), label: const Text('اتصال'))), const SizedBox(width: 8), Expanded(child: OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.chat_outlined), label: const Text('واتساب')))]),
        const SizedBox(height: 20),
        const SectionTitle(title: 'الوصف'),
        const SizedBox(height: 8),
        const Text('خدمة موثقة ومعلوماتها محدثة من فريق هنا قنا.', style: TextStyle(color: muted, height: 1.5)),
        const SizedBox(height: 10),
        const Row(children: [Icon(Icons.star, color: gold, size: 20), SizedBox(width: 5), Text('4.8', style: TextStyle(color: teal, fontWeight: FontWeight.w700)), SizedBox(width: 5), Text('من 24 تقييم', style: TextStyle(color: muted, fontSize: 12))]),
        const SizedBox(height: 18),
        const SectionTitle(title: 'التقييمات الموجودة'),
        const SizedBox(height: 8),
        const CommentBubble(name: 'أحمد محمد', initial: 'أ', text: 'خدمة ممتازة والتعامل محترم.', rating: 5, replies: [CommentReply(name: 'مريم علي', initial: 'م', text: 'أتفق معاك، تجربتي كانت كويسة برضه.')]),
        const CommentBubble(name: 'مريم علي', initial: 'م', text: 'سعر مناسب وملتزمين بالموعد.', rating: 4),
        FilledButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ReviewPage(providerName: title))), icon: const Icon(Icons.star_border), label: const Text('أضف تقييمك'), style: FilledButton.styleFrom(backgroundColor: teal, minimumSize: const Size.fromHeight(48), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)))),
      ]),
    ),
  );
}

class CommentBubble extends StatelessWidget {
  const CommentBubble({super.key, required this.name, required this.initial, required this.text, required this.rating, this.replies = const []});
  final String name;
  final String initial;
  final String text;
  final int rating;
  final List<CommentReply> replies;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 16), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      CircleAvatar(radius: 19, backgroundColor: const Color(0xFFD8EFEC), child: Text(initial, style: const TextStyle(color: deepTeal, fontWeight: FontWeight.w700))),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Expanded(child: Text(name, style: const TextStyle(color: deepTeal, fontWeight: FontWeight.w700))), Text('منذ يوم', style: const TextStyle(color: muted, fontSize: 11))]),
        const SizedBox(height: 5),
        Text(text, style: const TextStyle(color: ink, height: 1.4)),
        const SizedBox(height: 5),
        Row(children: [Text('$rating', style: const TextStyle(color: teal, fontWeight: FontWeight.w700)), const Icon(Icons.star, color: gold, size: 15), const SizedBox(width: 12), TextButton(onPressed: () {}, style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero), child: const Text('مفيد')), const SizedBox(width: 12), TextButton(onPressed: () {}, style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero), child: const Text('رد'))]),
      ])),
    ]),
    if (replies.isNotEmpty) Padding(padding: const EdgeInsetsDirectional.only(start: 42, top: 8), child: Column(children: replies)),
  ]));
}

class CommentReply extends StatelessWidget {
  const CommentReply({super.key, required this.name, required this.initial, required this.text});
  final String name;
  final String initial;
  final String text;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [CircleAvatar(radius: 15, backgroundColor: const Color(0xFFE8F5F2), child: Text(initial, style: const TextStyle(color: deepTeal, fontSize: 12, fontWeight: FontWeight.w700))), const SizedBox(width: 8), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(name, style: const TextStyle(color: deepTeal, fontSize: 13, fontWeight: FontWeight.w700)), const SizedBox(height: 2), Text(text, style: const TextStyle(color: ink, fontSize: 13, height: 1.3)), Row(children: [TextButton(onPressed: () {}, style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero), child: const Text('مفيد', style: TextStyle(fontSize: 12))), TextButton(onPressed: () {}, style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero), child: const Text('رد', style: TextStyle(fontSize: 12)))])]))]));
}

class ReviewPage extends StatefulWidget {
  const ReviewPage({super.key, required this.providerName});
  final String providerName;
  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  final scores = <String, int>{'الجودة': 0, 'الالتزام': 0, 'السعر': 0};
  final comment = TextEditingController();
  @override
  void dispose() { comment.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => Directionality(textDirection: TextDirection.rtl, child: Scaffold(
    appBar: AppBar(title: const Text('إضافة تقييم')),
    body: ListView(padding: const EdgeInsets.fromLTRB(18, 12, 18, 24), children: [
      Text('قيّم ${widget.providerName}', style: const TextStyle(color: deepTeal, fontSize: 21, fontWeight: FontWeight.w700)),
      const SizedBox(height: 7),
      const Text('تقييمك يساعد أهل قنا يختاروا بشكل أفضل.', style: TextStyle(color: muted)),
      const SizedBox(height: 22),
      ...scores.keys.map((label) => _ScorePicker(label: label, value: scores[label]!, onChanged: (value) => setState(() => scores[label] = value))),
      const SizedBox(height: 18),
      TextField(controller: comment, maxLines: 5, decoration: const InputDecoration(labelText: 'اكتب تعليقك', hintText: 'إيه اللي عجبك أو محتاج يتحسن؟')),
      const SizedBox(height: 12),
      const Text('التقييم يظهر باسمك الحقيقي ويمكنك تعديله من مساهماتك.', style: TextStyle(color: muted, fontSize: 12)),
      const SizedBox(height: 22),
      FilledButton(onPressed: scores.values.any((value) => value == 0) ? null : () { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إرسال التقييم للمراجعة'))); }, style: FilledButton.styleFrom(backgroundColor: teal, minimumSize: const Size.fromHeight(50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))), child: const Text('إرسال التقييم')),
    ]),
  ));
}

class _ScorePicker extends StatelessWidget {
  const _ScorePicker({required this.label, required this.value, required this.onChanged});
  final String label;
  final int value;
  final ValueChanged<int> onChanged;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 15), child: Row(children: [SizedBox(width: 82, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700, color: deepTeal))), ...List.generate(5, (index) => IconButton(visualDensity: VisualDensity.compact, onPressed: () => onChanged(index + 1), icon: AnimatedScale(scale: index < value ? 1.12 : 1, duration: AppMotion.quick, curve: Curves.easeOutBack, child: AnimatedSwitcher(duration: AppMotion.quick, child: Icon(index < value ? Icons.star : Icons.star_border, key: ValueKey(index < value), color: gold, size: 27))))), if (value > 0) Text('$value/5', style: const TextStyle(color: muted, fontSize: 12))]));
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
    AnimatedSwitcher(duration: AppMotion.standard, transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: SlideTransition(position: Tween<Offset>(begin: const Offset(.03, 0), end: Offset.zero).animate(animation), child: child)), child: selected == 'offers' ? const Column(key: ValueKey('offers'), children: [MiniItem(icon: Icons.local_offer_outlined, title: 'خصم 15% على الأجهزة', subtitle: 'من نشاط موثق · ينتهي خلال 3 أيام'), MiniItem(icon: Icons.local_offer_outlined, title: 'عرض نهاية الأسبوع', subtitle: 'مطاعم مختارة · ينتهي غدًا')]) : const Column(key: ValueKey('prices'), children: [MiniItem(icon: Icons.shopping_basket_outlined, title: 'زيت عباد الشمس — 1 لتر', subtitle: 'السعر المعتاد 72 جنيه · من 68 إلى 77 · منذ يومين'), MiniItem(icon: Icons.home_repair_service_outlined, title: 'تركيب تكييف', subtitle: 'من 800 إلى 1,200 جنيه · سعر تقريبي')])),
  ]));
}

class NowPage extends StatefulWidget { const NowPage({super.key}); @override State<NowPage> createState() => _NowPageState(); }
class _NowPageState extends State<NowPage> {
  String selected = 'الكل';
  @override
  Widget build(BuildContext context) => BasePage(title: 'دلوقتي', child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    const Row(children: [Expanded(child: Text('اعرف إيه اللي بيحصل حواليك', style: TextStyle(color: muted))), LivePulse()]),
    const SizedBox(height: 14),
    Wrap(spacing: 8, children: ['الكل', 'خدمات ومرافق', 'طرق ومواصلات', 'فعاليات'].map((x) => ChoiceChip(label: Text(x), selected: x == selected, onSelected: (_) => setState(() => selected = x), selectedColor: const Color(0xFFD8EFEC))).toList()),
    const SizedBox(height: 14),
    AnimatedSwitcher(duration: AppMotion.standard, transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: SlideTransition(position: Tween<Offset>(begin: const Offset(0, .025), end: Offset.zero).animate(animation), child: child)), child: Column(key: ValueKey(selected), children: _items())),
  ]));

  List<Widget> _items() {
    if (selected == 'خدمات ومرافق') return const [MotionIn(child: _AlertCard(title: 'انقطاع مياه مؤقت', subtitle: 'الحميدات · منذ ساعتين · تم التأكيد', icon: Icons.water_drop_outlined, color: teal))];
    if (selected == 'طرق ومواصلات') return const [MotionIn(child: _AlertCard(title: 'فتح شارع جديد', subtitle: 'وسط البلد · منذ 30 دقيقة', icon: Icons.traffic_outlined, color: gold))];
    if (selected == 'فعاليات') return const [MotionIn(child: _AlertCard(title: 'معرض منتجات قنا', subtitle: 'فعالية محلية · اليوم', icon: Icons.event_outlined, color: deepTeal))];
    return const [MotionIn(child: _AlertCard(title: 'انقطاع مياه مؤقت', subtitle: 'الحميدات · منذ ساعتين · تم التأكيد', icon: Icons.water_drop_outlined, color: teal)), MotionIn(delay: 80, child: _AlertCard(title: 'فتح شارع جديد', subtitle: 'وسط البلد · منذ 30 دقيقة', icon: Icons.traffic_outlined, color: gold)), MotionIn(delay: 160, child: _AlertCard(title: 'معرض منتجات قنا', subtitle: 'فعالية محلية · اليوم', icon: Icons.event_outlined, color: deepTeal))];
  }
}
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

class ListingsPage extends StatelessWidget {
  const ListingsPage({super.key});
  @override
  Widget build(BuildContext context) => BasePage(title: 'عندك؟', child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    const Text('اعرض اللي عندك، ودوّر على اللي محتاجه', style: TextStyle(color: muted)),
    const SizedBox(height: 14),
    const TextField(decoration: InputDecoration(prefixIcon: Icon(Icons.search, color: teal), hintText: 'ابحث في الإعلانات')),
    const SizedBox(height: 10),
    const CategoryRail(items: ['للبيع', 'للإيجار', 'وظائف', 'سيارات', 'عقارات']),
    const SizedBox(height: 12),
    MiniItem(icon: Icons.home_outlined, title: 'شقة للإيجار في قنا الجديدة', subtitle: '7,500 جنيه · قنا الجديدة · منذ يوم', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ListingDetailPage(title: 'شقة للإيجار في قنا الجديدة', price: '7,500 جنيه', location: 'قنا الجديدة')))),
    MiniItem(icon: Icons.kitchen_outlined, title: 'ثلاجة بحالة ممتازة', subtitle: '3,500 جنيه · الحميدات · منذ 3 أيام', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ListingDetailPage(title: 'ثلاجة بحالة ممتازة', price: '3,500 جنيه', location: 'الحميدات')))),
    const SizedBox(height: 8),
    FilledButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateListingPage())), icon: const Icon(Icons.add), label: const Text('أضف إعلانًا'), style: FilledButton.styleFrom(backgroundColor: gold, foregroundColor: deepTeal, minimumSize: const Size.fromHeight(48), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)))),
  ]));
}

class CreateListingPage extends StatefulWidget {
  const CreateListingPage({super.key});
  @override
  State<CreateListingPage> createState() => _CreateListingPageState();
}

class ListingDetailPage extends StatelessWidget {
  const ListingDetailPage({super.key, required this.title, required this.price, required this.location});
  final String title;
  final String price;
  final String location;
  @override
  Widget build(BuildContext context) => Directionality(textDirection: TextDirection.rtl, child: Scaffold(appBar: AppBar(title: const Text('تفاصيل الإعلان'), actions: [IconButton(onPressed: () {}, icon: const Icon(Icons.share_outlined)), IconButton(onPressed: () {}, icon: const Icon(Icons.favorite_border))]), body: ListView(padding: const EdgeInsets.all(18), children: [MediaGallery(imageCount: 3, label: 'صور الإعلان', heroTag: 'listing-image-$title'), const SizedBox(height: 16), Row(children: [Expanded(child: Text(title, style: const TextStyle(color: deepTeal, fontSize: 21, fontWeight: FontWeight.w700))), const Chip(label: Text('مراجع'), avatar: Icon(Icons.verified_outlined, size: 16, color: teal), backgroundColor: Color(0xFFE8F5F2))]), const SizedBox(height: 8), Text('$price · $location', style: const TextStyle(color: muted)), const SizedBox(height: 20), Row(children: [Expanded(child: FilledButton.icon(onPressed: () {}, icon: const Icon(Icons.phone_outlined), label: const Text('اتصال'))), const SizedBox(width: 8), Expanded(child: OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.chat_outlined), label: const Text('واتساب')))]), const SizedBox(height: 18), Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [TextButton.icon(onPressed: () {}, icon: const Icon(Icons.thumb_up_alt_outlined), label: const Text('مهتم')), TextButton.icon(onPressed: () {}, icon: const Icon(Icons.bookmark_border), label: const Text('حفظ')), TextButton.icon(onPressed: () {}, icon: const Icon(Icons.ios_share_outlined), label: const Text('مشاركة'))]), const SizedBox(height: 10), const SectionTitle(title: 'الوصف'), const SizedBox(height: 8), const Text('إعلان منشور من مستخدم بعد مراجعة الإدارة. التفاصيل والصور قابلة للتحديث من صاحب الإعلان.', style: TextStyle(color: muted, height: 1.5)), const SizedBox(height: 22), const SectionTitle(title: 'التفاعل'), const SizedBox(height: 8), const MiniItem(icon: Icons.person_outline, title: 'أحمد محمد', subtitle: 'إعلان واضح ومعلوماته كاملة · منذ ساعة'), const SizedBox(height: 10), OutlinedButton.icon(onPressed: () => _report(context), icon: const Icon(Icons.flag_outlined), label: const Text('إبلاغ عن الإعلان'))])));
  void _report(BuildContext context) { showModalBottomSheet<void>(context: context, useSafeArea: true, showDragHandle: true, backgroundColor: paper, sheetAnimationStyle: const AnimationStyle(duration: AppMotion.gentle, reverseDuration: AppMotion.quick), shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))), builder: (_) => Directionality(textDirection: TextDirection.rtl, child: SafeArea(child: Wrap(children: [const Padding(padding: EdgeInsets.all(18), child: Text('سبب الإبلاغ', style: TextStyle(color: deepTeal, fontSize: 18, fontWeight: FontWeight.w700))), ...['السعر غير صحيح', 'محتوى مخالف', 'إعلان مكرر', 'سبب آخر'].map((x) => ListTile(title: Text(x), leading: const Icon(Icons.radio_button_unchecked, color: teal), onTap: () => Navigator.pop(context)))])))); }
}

class _CreateListingPageState extends State<CreateListingPage> {
  int step = 0;
  String category = 'للبيع';
  final title = TextEditingController();
  final price = TextEditingController();
  final description = TextEditingController();
  @override
  void dispose() { title.dispose(); price.dispose(); description.dispose(); super.dispose(); }
  void next() { if (step < 2) { setState(() => step++); } else { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إرسال الإعلان للمراجعة'))); } }
  @override
  Widget build(BuildContext context) => Directionality(textDirection: TextDirection.rtl, child: Scaffold(
    appBar: AppBar(title: const Text('إضافة إعلان')),
    body: ListView(padding: const EdgeInsets.fromLTRB(18, 10, 18, 24), children: [
      Text('${step + 1} من 3', style: const TextStyle(color: muted)),
      const SizedBox(height: 7),
      LinearProgressIndicator(value: (step + 1) / 3, minHeight: 5, borderRadius: BorderRadius.circular(8), color: teal, backgroundColor: const Color(0xFFDDE9E7)),
      const SizedBox(height: 22),
      AnimatedSwitcher(duration: AppMotion.standard, child: KeyedSubtree(key: ValueKey(step), child: _body())),
      const SizedBox(height: 24),
      FilledButton(onPressed: next, style: FilledButton.styleFrom(backgroundColor: teal, minimumSize: const Size.fromHeight(50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))), child: Text(step == 2 ? 'إرسال للمراجعة' : 'التالي')),
    ]),
  ));
  Widget _body() {
    if (step == 0) return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [const Text('بيانات الإعلان', style: TextStyle(color: deepTeal, fontSize: 20, fontWeight: FontWeight.w700)), const SizedBox(height: 10), const Text('اختار نوع الإعلان واكتب البيانات الأساسية.', style: TextStyle(color: muted)), const SizedBox(height: 18), const Text('القسم', style: TextStyle(color: deepTeal, fontWeight: FontWeight.w700)), const SizedBox(height: 8), Wrap(spacing: 8, children: ['للبيع', 'للإيجار', 'وظائف', 'سيارات', 'عقارات'].map((x) => ChoiceChip(label: Text(x), selected: category == x, onSelected: (_) => setState(() => category = x), selectedColor: const Color(0xFFD8EFEC))).toList()), const SizedBox(height: 18), TextField(controller: title, decoration: const InputDecoration(labelText: 'عنوان الإعلان', hintText: 'مثال: شقة غرفتين للإيجار')), const SizedBox(height: 12), TextField(controller: price, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'السعر *', hintText: 'السعر بالجنيه المصري'))]);
    if (step == 1) return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [const Text('صور ووصف', style: TextStyle(color: deepTeal, fontSize: 20, fontWeight: FontWeight.w700)), const SizedBox(height: 10), const Text('أضف صورة واضحة واحدة على الأقل، وبحد أقصى 5 صور.', style: TextStyle(color: muted)), const SizedBox(height: 16), OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.add_a_photo_outlined), label: const Text('إضافة صور')), const SizedBox(height: 12), TextField(controller: description, maxLines: 5, decoration: const InputDecoration(labelText: 'وصف الإعلان', hintText: 'اكتب التفاصيل المهمة'))]);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [const Text('المراجعة والإرسال', style: TextStyle(color: deepTeal, fontSize: 20, fontWeight: FontWeight.w700)), const SizedBox(height: 10), const Text('إعلانك سيظهر بعد مراجعة الإدارة والتأكد من السعر والصور.', style: TextStyle(color: muted, height: 1.5)), const SizedBox(height: 18), Card(elevation: 0, color: Colors.white, child: ListTile(title: Text(title.text.isEmpty ? 'عنوان الإعلان' : title.text, style: const TextStyle(fontWeight: FontWeight.w700)), subtitle: Text('${price.text.isEmpty ? 'السعر غير مكتوب' : price.text} · $category'))), const SizedBox(height: 12), const Text('بإرسال الإعلان أنت توافق على مراجعته قبل النشر.', style: TextStyle(color: muted, fontSize: 12))]);
}
}

class MediaGallery extends StatefulWidget {
  const MediaGallery({super.key, required this.imageCount, this.label, this.heroTag});
  final int imageCount;
  final String? label;
  final String? heroTag;
  @override
  State<MediaGallery> createState() => _MediaGalleryState();
}

class _MediaGalleryState extends State<MediaGallery> with SingleTickerProviderStateMixin {
  late final PageController controller = PageController();
  late final AnimationController hintController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..repeat(reverse: true);
  int active = 0;
  bool showSwipeHint = true;
  final galleryColors = const [Color(0xFFD8EFEC), Color(0xFFEFE5C8), Color(0xFFDDE5EA), Color(0xFFE9DDE9), Color(0xFFE8F0EE)];
  @override
  void dispose() { controller.dispose(); hintController.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => Column(children: [
    SizedBox(height: 205, child: PageView.builder(controller: controller, itemCount: widget.imageCount, onPageChanged: (value) => setState(() { active = value; showSwipeHint = false; }), itemBuilder: (_, index) {
      final image = Container(decoration: BoxDecoration(color: galleryColors[index % galleryColors.length], borderRadius: BorderRadius.circular(20)), child: Stack(children: [Center(child: Icon(Icons.image_outlined, color: deepTeal.withValues(alpha: .45), size: 54)), PositionedDirectional(top: 12, end: 12, child: Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5), decoration: BoxDecoration(color: Colors.white.withValues(alpha: .85), borderRadius: BorderRadius.circular(14)), child: Text('${index + 1} / ${widget.imageCount}', style: const TextStyle(color: deepTeal, fontSize: 12, fontWeight: FontWeight.w700))))]));
      if (widget.heroTag == null) return image;
      return Hero(tag: widget.heroTag!, child: image);
    })),
    const SizedBox(height: 8),
    const SizedBox(height: 5),
    AnimatedBuilder(animation: hintController, builder: (_, value) {
      final dots = [for (var i = 0; i < widget.imageCount; i++) AnimatedContainer(duration: AppMotion.quick, width: i == active ? 18 : 6, height: 6, margin: const EdgeInsets.symmetric(horizontal: 3), decoration: BoxDecoration(color: i == active ? teal : const Color(0xFFD6E3E0), borderRadius: BorderRadius.circular(8)))];
      final midpoint = dots.length ~/ 2;
      return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        ...dots.take(midpoint),
        const SizedBox(width: 4),
        AnimatedSwitcher(duration: AppMotion.standard, transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: ScaleTransition(scale: animation, child: child)), child: showSwipeHint ? Transform.translate(key: const ValueKey('swipe-hint'), offset: Offset(-4 * hintController.value, 0), child: const Icon(Icons.swipe, color: teal, size: 17)) : const SizedBox(key: ValueKey('swipe-hidden'), width: 17, height: 17)),
        const SizedBox(width: 4),
        ...dots.skip(midpoint),
      ]);
    }),
  ]);
}

class AccountPage extends StatelessWidget {
  const AccountPage({super.key});
  @override
  Widget build(BuildContext context) => Directionality(textDirection: TextDirection.rtl, child: Scaffold(
    appBar: AppBar(title: const Text('حسابي'), actions: [IconButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsPage())), icon: const Icon(Icons.settings_outlined))]),
    body: ListView(padding: const EdgeInsets.all(18), children: [
      Card(elevation: 0, color: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)), child: const ListTile(contentPadding: EdgeInsets.all(14), leading: CircleAvatar(radius: 25, backgroundColor: deepTeal, child: Text('م', style: TextStyle(color: Colors.white, fontSize: 18))), title: Text('محمد أحمد', style: TextStyle(fontWeight: FontWeight.w700)), subtitle: Text('قناوي رايق · 74 نقطة', style: TextStyle(color: teal)), trailing: Icon(Icons.chevron_left))),
      const SizedBox(height: 10),
      _AccountTile(icon: Icons.notifications_none, title: 'الإشعارات', subtitle: '3 إشعارات جديدة', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsPage()))),
      _AccountTile(icon: Icons.favorite_border, title: 'المفضلة', onTap: () {}),
      _AccountTile(icon: Icons.rate_review_outlined, title: 'تقييماتي ومساهماتي', onTap: () {}),
      _AccountTile(icon: Icons.campaign_outlined, title: 'إعلاناتي', onTap: () {}),
      const Divider(height: 26),
      _AccountTile(icon: Icons.settings_outlined, title: 'الإعدادات', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsPage()))),
      _AccountTile(icon: Icons.help_outline, title: 'المساعدة والدعم', onTap: () {}),
      _AccountTile(icon: Icons.delete_outline, title: 'حذف الحساب', onTap: () {}, destructive: true),
    ]),
  ));
}

class _AccountTile extends StatelessWidget {
  const _AccountTile({required this.icon, required this.title, required this.onTap, this.subtitle, this.destructive = false});
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final bool destructive;
  @override
  Widget build(BuildContext context) => ListTile(onTap: onTap, contentPadding: const EdgeInsets.symmetric(horizontal: 4), leading: Icon(icon, color: destructive ? Colors.redAccent : teal), title: Text(title, style: TextStyle(color: destructive ? Colors.redAccent : ink)), subtitle: subtitle == null ? null : Text(subtitle!, style: const TextStyle(color: muted, fontSize: 12)), trailing: const Icon(Icons.chevron_left, color: muted));
}

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});
  @override
  Widget build(BuildContext context) => Directionality(textDirection: TextDirection.rtl, child: Scaffold(
    appBar: AppBar(title: const Text('الإشعارات'), actions: [TextButton(onPressed: () {}, child: const Text('تحديد الكل'))]),
    body: ListView(padding: const EdgeInsets.all(18), children: [
      const Text('الجديد', style: TextStyle(color: deepTeal, fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      const MotionIn(child: _NotificationCard(icon: Icons.local_offer_outlined, title: 'عرض جديد قريب منك', subtitle: 'خصم خاص لأهل قنا · منذ 10 دقائق', unread: true)),
      const MotionIn(delay: 80, child: _NotificationCard(icon: Icons.thumb_up_alt_outlined, title: 'تفاعل مع مساهمتك', subtitle: '12 شخص اعتبروا تقييمك مفيدًا · منذ ساعة', unread: true)),
      const SizedBox(height: 16),
      const Text('أقدم', style: TextStyle(color: deepTeal, fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      const MotionIn(delay: 160, child: _NotificationCard(icon: Icons.bolt_outlined, title: 'تحديث في منطقتك', subtitle: 'تم تأكيد فتح شارع جديد · أمس')),
    ]),
  ));
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.icon, required this.title, required this.subtitle, this.unread = false});
  final IconData icon;
  final String title;
  final String subtitle;
  final bool unread;
  @override
  Widget build(BuildContext context) => Card(elevation: 0, margin: const EdgeInsets.only(bottom: 8), color: unread ? const Color(0xFFEFF8F6) : Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: const BorderSide(color: Color(0xFFE0E8E6))), child: ListTile(leading: CircleAvatar(backgroundColor: const Color(0xFFD8EFEC), child: Icon(icon, color: deepTeal)), title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)), subtitle: Text(subtitle, style: const TextStyle(color: muted, fontSize: 12)), trailing: unread ? TweenAnimationBuilder<double>(tween: Tween(begin: .55, end: 1), duration: AppMotion.gentle, curve: Curves.easeOutBack, builder: (_, value, child) => Transform.scale(scale: value, child: child), child: const Icon(Icons.circle, size: 9, color: teal)) : null));
}

class AddActivityPage extends StatefulWidget {
  const AddActivityPage({super.key});
  @override
  State<AddActivityPage> createState() => _AddActivityPageState();
}

class _AddActivityPageState extends State<AddActivityPage> {
  final formKey = GlobalKey<FormState>();
  final api = ApiClient();
  final name = TextEditingController();
  final description = TextEditingController();
  final address = TextEditingController();
  final phone = TextEditingController();
  final whatsapp = TextEditingController();
  String? areaId;
  String? categoryId;
  String mode = 'LOCAL';
  String phoneType = 'BUSINESS';
  String opening = '09:00';
  String closing = '22:00';
  int imageCount = 1;
  final selectedImages = <XFile>[];
  bool preview = false;
  late Future<List<AreaOption>> areas;
  late Future<List<CategoryOption>> categories;

  @override
  void initState() { super.initState(); areas = api.fetchAreas(); categories = api.fetchCategories(); }
  @override
  void dispose() { for (final controller in [name, description, address, phone, whatsapp]) { controller.dispose(); } super.dispose(); }

  @override
  Widget build(BuildContext context) => Directionality(textDirection: TextDirection.rtl, child: Scaffold(
    appBar: AppBar(title: Text(preview ? 'مراجعة النشاط' : 'أضف نشاط')),
    body: Form(key: formKey, child: ListView(padding: const EdgeInsets.fromLTRB(18, 10, 18, 24), children: [
      if (!preview) ...[_intro(), _fields()] else ...[_previewCard(), const SizedBox(height: 14), const Text('سيظهر النشاط بعد مراجعة الإدارة فقط، وسيحمل شارة «مضاف من المجتمع».', style: TextStyle(color: muted, height: 1.5))],
      const SizedBox(height: 22),
      FilledButton(onPressed: preview ? _submit : _review, style: FilledButton.styleFrom(backgroundColor: teal, minimumSize: const Size.fromHeight(52), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))), child: Text(preview ? 'إرسال للمراجعة' : 'معاينة النشاط')),
      if (preview) TextButton(onPressed: () => setState(() => preview = false), child: const Text('تعديل البيانات')),
    ])),
  ));

  Widget _intro() => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: const [Text('ساعد أهل قنا يعرفوا نشاطك', style: TextStyle(color: deepTeal, fontSize: 22, fontWeight: FontWeight.w700)), SizedBox(height: 6), Text('أضف البيانات الأساسية، وإحنا نراجعها قبل ما تظهر للجمهور.', style: TextStyle(color: muted)), SizedBox(height: 18)]);

  Widget _fields() => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    TextFormField(controller: name, decoration: const InputDecoration(labelText: 'اسم النشاط *'), validator: (value) => value == null || value.trim().length < 2 ? 'اكتب اسم النشاط' : null),
    const SizedBox(height: 12),
    FutureBuilder<List<CategoryOption>>(future: categories, builder: (_, snapshot) => DropdownButtonFormField<String>(initialValue: categoryId, decoration: const InputDecoration(labelText: 'نوع النشاط *'), items: (snapshot.data ?? const []).map((item) => DropdownMenuItem(value: item.id, child: Text(item.name))).toList(), onChanged: (value) => setState(() => categoryId = value), validator: (value) => value == null ? 'اختار نوع النشاط' : null)),
    const SizedBox(height: 12),
    SegmentedButton<String>(segments: const [ButtonSegment(value: 'LOCAL', label: Text('محلي'), icon: Icon(Icons.storefront_outlined)), ButtonSegment(value: 'ONLINE', label: Text('أونلاين'), icon: Icon(Icons.language))], selected: {mode}, onSelectionChanged: (value) => setState(() => mode = value.first)),
    const SizedBox(height: 12),
    FutureBuilder<List<AreaOption>>(future: areas, builder: (_, snapshot) => DropdownButtonFormField<String>(initialValue: areaId, decoration: const InputDecoration(labelText: 'المنطقة *'), items: (snapshot.data ?? const []).map((item) => DropdownMenuItem(value: item.id, child: Text(item.name))).toList(), onChanged: mode == 'ONLINE' ? null : (value) => setState(() => areaId = value), validator: (value) => mode == 'ONLINE' || value != null ? null : 'اختار المنطقة')),
    const SizedBox(height: 12),
    if (mode == 'LOCAL') TextFormField(controller: address, decoration: const InputDecoration(labelText: 'العنوان بالتفصيل *'), validator: (value) => mode == 'LOCAL' && (value == null || value.trim().isEmpty) ? 'اكتب العنوان' : null),
    if (mode == 'LOCAL') const SizedBox(height: 12),
    TextFormField(controller: description, maxLines: 3, decoration: const InputDecoration(labelText: 'وصف مختصر', hintText: 'اكتب للناس نشاطك بيقدم إيه')),
    const SizedBox(height: 12),
    TextFormField(controller: phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'رقم الهاتف *'), validator: (value) => value == null || !RegExp(r'^01[0125][0-9]{8}$').hasMatch(value) ? 'اكتب رقم مصري صحيح' : null),
    const SizedBox(height: 12),
    SegmentedButton<String>(segments: const [ButtonSegment(value: 'BUSINESS', label: Text('رقم نشاط')), ButtonSegment(value: 'PERSONAL', label: Text('رقم شخصي'))], selected: {phoneType}, onSelectionChanged: (value) => setState(() => phoneType = value.first)),
    const SizedBox(height: 12),
    TextFormField(controller: whatsapp, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'واتساب (اختياري)')),
    const SizedBox(height: 14),
    if (mode == 'LOCAL') Row(children: [const Expanded(child: Text('مواعيد العمل', style: TextStyle(color: deepTeal, fontWeight: FontWeight.w700))), TextButton(onPressed: () => _pickTime(true), child: Text(opening)), const Text('–'), TextButton(onPressed: () => _pickTime(false), child: Text(closing))]),
    const SizedBox(height: 8),
    Row(children: [Expanded(child: Text('الصور ${selectedImages.isEmpty ? imageCount : selectedImages.length} / 10', style: const TextStyle(color: deepTeal, fontWeight: FontWeight.w700))), IconButton(onPressed: selectedImages.length >= 10 ? null : _pickImages, icon: const Icon(Icons.add_a_photo_outlined, color: teal))]),
    if (selectedImages.isNotEmpty) SizedBox(height: 76, child: ListView.separated(scrollDirection: Axis.horizontal, itemCount: selectedImages.length, separatorBuilder: (_, index) => const SizedBox(width: 8), itemBuilder: (_, index) => ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(File(selectedImages[index].path), width: 76, height: 76, fit: BoxFit.cover)))),
    Text(selectedImages.isEmpty ? 'أضف من 1 إلى 10 صور واضحة للنشاط.' : 'تم اختيار ${selectedImages.length} صور — الصورة الأولى هي الغلاف.', style: const TextStyle(color: muted, fontSize: 12)),
  ]);

  Future<void> _pickTime(bool isOpening) async {
    final picked = await showTimePicker(context: context, initialTime: TimeOfDay(hour: int.parse((isOpening ? opening : closing).split(':').first), minute: 0));
    if (picked != null) {
      setState(() { final value = picked.format(context); if (isOpening) { opening = value; } else { closing = value; } });
    }
  }
  Future<void> _pickImages() async { final picked = await ImagePicker().pickMultiImage(imageQuality: 82, maxWidth: 1600); if (!mounted || picked.isEmpty) return; setState(() { selectedImages..clear()..addAll(picked.take(10)); imageCount = selectedImages.length; }); }
  void _review() { if (formKey.currentState?.validate() ?? false) setState(() => preview = true); }
  Widget _previewCard() => Card(elevation: 0, color: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: const BorderSide(color: Color(0xFFE0E8E6))), child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [Container(height: 130, decoration: BoxDecoration(color: const Color(0xFFD8EFEC), borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.image_outlined, color: deepTeal, size: 52)), const SizedBox(height: 14), Text(name.text, style: const TextStyle(color: deepTeal, fontSize: 20, fontWeight: FontWeight.w700)), const SizedBox(height: 6), Text('${mode == 'LOCAL' ? 'محلي' : 'أونلاين'} · ${phoneType == 'BUSINESS' ? 'رقم نشاط' : 'رقم شخصي'}', style: const TextStyle(color: teal)), if (address.text.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 6), child: Text(address.text, style: const TextStyle(color: muted))), if (description.text.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 10), child: Text(description.text, style: const TextStyle(color: ink, height: 1.4))), const SizedBox(height: 12), const Row(children: [Icon(Icons.hourglass_top_outlined, size: 16, color: gold), SizedBox(width: 5), Text('بانتظار مراجعة الإدارة', style: TextStyle(color: muted, fontSize: 12))])])));
  Future<void> _submit() async { try { final category = categoryId; if (category == null) return; final resolvedArea = areaId ?? (await areas).first.id; await api.submitProvider(data: {'name': name.text.trim(), 'description': description.text.trim(), 'phone': phone.text.trim(), 'whatsapp': whatsapp.text.trim().isEmpty ? null : whatsapp.text.trim(), 'phoneType': phoneType, 'serviceMode': mode, 'areaId': resolvedArea, 'categoryIds': [category], 'openingTime': opening, 'closingTime': closing, 'address': address.text.trim(), 'images': List.generate(imageCount, (index) => {'url': 'https://placehold.co/800x600/png?text=Hena+Qena', 'kind': index == 0 ? 'cover' : 'gallery'})}); if (!mounted) return; Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إرسال النشاط للمراجعة'))); } catch (error) { if (!mounted) return; ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString().contains('duplicate') ? 'النشاط موجود بالفعل أو قيد المراجعة' : 'تعذر إرسال النشاط حالياً'))); } }
}

class CommunityRequestPage extends StatefulWidget {
  const CommunityRequestPage({super.key, required this.kind});
  final String kind;
  @override
  State<CommunityRequestPage> createState() => _CommunityRequestPageState();
}

class _CommunityRequestPageState extends State<CommunityRequestPage> {
  final api = ApiClient();
  final name = TextEditingController();
  final phone = TextEditingController();
  final note = TextEditingController();
  @override
  void dispose() { name.dispose(); phone.dispose(); note.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => Directionality(textDirection: TextDirection.rtl, child: Scaffold(appBar: AppBar(title: Text(widget.kind == 'CLAIM' ? 'أملك نشاط' : 'أبلغ عن نشاط')), body: ListView(padding: const EdgeInsets.all(18), children: [Text(widget.kind == 'CLAIM' ? 'أثبت ملكيتك لنشاط موجود' : 'ساعدنا نراجع بيانات نشاط', style: const TextStyle(color: deepTeal, fontSize: 21, fontWeight: FontWeight.w700)), const SizedBox(height: 8), Text(widget.kind == 'CLAIM' ? 'اكتب بيانات النشاط وهنراجع الطلب مع الإدارة.' : 'اكتب اسم النشاط وسبب البلاغ، ولن يظهر البلاغ للجمهور.', style: const TextStyle(color: muted, height: 1.5)), const SizedBox(height: 22), TextField(controller: name, decoration: const InputDecoration(labelText: 'اسم النشاط *')), const SizedBox(height: 12), TextField(controller: phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'رقم الهاتف (اختياري)')), const SizedBox(height: 12), TextField(controller: note, maxLines: 5, decoration: InputDecoration(labelText: widget.kind == 'CLAIM' ? 'معلومة تساعدنا في التحقق' : 'سبب البلاغ')), const SizedBox(height: 22), FilledButton(onPressed: _submit, style: FilledButton.styleFrom(backgroundColor: teal, minimumSize: const Size.fromHeight(52), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))), child: const Text('إرسال للمراجعة'))])));
  Future<void> _submit() async { if (name.text.trim().length < 2) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('اكتب اسم النشاط'))); return; } try { await api.submitProviderReport(data: {'kind': widget.kind, 'name': name.text.trim(), 'phone': phone.text.trim().isEmpty ? null : phone.text.trim(), 'note': note.text.trim().isEmpty ? null : note.text.trim()}); if (!mounted) return; Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إرسال الطلب للمراجعة'))); } catch (_) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر إرسال الطلب حالياً'))); } }
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool allNotifications = true;
  bool areaOnly = false;
  bool privateProfile = false;
  @override
  Widget build(BuildContext context) => Directionality(textDirection: TextDirection.rtl, child: Scaffold(
    appBar: AppBar(title: const Text('الإعدادات')),
    body: ListView(padding: const EdgeInsets.all(18), children: [
      Card(elevation: 0, color: const Color(0xFFE8F5F2), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), child: ListTile(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddActivityPage())), leading: const CircleAvatar(backgroundColor: teal, child: Icon(Icons.add_business_outlined, color: Colors.white)), title: const Text('أضف نشاط', style: TextStyle(color: deepTeal, fontWeight: FontWeight.w700)), subtitle: const Text('ساعدنا نضيف نشاط موثوق لقنا', style: TextStyle(color: muted)), trailing: const Icon(Icons.chevron_left, color: deepTeal))),
      const SizedBox(height: 18),
      _AccountTile(icon: Icons.verified_user_outlined, title: 'أملك نشاط', subtitle: 'اطلب إثبات ملكية نشاط موجود', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CommunityRequestPage(kind: 'CLAIM')))),
      _AccountTile(icon: Icons.flag_outlined, title: 'أبلغ عن نشاط', subtitle: 'أرسل ملاحظة للإدارة للمراجعة', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CommunityRequestPage(kind: 'REPORT')))),
      const Divider(height: 26),
      const Text('الإشعارات', style: TextStyle(color: deepTeal, fontWeight: FontWeight.w700)),
      SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('كل الإشعارات'), value: allNotifications, onChanged: (value) => setState(() => allNotifications = value), activeThumbColor: teal),
      SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('إشعارات منطقتي فقط'), value: areaOnly, onChanged: (value) => setState(() => areaOnly = value), activeThumbColor: teal),
      const Divider(height: 26),
      const Text('الخصوصية', style: TextStyle(color: deepTeal, fontWeight: FontWeight.w700)),
      SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('جعل صفحتي خاصة'), subtitle: const Text('مساهماتك تظل ظاهرة باسمك', style: TextStyle(color: muted, fontSize: 12)), value: privateProfile, onChanged: (value) => setState(() => privateProfile = value), activeThumbColor: teal),
      const Divider(height: 26),
      const ListTile(contentPadding: EdgeInsets.zero, leading: Icon(Icons.location_on_outlined, color: teal), title: Text('المناطق المختارة'), subtitle: Text('قنا كلها', style: TextStyle(color: muted))),
      const ListTile(contentPadding: EdgeInsets.zero, leading: Icon(Icons.language, color: teal), title: Text('اللغة'), subtitle: Text('العربية', style: TextStyle(color: muted))),
    ]),
  ));
}
