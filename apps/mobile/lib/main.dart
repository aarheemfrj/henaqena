import 'dart:io';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'core/auth/auth_session.dart';
import 'core/platform/app_actions.dart';
import 'core/theme/app_theme.dart';
import 'core/network/api_client.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AuthSession.restore();
  runApp(const HenaQenaApp());
}

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
        colorScheme:
            ColorScheme.fromSeed(
              seedColor: teal,
              brightness: Brightness.light,
            ).copyWith(
              primary: teal,
              onPrimary: Colors.white,
              secondary: gold,
              surface: Colors.white,
              onSurface: ink,
            ),
        fontFamily: 'Tajawal',
        textTheme: const TextTheme(
          headlineMedium: TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.w700,
            color: deepTeal,
          ),
          headlineSmall: TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.w700,
            color: deepTeal,
          ),
          titleLarge: TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.w700,
            color: deepTeal,
          ),
          titleMedium: TextStyle(fontWeight: FontWeight.w500, color: ink),
          bodyLarge: TextStyle(fontWeight: FontWeight.w400, color: ink),
          bodyMedium: TextStyle(fontWeight: FontWeight.w400, color: ink),
          labelLarge: TextStyle(fontWeight: FontWeight.w500),
        ),
        navigationBarTheme: NavigationBarThemeData(
          labelTextStyle: WidgetStatePropertyAll(
            TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: muted,
            ),
          ),
          height: 72,
        ),
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: SmoothPageTransitionsBuilder(),
            TargetPlatform.iOS: SmoothPageTransitionsBuilder(),
            TargetPlatform.macOS: SmoothPageTransitionsBuilder(),
          },
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: paper,
          foregroundColor: deepTeal,
          elevation: 0,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          hintStyle: const TextStyle(color: muted),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFE0E8E6)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: teal, width: 1.5),
          ),
        ),
      ),
      home: AuthSession.isSignedIn ? const HomeShell() : const WelcomeScreen(),
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
      decoration: BoxDecoration(
        color: dark ? Colors.white.withValues(alpha: .12) : Colors.white,
        borderRadius: BorderRadius.circular(size * .28),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.location_on_outlined,
            size: size * .72,
            color: dark ? Colors.white : deepTeal,
          ),
          Container(
            width: size * .18,
            height: size * .18,
            decoration: const BoxDecoration(
              color: gold,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  void _begin(BuildContext context) => Navigator.of(
    context,
  ).pushReplacement(MaterialPageRoute(builder: (_) => const SetupFlow()));

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),
                Center(
                  child: Column(
                    children: [
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: .86, end: 1),
                        duration: AppMotion.gentle,
                        curve: Curves.easeOutBack,
                        builder: (_, value, child) =>
                            Transform.scale(scale: value, child: child),
                        child: const LogoMark(size: 82),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'هنا قنا',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              color: deepTeal,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'أهلًا بيك.. قنا كلها هنا',
                        style: TextStyle(color: muted, fontSize: 16),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: () => _begin(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: teal,
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'ابدأ الآن',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: () => Navigator.of(
                    context,
                  ).push(MaterialPageRoute(builder: (_) => const AuthPage())),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: deepTeal,
                    minimumSize: const Size.fromHeight(52),
                    side: const BorderSide(color: teal),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'تسجيل الدخول',
                    style: TextStyle(fontSize: 15),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const HomeShell()),
                  ),
                  child: const Text(
                    'التكملة كزائر',
                    style: TextStyle(color: deepTeal),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'كل ما تحتاجه.. قريب منك',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: muted, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AuthPage extends StatefulWidget {
  const AuthPage({super.key, this.createAccount = false});
  final bool createAccount;

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final formKey = GlobalKey<FormState>();
  final api = ApiClient();
  final name = TextEditingController();
  final phone = TextEditingController();
  final password = TextEditingController();
  final email = TextEditingController();
  late bool createAccount;
  bool submitting = false;

  @override
  void initState() {
    super.initState();
    createAccount = widget.createAccount;
  }

  @override
  void dispose() {
    for (final controller in [name, phone, password, email]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> submit() async {
    if (!(formKey.currentState?.validate() ?? false)) return;
    setState(() => submitting = true);
    try {
      if (createAccount) {
        await api.register(
          name: name.text.trim(),
          phone: phone.text.trim(),
          password: password.text,
          email: email.text.trim(),
        );
      } else {
        await api.login(phone: phone.text.trim(), password: password.text);
      }
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeShell()),
        (_) => false,
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.toString().contains('invalid_credentials')
                ? 'رقم الهاتف أو كلمة المرور غير صحيحين'
                : 'تعذر إتمام الدخول حالياً',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      appBar: AppBar(
        title: Text(createAccount ? 'إنشاء حساب' : 'تسجيل الدخول'),
      ),
      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              createAccount
                  ? 'أهلاً بيك في مجتمع هنا قنا'
                  : 'سجّل دخولك عشان تقدر تضيف وتتابع مساهماتك',
              style: const TextStyle(
                color: deepTeal,
                fontSize: 21,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),
            if (createAccount) ...[
              TextFormField(
                controller: name,
                decoration: const InputDecoration(labelText: 'الاسم الحقيقي *'),
                validator: (value) => value == null || value.trim().length < 2
                    ? 'اكتب اسمك'
                    : null,
              ),
              const SizedBox(height: 12),
            ],
            TextFormField(
              controller: phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'رقم الموبايل المصري *',
              ),
              validator: (value) =>
                  value == null ||
                      !RegExp(r'^01[0125][0-9]{8}$').hasMatch(value)
                  ? 'اكتب رقم مصري صحيح'
                  : null,
            ),
            const SizedBox(height: 12),
            if (createAccount) ...[
              TextFormField(
                controller: email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'البريد الإلكتروني (اختياري)',
                ),
              ),
              const SizedBox(height: 12),
            ],
            TextFormField(
              controller: password,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'كلمة المرور *'),
              validator: (value) => value == null || value.length < 8
                  ? 'كلمة المرور 8 حروف على الأقل'
                  : null,
            ),
            const SizedBox(height: 22),
            FilledButton(
              onPressed: submitting ? null : submit,
              style: FilledButton.styleFrom(
                backgroundColor: teal,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                submitting
                    ? 'جارٍ المتابعة…'
                    : createAccount
                    ? 'إنشاء الحساب'
                    : 'دخول',
              ),
            ),
            TextButton(
              onPressed: submitting
                  ? null
                  : () => setState(() => createAccount = !createAccount),
              child: Text(
                createAccount ? 'عندي حساب بالفعل' : 'إنشاء حساب جديد',
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class ContributionsPage extends StatefulWidget {
  const ContributionsPage({super.key});
  @override
  State<ContributionsPage> createState() => _ContributionsPageState();
}

class _ContributionsPageState extends State<ContributionsPage> {
  late Future<Map<String, dynamic>> contributions = ApiClient()
      .fetchContributions();
  Future<void> _reload() async =>
      setState(() => contributions = ApiClient().fetchContributions());
  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      appBar: AppBar(
        title: const Text('مساهماتي'),
        actions: [
          IconButton(onPressed: _reload, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: contributions,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator(color: teal));
          final data = snapshot.data ?? {};
          final providers = (data['providers'] as List<dynamic>? ?? []);
          final listings = (data['listings'] as List<dynamic>? ?? []);
          final reviews = (data['reviews'] as List<dynamic>? ?? []);
          final reports = (data['reports'] as List<dynamic>? ?? []);
          return RefreshIndicator(
            onRefresh: _reload,
            color: teal,
            child: ListView(
              padding: const EdgeInsets.all(18),
              children: [
                Text(
                  'الأنشطة: ${providers.length}',
                  style: const TextStyle(
                    color: deepTeal,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                ...providers.map(
                  (item) => _ContributionTile(
                    title: item['name'] as String,
                    subtitle:
                        '${item['area']?['name'] ?? 'قنا'} · ${item['status']}',
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'الإعلانات: ${listings.length}',
                  style: const TextStyle(
                    color: deepTeal,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                ...listings.map(
                  (item) => _ContributionTile(
                    title: item['title'] as String,
                    subtitle: '${item['price']} جنيه · ${item['status']}',
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'التقييمات: ${reviews.length}',
                  style: const TextStyle(
                    color: deepTeal,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                ...reviews.map(
                  (item) => _ContributionTile(
                    title: item['provider']?['name'] as String? ?? 'تقييم',
                    subtitle: item['status'] as String? ?? 'قيد المراجعة',
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'البلاغات: ${reports.length}',
                  style: const TextStyle(
                    color: deepTeal,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                ...reports.map(
                  (item) => _ContributionTile(
                    title:
                        item['provider']?['name'] as String? ??
                        item['name'] as String,
                    subtitle: item['status'] as String? ?? 'قيد المراجعة',
                  ),
                ),
              ],
            ),
          );
        },
      ),
    ),
  );
}

class _ContributionTile extends StatelessWidget {
  const _ContributionTile({required this.title, required this.subtitle});
  final String title;
  final String subtitle;
  @override
  Widget build(BuildContext context) => Card(
    elevation: 0,
    margin: const EdgeInsets.only(top: 7),
    child: ListTile(
      title: Text(title),
      subtitle: Text(subtitle, style: const TextStyle(color: muted)),
      trailing: const Icon(Icons.chevron_left, color: teal),
    ),
  );
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
  final areaOptions = [
    'قنا كلها',
    'وسط البلد',
    'مدينة العمال',
    'الشؤون',
    'المساكن',
    'نجع سعيد',
    'المعنى',
    'الحميدات',
    'الأحوال',
    'عمر فندي',
    'المنشية',
  ];
  final interestOptions = [
    'خدمات طبية',
    'مطاعم وكافيهات',
    'صيانة وفنيين',
    'سوبر ماركت',
    'تعليم ودروس',
    'ترفيه ومناسبات',
    'عقارات',
    'سيارات',
  ];

  Future<void> _useCurrentLocation() async {
    try {
      await AppActions.currentPosition();
      if (!mounted) return;
      setState(() {
        areas
          ..clear()
          ..add('قنا كلها');
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم تحديد موقعك، وهنعرض الأقرب داخل مدينة قنا'),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('فعّل خدمة الموقع واسمح للتطبيق باستخدامها'),
        ),
      );
    }
  }

  void next() {
    if (step < 3) {
      setState(() => step++);
    } else {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const HomeShell()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final titles = [
      'اختار منطقتك',
      'خلّينا نعرفك أكتر',
      'إيه اللي يهمك؟',
      'جاهز تبدأ؟',
    ];
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text('${step + 1} من 4', style: const TextStyle(fontSize: 14)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const HomeShell()),
              ),
              child: const Text('تخطي'),
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LinearProgressIndicator(
                value: (step + 1) / 4,
                minHeight: 5,
                borderRadius: BorderRadius.circular(8),
                color: teal,
                backgroundColor: const Color(0xFFDDE9E7),
              ),
              const SizedBox(height: 28),
              Text(
                titles[step],
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: deepTeal,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                step == 0
                    ? 'اختار الأماكن اللي بتتواجد فيها علشان نرشح لك الأقرب.'
                    : step == 1
                    ? 'اختيارات بسيطة تساعدنا نحسن الترشيحات. تقدر تتخطاها.'
                    : step == 2
                    ? 'اختار لحد 5 اهتمامات، وإحنا نرتب لك الفئات.'
                    : 'اختار طريقة الدخول المناسبة ليك.',
                style: const TextStyle(color: muted, height: 1.5),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: AnimatedSwitcher(
                  duration: AppMotion.standard,
                  switchInCurve: Curves.easeOutCubic,
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(.035, 0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  ),
                  child: KeyedSubtree(key: ValueKey(step), child: _stepBody()),
                ),
              ),
              FilledButton(
                onPressed: next,
                style: FilledButton.styleFrom(
                  backgroundColor: teal,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(step == 3 ? 'دخول للتطبيق' : 'كمّل'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stepBody() {
    if (step == 0) {
      return ListView(
        children: [
          OutlinedButton.icon(
            onPressed: _useCurrentLocation,
            icon: const Icon(Icons.my_location_outlined),
            label: const Text('استخدم موقعي الحالي'),
            style: OutlinedButton.styleFrom(
              foregroundColor: deepTeal,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.all(15),
              side: const BorderSide(color: teal),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          const SizedBox(height: 10),
          ...areaOptions.map(
            (area) => _choiceTile(
              area,
              areas.contains(area),
              () => setState(() {
                if (areas.contains(area)) {
                  areas.remove(area);
                } else if (areas.length < 3) {
                  areas.add(area);
                }
              }),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'تحديثات قادمة: مناطق سنضيفها قريبًا',
              style: TextStyle(color: muted, fontSize: 12),
            ),
          ),
        ],
      );
    }
    if (step == 1) {
      return ListView(
        children: [
          const Text(
            'السن',
            style: TextStyle(color: deepTeal, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                [
                      'أقل من 18',
                      '18–24',
                      '25–34',
                      '35–49',
                      '50 أو أكثر',
                      'أفضل عدم الإفصاح',
                    ]
                    .map(
                      (item) => ChoiceChip(
                        label: Text(item),
                        selected: age == item,
                        onSelected: (_) => setState(() => age = item),
                        selectedColor: const Color(0xFFD8EFEC),
                      ),
                    )
                    .toList(),
          ),
          const SizedBox(height: 24),
          const Text(
            'النوع',
            style: TextStyle(color: deepTeal, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ['رجل', 'امرأة', 'أفضل عدم الإفصاح']
                .map(
                  (item) => ChoiceChip(
                    label: Text(item),
                    selected: gender == item,
                    onSelected: (_) => setState(() => gender = item),
                    selectedColor: const Color(0xFFD8EFEC),
                  ),
                )
                .toList(),
          ),
        ],
      );
    }
    if (step == 2) {
      return ListView(
        children: interestOptions
            .map(
              (interest) => _choiceTile(
                interest,
                interests.contains(interest),
                () => setState(() {
                  if (interests.contains(interest)) {
                    interests.remove(interest);
                  } else if (interests.length < 5) {
                    interests.add(interest);
                  }
                }),
              ),
            )
            .toList(),
      );
    }
    return ListView(
      children: [
        _authChoice(
          Icons.person_add_alt_1,
          'إنشاء حساب',
          'اسم، رقم هاتف، وكلمة مرور',
          () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const AuthPage(createAccount: true),
            ),
          ),
        ),
        _authChoice(
          Icons.login,
          'تسجيل الدخول',
          'ادخل على حسابك الحالي',
          () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const AuthPage())),
        ),
        _authChoice(
          Icons.g_mobiledata,
          'المتابعة باستخدام Google',
          'قريباً',
          () => _comingSoon('تسجيل Google'),
        ),
        _authChoice(
          Icons.apple,
          'المتابعة باستخدام Apple',
          'قريباً',
          () => _comingSoon('تسجيل Apple'),
        ),
        _authChoice(
          Icons.explore_outlined,
          'التكملة كزائر',
          'تصفح التطبيق بدون حساب',
          () => Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomeShell()),
          ),
        ),
      ],
    );
  }

  Widget _choiceTile(String label, bool selected, VoidCallback onTap) => Card(
    color: selected ? const Color(0xFFD8EFEC) : Colors.white,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: BorderSide(color: selected ? teal : const Color(0xFFE0E8E6)),
    ),
    child: ListTile(
      onTap: onTap,
      leading: Icon(
        selected ? Icons.check_circle : Icons.circle_outlined,
        color: selected ? teal : muted,
      ),
      title: Text(label),
      trailing: label == 'قنا كلها'
          ? const Text('المدينة', style: TextStyle(color: muted, fontSize: 12))
          : null,
    ),
  );
  void _comingSoon(String label) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text('$label هيتوفر قريباً')));
  Widget _authChoice(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) => Card(
    elevation: 0,
    color: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: const BorderSide(color: Color(0xFFE0E8E6)),
    ),
    child: ListTile(
      onTap: onTap,
      leading: Icon(icon, color: teal),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: muted, fontSize: 12),
      ),
      trailing: const Icon(Icons.chevron_left, color: muted),
    ),
  );
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int index = 0;
  int previousIndex = 0;
  final pages = const [
    HomePage(),
    DirectoryPage(),
    PricesPage(),
    NowPage(),
    ListingsPage(),
  ];
  final labels = const ['الرئيسية', 'مين؟', 'بكام؟', 'دلوقتي', 'عندك؟'];
  final icons = const [
    Icons.home_outlined,
    Icons.person_search_outlined,
    Icons.sell_outlined,
    Icons.bolt_outlined,
    Icons.campaign_outlined,
  ];

  void _select(int value) => setState(() {
    previousIndex = index;
    index = value;
  });

  @override
  Widget build(BuildContext context) {
    final forward = index >= previousIndex;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: AnimatedSwitcher(
          duration: AppMotion.page,
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position:
                  Tween<Offset>(
                    begin: Offset(forward ? 0.12 : -0.12, 0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
              child: ScaleTransition(
                scale: Tween<double>(begin: .94, end: 1).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
                child: child,
              ),
            ),
          ),
          child: KeyedSubtree(key: ValueKey(index), child: pages[index]),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: index,
          onDestinationSelected: _select,
          backgroundColor: Colors.white,
          indicatorColor: const Color(0xFFD8EFEC),
          destinations: [
            for (var i = 0; i < labels.length; i++)
              NavigationDestination(
                icon: Icon(icons[i]),
                selectedIcon: Icon(icons[i], color: deepTeal),
                label: labels[i],
              ),
          ],
        ),
      ),
    );
  }
}

class BasePage extends StatelessWidget {
  const BasePage({
    super.key,
    required this.child,
    this.title,
    this.header,
    this.onRefresh,
  });
  final Widget child;
  final String? title;
  final Widget? header;
  final Future<void> Function()? onRefresh;
  @override
  Widget build(BuildContext context) {
    final refresh =
        onRefresh ??
        () async => Future<void>.delayed(const Duration(milliseconds: 450));
    return SafeArea(
      child: RefreshIndicator(
        color: teal,
        displacement: 24,
        onRefresh: refresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
          children: [
            header ??
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (title == null)
                      const BrandText()
                    else if (title!.isNotEmpty)
                      Text(
                        title!,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: deepTeal,
                        ),
                      )
                    else
                      const Spacer(),
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const NotificationsPage(),
                            ),
                          ),
                          icon: const Icon(
                            Icons.notifications_none,
                            color: deepTeal,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const AccountPage(),
                            ),
                          ),
                          icon: const CircleAvatar(
                            radius: 15,
                            backgroundColor: deepTeal,
                            child: Text(
                              'م',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class BrandText extends StatelessWidget {
  const BrandText({super.key});
  @override
  Widget build(BuildContext context) => const Text(
    'هنا قنا',
    style: TextStyle(
      color: deepTeal,
      fontSize: 20,
      fontWeight: FontWeight.w700,
    ),
  );
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String selectedArea = 'قنا كلها';

  void _openDirectory(String query) => Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => DirectoryPage(initialQuery: query)));

  Future<void> _pickArea() async {
    List<AreaOption> options;
    try {
      options = await ApiClient().fetchAreas();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر تحميل المناطق حالياً')),
      );
      return;
    }
    if (!mounted) return;
    final picked = await showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 12),
          children: [
            const ListTile(
              title: Text(
                'اختار المنطقة',
                style: TextStyle(color: deepTeal, fontWeight: FontWeight.w700),
              ),
            ),
            for (final area in options)
              RadioListTile<String>(
                value: area.name,
                groupValue: selectedArea,
                title: Text(area.name),
                onChanged: (value) => Navigator.pop(context, value),
              ),
          ],
        ),
      ),
    );
    if (picked != null && mounted) setState(() => selectedArea = picked);
  }

  @override
  Widget build(BuildContext context) => BasePage(
    header: Row(
      children: [
        Expanded(
          child: TextField(
            textInputAction: TextInputAction.search,
            onSubmitted: (value) {
              if (value.trim().isNotEmpty) _openDirectory(value.trim());
            },
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search, color: teal),
              hintText: 'بتدور على إيه؟',
              isDense: true,
            ),
          ),
        ),
        IconButton(
          onPressed: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const NotificationsPage())),
          icon: const Icon(Icons.notifications_none, color: deepTeal),
        ),
        IconButton(
          onPressed: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const SettingsPage())),
          icon: const Icon(Icons.settings_outlined, color: deepTeal),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(Icons.location_on_outlined, size: 18, color: teal),
            const SizedBox(width: 5),
            Text(selectedArea, style: const TextStyle(color: muted)),
            const Spacer(),
            TextButton(onPressed: _pickArea, child: const Text('تغيير')),
          ],
        ),
        const SizedBox(height: 16),
        const HeroBanner(),
        const SizedBox(height: 14),
        const PromoCarousel(),
        const SizedBox(height: 20),
        const SectionTitle(title: 'فئات قريبة منك'),
        const SizedBox(height: 9),
        const SizedBox(height: 2),
        CategoryRail(
          items: ['صيدليات', 'مطاعم', 'فنيين', 'سوبر ماركت', 'تعليم', 'ترفيه'],
          onSelected: _openDirectory,
        ),
        const SizedBox(height: 20),
        const SectionTitle(title: 'مختارات قنا'),
        const SizedBox(height: 9),
        MotionIn(
          child: MiniItem(
            icon: Icons.local_pharmacy_outlined,
            title: 'صيدلية الرحمة',
            subtitle: 'الحميدات · مفتوح الآن · 4.8 ★',
            onTap: () => _openDetails(
              context,
              'صيدلية الرحمة',
              Icons.local_pharmacy_outlined,
              'الحميدات · مفتوح الآن · 4.8 ★',
            ),
          ),
        ),
        MotionIn(
          delay: 60,
          child: MiniItem(
            icon: Icons.coffee_outlined,
            title: 'قهوة البلد',
            subtitle: 'وسط البلد · على بُعد 0.8 كم',
            onTap: () => _openDetails(
              context,
              'قهوة البلد',
              Icons.coffee_outlined,
              'وسط البلد · مفتوح الآن · 4.7 ★',
            ),
          ),
        ),
      ],
    ),
  );

  void _openDetails(
    BuildContext context,
    String title,
    IconData icon,
    String subtitle,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProviderDetailPage(
          providerId: null,
          title: title,
          icon: icon,
          subtitle: subtitle,
        ),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle({super.key, required this.title});
  final String title;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        title,
        style: const TextStyle(
          color: deepTeal,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
      const Text('شوف الكل', style: TextStyle(color: teal, fontSize: 12)),
    ],
  );
}

class _StateMessage extends StatelessWidget {
  const _StateMessage({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 12),
    child: Column(
      children: [
        Icon(icon, size: 38, color: teal),
        const SizedBox(height: 10),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(color: deepTeal, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 5),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(color: muted),
        ),
        if (actionLabel != null && onAction != null) ...[
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ],
    ),
  );
}

class MotionIn extends StatelessWidget {
  const MotionIn({super.key, required this.child, this.delay = 0});
  final Widget child;
  final int delay;
  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: 1),
    duration: Duration(milliseconds: 280 + delay),
    curve: Curves.easeOutCubic,
    builder: (_, value, child) => Opacity(
      opacity: value,
      child: Transform.translate(
        offset: Offset(0, 10 * (1 - value)),
        child: child,
      ),
    ),
    child: child,
  );
}

class HeroBanner extends StatefulWidget {
  const HeroBanner({super.key});
  @override
  State<HeroBanner> createState() => _HeroBannerState();
}

class _HeroBannerState extends State<HeroBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 5),
  )..repeat(reverse: true);

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
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            deepTeal,
            Color.lerp(teal, deepTeal, controller.value * .35)!,
          ],
        ),
      ),
      child: Stack(
        children: [
          PositionedDirectional(
            end: -24 + controller.value * 12,
            top: -25,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: .07),
              ),
            ),
          ),
          PositionedDirectional(
            end: 38 - controller.value * 8,
            bottom: -46,
            child: Container(
              width: 125,
              height: 125,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: .08),
                  width: 10,
                ),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'قنا كلها هنا',
                      style: TextStyle(color: Color(0xDDF7F6F2), fontSize: 13),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'كل ما تحتاجه.. قريب منك',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'اكتشف، قارن، واعرف الجديد حواليك',
                      style: TextStyle(color: Color(0xDDF7F6F2)),
                    ),
                  ],
                ),
              ),
              Transform.translate(
                offset: Offset(0, -3 * controller.value),
                child: const LogoMark(dark: true, size: 47),
              ),
            ],
          ),
        ],
      ),
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
  List<(String, String, IconData, Color)> promos = [
    ('إعلان مميز', 'خصم خاص لأهل قنا اليوم', Icons.campaign_outlined, gold),
    (
      'قنا كلها هنا',
      'اعرف الجديد والخدمات الأقرب ليك',
      Icons.explore_outlined,
      teal,
    ),
    (
      'دلوقتي في قنا',
      'تحديثات محلية مهمة من حواليك',
      Icons.bolt_outlined,
      deepTeal,
    ),
  ];

  @override
  void initState() {
    super.initState();
    ApiClient()
        .fetchAds()
        .then((ads) {
          if (!mounted || ads.isEmpty) return;
          setState(() {
            promos = ads
                .map(
                  (ad) => (
                    ad['name'] as String,
                    (ad['description'] as String?) ?? 'إعلان مميز من هنا قنا',
                    Icons.campaign_outlined,
                    gold,
                  ),
                )
                .toList();
          });
        })
        .catchError((_) {});
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: isGold ? gold.withValues(alpha: .22) : promo.$4,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    Icon(
                      promo.$3,
                      color: isGold ? deepTeal : Colors.white,
                      size: 25,
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            promo.$1,
                            style: TextStyle(
                              color: isGold ? deepTeal : Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            promo.$2,
                            style: TextStyle(
                              color: isGold
                                  ? ink
                                  : Colors.white.withValues(alpha: .9),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_left,
                      color: isGold ? deepTeal : Colors.white,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      const SizedBox(height: 7),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < promos.length; i++)
            AnimatedContainer(
              duration: AppMotion.quick,
              width: i == active ? 18 : 6,
              height: 6,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: i == active ? teal : const Color(0xFFD6E3E0),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
        ],
      ),
    ],
  );
}

class CategoryRail extends StatelessWidget {
  const CategoryRail({super.key, required this.items, this.onSelected});
  final List<String> items;
  final ValueChanged<String>? onSelected;
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 42,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (_, index) => const SizedBox(width: 8),
      itemBuilder: (_, index) => ActionChip(
        onPressed: onSelected == null ? null : () => onSelected!(items[index]),
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
  const MiniItem({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });
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
    onTapDown: widget.onTap == null
        ? null
        : (_) => setState(() => pressed = true),
    onTapUp: widget.onTap == null
        ? null
        : (_) => setState(() => pressed = false),
    onTapCancel: widget.onTap == null
        ? null
        : () => setState(() => pressed = false),
    onTap: widget.onTap,
    child: AnimatedScale(
      scale: pressed ? .975 : 1,
      duration: AppMotion.quick,
      curve: Curves.easeOutCubic,
      child: Card(
        elevation: 0,
        color: Colors.white,
        margin: const EdgeInsets.only(bottom: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: const BorderSide(color: Color(0xFFE0E8E6)),
        ),
        child: ListTile(
          leading: Hero(
            tag: 'provider-icon-${widget.title}',
            child: CircleAvatar(
              backgroundColor: const Color(0xFFD8EFEC),
              child: Icon(widget.icon, color: deepTeal),
            ),
          ),
          title: Text(
            widget.title,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          subtitle: Text(
            widget.subtitle,
            style: const TextStyle(color: muted, fontSize: 12),
          ),
          trailing: const Icon(Icons.chevron_left, color: muted),
        ),
      ),
    ),
  );
}

class DirectoryPage extends StatefulWidget {
  const DirectoryPage({super.key, this.initialQuery});
  final String? initialQuery;
  @override
  State<DirectoryPage> createState() => _DirectoryPageState();
}

class _DirectoryPageState extends State<DirectoryPage> {
  late Future<List<ProviderSummary>> providersFuture;
  final api = ApiClient();
  final searchController = TextEditingController();
  Timer? searchDebounce;
  @override
  void initState() {
    super.initState();
    searchController.text = widget.initialQuery ?? '';
    providersFuture = api.fetchProviders(searchQuery: widget.initialQuery);
  }

  @override
  void dispose() {
    searchDebounce?.cancel();
    searchController.dispose();
    super.dispose();
  }

  void _search(String value) {
    searchDebounce?.cancel();
    searchDebounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted)
        setState(
          () => providersFuture = api.fetchProviders(searchQuery: value),
        );
    });
  }

  @override
  Widget build(BuildContext context) => BasePage(
    title: '',
    onRefresh: _reload,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'اختار الفئة الأقرب والأنسب ليك',
          style: TextStyle(color: muted),
        ),
        const SizedBox(height: 10),
        CategoryRail(
          items: [
            'خدمات طبية',
            'مطاعم وكافيهات',
            'صيانة وفنيين',
            'سوبر ماركت',
            'تعليم ودروس',
            'ترفيه',
          ],
          onSelected: (value) {
            searchController.text = value;
            _search(value);
          },
        ),
        const SizedBox(height: 16),
        TextField(
          controller: searchController,
          onChanged: _search,
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.search, color: teal),
            hintText: 'اكتب اسم الخدمة أو المكان',
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: () => _showFilters(context),
              icon: const Icon(Icons.tune),
              label: const Text('فلاتر'),
            ),
            const Spacer(),
            OutlinedButton.icon(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'افتح تفاصيل المكان ثم اضغط «الخريطة» للوصول إليه',
                  ),
                ),
              ),
              icon: const Icon(Icons.map_outlined),
              label: const Text('خريطة'),
            ),
          ],
        ),
        FutureBuilder<List<ProviderSummary>>(
          future: providersFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.all(28),
                child: Center(child: CircularProgressIndicator(color: teal)),
              );
            }
            if (snapshot.hasError) {
              return _StateMessage(
                icon: Icons.cloud_off_outlined,
                title: 'تعذر تحميل الدليل',
                subtitle: 'تأكد من الاتصال وحاول مرة أخرى.',
                actionLabel: 'إعادة المحاولة',
                onAction: _reload,
              );
            }
            final providers = snapshot.data ?? const <ProviderSummary>[];
            if (providers.isEmpty) {
              return const _StateMessage(
                icon: Icons.search_off_outlined,
                title: 'مفيش نتائج مطابقة',
                subtitle: 'جرّب اسمًا أو فئة مختلفة.',
              );
            }
            return Column(
              children: [
                if (snapshot.connectionState == ConnectionState.waiting)
                  const LinearProgressIndicator(minHeight: 3, color: teal),
                if (snapshot.hasError)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Text(
                      'بيانات تجريبية — سيتم تحديثها عند تشغيل الخادم',
                      style: TextStyle(color: muted, fontSize: 11),
                    ),
                  ),
                ...providers.asMap().entries.map((entry) {
                  final icon = entry.key == 0
                      ? Icons.build_outlined
                      : Icons.local_hospital_outlined;
                  final provider = entry.value;
                  return MotionIn(
                    delay: entry.key * 60,
                    child: MiniItem(
                      icon: icon,
                      title: provider.name,
                      subtitle: provider.subtitle,
                      onTap: () => _openDetails(context, provider, icon),
                    ),
                  );
                }),
              ],
            );
          },
        ),
      ],
    ),
  );

  Future<void> _reload() async {
    setState(() => providersFuture = api.fetchProviders());
    await providersFuture;
  }

  void _openDetails(
    BuildContext context,
    ProviderSummary provider,
    IconData icon,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProviderDetailPage(
          providerId: provider.id,
          title: provider.name,
          icon: icon,
          subtitle: provider.subtitle,
        ),
      ),
    );
  }

  void _showFilters(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      sheetAnimationStyle: const AnimationStyle(
        duration: AppMotion.gentle,
        reverseDuration: AppMotion.quick,
      ),
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
    child: SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
        decoration: const BoxDecoration(
          color: paper,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Wrap(
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD0DAD8),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'فلترة النتائج',
                    style: TextStyle(
                      color: deepTeal,
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'الترتيب',
              style: TextStyle(color: deepTeal, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: ['الأقرب', 'الأعلى تقييمًا', 'الأحدث']
                  .map(
                    (item) => ChoiceChip(
                      label: Text(item),
                      selected: sort == item,
                      onSelected: (_) => setState(() => sort = item),
                      selectedColor: const Color(0xFFD8EFEC),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 10),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('مفتوح الآن'),
              value: openNow,
              onChanged: (value) => setState(() => openNow = value),
              activeThumbColor: teal,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('أماكن موثقة فقط'),
              value: verified,
              onChanged: (value) => setState(() => verified = value),
              activeThumbColor: teal,
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              style: FilledButton.styleFrom(
                backgroundColor: teal,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text('تطبيق الفلاتر'),
            ),
          ],
        ),
      ),
    ),
  );
}

class ProviderDetailPage extends StatefulWidget {
  const ProviderDetailPage({
    super.key,
    required this.providerId,
    required this.title,
    required this.icon,
    required this.subtitle,
  });
  final String? providerId;
  final String title;
  final IconData icon;
  final String subtitle;
  @override
  State<ProviderDetailPage> createState() => _ProviderDetailPageState();
}

class _ProviderDetailPageState extends State<ProviderDetailPage> {
  late Future<ProviderDetails?> details = widget.providerId == null
      ? Future.value(null)
      : ApiClient().fetchProvider(widget.providerId!).then((value) => value);
  bool? favorite;

  void _reload() => setState(() {
    details = widget.providerId == null
        ? Future.value(null)
        : ApiClient().fetchProvider(widget.providerId!).then((value) => value);
  });

  Future<void> _toggleFavorite() async {
    final id = widget.providerId;
    if (id == null) return;
    try {
      final result = await ApiClient().toggleProviderFavorite(id);
      if (mounted) setState(() => favorite = result['active'] as bool);
    } catch (error) {
      if (!mounted) return;
      if (error.toString().contains('unauthorized')) {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AuthPage()),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تعذر حفظ النشاط')));
      }
    }
  }

  Future<void> _helpful(String reviewId) async {
    try {
      await ApiClient().toggleReviewHelpful(reviewId);
      _reload();
    } catch (error) {
      if (!mounted) return;
      if (error.toString().contains('unauthorized')) {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AuthPage()),
        );
      }
    }
  }

  Future<void> _reply(String reviewId) async {
    final controller = TextEditingController();
    final submit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('اكتب ردك'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 4,
          decoration: const InputDecoration(hintText: 'رد محترم ومفيد'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('نشر'),
          ),
        ],
      ),
    );
    final text = controller.text.trim();
    controller.dispose();
    if (submit != true || text.isEmpty) return;
    try {
      await ApiClient().replyToReview(reviewId, text);
      _reload();
    } catch (error) {
      if (!mounted) return;
      if (error.toString().contains('unauthorized')) {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AuthPage()),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تعذر نشر الرد')));
      }
    }
  }

  Future<void> _external(Future<bool> action, String unavailable) async {
    try {
      if (await action || !mounted) return;
    } catch (_) {
      if (!mounted) return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(unavailable)));
  }

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      appBar: AppBar(title: const Text('تفاصيل المكان')),
      floatingActionButton: widget.providerId == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ReviewPage(
                      providerId: widget.providerId!,
                      providerName: widget.title,
                    ),
                  ),
                );
                _reload();
              },
              backgroundColor: teal,
              icon: const Icon(Icons.star_border),
              label: const Text('أضف تقييمك'),
            ),
      body: FutureBuilder<ProviderDetails?>(
        future: details,
        builder: (context, snapshot) {
          final data = snapshot.data;
          favorite ??= data?.viewerFavorite ?? false;
          final imageUrls = data?.images ?? const <String>[];
          final reviews = data?.reviews ?? const <Map<String, dynamic>>[];
          return ListView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 90),
            children: [
              if (snapshot.connectionState == ConnectionState.waiting)
                const LinearProgressIndicator(color: teal),
              MediaGallery(
                imageCount: imageUrls.isEmpty ? 1 : imageUrls.length,
                imageUrls: imageUrls,
              ),
              const SizedBox(height: 14),
              Card(
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: const BorderSide(color: Color(0xFFE0E8E6)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      Hero(
                        tag: 'provider-icon-${widget.title}',
                        child: CircleAvatar(
                          radius: 30,
                          backgroundColor: const Color(0xFFD8EFEC),
                          child: Icon(widget.icon, color: deepTeal, size: 30),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data?.name ?? widget.title,
                              style: const TextStyle(
                                color: deepTeal,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 7),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    widget.subtitle
                                        .replaceAll(
                                          RegExp(r' · \d(?:\.\d)? ★'),
                                          '',
                                        )
                                        .replaceAll('موثق · ', '')
                                        .replaceAll(' · موثق', ''),
                                    style: const TextStyle(color: muted),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                const Text(
                                  'موثق',
                                  style: TextStyle(
                                    color: teal,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: data?.phone == null
                          ? null
                          : () => _external(
                              AppActions.call(data!.phone),
                              'تعذر فتح الاتصال على هذا الجهاز',
                            ),
                      icon: const Icon(Icons.phone_outlined),
                      label: const Text('اتصال'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: (data?.whatsapp ?? data?.phone) == null
                          ? null
                          : () => _external(
                              AppActions.whatsapp(
                                data?.whatsapp ?? data?.phone,
                                message:
                                    'مرحبًا، وصلت لنشاط ${data?.name ?? widget.title} من تطبيق هنا قنا.',
                              ),
                              'واتساب غير متاح على هذا الجهاز',
                            ),
                      icon: const Icon(Icons.chat_outlined),
                      label: const Text('واتساب'),
                    ),
                  ),
                  Expanded(
                    child: TextButton.icon(
                      onPressed: widget.providerId == null
                          ? null
                          : _toggleFavorite,
                      icon: Icon(
                        favorite == true
                            ? Icons.favorite
                            : Icons.favorite_border,
                      ),
                      label: const Text('حفظ'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextButton.icon(
                      onPressed: data?.address == null && data?.latitude == null
                          ? null
                          : () => _external(
                              AppActions.map(
                                latitude: data?.latitude,
                                longitude: data?.longitude,
                                address:
                                    '${data?.address ?? ''}، ${data?.areaName ?? 'قنا'}، قنا',
                              ),
                              'لا توجد بيانات موقع كافية',
                            ),
                      icon: const Icon(Icons.map_outlined),
                      label: const Text('الخريطة'),
                    ),
                  ),
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () => AppActions.share(
                        context,
                        subject: data?.name ?? widget.title,
                        text:
                            '${data?.name ?? widget.title}\n${data?.description ?? ''}\n${data?.address ?? data?.areaName ?? 'قنا'}\nمن تطبيق هنا قنا',
                      ),
                      icon: const Icon(Icons.share_outlined),
                      label: const Text('مشاركة'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const SectionTitle(title: 'الوصف'),
              const SizedBox(height: 8),
              Text(
                data?.description ??
                    'خدمة موثقة ومعلوماتها محدثة من فريق هنا قنا.',
                style: const TextStyle(color: muted, height: 1.5),
              ),
              if (data?.offers.isNotEmpty == true) ...[
                const SizedBox(height: 18),
                const SectionTitle(title: 'العروض'),
                const SizedBox(height: 8),
                ...data!.offers.map(
                  (offer) => MiniItem(
                    icon: Icons.local_offer_outlined,
                    title: offer['title'] as String? ?? 'عرض',
                    subtitle:
                        offer['description'] as String? ?? 'عرض متاح حاليًا',
                  ),
                ),
              ],
              if (data?.services.isNotEmpty == true) ...[
                const SizedBox(height: 18),
                const SectionTitle(title: 'الخدمات والأسعار'),
                const SizedBox(height: 8),
                ...data!.services.map(
                  (service) => MiniItem(
                    icon: Icons.design_services_outlined,
                    title: service['name'] as String? ?? 'خدمة',
                    subtitle: service['price'] == null
                        ? service['priceNote'] as String? ?? 'اسأل عن السعر'
                        : '${service['price']} جنيه${service['priceNote'] == null ? '' : ' · ${service['priceNote']}'}',
                  ),
                ),
              ],
              const SizedBox(height: 18),
              const SectionTitle(title: 'التقييمات الموجودة'),
              const SizedBox(height: 8),
              if (snapshot.hasError)
                const Text(
                  'تعذر تحميل التقييمات حالياً.',
                  style: TextStyle(color: muted),
                ),
              ...reviews.asMap().entries.map((entry) {
                final review = entry.value;
                final author =
                    (review['author'] as Map<String, dynamic>?)?['name']
                        as String? ??
                    'مستخدم هنا قنا';
                final text = review['comment'] as String? ?? 'تقييم بدون تعليق';
                final initials = author.isEmpty
                    ? 'هـ'
                    : author.characters.first;
                final score =
                    ((review['quality'] as int? ?? 0) +
                        (review['commitment'] as int? ?? 0) +
                        (review['value'] as int? ?? 0)) ~/
                    3;
                final reviewId = review['id'] as String;
                final replies = (review['replies'] as List<dynamic>? ?? []).map(
                  (replyValue) {
                    final reply = replyValue as Map<String, dynamic>;
                    final replyAuthor =
                        (reply['author'] as Map<String, dynamic>?)?['name']
                            as String? ??
                        'مستخدم هنا قنا';
                    return CommentReply(
                      name: replyAuthor,
                      initial: replyAuthor.isEmpty
                          ? 'هـ'
                          : replyAuthor.characters.first,
                      text: reply['text'] as String? ?? '',
                      onReply: () => _reply(reviewId),
                    );
                  },
                ).toList();
                return MotionIn(
                  delay: entry.key * 60,
                  child: CommentBubble(
                    name: author,
                    initial: initials,
                    text: text,
                    rating: score,
                    helpfulCount:
                        review['_count']?['helpfulVotes'] as int? ?? 0,
                    onHelpful: () => _helpful(reviewId),
                    onReply: () => _reply(reviewId),
                    replies: replies,
                  ),
                );
              }),
              if (reviews.isEmpty)
                const Text(
                  'لسه مفيش تقييمات. كن أول واحد يقيّم المكان.',
                  style: TextStyle(color: muted),
                ),
            ],
          );
        },
      ),
    ),
  );
}

class CommentBubble extends StatelessWidget {
  const CommentBubble({
    super.key,
    required this.name,
    required this.initial,
    required this.text,
    required this.rating,
    required this.helpfulCount,
    required this.onHelpful,
    required this.onReply,
    this.replies = const [],
  });
  final String name;
  final String initial;
  final String text;
  final int rating;
  final int helpfulCount;
  final VoidCallback onHelpful;
  final VoidCallback onReply;
  final List<CommentReply> replies;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 19,
              backgroundColor: const Color(0xFFD8EFEC),
              child: Text(
                initial,
                style: const TextStyle(
                  color: deepTeal,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(
                            color: deepTeal,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        'منذ يوم',
                        style: const TextStyle(color: muted, fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(text, style: const TextStyle(color: ink, height: 1.4)),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        '$rating',
                        style: const TextStyle(
                          color: teal,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Icon(Icons.star, color: gold, size: 15),
                      const SizedBox(width: 12),
                      TextButton(
                        onPressed: onHelpful,
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          helpfulCount == 0 ? 'مفيد' : 'مفيد · $helpfulCount',
                        ),
                      ),
                      const SizedBox(width: 12),
                      TextButton(
                        onPressed: onReply,
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text('رد'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        if (replies.isNotEmpty)
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 42, top: 8),
            child: Column(children: replies),
          ),
      ],
    ),
  );
}

class CommentReply extends StatelessWidget {
  const CommentReply({
    super.key,
    required this.name,
    required this.initial,
    required this.text,
    required this.onReply,
  });
  final String name;
  final String initial;
  final String text;
  final VoidCallback onReply;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 15,
          backgroundColor: const Color(0xFFE8F5F2),
          child: Text(
            initial,
            style: const TextStyle(
              color: deepTeal,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  color: deepTeal,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                text,
                style: const TextStyle(color: ink, fontSize: 13, height: 1.3),
              ),
              Row(
                children: [
                  TextButton(
                    onPressed: onReply,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('رد', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class ReviewPage extends StatefulWidget {
  const ReviewPage({
    super.key,
    required this.providerId,
    required this.providerName,
  });
  final String providerId;
  final String providerName;
  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  final api = ApiClient();
  final scores = <String, int>{'الجودة': 0, 'الالتزام': 0, 'السعر': 0};
  final comment = TextEditingController();
  bool submitting = false;
  @override
  void dispose() {
    comment.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      appBar: AppBar(title: const Text('إضافة تقييم')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
        children: [
          Text(
            'قيّم ${widget.providerName}',
            style: const TextStyle(
              color: deepTeal,
              fontSize: 21,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 7),
          const Text(
            'تقييمك يساعد أهل قنا يختاروا بشكل أفضل.',
            style: TextStyle(color: muted),
          ),
          const SizedBox(height: 22),
          ...scores.keys.map(
            (label) => _ScorePicker(
              label: label,
              value: scores[label]!,
              onChanged: (value) => setState(() => scores[label] = value),
            ),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: comment,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'اكتب تعليقك',
              hintText: 'إيه اللي عجبك أو محتاج يتحسن؟',
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'التقييم يظهر باسمك الحقيقي ويمكنك تعديله من مساهماتك.',
            style: TextStyle(color: muted, fontSize: 12),
          ),
          const SizedBox(height: 22),
          FilledButton(
            onPressed: scores.values.any((value) => value == 0) || submitting
                ? null
                : _submit,
            style: FilledButton.styleFrom(
              backgroundColor: teal,
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(submitting ? 'جارٍ الإرسال…' : 'إرسال التقييم'),
          ),
        ],
      ),
    ),
  );

  Future<void> _submit() async {
    setState(() => submitting = true);
    try {
      await api.submitReview(
        providerId: widget.providerId,
        quality: scores['الجودة']!,
        commitment: scores['الالتزام']!,
        value: scores['السعر']!,
        comment: comment.text,
      );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تم إرسال التقييم')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.toString().contains('unauthorized')
                ? 'سجّل الدخول أولاً للتقييم'
                : error.toString().contains('duplicate_review')
                ? 'سبق لك تقييم هذا المكان'
                : 'تعذر إرسال التقييم حالياً',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => submitting = false);
    }
  }
}

class _ScorePicker extends StatelessWidget {
  const _ScorePicker({
    required this.label,
    required this.value,
    required this.onChanged,
  });
  final String label;
  final int value;
  final ValueChanged<int> onChanged;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 15),
    child: Row(
      children: [
        SizedBox(
          width: 82,
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: deepTeal,
            ),
          ),
        ),
        ...List.generate(
          5,
          (index) => IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: () => onChanged(index + 1),
            icon: AnimatedScale(
              scale: index < value ? 1.12 : 1,
              duration: AppMotion.quick,
              curve: Curves.easeOutBack,
              child: AnimatedSwitcher(
                duration: AppMotion.quick,
                child: Icon(
                  index < value ? Icons.star : Icons.star_border,
                  key: ValueKey(index < value),
                  color: gold,
                  size: 27,
                ),
              ),
            ),
          ),
        ),
        if (value > 0)
          Text('$value/5', style: const TextStyle(color: muted, fontSize: 12)),
      ],
    ),
  );
}

class PricesPage extends StatefulWidget {
  const PricesPage({super.key});
  @override
  State<PricesPage> createState() => _PricesPageState();
}

class _PricesPageState extends State<PricesPage> {
  String selected = 'offers';
  late Future<List<Map<String, dynamic>>> pricesFuture;

  @override
  void initState() {
    super.initState();
    pricesFuture = ApiClient().fetchPrices();
  }

  @override
  Widget build(BuildContext context) => BasePage(
    title: 'بكام؟',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'العروض أولًا، ثم الأسعار المحدثة',
          style: TextStyle(color: muted),
        ),
        const SizedBox(height: 14),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(
              value: 'offers',
              label: Text('العروض'),
              icon: Icon(Icons.local_offer_outlined),
            ),
            ButtonSegment(
              value: 'prices',
              label: Text('الأسعار'),
              icon: Icon(Icons.sell_outlined),
            ),
          ],
          selected: {selected},
          onSelectionChanged: (value) => setState(() => selected = value.first),
        ),
        const SizedBox(height: 16),
        AnimatedSwitcher(
          duration: AppMotion.standard,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(.03, 0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          ),
          child: selected == 'offers'
              ? const Column(
                  key: ValueKey('offers'),
                  children: [
                    MotionIn(
                      child: MiniItem(
                        icon: Icons.local_offer_outlined,
                        title: 'خصم 15% على الأجهزة',
                        subtitle: 'من نشاط موثق · ينتهي خلال 3 أيام',
                      ),
                    ),
                    MotionIn(
                      delay: 60,
                      child: MiniItem(
                        icon: Icons.local_offer_outlined,
                        title: 'عرض نهاية الأسبوع',
                        subtitle: 'مطاعم مختارة · ينتهي غدًا',
                      ),
                    ),
                  ],
                )
              : FutureBuilder<List<Map<String, dynamic>>>(
                  key: const ValueKey('prices'),
                  future: pricesFuture,
                  builder: (context, snapshot) {
                    final items =
                        snapshot.data ?? const <Map<String, dynamic>>[];
                    if (snapshot.connectionState == ConnectionState.waiting)
                      return const Center(child: CircularProgressIndicator());
                    if (items.isEmpty)
                      return const MiniItem(
                        icon: Icons.sell_outlined,
                        title: 'لا توجد أسعار منشورة بعد',
                        subtitle:
                            'سيظهر هنا دليل الأسعار بعد اعتماده من الإدارة',
                      );
                    return Column(
                      children: [
                        for (final item in items)
                          MotionIn(
                            child: MiniItem(
                              icon: Icons.sell_outlined,
                              title: item['name'] as String,
                              subtitle:
                                  'من ${item['minPrice']} إلى ${item['maxPrice']} جنيه${item['unit'] == null ? '' : ' · ${item['unit']}'}',
                            ),
                          ),
                      ],
                    );
                  },
                ),
        ),
      ],
    ),
  );
}

class NowPage extends StatefulWidget {
  const NowPage({super.key});
  @override
  State<NowPage> createState() => _NowPageState();
}

class _NowPageState extends State<NowPage> {
  String selected = 'الكل';
  List<Map<String, dynamic>> nowItems = const [];

  @override
  void initState() {
    super.initState();
    ApiClient()
        .fetchNow()
        .then((items) {
          if (mounted) setState(() => nowItems = items);
        })
        .catchError((_) {});
  }

  @override
  Widget build(BuildContext context) => BasePage(
    title: 'دلوقتي',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Row(
          children: [
            Expanded(
              child: Text(
                'اعرف إيه اللي بيحصل حواليك',
                style: TextStyle(color: muted),
              ),
            ),
            LivePulse(),
          ],
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          children: ['الكل', 'خدمات ومرافق', 'طرق ومواصلات', 'فعاليات']
              .map(
                (x) => ChoiceChip(
                  label: Text(x),
                  selected: x == selected,
                  onSelected: (_) => setState(() => selected = x),
                  selectedColor: const Color(0xFFD8EFEC),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 14),
        AnimatedSwitcher(
          duration: AppMotion.standard,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, .025),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          ),
          child: Column(key: ValueKey(selected), children: _items()),
        ),
      ],
    ),
  );

  List<Widget> _items() {
    final live = nowItems
        .where((item) => selected == 'الكل' || item['category'] == selected)
        .toList();
    if (live.isNotEmpty) {
      return [
        for (var index = 0; index < live.length; index++)
          MotionIn(
            delay: index * 60,
            child: _AlertCard(
              id: live[index]['id'] as String,
              title: live[index]['title'] as String,
              subtitle:
                  '${live[index]['body'] ?? 'تحديث محلي'} · ${live[index]['area']?['name'] ?? 'قنا'}',
              icon: Icons.bolt_outlined,
              color: teal,
              helpfulCount: live[index]['_count']?['helpfulVotes'] as int? ?? 0,
            ),
          ),
      ];
    }
    return const [
      _StateMessage(
        icon: Icons.bolt_outlined,
        title: 'لا توجد تحديثات حالياً',
        subtitle: 'هنا هتظهر التحديثات المحلية بعد اعتماد الإدارة.',
      ),
    ];
  }
}

class LivePulse extends StatefulWidget {
  const LivePulse({super.key});
  @override
  State<LivePulse> createState() => _LivePulseState();
}

class _LivePulseState extends State<LivePulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (_, value) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5F2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8 + (controller.value * 3),
            height: 8 + (controller.value * 3),
            decoration: BoxDecoration(
              color: teal.withValues(alpha: .32),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: teal,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          const SizedBox(width: 5),
          const Text(
            'مباشر',
            style: TextStyle(
              color: deepTeal,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    ),
  );
}

class _AlertCard extends StatefulWidget {
  const _AlertCard({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.helpfulCount,
  });
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final int helpfulCount;
  @override
  State<_AlertCard> createState() => _AlertCardState();
}

class _AlertCardState extends State<_AlertCard> {
  late int helpfulCount = widget.helpfulCount;
  bool active = false;

  Future<void> _toggleHelpful() async {
    try {
      final result = await ApiClient().toggleNowHelpful(widget.id);
      if (!mounted) return;
      setState(() {
        active = result['active'] as bool;
        helpfulCount = result['count'] as int;
      });
    } catch (error) {
      if (!mounted) return;
      if (error.toString().contains('unauthorized')) {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AuthPage()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => Card(
    elevation: 0,
    margin: const EdgeInsets.only(bottom: 9),
    color: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: Color(0xFFE0E8E6)),
    ),
    child: ListTile(
      leading: CircleAvatar(
        backgroundColor: widget.color.withValues(alpha: .14),
        child: Icon(widget.icon, color: widget.color),
      ),
      title: Text(
        widget.title,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        widget.subtitle,
        style: const TextStyle(color: muted, fontSize: 12),
      ),
      trailing: OutlinedButton.icon(
        onPressed: _toggleHelpful,
        icon: Icon(active ? Icons.thumb_up : Icons.thumb_up_outlined, size: 16),
        label: Text(helpfulCount == 0 ? 'مفيد' : '$helpfulCount'),
      ),
    ),
  );
}

class ListingsPage extends StatefulWidget {
  const ListingsPage({super.key});
  @override
  State<ListingsPage> createState() => _ListingsPageState();
}

class _ListingsPageState extends State<ListingsPage> {
  final api = ApiClient();
  final search = TextEditingController();
  Timer? debounce;
  String? category;
  late Future<List<Map<String, dynamic>>> listings = api.fetchListings();

  @override
  void dispose() {
    debounce?.cancel();
    search.dispose();
    super.dispose();
  }

  void _reload() => setState(
    () => listings = api.fetchListings(category: category, query: search.text),
  );

  void _search(String _) {
    debounce?.cancel();
    debounce = Timer(const Duration(milliseconds: 350), _reload);
  }

  @override
  Widget build(BuildContext context) => BasePage(
    title: 'عندك؟',
    onRefresh: () async {
      _reload();
      await listings;
    },
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'اعرض اللي عندك، ودوّر على اللي محتاجه',
          style: TextStyle(color: muted),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: search,
          onChanged: _search,
          textInputAction: TextInputAction.search,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search, color: teal),
            hintText: 'ابحث في الإعلانات',
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 42,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (final item in [
                'الكل',
                'للبيع',
                'للإيجار',
                'وظائف',
                'سيارات',
                'عقارات',
              ])
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 8),
                  child: ChoiceChip(
                    label: Text(item),
                    selected: (category ?? 'الكل') == item,
                    selectedColor: const Color(0xFFD8EFEC),
                    onSelected: (_) {
                      setState(() => category = item == 'الكل' ? null : item);
                      _reload();
                    },
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        FutureBuilder<List<Map<String, dynamic>>>(
          future: listings,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.all(28),
                child: Center(child: CircularProgressIndicator(color: teal)),
              );
            }
            if (snapshot.hasError) {
              return _StateMessage(
                icon: Icons.cloud_off_outlined,
                title: 'تعذر تحميل الإعلانات',
                subtitle: 'تأكد من الاتصال وحاول مرة أخرى.',
                actionLabel: 'إعادة المحاولة',
                onAction: _reload,
              );
            }
            final items = snapshot.data ?? const <Map<String, dynamic>>[];
            if (items.isEmpty) {
              return const _StateMessage(
                icon: Icons.inventory_2_outlined,
                title: 'مفيش إعلانات متاحة حاليًا',
                subtitle: 'غيّر البحث أو كن أول شخص يضيف إعلانًا.',
              );
            }
            return Column(
              children: [
                for (var index = 0; index < items.length; index++)
                  MotionIn(
                    delay: index * 45,
                    child: MiniItem(
                      icon: Icons.campaign_outlined,
                      title: items[index]['title'] as String? ?? 'إعلان',
                      subtitle:
                          '${items[index]['price']} جنيه · ${items[index]['area']?['name'] ?? 'قنا'} · ${items[index]['category'] ?? ''}',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ListingDetailPage(
                            listingId: items[index]['id'] as String,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateListingPage()),
          ),
          icon: const Icon(Icons.add),
          label: const Text('أضف إعلانًا'),
          style: FilledButton.styleFrom(
            backgroundColor: gold,
            foregroundColor: deepTeal,
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
        ),
      ],
    ),
  );
}

class CreateListingPage extends StatefulWidget {
  const CreateListingPage({super.key});
  @override
  State<CreateListingPage> createState() => _CreateListingPageState();
}

class ListingDetailPage extends StatefulWidget {
  const ListingDetailPage({super.key, required this.listingId});
  final String listingId;
  @override
  State<ListingDetailPage> createState() => _ListingDetailPageState();
}

class _ListingDetailPageState extends State<ListingDetailPage> {
  final api = ApiClient();
  late Future<Map<String, dynamic>> listing = api.fetchListing(
    widget.listingId,
  );
  bool? favorite;
  bool? interested;

  Future<void> _toggle(String action) async {
    try {
      final result = action == 'favorite'
          ? await api.toggleListingFavorite(widget.listingId)
          : await api.toggleListingInterested(widget.listingId);
      if (!mounted) return;
      setState(() {
        if (action == 'favorite') {
          favorite = result['active'] as bool;
        } else {
          interested = result['active'] as bool;
        }
      });
    } catch (error) {
      if (!mounted) return;
      if (error.toString().contains('unauthorized')) {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AuthPage()),
        );
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تعذر حفظ التفاعل حالياً')));
    }
  }

  Future<void> _report() async {
    final reason = await showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: paper,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: ListView(
          shrinkWrap: true,
          children: [
            const ListTile(
              title: Text(
                'سبب الإبلاغ',
                style: TextStyle(color: deepTeal, fontWeight: FontWeight.w700),
              ),
            ),
            for (final item in [
              'السعر غير صحيح',
              'محتوى مخالف',
              'إعلان مكرر',
              'المنتج غير متاح',
            ])
              ListTile(
                title: Text(item),
                leading: const Icon(Icons.flag_outlined, color: teal),
                onTap: () => Navigator.pop(context, item),
              ),
          ],
        ),
      ),
    );
    if (reason == null) return;
    try {
      await api.reportListing(widget.listingId, reason);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تم إرسال البلاغ للمراجعة')));
    } catch (error) {
      if (!mounted) return;
      if (error.toString().contains('unauthorized')) {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AuthPage()),
        );
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تعذر إرسال البلاغ')));
    }
  }

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      appBar: AppBar(title: const Text('تفاصيل الإعلان')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: listing,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: teal));
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return _StateMessage(
              icon: Icons.error_outline,
              title: 'الإعلان غير متاح',
              subtitle: 'ربما انتهت مدته أو تم حذفه.',
              actionLabel: 'إعادة المحاولة',
              onAction: () =>
                  setState(() => listing = api.fetchListing(widget.listingId)),
            );
          }
          final data = snapshot.data!;
          final owner = data['owner'] as Map<String, dynamic>?;
          final images = (data['images'] as List<dynamic>? ?? [])
              .map((item) => (item as Map<String, dynamic>)['url'] as String)
              .toList();
          final viewer = data['viewer'] as Map<String, dynamic>?;
          favorite ??= viewer?['favorite'] as bool? ?? false;
          interested ??= viewer?['interested'] as bool? ?? false;
          final title = data['title'] as String? ?? 'إعلان';
          final phone = owner?['phone'] as String?;
          return ListView(
            padding: const EdgeInsets.all(18),
            children: [
              MediaGallery(
                imageCount: images.isEmpty ? 1 : images.length,
                imageUrls: images,
                label: 'صور الإعلان',
                heroTag: 'listing-image-${widget.listingId}',
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: deepTeal,
                        fontSize: 21,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const Chip(
                    label: Text('مراجع'),
                    avatar: Icon(
                      Icons.verified_outlined,
                      size: 16,
                      color: teal,
                    ),
                    backgroundColor: Color(0xFFE8F5F2),
                  ),
                ],
              ),
              Text(
                '${data['price']} جنيه · ${data['area']?['name'] ?? 'قنا'} · ${data['category'] ?? ''}',
                style: const TextStyle(color: muted),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: phone == null
                          ? null
                          : () => AppActions.call(phone),
                      icon: const Icon(Icons.phone_outlined),
                      label: const Text('اتصال'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: phone == null
                          ? null
                          : () => AppActions.whatsapp(
                              phone,
                              message:
                                  'مرحبًا، شفت إعلان «$title» على تطبيق هنا قنا.',
                            ),
                      icon: const Icon(Icons.chat_outlined),
                      label: const Text('واتساب'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                alignment: WrapAlignment.spaceAround,
                children: [
                  TextButton.icon(
                    onPressed: () => _toggle('interested'),
                    icon: Icon(
                      interested == true
                          ? Icons.thumb_up_alt
                          : Icons.thumb_up_alt_outlined,
                    ),
                    label: const Text('مهتم'),
                  ),
                  TextButton.icon(
                    onPressed: () => _toggle('favorite'),
                    icon: Icon(
                      favorite == true ? Icons.bookmark : Icons.bookmark_border,
                    ),
                    label: const Text('حفظ'),
                  ),
                  TextButton.icon(
                    onPressed: () => AppActions.share(
                      context,
                      subject: title,
                      text:
                          '$title\n${data['price']} جنيه · ${data['area']?['name'] ?? 'قنا'}\nمن تطبيق هنا قنا',
                    ),
                    icon: const Icon(Icons.ios_share_outlined),
                    label: const Text('مشاركة'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const SectionTitle(title: 'الوصف'),
              const SizedBox(height: 8),
              Text(
                data['description'] as String? ?? 'لا يوجد وصف إضافي.',
                style: const TextStyle(color: muted, height: 1.5),
              ),
              const SizedBox(height: 18),
              MiniItem(
                icon: Icons.person_outline,
                title: owner?['name'] as String? ?? 'مستخدم هنا قنا',
                subtitle:
                    '${data['_count']?['interests'] ?? 0} مهتم · ${data['_count']?['favorites'] ?? 0} حفظ',
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _report,
                icon: const Icon(Icons.flag_outlined),
                label: const Text('إبلاغ عن الإعلان'),
              ),
            ],
          );
        },
      ),
    ),
  );
}

class _CreateListingPageState extends State<CreateListingPage> {
  final api = ApiClient();
  int step = 0;
  String category = 'للبيع';
  String? areaId;
  late final Future<List<AreaOption>> areas = api.fetchAreas();
  final title = TextEditingController();
  final price = TextEditingController();
  final description = TextEditingController();
  final selectedImages = <XFile>[];
  @override
  void dispose() {
    title.dispose();
    price.dispose();
    description.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final picked = await ImagePicker().pickMultiImage(
      imageQuality: 75,
      maxWidth: 1200,
    );
    if (!mounted || picked.isEmpty) return;
    setState(
      () => selectedImages
        ..clear()
        ..addAll(picked.take(5)),
    );
  }

  Future<void> next() async {
    if (step < 2) {
      setState(() => step++);
      return;
    }
    if (title.text.trim().length < 3 ||
        double.tryParse(price.text.trim()) == null ||
        selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('أكمل العنوان والسعر وأضف صورة واحدة على الأقل'),
        ),
      );
      return;
    }
    try {
      final resolvedArea = areaId;
      if (resolvedArea == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('اختار المنطقة أولاً')));
        setState(() => step = 0);
        return;
      }
      final uploaded = await api.uploadProviderImages(selectedImages);
      await api.submitListing(
        title: title.text.trim(),
        category: category,
        price: double.parse(price.text.trim()),
        areaId: resolvedArea,
        images: uploaded.map((image) => image['url'] as String).toList(),
        description: description.text,
      );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إرسال الإعلان للمراجعة')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.toString().contains('unauthorized')
                ? 'سجّل الدخول أولاً لإضافة إعلان'
                : 'تعذر إرسال الإعلان حالياً',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      appBar: AppBar(title: const Text('إضافة إعلان')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
        children: [
          Text('${step + 1} من 3', style: const TextStyle(color: muted)),
          const SizedBox(height: 7),
          LinearProgressIndicator(
            value: (step + 1) / 3,
            minHeight: 5,
            borderRadius: BorderRadius.circular(8),
            color: teal,
            backgroundColor: const Color(0xFFDDE9E7),
          ),
          const SizedBox(height: 22),
          AnimatedSwitcher(
            duration: AppMotion.standard,
            child: KeyedSubtree(key: ValueKey(step), child: _body()),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: next,
            style: FilledButton.styleFrom(
              backgroundColor: teal,
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(step == 2 ? 'إرسال للمراجعة' : 'التالي'),
          ),
        ],
      ),
    ),
  );
  Widget _body() {
    if (step == 0)
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'بيانات الإعلان',
            style: TextStyle(
              color: deepTeal,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'اختار نوع الإعلان واكتب البيانات الأساسية.',
            style: TextStyle(color: muted),
          ),
          const SizedBox(height: 18),
          const Text(
            'القسم',
            style: TextStyle(color: deepTeal, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: ['للبيع', 'للإيجار', 'وظائف', 'سيارات', 'عقارات']
                .map(
                  (x) => ChoiceChip(
                    label: Text(x),
                    selected: category == x,
                    onSelected: (_) => setState(() => category = x),
                    selectedColor: const Color(0xFFD8EFEC),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 14),
          FutureBuilder<List<AreaOption>>(
            future: areas,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const LinearProgressIndicator(color: teal);
              }
              if (snapshot.hasError) {
                return const Text(
                  'تعذر تحميل المناطق. ارجع وحاول مرة أخرى.',
                  style: TextStyle(color: Colors.red),
                );
              }
              return DropdownButtonFormField<String>(
                initialValue: areaId,
                decoration: const InputDecoration(labelText: 'المنطقة *'),
                items: (snapshot.data ?? const <AreaOption>[])
                    .map(
                      (area) => DropdownMenuItem(
                        value: area.id,
                        child: Text(area.name),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => areaId = value),
              );
            },
          ),
          const SizedBox(height: 18),
          TextField(
            controller: title,
            decoration: const InputDecoration(
              labelText: 'عنوان الإعلان',
              hintText: 'مثال: شقة غرفتين للإيجار',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: price,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'السعر *',
              hintText: 'السعر بالجنيه المصري',
            ),
          ),
        ],
      );
    if (step == 1)
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'صور ووصف',
            style: TextStyle(
              color: deepTeal,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'أضف صورة واضحة واحدة على الأقل، وبحد أقصى 5 صور.',
            style: TextStyle(color: muted),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: selectedImages.length >= 5 ? null : _pickImages,
            icon: const Icon(Icons.add_a_photo_outlined),
            label: Text('إضافة صور (${selectedImages.length}/5)'),
          ),
          if (selectedImages.isNotEmpty)
            SizedBox(
              height: 80,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: selectedImages.length,
                separatorBuilder: (_, index) => const SizedBox(width: 8),
                itemBuilder: (_, index) => ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    File(selectedImages[index].path),
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          const SizedBox(height: 12),
          TextField(
            controller: description,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'وصف الإعلان',
              hintText: 'اكتب التفاصيل المهمة',
            ),
          ),
        ],
      );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'المراجعة والإرسال',
          style: TextStyle(
            color: deepTeal,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'إعلانك سيظهر بعد مراجعة الإدارة والتأكد من السعر والصور.',
          style: TextStyle(color: muted, height: 1.5),
        ),
        const SizedBox(height: 18),
        Card(
          elevation: 0,
          color: Colors.white,
          child: ListTile(
            title: Text(
              title.text.isEmpty ? 'عنوان الإعلان' : title.text,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Text(
              '${price.text.isEmpty ? 'السعر غير مكتوب' : price.text} · $category',
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'بإرسال الإعلان أنت توافق على مراجعته قبل النشر.',
          style: TextStyle(color: muted, fontSize: 12),
        ),
      ],
    );
  }
}

class MediaGallery extends StatefulWidget {
  const MediaGallery({
    super.key,
    required this.imageCount,
    this.imageUrls = const [],
    this.label,
    this.heroTag,
  });
  final int imageCount;
  final List<String> imageUrls;
  final String? label;
  final String? heroTag;
  @override
  State<MediaGallery> createState() => _MediaGalleryState();
}

class _MediaGalleryState extends State<MediaGallery>
    with SingleTickerProviderStateMixin {
  late final PageController controller = PageController();
  late final AnimationController hintController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);
  int active = 0;
  bool showSwipeHint = true;
  final galleryColors = const [
    Color(0xFFD8EFEC),
    Color(0xFFEFE5C8),
    Color(0xFFDDE5EA),
    Color(0xFFE9DDE9),
    Color(0xFFE8F0EE),
  ];
  @override
  void dispose() {
    controller.dispose();
    hintController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      SizedBox(
        height: 205,
        child: PageView.builder(
          controller: controller,
          itemCount: widget.imageCount,
          onPageChanged: (value) => setState(() {
            active = value;
            showSwipeHint = false;
          }),
          itemBuilder: (_, index) {
            final image = Container(
              decoration: BoxDecoration(
                color: galleryColors[index % galleryColors.length],
                borderRadius: BorderRadius.circular(20),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  if (index < widget.imageUrls.length)
                    Positioned.fill(
                      child: Image.network(
                        widget.imageUrls[index],
                        fit: BoxFit.cover,
                        errorBuilder: (_, error, stack) => Center(
                          child: Icon(
                            Icons.image_outlined,
                            color: deepTeal.withValues(alpha: .45),
                            size: 54,
                          ),
                        ),
                      ),
                    )
                  else
                    Center(
                      child: Icon(
                        Icons.image_outlined,
                        color: deepTeal.withValues(alpha: .45),
                        size: 54,
                      ),
                    ),
                  PositionedDirectional(
                    top: 12,
                    end: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .85),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        '${index + 1} / ${widget.imageCount}',
                        style: const TextStyle(
                          color: deepTeal,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
            if (widget.heroTag == null) return image;
            return Hero(tag: widget.heroTag!, child: image);
          },
        ),
      ),
      const SizedBox(height: 8),
      const SizedBox(height: 5),
      AnimatedBuilder(
        animation: hintController,
        builder: (_, value) {
          final dots = [
            for (var i = 0; i < widget.imageCount; i++)
              AnimatedContainer(
                duration: AppMotion.quick,
                width: i == active ? 18 : 6,
                height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: i == active ? teal : const Color(0xFFD6E3E0),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
          ];
          final midpoint = dots.length ~/ 2;
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ...dots.take(midpoint),
              AnimatedContainer(
                duration: AppMotion.quick,
                width: showSwipeHint ? 4 : 0,
              ),
              AnimatedSwitcher(
                duration: AppMotion.standard,
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(scale: animation, child: child),
                ),
                child: showSwipeHint
                    ? Transform.translate(
                        key: const ValueKey('swipe-hint'),
                        offset: Offset(-4 * hintController.value, 0),
                        child: const Icon(Icons.swipe, color: teal, size: 17),
                      )
                    : const SizedBox.shrink(key: ValueKey('swipe-hidden')),
              ),
              AnimatedContainer(
                duration: AppMotion.quick,
                width: showSwipeHint ? 4 : 0,
              ),
              ...dots.skip(midpoint),
            ],
          );
        },
      ),
    ],
  );
}

class AccountPage extends StatelessWidget {
  const AccountPage({super.key});
  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      appBar: AppBar(
        title: const Text('حسابي'),
        actions: [
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsPage()),
            ),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: ApiClient().fetchMe(),
        builder: (context, snapshot) {
          final profile = snapshot.data;
          final profileName =
              profile?['name'] as String? ?? AuthSession.name ?? 'حسابي';
          final points = profile?['points'] as int? ?? 0;
          final level = profile?['level'] as String? ?? 'QENAWY';
          final levelLabel = level == 'QENAWY_ASIL'
              ? 'قناوي أصيل'
              : level == 'QENAWY_RAYEQ'
              ? 'قناوي رايق'
              : 'قناوي';
          return ListView(
            padding: const EdgeInsets.all(18),
            children: [
              Card(
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                child: ListTile(
                  contentPadding: EdgeInsets.all(14),
                  leading: CircleAvatar(
                    radius: 25,
                    backgroundColor: deepTeal,
                    child: Text(
                      profileName.isEmpty ? 'هـ' : profileName.characters.first,
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ),
                  title: Text(
                    profileName,
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    '$levelLabel · $points نقطة',
                    style: TextStyle(color: teal),
                  ),
                  trailing: Icon(Icons.chevron_left),
                ),
              ),
              const SizedBox(height: 10),
              _AccountTile(
                icon: Icons.notifications_none,
                title: 'الإشعارات',
                subtitle: '3 إشعارات جديدة',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NotificationsPage()),
                ),
              ),
              _AccountTile(
                icon: Icons.favorite_border,
                title: 'المفضلة',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const FavoritesPage()),
                ),
              ),
              _AccountTile(
                icon: Icons.rate_review_outlined,
                title: 'تقييماتي ومساهماتي',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ContributionsPage()),
                ),
              ),
              _AccountTile(
                icon: Icons.campaign_outlined,
                title: 'إعلاناتي',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MyListingsPage()),
                ),
              ),
              const Divider(height: 26),
              _AccountTile(
                icon: Icons.settings_outlined,
                title: 'الإعدادات',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsPage()),
                ),
              ),
              _AccountTile(
                icon: Icons.help_outline,
                title: 'المساعدة والدعم',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SupportPage()),
                ),
              ),
              _AccountTile(
                icon: Icons.delete_outline,
                title: 'حذف الحساب',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsPage()),
                ),
                destructive: true,
              ),
            ],
          );
        },
      ),
    ),
  );
}

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});
  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  late Future<Map<String, dynamic>> favorites = ApiClient().fetchFavorites();
  void _reload() => setState(() => favorites = ApiClient().fetchFavorites());

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      appBar: AppBar(title: const Text('المفضلة')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: favorites,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: teal));
          }
          if (snapshot.hasError) {
            return _StateMessage(
              icon: Icons.lock_outline,
              title: 'سجّل الدخول لعرض المفضلة',
              subtitle: 'المفضلة محفوظة على حسابك وتظهر على كل أجهزتك.',
              actionLabel: 'تسجيل الدخول',
              onAction: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AuthPage()),
                );
                _reload();
              },
            );
          }
          final providers = snapshot.data?['providers'] as List<dynamic>? ?? [];
          final listings = snapshot.data?['listings'] as List<dynamic>? ?? [];
          if (providers.isEmpty && listings.isEmpty) {
            return const _StateMessage(
              icon: Icons.favorite_border,
              title: 'المفضلة فاضية',
              subtitle: 'احفظ الأماكن والإعلانات المهمة وهتلاقيها هنا.',
            );
          }
          return ListView(
            padding: const EdgeInsets.all(18),
            children: [
              if (providers.isNotEmpty) ...[
                const SectionTitle(title: 'الأماكن والخدمات'),
                const SizedBox(height: 8),
                for (final value in providers)
                  Builder(
                    builder: (context) {
                      final provider = value as Map<String, dynamic>;
                      return MiniItem(
                        icon: Icons.storefront_outlined,
                        title: provider['name'] as String? ?? 'نشاط',
                        subtitle: provider['area']?['name'] as String? ?? 'قنا',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ProviderDetailPage(
                              providerId: provider['id'] as String,
                              title: provider['name'] as String? ?? 'نشاط',
                              icon: Icons.storefront_outlined,
                              subtitle:
                                  provider['area']?['name'] as String? ?? 'قنا',
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                const SizedBox(height: 18),
              ],
              if (listings.isNotEmpty) ...[
                const SectionTitle(title: 'الإعلانات'),
                const SizedBox(height: 8),
                for (final value in listings)
                  Builder(
                    builder: (context) {
                      final listing = value as Map<String, dynamic>;
                      return MiniItem(
                        icon: Icons.campaign_outlined,
                        title: listing['title'] as String? ?? 'إعلان',
                        subtitle:
                            '${listing['price']} جنيه · ${listing['area']?['name'] ?? 'قنا'}',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ListingDetailPage(
                              listingId: listing['id'] as String,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ],
          );
        },
      ),
    ),
  );
}

class MyListingsPage extends StatefulWidget {
  const MyListingsPage({super.key});
  @override
  State<MyListingsPage> createState() => _MyListingsPageState();
}

class _MyListingsPageState extends State<MyListingsPage> {
  final api = ApiClient();
  late Future<Map<String, dynamic>> contributions = api.fetchContributions();
  void _reload() => setState(() => contributions = api.fetchContributions());

  String _status(String? value) => switch (value) {
    'PENDING' => 'قيد المراجعة',
    'ACTIVE' => 'منشور',
    'EXPIRED' => 'منتهي',
    'ARCHIVED' => 'مؤرشف',
    'REJECTED' => 'مرفوض',
    _ => 'غير معروف',
  };

  Future<void> _renew(String id) async {
    try {
      await api.renewListing(id);
      _reload();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تعذر إعادة نشر الإعلان')));
      }
    }
  }

  Future<void> _delete(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف الإعلان نهائيًا؟'),
        content: const Text('سيتم حذف الإعلان وصوره ولا يمكن استرجاعه.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await api.deleteListing(id);
      _reload();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تعذر حذف الإعلان')));
      }
    }
  }

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      appBar: AppBar(title: const Text('إعلاناتي')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: contributions,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: teal));
          }
          final items = snapshot.data?['listings'] as List<dynamic>? ?? [];
          if (snapshot.hasError || items.isEmpty) {
            return const _StateMessage(
              icon: Icons.campaign_outlined,
              title: 'مفيش إعلانات على حسابك',
              subtitle: 'أضف إعلانًا من قسم «عندك؟» وتابع حالته هنا.',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(18),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index] as Map<String, dynamic>;
              final status = item['status'] as String?;
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(item['title'] as String? ?? 'إعلان'),
                        subtitle: Text(
                          '${item['price']} جنيه · ${_status(status)}',
                        ),
                      ),
                      Row(
                        children: [
                          if (status == 'EXPIRED' || status == 'ARCHIVED')
                            Expanded(
                              child: FilledButton(
                                onPressed: () => _renew(item['id'] as String),
                                child: const Text('إعادة نشر'),
                              ),
                            ),
                          if (status == 'EXPIRED' || status == 'ARCHIVED')
                            const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _delete(item['id'] as String),
                              child: const Text('حذف نهائي'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    ),
  );
}

class SupportPage extends StatefulWidget {
  const SupportPage({super.key});
  @override
  State<SupportPage> createState() => _SupportPageState();
}

class _SupportPageState extends State<SupportPage> {
  final subject = TextEditingController();
  final message = TextEditingController();
  bool submitting = false;

  @override
  void dispose() {
    subject.dispose();
    message.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (subject.text.trim().length < 3 || message.text.trim().length < 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اكتب عنوانًا ورسالة واضحة')),
      );
      return;
    }
    setState(() => submitting = true);
    try {
      await ApiClient().submitSupportTicket(
        subject: subject.text,
        message: message.text,
      );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تم إرسال طلب الدعم')));
    } catch (error) {
      if (!mounted) return;
      if (error.toString().contains('unauthorized')) {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AuthPage()),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تعذر إرسال الطلب')));
      }
    } finally {
      if (mounted) setState(() => submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      appBar: AppBar(title: const Text('المساعدة والدعم')),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          const Text(
            'قول لنا المشكلة أو الاقتراح، وفريق هنا قنا هيراجعه.',
            style: TextStyle(color: muted),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: subject,
            decoration: const InputDecoration(labelText: 'عنوان الطلب'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: message,
            maxLines: 6,
            decoration: const InputDecoration(labelText: 'التفاصيل'),
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: submitting ? null : _submit,
            child: Text(submitting ? 'جارٍ الإرسال…' : 'إرسال'),
          ),
        ],
      ),
    ),
  );
}

class _AccountTile extends StatelessWidget {
  const _AccountTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.destructive = false,
  });
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final bool destructive;
  @override
  Widget build(BuildContext context) => ListTile(
    onTap: onTap,
    contentPadding: const EdgeInsets.symmetric(horizontal: 4),
    leading: Icon(icon, color: destructive ? Colors.redAccent : teal),
    title: Text(
      title,
      style: TextStyle(color: destructive ? Colors.redAccent : ink),
    ),
    subtitle: subtitle == null
        ? null
        : Text(subtitle!, style: const TextStyle(color: muted, fontSize: 12)),
    trailing: const Icon(Icons.chevron_left, color: muted),
  );
}

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});
  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final api = ApiClient();
  late Future<List<Map<String, dynamic>>> notifications = api
      .fetchNotifications();
  Future<void> _reload() async =>
      setState(() => notifications = api.fetchNotifications());
  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      appBar: AppBar(
        title: const Text('الإشعارات'),
        actions: [
          TextButton(
            onPressed: () async {
              await api.markAllNotificationsRead();
              await _reload();
            },
            child: const Text('تحديد الكل'),
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: notifications,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator(color: teal));
          final items = snapshot.data ?? const <Map<String, dynamic>>[];
          if (items.isEmpty)
            return RefreshIndicator(
              onRefresh: _reload,
              color: teal,
              child: ListView(
                children: const [
                  Padding(
                    padding: EdgeInsets.all(40),
                    child: Text(
                      'مفيش إشعارات جديدة دلوقتي.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: muted),
                    ),
                  ),
                ],
              ),
            );
          return RefreshIndicator(
            onRefresh: _reload,
            color: teal,
            child: ListView(
              padding: const EdgeInsets.all(18),
              children: [
                const Text(
                  'الإشعارات',
                  style: TextStyle(
                    color: deepTeal,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                ...items.asMap().entries.map((entry) {
                  final item = entry.value;
                  return MotionIn(
                    delay: entry.key * 50,
                    child: GestureDetector(
                      onTap: () async {
                        if (item['readAt'] == null) {
                          await api.markNotificationRead(item['id'] as String);
                          await _reload();
                        }
                      },
                      child: _NotificationCard(
                        icon: Icons.notifications_none,
                        title: item['title'] as String? ?? 'تحديث جديد',
                        subtitle: item['body'] as String? ?? '',
                        unread: item['readAt'] == null,
                      ),
                    ),
                  );
                }),
              ],
            ),
          );
        },
      ),
    ),
  );
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.unread = false,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final bool unread;
  @override
  Widget build(BuildContext context) => Card(
    elevation: 0,
    margin: const EdgeInsets.only(bottom: 8),
    color: unread ? const Color(0xFFEFF8F6) : Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(15),
      side: const BorderSide(color: Color(0xFFE0E8E6)),
    ),
    child: ListTile(
      leading: CircleAvatar(
        backgroundColor: const Color(0xFFD8EFEC),
        child: Icon(icon, color: deepTeal),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: muted, fontSize: 12),
      ),
      trailing: unread
          ? TweenAnimationBuilder<double>(
              tween: Tween(begin: .55, end: 1),
              duration: AppMotion.gentle,
              curve: Curves.easeOutBack,
              builder: (_, value, child) =>
                  Transform.scale(scale: value, child: child),
              child: const Icon(Icons.circle, size: 9, color: teal),
            )
          : null,
    ),
  );
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
  int imageCount = 0;
  final selectedImages = <XFile>[];
  bool preview = false;
  late Future<List<AreaOption>> areas;
  late Future<List<CategoryOption>> categories;

  @override
  void initState() {
    super.initState();
    areas = api.fetchAreas();
    categories = api.fetchCategories();
  }

  @override
  void dispose() {
    for (final controller in [name, description, address, phone, whatsapp]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      appBar: AppBar(title: Text(preview ? 'مراجعة النشاط' : 'أضف نشاط')),
      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
          children: [
            if (!preview) ...[
              _intro(),
              _fields(),
            ] else ...[
              _previewCard(),
              const SizedBox(height: 14),
              const Text(
                'سيظهر النشاط بعد مراجعة الإدارة فقط، وسيحمل شارة «مضاف من المجتمع».',
                style: TextStyle(color: muted, height: 1.5),
              ),
            ],
            const SizedBox(height: 22),
            FilledButton(
              onPressed: preview ? _submit : _review,
              style: FilledButton.styleFrom(
                backgroundColor: teal,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: Text(preview ? 'إرسال للمراجعة' : 'معاينة النشاط'),
            ),
            if (preview)
              TextButton(
                onPressed: () => setState(() => preview = false),
                child: const Text('تعديل البيانات'),
              ),
          ],
        ),
      ),
    ),
  );

  Widget _intro() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: const [
      Text(
        'ساعد أهل قنا يعرفوا نشاطك',
        style: TextStyle(
          color: deepTeal,
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),
      ),
      SizedBox(height: 6),
      Text(
        'أضف البيانات الأساسية، وإحنا نراجعها قبل ما تظهر للجمهور.',
        style: TextStyle(color: muted),
      ),
      SizedBox(height: 18),
    ],
  );

  Widget _fields() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      TextFormField(
        controller: name,
        decoration: const InputDecoration(labelText: 'اسم النشاط *'),
        validator: (value) =>
            value == null || value.trim().length < 2 ? 'اكتب اسم النشاط' : null,
      ),
      const SizedBox(height: 12),
      FutureBuilder<List<CategoryOption>>(
        future: categories,
        builder: (_, snapshot) => DropdownButtonFormField<String>(
          initialValue: categoryId,
          decoration: const InputDecoration(labelText: 'نوع النشاط *'),
          items: (snapshot.data ?? const [])
              .map(
                (item) =>
                    DropdownMenuItem(value: item.id, child: Text(item.name)),
              )
              .toList(),
          onChanged: (value) => setState(() => categoryId = value),
          validator: (value) => value == null ? 'اختار نوع النشاط' : null,
        ),
      ),
      const SizedBox(height: 12),
      SegmentedButton<String>(
        segments: const [
          ButtonSegment(
            value: 'LOCAL',
            label: Text('محلي'),
            icon: Icon(Icons.storefront_outlined),
          ),
          ButtonSegment(
            value: 'ONLINE',
            label: Text('أونلاين'),
            icon: Icon(Icons.language),
          ),
        ],
        selected: {mode},
        onSelectionChanged: (value) => setState(() => mode = value.first),
      ),
      const SizedBox(height: 12),
      FutureBuilder<List<AreaOption>>(
        future: areas,
        builder: (_, snapshot) => DropdownButtonFormField<String>(
          initialValue: areaId,
          decoration: const InputDecoration(labelText: 'المنطقة *'),
          items: (snapshot.data ?? const [])
              .map(
                (item) =>
                    DropdownMenuItem(value: item.id, child: Text(item.name)),
              )
              .toList(),
          onChanged: mode == 'ONLINE'
              ? null
              : (value) => setState(() => areaId = value),
          validator: (value) =>
              mode == 'ONLINE' || value != null ? null : 'اختار المنطقة',
        ),
      ),
      const SizedBox(height: 12),
      if (mode == 'LOCAL')
        TextFormField(
          controller: address,
          decoration: const InputDecoration(labelText: 'العنوان بالتفصيل *'),
          validator: (value) =>
              mode == 'LOCAL' && (value == null || value.trim().isEmpty)
              ? 'اكتب العنوان'
              : null,
        ),
      if (mode == 'LOCAL') const SizedBox(height: 12),
      TextFormField(
        controller: description,
        maxLines: 3,
        decoration: const InputDecoration(
          labelText: 'وصف مختصر',
          hintText: 'اكتب للناس نشاطك بيقدم إيه',
        ),
      ),
      const SizedBox(height: 12),
      TextFormField(
        controller: phone,
        keyboardType: TextInputType.phone,
        decoration: const InputDecoration(labelText: 'رقم الهاتف *'),
        validator: (value) =>
            value == null || !RegExp(r'^01[0125][0-9]{8}$').hasMatch(value)
            ? 'اكتب رقم مصري صحيح'
            : null,
      ),
      const SizedBox(height: 12),
      SegmentedButton<String>(
        segments: const [
          ButtonSegment(value: 'BUSINESS', label: Text('رقم نشاط')),
          ButtonSegment(value: 'PERSONAL', label: Text('رقم شخصي')),
        ],
        selected: {phoneType},
        onSelectionChanged: (value) => setState(() => phoneType = value.first),
      ),
      const SizedBox(height: 12),
      TextFormField(
        controller: whatsapp,
        keyboardType: TextInputType.phone,
        decoration: const InputDecoration(labelText: 'واتساب (اختياري)'),
      ),
      const SizedBox(height: 14),
      if (mode == 'LOCAL')
        Row(
          children: [
            const Expanded(
              child: Text(
                'مواعيد العمل',
                style: TextStyle(color: deepTeal, fontWeight: FontWeight.w700),
              ),
            ),
            TextButton(onPressed: () => _pickTime(true), child: Text(opening)),
            const Text('–'),
            TextButton(onPressed: () => _pickTime(false), child: Text(closing)),
          ],
        ),
      const SizedBox(height: 8),
      Row(
        children: [
          Expanded(
            child: Text(
              'الصور ${selectedImages.isEmpty ? imageCount : selectedImages.length} / 10',
              style: const TextStyle(
                color: deepTeal,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          IconButton(
            onPressed: selectedImages.length >= 10 ? null : _pickImages,
            icon: const Icon(Icons.add_a_photo_outlined, color: teal),
          ),
        ],
      ),
      if (selectedImages.isNotEmpty)
        SizedBox(
          height: 76,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: selectedImages.length,
            separatorBuilder: (_, index) => const SizedBox(width: 8),
            itemBuilder: (_, index) => ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                File(selectedImages[index].path),
                width: 76,
                height: 76,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
      Text(
        selectedImages.isEmpty
            ? 'أضف من 1 إلى 10 صور واضحة للنشاط.'
            : 'تم اختيار ${selectedImages.length} صور — الصورة الأولى هي الغلاف.',
        style: const TextStyle(color: muted, fontSize: 12),
      ),
    ],
  );

  Future<void> _pickTime(bool isOpening) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: int.parse((isOpening ? opening : closing).split(':').first),
        minute: 0,
      ),
    );
    if (picked != null) {
      setState(() {
        final value = picked.format(context);
        if (isOpening) {
          opening = value;
        } else {
          closing = value;
        }
      });
    }
  }

  Future<void> _pickImages() async {
    final picked = await ImagePicker().pickMultiImage(
      imageQuality: 75,
      maxWidth: 1200,
    );
    if (!mounted || picked.isEmpty) return;
    setState(() {
      selectedImages
        ..clear()
        ..addAll(picked.take(10));
      imageCount = selectedImages.length;
    });
  }

  void _review() {
    if (!(formKey.currentState?.validate() ?? false)) return;
    if (selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('أضف صورة واضحة واحدة على الأقل للنشاط')),
      );
      return;
    }
    setState(() => preview = true);
  }

  Widget _previewCard() => Card(
    elevation: 0,
    color: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
      side: const BorderSide(color: Color(0xFFE0E8E6)),
    ),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 130,
            decoration: BoxDecoration(
              color: const Color(0xFFD8EFEC),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.image_outlined, color: deepTeal, size: 52),
          ),
          const SizedBox(height: 14),
          Text(
            name.text,
            style: const TextStyle(
              color: deepTeal,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${mode == 'LOCAL' ? 'محلي' : 'أونلاين'} · ${phoneType == 'BUSINESS' ? 'رقم نشاط' : 'رقم شخصي'}',
            style: const TextStyle(color: teal),
          ),
          if (address.text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(address.text, style: const TextStyle(color: muted)),
            ),
          if (description.text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                description.text,
                style: const TextStyle(color: ink, height: 1.4),
              ),
            ),
          const SizedBox(height: 12),
          const Row(
            children: [
              Icon(Icons.hourglass_top_outlined, size: 16, color: gold),
              SizedBox(width: 5),
              Text(
                'بانتظار مراجعة الإدارة',
                style: TextStyle(color: muted, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    ),
  );
  Future<void> _submit() async {
    try {
      final category = categoryId;
      if (category == null) return;
      final resolvedArea = areaId ?? (await areas).first.id;
      final uploadedImages = await api.uploadProviderImages(selectedImages);
      await api.submitProvider(
        data: {
          'name': name.text.trim(),
          'description': description.text.trim(),
          'phone': phone.text.trim(),
          'whatsapp': whatsapp.text.trim().isEmpty
              ? null
              : whatsapp.text.trim(),
          'phoneType': phoneType,
          'serviceMode': mode,
          'areaId': resolvedArea,
          'categoryIds': [category],
          'openingTime': opening,
          'closingTime': closing,
          'address': address.text.trim(),
          'images': uploadedImages,
        },
      );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إرسال النشاط وصوره للمراجعة')),
      );
    } catch (error) {
      if (!mounted) return;
      if (error.toString().contains('unauthorized')) {
        await Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const AuthPage()));
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.toString().contains('duplicate')
                ? 'النشاط موجود بالفعل أو قيد المراجعة'
                : error.toString().contains('upload_error')
                ? 'تعذر رفع الصور، جرّب صوراً أصغر'
                : 'تعذر إرسال النشاط حالياً',
          ),
        ),
      );
    }
  }
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
  void dispose() {
    name.dispose();
    phone.dispose();
    note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      appBar: AppBar(
        title: Text(widget.kind == 'CLAIM' ? 'أملك نشاط' : 'أبلغ عن نشاط'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Text(
            widget.kind == 'CLAIM'
                ? 'أثبت ملكيتك لنشاط موجود'
                : 'ساعدنا نراجع بيانات نشاط',
            style: const TextStyle(
              color: deepTeal,
              fontSize: 21,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.kind == 'CLAIM'
                ? 'اكتب بيانات النشاط وهنراجع الطلب مع الإدارة.'
                : 'اكتب اسم النشاط وسبب البلاغ، ولن يظهر البلاغ للجمهور.',
            style: const TextStyle(color: muted, height: 1.5),
          ),
          const SizedBox(height: 22),
          TextField(
            controller: name,
            decoration: const InputDecoration(labelText: 'اسم النشاط *'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: phone,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'رقم الهاتف (اختياري)',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: note,
            maxLines: 5,
            decoration: InputDecoration(
              labelText: widget.kind == 'CLAIM'
                  ? 'معلومة تساعدنا في التحقق'
                  : 'سبب البلاغ',
            ),
          ),
          const SizedBox(height: 22),
          FilledButton(
            onPressed: _submit,
            style: FilledButton.styleFrom(
              backgroundColor: teal,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            child: const Text('إرسال للمراجعة'),
          ),
        ],
      ),
    ),
  );
  Future<void> _submit() async {
    if (name.text.trim().length < 2) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('اكتب اسم النشاط')));
      return;
    }
    try {
      await api.submitProviderReport(
        data: {
          'kind': widget.kind,
          'name': name.text.trim(),
          'phone': phone.text.trim().isEmpty ? null : phone.text.trim(),
          'note': note.text.trim().isEmpty ? null : note.text.trim(),
        },
      );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تم إرسال الطلب للمراجعة')));
    } catch (error) {
      if (!mounted) return;
      if (error.toString().contains('unauthorized')) {
        await Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const AuthPage()));
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تعذر إرسال الطلب حالياً')));
    }
  }
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final api = ApiClient();
  bool allNotifications = true;
  bool areaOnly = false;
  bool privateProfile = false;
  Future<void> _adminLogin() async {
    final email = TextEditingController();
    final password = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('دخول الإدارة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'البريد الإداري'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: password,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'كلمة المرور'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('دخول'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await api.adminLogin(email: email.text.trim(), password: password.text);
      if (mounted)
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AdminControlPage()),
        );
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('بيانات الإدارة غير صحيحة')),
        );
    }
  }

  Future<void> _logoutAll() async {
    try {
      await api.logoutAll();
      if (mounted)
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const WelcomeScreen()),
          (_) => false,
        );
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر تسجيل الخروج حالياً')),
        );
    }
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف الحساب؟'),
        content: const Text(
          'سيتم حذف بيانات الحساب والإعلانات المرتبطة به نهائياً.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await api.deleteAccount();
      if (mounted)
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const WelcomeScreen()),
          (_) => false,
        );
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تعذر حذف الحساب حالياً')));
    }
  }

  Future<void> _changePassword() async {
    final current = TextEditingController();
    final next = TextEditingController();
    final submit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تغيير كلمة المرور'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: current,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'كلمة المرور الحالية',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: next,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'كلمة المرور الجديدة',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
    if (submit != true) return;
    try {
      await api.changePassword(
        currentPassword: current.text,
        newPassword: next.text,
      );
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تم تغيير كلمة المرور')));
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تأكد من كلمة المرور الجديدة والحالية')),
        );
    }
  }

  Future<void> _savePreferences() async {
    try {
      await api.updatePreferences(
        profilePrivate: privateProfile,
        notificationScope: areaOnly ? 'area' : 'all',
        notificationDigest: !allNotifications,
      );
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر حفظ الإعدادات حالياً')),
        );
    }
  }

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      appBar: AppBar(title: const Text('الإعدادات')),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Card(
            elevation: 0,
            color: const Color(0xFFE8F5F2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListTile(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddActivityPage()),
              ),
              leading: const CircleAvatar(
                backgroundColor: teal,
                child: Icon(Icons.add_business_outlined, color: Colors.white),
              ),
              title: const Text(
                'أضف نشاط',
                style: TextStyle(color: deepTeal, fontWeight: FontWeight.w700),
              ),
              subtitle: const Text(
                'ساعدنا نضيف نشاط موثوق لقنا',
                style: TextStyle(color: muted),
              ),
              trailing: const Icon(Icons.chevron_left, color: deepTeal),
            ),
          ),
          const SizedBox(height: 18),
          _AccountTile(
            icon: Icons.verified_user_outlined,
            title: 'أملك نشاط',
            subtitle: 'اطلب إثبات ملكية نشاط موجود',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const CommunityRequestPage(kind: 'CLAIM'),
              ),
            ),
          ),
          _AccountTile(
            icon: Icons.flag_outlined,
            title: 'أبلغ عن نشاط',
            subtitle: 'أرسل ملاحظة للإدارة للمراجعة',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const CommunityRequestPage(kind: 'REPORT'),
              ),
            ),
          ),
          _AccountTile(
            icon: Icons.password_outlined,
            title: 'تغيير كلمة المرور',
            onTap: _changePassword,
          ),
          _AccountTile(
            icon: Icons.logout,
            title: 'تسجيل الخروج من كل الأجهزة',
            onTap: _logoutAll,
          ),
          _AccountTile(
            icon: Icons.admin_panel_settings_outlined,
            title: AuthSession.adminToken == null
                ? 'دخول الإدارة'
                : 'لوحة الإدارة',
            subtitle: AuthSession.adminToken == null
                ? 'للمدير وفريق المراجعة'
                : 'صلاحية ${AuthSession.adminRole ?? 'إدارة'}',
            onTap: AuthSession.adminToken == null
                ? _adminLogin
                : () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminControlPage()),
                  ),
          ),
          const Divider(height: 26),
          const Text(
            'الإشعارات',
            style: TextStyle(color: deepTeal, fontWeight: FontWeight.w700),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('كل الإشعارات'),
            value: allNotifications,
            onChanged: (value) {
              setState(() => allNotifications = value);
              _savePreferences();
            },
            activeThumbColor: teal,
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('إشعارات منطقتي فقط'),
            value: areaOnly,
            onChanged: (value) {
              setState(() => areaOnly = value);
              _savePreferences();
            },
            activeThumbColor: teal,
          ),
          const Divider(height: 26),
          const Text(
            'الخصوصية',
            style: TextStyle(color: deepTeal, fontWeight: FontWeight.w700),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('جعل صفحتي خاصة'),
            subtitle: const Text(
              'مساهماتك تظل ظاهرة باسمك',
              style: TextStyle(color: muted, fontSize: 12),
            ),
            value: privateProfile,
            onChanged: (value) {
              setState(() => privateProfile = value);
              _savePreferences();
            },
            activeThumbColor: teal,
          ),
          const Divider(height: 26),
          const ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.location_on_outlined, color: teal),
            title: Text('المناطق المختارة'),
            subtitle: Text('قنا كلها', style: TextStyle(color: muted)),
          ),
          _AccountTile(
            icon: Icons.delete_forever_outlined,
            title: 'حذف الحساب نهائياً',
            onTap: _deleteAccount,
            destructive: true,
          ),
          const ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.language, color: teal),
            title: Text('اللغة'),
            subtitle: Text('العربية', style: TextStyle(color: muted)),
          ),
        ],
      ),
    ),
  );
}

class AdminControlPage extends StatefulWidget {
  const AdminControlPage({super.key});
  @override
  State<AdminControlPage> createState() => _AdminControlPageState();
}

class _AdminControlPageState extends State<AdminControlPage> {
  final api = ApiClient();
  late Future<List<Map<String, dynamic>>> providers = api.fetchAdminProviders();
  late Future<List<Map<String, dynamic>>> listings = api.fetchAdminListings();
  Future<void> _reload() async => setState(() {
    providers = api.fetchAdminProviders();
    listings = api.fetchAdminListings();
  });
  Future<void> _logout() async {
    await api.adminLogout();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      appBar: AppBar(
        title: const Text('لوحة الإدارة'),
        actions: [
          IconButton(onPressed: _reload, icon: const Icon(Icons.refresh)),
          IconButton(onPressed: _logout, icon: const Icon(Icons.logout)),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _reload,
        color: teal,
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            Text(
              'مرحباً ${AuthSession.adminName ?? ''}',
              style: const TextStyle(
                color: deepTeal,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'طلبات الأنشطة',
              style: TextStyle(color: deepTeal, fontWeight: FontWeight.w700),
            ),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: providers,
              builder: (context, snapshot) {
                final items = (snapshot.data ?? const <Map<String, dynamic>>[])
                    .where((item) => item['status'] == 'PENDING')
                    .toList();
                return Column(
                  children: [
                    for (final item in items)
                      _AdminApprovalTile(
                        title: item['name'] as String,
                        subtitle: item['area']?['name'] as String? ?? 'قنا',
                        onApprove: () async {
                          await api.moderateAdminProvider(
                            id: item['id'] as String,
                            status: 'APPROVED',
                          );
                          await _reload();
                        },
                        onReject: () async {
                          await api.moderateAdminProvider(
                            id: item['id'] as String,
                            status: 'REJECTED',
                          );
                          await _reload();
                        },
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 18),
            const Text(
              'طلبات الإعلانات المحلية',
              style: TextStyle(color: deepTeal, fontWeight: FontWeight.w700),
            ),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: listings,
              builder: (context, snapshot) {
                final items = (snapshot.data ?? const <Map<String, dynamic>>[])
                    .where((item) => item['status'] == 'PENDING')
                    .toList();
                return Column(
                  children: [
                    for (final item in items)
                      _AdminApprovalTile(
                        title: item['title'] as String,
                        subtitle:
                            '${item['price']} جنيه · ${item['area']?['name'] ?? 'قنا'}',
                        onApprove: () async {
                          await api.moderateAdminListing(
                            id: item['id'] as String,
                            status: 'ACTIVE',
                          );
                          await _reload();
                        },
                        onReject: () async {
                          await api.moderateAdminListing(
                            id: item['id'] as String,
                            status: 'REJECTED',
                          );
                          await _reload();
                        },
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    ),
  );
}

class _AdminApprovalTile extends StatelessWidget {
  const _AdminApprovalTile({
    required this.title,
    required this.subtitle,
    required this.onApprove,
    required this.onReject,
  });
  final String title;
  final String subtitle;
  final Future<void> Function() onApprove;
  final Future<void> Function() onReject;
  @override
  Widget build(BuildContext context) => Card(
    elevation: 0,
    margin: const EdgeInsets.only(top: 8),
    child: ListTile(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(subtitle),
      trailing: Wrap(
        spacing: 4,
        children: [
          IconButton(
            onPressed: onApprove,
            color: teal,
            icon: const Icon(Icons.check_circle_outline),
          ),
          IconButton(
            onPressed: onReject,
            color: Colors.redAccent,
            icon: const Icon(Icons.cancel_outlined),
          ),
        ],
      ),
    ),
  );
}
