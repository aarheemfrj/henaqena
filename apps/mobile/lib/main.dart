import 'dart:io';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'core/auth/auth_session.dart';
import 'core/auth/social_auth_service.dart';
import 'core/platform/app_actions.dart';
import 'core/theme/app_theme.dart';
import 'core/network/api_client.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Future.wait([AuthSession.restore(), AppThemeController.restore()]);
  runApp(const HenaQenaApp());
}

String _relativeTime(dynamic raw) {
  final date = raw is String ? DateTime.tryParse(raw)?.toLocal() : null;
  if (date == null) return '';
  final difference = DateTime.now().difference(date);
  if (difference.inMinutes < 1) return 'الآن';
  if (difference.inHours < 1) return 'منذ ${difference.inMinutes} د';
  if (difference.inDays < 1) return 'منذ ${difference.inHours} س';
  if (difference.inDays < 7) return 'منذ ${difference.inDays} ي';
  return '${date.day}/${date.month}/${date.year}';
}

void showTopToast(BuildContext context, {required String message, bool isError = false}) {
  final colors = AppThemeController.current;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: isError ? Colors.redAccent : colors.primary,
      duration: const Duration(seconds: 3),
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      elevation: 6,
    ),
  );
}

class SocialPlatform {
  const SocialPlatform({
    required this.label,
    required this.icon,
    required this.color,
  });
  final String label;
  final FaIconData icon;
  final Color color;

  static const _platforms = <String, SocialPlatform>{
    'facebook': SocialPlatform(
      label: 'فيسبوك',
      icon: FontAwesomeIcons.facebook,
      color: Color(0xFF1877F2),
    ),
    'instagram': SocialPlatform(
      label: 'إنستجرام',
      icon: FontAwesomeIcons.instagram,
      color: Color(0xFFE1306C),
    ),
    'x': SocialPlatform(
      label: 'إكس',
      icon: FontAwesomeIcons.xTwitter,
      color: Color(0xFF000000),
    ),
    'tiktok': SocialPlatform(
      label: 'تيك توك',
      icon: FontAwesomeIcons.tiktok,
      color: Color(0xFF000000),
    ),
    'youtube': SocialPlatform(
      label: 'يوتيوب',
      icon: FontAwesomeIcons.youtube,
      color: Color(0xFFFF0000),
    ),
  };

  static SocialPlatform? of(String? key) =>
      key == null ? null : _platforms[key];

  static Map<String, SocialPlatform> get all => _platforms;
}

class HenaQenaApp extends StatelessWidget {
  const HenaQenaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: AppThemeController.selectedId,
      builder: (context, themeId, _) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'هنا قنا',
        theme: AppThemeController.theme(AppThemeController.current),
        home: _ThemeScope(
          key: ValueKey(themeId),
          child: AuthSession.isSignedIn ? const HomeShell() : const WelcomeScreen(),
        ),
      ),
    );
  }
}

class _ThemeScope extends StatelessWidget {
  const _ThemeScope({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: AppThemeController.selectedId,
      builder: (context, _, _) => child,
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
            decoration: BoxDecoration(
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
                    side: BorderSide(color: teal),
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
                  child: Text(
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
  const AuthPage({
    super.key,
    this.createAccount = false,
    this.setupAreas = const [],
    this.setupInterests = const [],
    this.setupAge,
    this.setupGender,
  });
  final bool createAccount;
  final List<String> setupAreas;
  final List<String> setupInterests;
  final String? setupAge;
  final String? setupGender;

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
        await api.login(identifier: phone.text.trim(), password: password.text);
      }
      if (widget.setupAreas.isNotEmpty || widget.setupInterests.isNotEmpty) {
        final availableAreas = await api.fetchAreas();
        final areaIds = availableAreas
            .where((area) => widget.setupAreas.contains(area.name))
            .map((area) => area.id)
            .take(3)
            .toList();
        await api.updatePreferences(
          profilePrivate: false,
          notificationScope: 'all',
          notificationDigest: false,
          preferredAreaIds: areaIds,
          interests: widget.setupInterests,
          ageRange: widget.setupAge,
          gender: widget.setupGender,
        );
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
              style: TextStyle(
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
              keyboardType: createAccount
                  ? TextInputType.phone
                  : TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: createAccount
                    ? 'رقم الموبايل المصري *'
                    : 'رقم الموبايل أو البريد الإلكتروني *',
              ),
              validator: (value) {
                final input = value?.trim() ?? '';
                final validPhone = RegExp(
                  r'^01[0125][0-9]{8}$',
                ).hasMatch(input);
                final validEmail = RegExp(
                  r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                ).hasMatch(input);
                if (createAccount && !validPhone) return 'اكتب رقم مصري صحيح';
                if (!createAccount && !validPhone && !validEmail) {
                  return 'اكتب رقم مصري أو بريد صحيح';
                }
                return null;
              },
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
            if (!createAccount)
              TextButton(
                onPressed: submitting
                    ? null
                    : () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ForgotPasswordPage(),
                        ),
                      ),
                child: const Text('نسيت كلمة المرور؟'),
              ),
          ],
        ),
      ),
    ),
  );
}

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});
  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final identifier = TextEditingController();
  final code = TextEditingController();
  final password = TextEditingController();
  String channel = 'whatsapp';
  bool requested = false;
  bool submitting = false;

  @override
  void dispose() {
    identifier.dispose();
    code.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (identifier.text.trim().isEmpty) return;
    setState(() => submitting = true);
    try {
      if (!requested) {
        await ApiClient().requestPasswordReset(
          identifier: identifier.text.trim(),
          channel: channel,
        );
        if (mounted) setState(() => requested = true);
      } else {
        await ApiClient().confirmPasswordReset(
          identifier: identifier.text.trim(),
          channel: channel,
          code: code.text.trim(),
          newPassword: password.text,
        );
        if (!mounted) return;
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تغيير كلمة المرور، سجّل دخولك الآن'),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              requested
                  ? 'تأكد من الرمز وكلمة المرور الجديدة'
                  : 'تعذر إرسال رمز الاستعادة حالياً',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      appBar: AppBar(title: const Text('استعادة كلمة المرور')),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          const Text(
            'اختار وسيلة الاستعادة المرتبطة بحسابك.',
            style: TextStyle(color: muted),
          ),
          const SizedBox(height: 14),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'whatsapp', label: Text('واتساب')),
              ButtonSegment(value: 'sms', label: Text('رسالة')),
              ButtonSegment(value: 'email', label: Text('بريد')),
            ],
            selected: {channel},
            onSelectionChanged: requested
                ? null
                : (value) => setState(() => channel = value.first),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: identifier,
            enabled: !requested,
            keyboardType: channel == 'email'
                ? TextInputType.emailAddress
                : TextInputType.phone,
            decoration: InputDecoration(
              labelText: channel == 'email'
                  ? 'البريد الإلكتروني'
                  : 'رقم الهاتف',
            ),
          ),
          if (requested) ...[
            const SizedBox(height: 12),
            TextField(
              controller: code,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(labelText: 'رمز التأكيد'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: password,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'كلمة المرور الجديدة',
              ),
            ),
          ],
          const SizedBox(height: 18),
          FilledButton(
            onPressed: submitting ? null : _submit,
            child: Text(
              submitting
                  ? 'جارٍ التنفيذ…'
                  : requested
                  ? 'تأكيد كلمة المرور'
                  : 'إرسال الرمز',
            ),
          ),
        ],
      ),
    ),
  );
}

class AccountVerificationPage extends StatefulWidget {
  const AccountVerificationPage({super.key});
  @override
  State<AccountVerificationPage> createState() =>
      _AccountVerificationPageState();
}

class _AccountVerificationPageState extends State<AccountVerificationPage> {
  final code = TextEditingController();
  String channel = 'whatsapp';
  bool requested = false;
  bool submitting = false;

  @override
  void dispose() {
    code.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => submitting = true);
    try {
      if (!requested) {
        await ApiClient().requestVerification(channel);
        if (mounted) setState(() => requested = true);
      } else {
        await ApiClient().confirmVerification(channel, code.text);
        if (!mounted) return;
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تم تأكيد وسيلة التواصل')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تعذر التأكيد؛ راجع الرمز وحاول مرة أخرى'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      appBar: AppBar(title: const Text('تأكيد الحساب')),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'whatsapp', label: Text('واتساب')),
              ButtonSegment(value: 'sms', label: Text('رسالة')),
              ButtonSegment(value: 'email', label: Text('بريد')),
            ],
            selected: {channel},
            onSelectionChanged: requested
                ? null
                : (value) => setState(() => channel = value.first),
          ),
          if (requested) ...[
            const SizedBox(height: 14),
            TextField(
              controller: code,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(labelText: 'رمز التأكيد'),
            ),
          ],
          const SizedBox(height: 18),
          FilledButton(
            onPressed: submitting ? null : _submit,
            child: Text(
              submitting
                  ? 'جارٍ التنفيذ…'
                  : requested
                  ? 'تأكيد الرمز'
                  : 'إرسال الرمز',
            ),
          ),
        ],
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
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: teal));
          }
          if (snapshot.hasError) {
            return _StateMessage(
              icon: Icons.lock_outline,
              title: 'سجّل الدخول لعرض مساهماتك',
              subtitle: 'كل طلباتك وتقييماتك محفوظة في حسابك.',
              actionLabel: 'تسجيل الدخول',
              onAction: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AuthPage()),
                );
                if (mounted) _reload();
              },
            );
          }
          final data = snapshot.data ?? {};
          List<dynamic> section(String key) =>
              (data[key] as Map<String, dynamic>?)?['data'] as List<dynamic>? ??
              [];
          final providers = section('providers');
          final listings = section('listings');
          final reviews = section('reviews');
          final reports = section('reports');
          return RefreshIndicator(
            onRefresh: _reload,
            color: teal,
            child: ListView(
              padding: const EdgeInsets.all(18),
              children: [
                Text(
                  'الأنشطة: ${providers.length}',
                  style: TextStyle(
                    color: deepTeal,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                ...providers.map(
                  (item) => _ContributionTile(
                    title: item['name'] as String,
                    subtitle:
                        '${item['area']?['name'] ?? 'قنا'} · ${item['status']}',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProviderDetailPage(
                          providerId: item['id'] as String,
                          title: item['name'] as String,
                          icon: Icons.storefront_outlined,
                          subtitle: item['area']?['name'] as String? ?? 'قنا',
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'الإعلانات: ${listings.length}',
                  style: TextStyle(
                    color: deepTeal,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                ...listings.map(
                  (item) => _ContributionTile(
                    title: item['title'] as String,
                    subtitle: '${item['price']} جنيه · ${item['status']}',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            ListingDetailPage(listingId: item['id'] as String),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'التقييمات: ${reviews.length}',
                  style: TextStyle(
                    color: deepTeal,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                ...reviews.map(
                  (item) => _ContributionTile(
                    title: item['provider']?['name'] as String? ?? 'تقييم',
                    subtitle: item['status'] as String? ?? 'قيد المراجعة',
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ReviewPage(
                            providerId: item['providerId'] as String,
                            providerName:
                                item['provider']?['name'] as String? ??
                                'النشاط',
                            reviewId: item['id'] as String,
                            initialQuality: item['quality'] as int? ?? 0,
                            initialCommitment: item['commitment'] as int? ?? 0,
                            initialValue: item['value'] as int? ?? 0,
                            initialComment: item['comment'] as String?,
                          ),
                        ),
                      );
                      if (mounted) _reload();
                    },
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'البلاغات: ${reports.length}',
                  style: TextStyle(
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
                    onTap: () => showDialog<void>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text(
                          item['kind'] == 'CLAIM' ? 'طلب ملكية' : 'بلاغ',
                        ),
                        content: Text(
                          item['note'] as String? ?? 'بدون ملاحظات',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('إغلاق'),
                          ),
                        ],
                      ),
                    ),
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
  const _ContributionTile({
    required this.title,
    required this.subtitle,
    this.onTap,
  });
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Card(
    elevation: 0,
    margin: const EdgeInsets.only(top: 7),
    child: ListTile(
      onTap: onTap,
      title: Text(title),
      subtitle: Text(subtitle, style: const TextStyle(color: muted)),
      trailing: onTap == null
          ? null
          : Icon(Icons.chevron_left, color: teal),
    ),
  );
}

class UserProfilePage extends StatelessWidget {
  const UserProfilePage({super.key, required this.userId});
  final String userId;

  String _levelLabel(String? level) => level == 'QENAWY_ASIL'
      ? 'قناوي أصيل'
      : level == 'QENAWY_RAYEQ'
      ? 'قناوي رايق'
      : 'قناوي';

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      appBar: AppBar(title: const Text('صفحة القناوي')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: ApiClient().fetchPublicProfile(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: teal));
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return const _StateMessage(
              icon: Icons.person_off_outlined,
              title: 'الصفحة غير متاحة',
              subtitle: 'قد يكون الحساب محذوفًا أو تعذر الاتصال.',
            );
          }
          final data = snapshot.data!;
          final name = data['name'] as String? ?? 'قناوي';
          final contributions = data['contributions'] as Map<String, dynamic>?;
          final reviews = contributions?['reviews'] as List<dynamic>? ?? [];
          final listings = contributions?['listings'] as List<dynamic>? ?? [];
          final providers = contributions?['providers'] as List<dynamic>? ?? [];
          return ListView(
            padding: const EdgeInsets.all(18),
            children: [
              Card(
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 34,
                        backgroundColor: const Color(0xFFD8EFEC),
                        backgroundImage: data['avatarUrl'] == null
                            ? null
                            : CachedNetworkImageProvider(data['avatarUrl'] as String),
                        child: data['avatarUrl'] == null
                            ? Text(
                                name.isEmpty ? 'ق' : name.characters.first,
                                style: TextStyle(
                                  color: deepTeal,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: TextStyle(
                                color: deepTeal,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              '${_levelLabel(data['level'] as String?)} · ${data['points'] ?? 0} نقطة',
                              style: TextStyle(color: teal),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (contributions == null)
                const _StateMessage(
                  icon: Icons.lock_outline,
                  title: 'الصفحة خاصة',
                  subtitle: 'مساهمات هذا المستخدم غير معروضة على صفحته.',
                )
              else ...[
                const SizedBox(height: 14),
                SectionTitle(title: 'الأنشطة (${providers.length})'),
                ...providers.map((value) {
                  final item = value as Map<String, dynamic>;
                  return _ContributionTile(
                    title: item['name'] as String? ?? 'نشاط',
                    subtitle: item['area']?['name'] as String? ?? 'قنا',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProviderDetailPage(
                          providerId: item['id'] as String,
                          title: item['name'] as String? ?? 'نشاط',
                          icon: Icons.storefront_outlined,
                          subtitle: item['area']?['name'] as String? ?? 'قنا',
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 14),
                SectionTitle(title: 'الإعلانات (${listings.length})'),
                ...listings.map((value) {
                  final item = value as Map<String, dynamic>;
                  return _ContributionTile(
                    title: item['title'] as String? ?? 'إعلان',
                    subtitle: '${item['price']} جنيه',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            ListingDetailPage(listingId: item['id'] as String),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 14),
                SectionTitle(title: 'التقييمات (${reviews.length})'),
                ...reviews.map((value) {
                  final item = value as Map<String, dynamic>;
                  return _ContributionTile(
                    title: item['provider']?['name'] as String? ?? 'تقييم',
                    subtitle: item['comment'] as String? ?? 'تقييم بالنجوم',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProviderDetailPage(
                          providerId: item['providerId'] as String,
                          title: item['provider']?['name'] as String? ?? 'نشاط',
                          icon: Icons.storefront_outlined,
                          subtitle: 'قنا',
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ],
          );
        },
      ),
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
              side: BorderSide(color: teal),
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
          Text(
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
          Text(
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
              builder: (_) => AuthPage(
                createAccount: true,
                setupAreas: areas.toList(),
                setupInterests: interests.toList(),
                setupAge: age.isEmpty ? null : age,
                setupGender: gender.isEmpty ? null : gender,
              ),
            ),
          ),
        ),
        _authChoice(
          Icons.login,
          'تسجيل الدخول',
          'ادخل على حسابك الحالي',
          () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AuthPage(
                setupAreas: areas.toList(),
                setupInterests: interests.toList(),
                setupAge: age.isEmpty ? null : age,
                setupGender: gender.isEmpty ? null : gender,
              ),
            ),
          ),
        ),
        _authChoice(
          Icons.g_mobiledata,
          'المتابعة باستخدام Google',
          SocialAuthConfig.googleReady
              ? 'دخول آمن بالحساب'
              : 'ينتظر إعداد Google',
          () => _socialSignIn('google'),
        ),
        _authChoice(
          Icons.apple,
          'المتابعة باستخدام Apple',
          SocialAuthConfig.appleReady
              ? 'دخول آمن بالحساب'
              : 'ينتظر إعداد Apple',
          () => _socialSignIn('apple'),
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
      side: BorderSide(color: selected ? teal : Color(0xFFE0E8E6)),
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
  Future<void> _socialSignIn(String provider) async {
    final configured = provider == 'google'
        ? SocialAuthConfig.googleReady
        : SocialAuthConfig.appleReady;
    if (!configured) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'المسار جاهز ويحتاج بيانات ${provider == 'google' ? 'Google Cloud' : 'Apple Developer'} وقت النشر.',
          ),
        ),
      );
      return;
    }
    try {
      final service = SocialAuthService();
      if (provider == 'google') {
        await service.signInWithGoogle();
      } else {
        await service.signInWithApple();
      }
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeShell()),
        (_) => false,
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر إكمال الدخول. حاول مرة تانية.')),
      );
    }
  }

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
    index = value;
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Stack(
          children: [
            AnimatedSwitcher(
              duration: AppMotion.quick,
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, animation) =>
                  FadeTransition(opacity: animation, child: child),
              child: KeyedSubtree(key: ValueKey(index), child: pages[index]),
            ),
            const Positioned(
              top: 0,
              right: 0,
              left: 0,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(18, 10, 18, 0),
                  child: PersistentTopActions(),
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: index,
          onDestinationSelected: _select,
          backgroundColor: Colors.white,
          indicatorColor: Theme.of(context).colorScheme.primaryContainer,
          destinations: [
            for (var i = 0; i < labels.length; i++)
              NavigationDestination(
                icon: Icon(icons[i]),
                selectedIcon: Icon(
                  icons[i],
                  color: Theme.of(context).colorScheme.primary,
                ),
                label: labels[i],
              ),
          ],
        ),
      ),
    );
  }
}

class PersistentTopActions extends StatelessWidget {
  const PersistentTopActions({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeController.current;
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        _TopActionButton(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const NotificationsPage()),
          ),
          child: Icon(Icons.notifications_none, color: colors.primary),
        ),
        const SizedBox(width: 8),
        _TopActionButton(
          onTap: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const AccountPage())),
          child: CircleAvatar(
            radius: 15,
            backgroundColor: colors.primary,
            child: const Text(
              'م',
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ),
      ],
    );
  }
}

class _TopActionButton extends StatelessWidget {
  const _TopActionButton({required this.onTap, required this.child});
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    shape: const CircleBorder(),
    elevation: 3,
    shadowColor: Colors.black26,
    child: InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Padding(padding: const EdgeInsets.all(7), child: child),
    ),
  );
}

class BasePage extends StatelessWidget {
  const BasePage({
    super.key,
    required this.child,
    this.title,
    this.header,
    this.onRefresh,
    this.showBackButton = false,
  });
  final Widget child;
  final String? title;
  final Widget? header;
  final Future<void> Function()? onRefresh;
  final bool showBackButton;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final refresh =
        onRefresh ??
        () async => Future<void>.delayed(const Duration(milliseconds: 450));
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Material(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: SafeArea(
          child: RefreshIndicator(
            color: colors.primary,
            displacement: 24,
            onRefresh: refresh,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
              children: [
                header ??
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (showBackButton)
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: Icon(
                              Icons.arrow_forward_outlined,
                              color: colors.primary,
                            ),
                          )
                        else if (title == null)
                          const BrandText()
                        else if (title!.isNotEmpty)
                          Text(
                            title!,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: colors.primary,
                            ),
                          )
                        else
                          const Spacer(),
                        // Reserves space for the persistent notification/account
                        // buttons that HomeShell floats above every tab.
                        const SizedBox(width: 92),
                      ],
                    ),
                const SizedBox(height: 12),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class BrandText extends StatelessWidget {
  const BrandText({super.key});
  @override
  Widget build(BuildContext context) => Text(
    'هنا قنا',
    style: TextStyle(
      color: Theme.of(context).colorScheme.primary,
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
  String? selectedAreaId;
  late Future<List<ProviderSummary>> featured = ApiClient().fetchProviders();
  List<String> categoryItems = const [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
    if (AuthSession.isSignedIn) _loadRecommendations();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await ApiClient().fetchCategories();
      if (!mounted) return;
      setState(() {
        categoryItems = categories.map((item) => item.name).toList();
      });
    } catch (_) {
      // Home stays usable without the category rail if the platform is unreachable.
    }
  }

  Future<void> _loadRecommendations() async {
    try {
      final results = await Future.wait([
        ApiClient().fetchMe(),
        ApiClient().fetchAreas(),
      ]);
      final profile = results[0] as Map<String, dynamic>;
      final areas = results[1] as List<AreaOption>;
      final preferredIds = (profile['preferredAreaIds'] as List<dynamic>? ?? [])
          .cast<String>();
      final interests = (profile['interests'] as List<dynamic>? ?? [])
          .cast<String>();
      AreaOption? preferredArea;
      if (preferredIds.isNotEmpty) {
        for (final area in areas) {
          if (area.id == preferredIds.first) {
            preferredArea = area;
            break;
          }
        }
      }
      if (!mounted) return;
      setState(() {
        if (interests.isNotEmpty && categoryItems.isNotEmpty) {
          final ordered = <String>{
            ...interests.where(categoryItems.contains),
            ...categoryItems,
          }.toList();
          categoryItems = ordered;
        }
        if (preferredArea != null) {
          selectedAreaId = preferredArea.id;
          selectedArea = preferredArea.name;
          featured = ApiClient().fetchProviders(areaId: preferredArea.id);
        }
      });
    } catch (_) {
      // The public home remains usable with the default order if preferences fail.
    }
  }

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
    final picked = await showModalBottomSheet<AreaOption>(
      context: context,
      useSafeArea: true,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 12),
          children: [
            ListTile(
              title: Text(
                'اختار المنطقة',
                style: TextStyle(color: deepTeal, fontWeight: FontWeight.w700),
              ),
            ),
            for (final area in options)
              ListTile(
                title: Text(area.name),
                leading: Icon(
                  selectedAreaId == area.id
                      ? Icons.check_circle
                      : Icons.circle_outlined,
                  color: teal,
                ),
                onTap: () => Navigator.pop(context, area),
              ),
          ],
        ),
      ),
    );
    if (picked != null && mounted) {
      setState(() {
        selectedArea = picked.name;
        selectedAreaId = picked.id;
        featured = ApiClient().fetchProviders(areaId: picked.id);
      });
    }
  }

  Future<void> _reload() async {
    setState(
      () => featured = ApiClient().fetchProviders(areaId: selectedAreaId),
    );
    await featured;
  }

  @override
  Widget build(BuildContext context) {
    return BasePage(
      onRefresh: _reload,
      header: const SizedBox.shrink(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MergedHeroBanner(
            selectedArea: selectedArea,
            categoryItems: categoryItems,
            onPickArea: _pickArea,
            onOpenDirectory: _openDirectory,
          ),
          const SizedBox(height: 20),
          PromoCarousel(areaId: selectedAreaId),
          const SizedBox(height: 20),
          const SectionTitle(title: 'فئات قريبة منك'),
          const SizedBox(height: 9),
          const SizedBox(height: 2),
          CategoryRail(items: categoryItems, onSelected: _openDirectory),
          const SizedBox(height: 20),
          const SectionTitle(title: 'مختارات قنا'),
          const SizedBox(height: 9),
          FutureBuilder<List<ProviderSummary>>(
            future: featured,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return LinearProgressIndicator(color: teal);
              }
              final items = snapshot.data ?? const <ProviderSummary>[];
              if (snapshot.hasError || items.isEmpty) {
                return const _StateMessage(
                  icon: Icons.storefront_outlined,
                  title: 'لا توجد مختارات منشورة حالياً',
                  subtitle: 'المختارات تظهر من الأنشطة المعتمدة في الدليل.',
                );
              }
              return Column(
                children: [
                  for (var index = 0; index < items.take(4).length; index++)
                    MotionIn(
                      delay: index * 50,
                      child: MiniItem(
                        icon: Icons.storefront_outlined,
                        title: items[index].name,
                        subtitle: items[index].subtitle,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ProviderDetailPage(
                              providerId: items[index].id,
                              title: items[index].name,
                              icon: Icons.storefront_outlined,
                              subtitle: items[index].subtitle,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle({super.key, required this.title, this.onSeeAll});
  final String title;
  final VoidCallback? onSeeAll;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        title,
        style: TextStyle(
          color: deepTeal,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
      if (onSeeAll != null)
        TextButton(onPressed: onSeeAll, child: const Text('شوف الكل')),
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
          style: TextStyle(color: deepTeal, fontWeight: FontWeight.w700),
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

class MergedHeroBanner extends StatefulWidget {
  const MergedHeroBanner({
    super.key,
    required this.selectedArea,
    required this.categoryItems,
    required this.onPickArea,
    required this.onOpenDirectory,
  });
  final String selectedArea;
  final List<String> categoryItems;
  final VoidCallback onPickArea;
  final ValueChanged<String> onOpenDirectory;

  @override
  State<MergedHeroBanner> createState() => _MergedHeroBannerState();
}

class _MergedHeroBannerState extends State<MergedHeroBanner>
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

  bool _isNightTime() {
    final hour = DateTime.now().hour;
    return hour < 6 || hour >= 18;
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppThemeController.current;
    final isNight = _isNightTime();
    return AnimatedBuilder(
      animation: controller,
      builder: (_, child) => Container(
        clipBehavior: Clip.antiAlias,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [palette.deep, Color.lerp(palette.primary, palette.deep, controller.value * .35)!],
          ),
          boxShadow: [
            BoxShadow(
              color: palette.deep.withValues(alpha: .2),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
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
            PositionedDirectional(
              start: 0,
              top: 8,
              child: Icon(
                isNight ? Icons.dark_mode : Icons.wb_sunny,
                size: 80,
                color: Colors.white.withValues(alpha: .12),
              ),
            ),
            Column(
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 76),
                  child: Text(
                    'كل ما تحتاجه في قنا..هنا',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  textInputAction: TextInputAction.search,
                  onSubmitted: (value) {
                    if (value.trim().isNotEmpty) {
                      widget.onOpenDirectory(value.trim());
                    }
                  },
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.search, color: palette.primary),
                    hintText: 'بتدور على خدمة أو مكان؟',
                    isDense: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '📍 ${widget.selectedArea}',
                    style: const TextStyle(color: Color(0xDDF7F6F2), fontSize: 14),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
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
  Widget build(BuildContext context) {
    final palette = AppThemeController.current;
    return AnimatedBuilder(
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
              palette.deep,
              Color.lerp(
                palette.primary,
                palette.deep,
                controller.value * .35,
              )!,
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
                        style: TextStyle(
                          color: Color(0xDDF7F6F2),
                          fontSize: 13,
                        ),
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
}

class PromoCarousel extends StatefulWidget {
  const PromoCarousel({super.key, this.areaId});
  final String? areaId;
  @override
  State<PromoCarousel> createState() => _PromoCarouselState();
}

class _PromoCarouselState extends State<PromoCarousel> {
  final controller = PageController(viewportFraction: .94);
  int active = 0;
  List<Map<String, dynamic>> promos = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant PromoCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.areaId != widget.areaId) _load();
  }

  void _load() {
    ApiClient()
        .fetchAds(areaId: widget.areaId)
        .then((ads) {
          if (mounted) {
            setState(() {
              promos = ads;
              active = 0;
            });
            if (controller.hasClients) controller.jumpToPage(0);
          }
        })
        .catchError((_) {});
  }

  Future<void> _react(int index) async {
    if (!AuthSession.isSignedIn) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AuthPage()),
      );
      if (!AuthSession.isSignedIn || !mounted) return;
    }
    try {
      final result = await ApiClient().toggleAdReaction(
        promos[index]['id'] as String,
      );
      if (!mounted) return;
      setState(() {
        promos[index]['viewerReacted'] = result['active'];
        promos[index]['_count'] = {'reactions': result['count']};
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر حفظ التفاعل حالياً')),
        );
      }
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (promos.isEmpty) return const SizedBox.shrink();
    return Column(
      children: [
        SizedBox(
          height: 104,
          child: PageView.builder(
            controller: controller,
            itemCount: promos.length,
            onPageChanged: (value) => setState(() => active = value),
            itemBuilder: (_, index) {
              final promo = promos[index];
              final imageUrl = promo['imageUrl'] as String?;
              return AnimatedScale(
                duration: AppMotion.quick,
                scale: index == active ? 1 : .97,
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: promo['targetUrl'] == null
                      ? null
                      : () => AppActions.openUrl(promo['targetUrl'] as String?),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: gold.withValues(alpha: .22),
                      image: imageUrl == null
                          ? null
                          : DecorationImage(
                              image: CachedNetworkImageProvider(imageUrl),
                              fit: BoxFit.cover,
                              colorFilter: ColorFilter.mode(
                                deepTeal.withValues(alpha: .48),
                                BlendMode.srcOver,
                              ),
                            ),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.campaign_outlined,
                          color: Colors.white,
                          size: 25,
                        ),
                        const SizedBox(width: 11),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                promo['name'] as String? ?? 'إعلان مميز',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                promo['description'] as String? ?? '',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: .92),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'إعجاب بالإعلان',
                          onPressed: () => _react(index),
                          color: Colors.white,
                          icon: Icon(
                            promo['viewerReacted'] == true
                                ? Icons.favorite
                                : Icons.favorite_border,
                          ),
                        ),
                        Text(
                          '${promo['_count']?['reactions'] ?? 0}',
                          style: const TextStyle(color: Colors.white),
                        ),
                        const Icon(Icons.chevron_left, color: Colors.white),
                      ],
                    ),
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
                  color: i == active ? teal : Color(0xFFD6E3E0),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class CategoryRail extends StatelessWidget {
  const CategoryRail({super.key, required this.items, this.onSelected});
  final List<String> items;
  final ValueChanged<String>? onSelected;
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 42,
    child: items.isEmpty
        ? Align(
            alignment: Alignment.centerRight,
            child: Text(
              'يتم تحميل الفئات من المنصة…',
              style: TextStyle(color: muted, fontSize: 12),
            ),
          )
        : ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (_, index) => const SizedBox(width: 8),
            itemBuilder: (_, index) => ActionChip(
              onPressed: onSelected == null
                  ? null
                  : () => onSelected!(items[index]),
              avatar: Icon(Icons.circle, size: 8, color: gold),
              label: Text(items[index]),
              backgroundColor: Colors.white,
              side: const BorderSide(color: Color(0xFFE0E8E6)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(13),
              ),
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
          trailing: widget.onTap == null
              ? null
              : const Icon(Icons.chevron_left, color: muted),
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
  DirectoryFilters filters = const DirectoryFilters();
  List<String> categoryItems = const [];
  @override
  void initState() {
    super.initState();
    searchController.text = widget.initialQuery ?? '';
    providersFuture = _fetchProviders();
    api
        .fetchCategories()
        .then((categories) {
          if (mounted) {
            setState(
              () => categoryItems = categories.map((c) => c.name).toList(),
            );
          }
        })
        .catchError((_) {});
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
      if (mounted) {
        setState(() => providersFuture = _fetchProviders(searchQuery: value));
      }
    });
  }

  Future<List<ProviderSummary>> _fetchProviders({String? searchQuery}) async {
    final sort = filters.sort == 'الأعلى تقييمًا'
        ? 'rating'
        : filters.sort == 'الأحدث'
        ? 'latest'
        : 'name';
    final query = (searchQuery ?? searchController.text).trim();
    final results = await api.fetchProviders(
      searchQuery: query,
      verifiedOnly: filters.verified,
      openNow: filters.openNow,
      sort: sort,
    );
    if (query.isEmpty || results.isNotEmpty) return results;

    // Arabic keyboards can produce visually identical letters/diacritics that
    // do not compare equally in PostgreSQL. Retry the current directory and
    // apply a normalized token match so the visible list and map stay useful.
    final all = await api.fetchProviders(
      verifiedOnly: filters.verified,
      openNow: filters.openNow,
      sort: sort,
    );
    final tokens = _normalizeArabicQuery(query).split(' ');
    return all.where((provider) {
      final haystack = _normalizeArabicQuery(
        '${provider.name} ${provider.description ?? ''} '
        '${provider.address ?? ''} ${provider.subtitle}',
      );
      return tokens.every(haystack.contains);
    }).toList();
  }

  String _normalizeArabicQuery(String value) => value
      .toLowerCase()
      .replaceAll(RegExp(r'[أإآٱ]'), 'ا')
      .replaceAll('ى', 'ي')
      .replaceAll('ؤ', 'و')
      .replaceAll('ئ', 'ي')
      .replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), '')
      .replaceAll(RegExp(r'[^a-z0-9\u0600-\u06FF]+'), ' ')
      .trim();

  Future<void> _openMap() async {
    searchDebounce?.cancel();
    final currentResults = _fetchProviders(searchQuery: searchController.text);
    setState(() => providersFuture = currentResults);
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProviderMapPage(providersFuture: currentResults),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => BasePage(
    title: '',
    showBackButton: widget.initialQuery != null,
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
          items: categoryItems,
          onSelected: (value) {
            searchController.text = value;
            _search(value);
          },
        ),
        const SizedBox(height: 16),
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: searchController,
          builder: (context, value, _) => TextField(
            controller: searchController,
            onChanged: _search,
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.search, color: teal),
              hintText: 'اكتب اسم الخدمة أو المكان',
              suffixIcon: value.text.isEmpty
                  ? null
                  : IconButton(
                      icon: Icon(Icons.close, color: muted),
                      tooltip: 'مسح البحث',
                      onPressed: () {
                        searchController.clear();
                        _search('');
                      },
                    ),
            ),
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
              onPressed: _openMap,
              icon: const Icon(Icons.map_outlined),
              label: const Text('خريطة'),
            ),
          ],
        ),
        FutureBuilder<List<ProviderSummary>>(
          future: providersFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Padding(
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
    setState(() => providersFuture = _fetchProviders());
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

  Future<void> _showFilters(BuildContext context) async {
    final selected = await showModalBottomSheet<DirectoryFilters>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      sheetAnimationStyle: const AnimationStyle(
        duration: AppMotion.gentle,
        reverseDuration: AppMotion.quick,
      ),
      builder: (_) => _FilterSheet(initial: filters),
    );
    if (selected == null || !mounted) return;
    setState(() {
      filters = selected;
      providersFuture = _fetchProviders();
    });
  }
}

class DirectoryFilters {
  const DirectoryFilters({
    this.sort = 'الافتراضي',
    this.openNow = false,
    this.verified = false,
  });
  final String sort;
  final bool openNow;
  final bool verified;
}

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({required this.initial});
  final DirectoryFilters initial;
  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late String sort = widget.initial.sort;
  late bool openNow = widget.initial.openNow;
  late bool verified = widget.initial.verified;
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
                Expanded(
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
            Text(
              'الترتيب',
              style: TextStyle(color: deepTeal, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: ['الافتراضي', 'الأعلى تقييمًا', 'الأحدث']
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
              onPressed: () => Navigator.pop(
                context,
                DirectoryFilters(
                  sort: sort,
                  openNow: openNow,
                  verified: verified,
                ),
              ),
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

class ProviderMapPage extends StatelessWidget {
  const ProviderMapPage({super.key, required this.providersFuture});

  final Future<List<ProviderSummary>> providersFuture;

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      appBar: AppBar(title: const Text('خريطة الخدمات')),
      body: FutureBuilder<List<ProviderSummary>>(
        future: providersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const _StateMessage(
              icon: Icons.cloud_off_outlined,
              title: 'تعذر تحميل الأماكن',
              subtitle: 'ارجع للدليل وحاول مرة تانية.',
            );
          }
          final mapped = (snapshot.data ?? const <ProviderSummary>[])
              .where(
                (item) =>
                    item.latitude != null ||
                    item.longitude != null ||
                    item.address?.isNotEmpty == true,
              )
              .toList();
          if (mapped.isEmpty) {
            return const _StateMessage(
              icon: Icons.map_outlined,
              title: 'مفيش مواقع مسجلة للنتائج دي',
              subtitle: 'غيّر البحث أو افتح المكان لمعرفة عنوانه.',
            );
          }
          final list = ListView.separated(
            padding: const EdgeInsets.all(18),
            itemCount: mapped.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final provider = mapped[index];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.primaryContainer,
                    child: const Icon(Icons.location_on_outlined),
                  ),
                  title: Text(provider.name),
                  subtitle: Text(provider.address ?? provider.subtitle),
                  trailing: const Icon(Icons.open_in_new),
                  onTap: () async {
                    final opened = await AppActions.map(
                      latitude: provider.latitude,
                      longitude: provider.longitude,
                      address: '${provider.address ?? provider.name}، قنا',
                    );
                    if (!opened && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('تعذر فتح تطبيق الخرائط')),
                      );
                    }
                  },
                ),
              );
            },
          );
          const mapsEnabled = bool.fromEnvironment('GOOGLE_MAPS_ENABLED');
          if (!mapsEnabled) return list;
          final markers = mapped
              .where((item) => item.latitude != null && item.longitude != null)
              .map(
                (item) => Marker(
                  markerId: MarkerId(item.id),
                  position: LatLng(item.latitude!, item.longitude!),
                  infoWindow: InfoWindow(
                    title: item.name,
                    snippet: item.address ?? item.subtitle,
                  ),
                ),
              )
              .toSet();
          return Column(
            children: [
              SizedBox(
                height: 310,
                child: GoogleMap(
                  initialCameraPosition: const CameraPosition(
                    target: LatLng(26.1551, 32.7160),
                    zoom: 12.4,
                  ),
                  markers: markers,
                  mapToolbarEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                ),
              ),
              Expanded(child: list),
            ],
          );
        },
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

  Future<void> _editProvider(ProviderDetails data) async {
    final name = TextEditingController(text: data.name);
    final description = TextEditingController(text: data.description);
    final phone = TextEditingController(text: data.phone);
    final whatsapp = TextEditingController(text: data.whatsapp);
    final address = TextEditingController(text: data.address);
    final opening = TextEditingController(text: data.openingTime);
    final closing = TextEditingController(text: data.closingTime);
    var verified = data.isVerified;
    final save = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('تعديل النشاط إداريًا'),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: name,
                    decoration: const InputDecoration(labelText: 'الاسم'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: description,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'الوصف'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: phone,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: 'الهاتف'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: whatsapp,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: 'واتساب'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: address,
                    decoration: const InputDecoration(labelText: 'العنوان'),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: opening,
                          decoration: const InputDecoration(
                            labelText: 'يفتح HH:mm',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: closing,
                          decoration: const InputDecoration(
                            labelText: 'يغلق HH:mm',
                          ),
                        ),
                      ),
                    ],
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('نشاط موثق'),
                    value: verified,
                    onChanged: (value) =>
                        setDialogState(() => verified = value),
                  ),
                ],
              ),
            ),
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
      ),
    );
    if (save != true) {
      for (final controller in [
        name,
        description,
        phone,
        whatsapp,
        address,
        opening,
        closing,
      ]) {
        controller.dispose();
      }
      return;
    }
    try {
      await ApiClient().updateAdminProviderContent(data.id, {
        'name': name.text.trim(),
        'description': description.text.trim(),
        'phone': phone.text.trim(),
        'whatsapp': whatsapp.text.trim(),
        'address': address.text.trim(),
        'openingTime': opening.text.trim().isEmpty ? null : opening.text.trim(),
        'closingTime': closing.text.trim().isEmpty ? null : closing.text.trim(),
        'isVerified': verified,
      });
      _reload();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تم حفظ تعديلات النشاط')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('راجع البيانات وحاول مرة أخرى')),
        );
      }
    } finally {
      for (final controller in [
        name,
        description,
        phone,
        whatsapp,
        address,
        opening,
        closing,
      ]) {
        controller.dispose();
      }
    }
  }

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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إرسال الرد للمراجعة وسيظهر بعد اعتماده'),
          ),
        );
      }
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
                if (!AuthSession.isSignedIn) {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AuthPage()),
                  );
                  if (!AuthSession.isSignedIn || !context.mounted) return;
                }
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
          if (snapshot.hasError) {
            return ListView(
              padding: const EdgeInsets.all(24),
              children: [
                _StateMessage(
                  icon: Icons.cloud_off_outlined,
                  title: 'تعذر تحميل تفاصيل النشاط',
                  subtitle: 'تحقق من الاتصال وحاول مرة أخرى.',
                  actionLabel: 'إعادة المحاولة',
                  onAction: _reload,
                ),
              ],
            );
          }
          final data = snapshot.data;
          favorite ??= data?.viewerFavorite ?? false;
          final imageUrls = data?.images ?? const <String>[];
          final reviews = data?.reviews ?? const <Map<String, dynamic>>[];
          return ListView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 90),
            children: [
              if (snapshot.connectionState == ConnectionState.waiting)
                LinearProgressIndicator(color: teal),
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
                              style: TextStyle(
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
                                if (data?.isVerified == true)
                                  Text(
                                    'موثق',
                                    style: TextStyle(
                                      color: teal,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  )
                                else if (data != null)
                                  const Text(
                                    'مضاف من المجتمع',
                                    style: TextStyle(
                                      color: muted,
                                      fontSize: 12,
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
              if (data != null && AuthSession.adminToken != null) ...[
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => _editProvider(data),
                  icon: const Icon(Icons.admin_panel_settings_outlined),
                  label: const Text('تعديل النشاط بصلاحية الإدارة'),
                ),
              ],
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
                  if (SocialPlatform.of(data?.socialPlatform) case final social?) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: social.color,
                          side: BorderSide(color: social.color.withValues(alpha: .4)),
                        ),
                        onPressed: () => _external(
                          AppActions.openUrl(data?.socialUrl),
                          'تعذر فتح الرابط',
                        ),
                        icon: FaIcon(social.icon, size: 16),
                        label: Text(social.label),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
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
                      userId:
                          (reply['author'] as Map<String, dynamic>?)?['id']
                              as String?,
                      name: replyAuthor,
                      initial: replyAuthor.isEmpty
                          ? 'هـ'
                          : replyAuthor.characters.first,
                      text: reply['text'] as String? ?? '',
                      timeLabel: _relativeTime(reply['createdAt']),
                      onReply: () => _reply(reviewId),
                    );
                  },
                ).toList();
                return MotionIn(
                  delay: entry.key * 60,
                  child: CommentBubble(
                    userId:
                        (review['author'] as Map<String, dynamic>?)?['id']
                            as String?,
                    name: author,
                    initial: initials,
                    text: text,
                    rating: score,
                    timeLabel: _relativeTime(review['createdAt']),
                    helpfulActive: review['viewerHelpful'] as bool? ?? false,
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
    required this.timeLabel,
    required this.helpfulCount,
    required this.helpfulActive,
    required this.onHelpful,
    required this.onReply,
    this.replies = const [],
    this.userId,
  });
  final String? userId;
  final String name;
  final String initial;
  final String text;
  final int rating;
  final String timeLabel;
  final int helpfulCount;
  final bool helpfulActive;
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
            GestureDetector(
              onTap: userId == null
                  ? null
                  : () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => UserProfilePage(userId: userId!),
                      ),
                    ),
              child: CircleAvatar(
                radius: 19,
                backgroundColor: const Color(0xFFD8EFEC),
                child: Text(
                  initial,
                  style: TextStyle(
                    color: deepTeal,
                    fontWeight: FontWeight.w700,
                  ),
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
                        child: GestureDetector(
                          onTap: userId == null
                              ? null
                              : () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        UserProfilePage(userId: userId!),
                                  ),
                                ),
                          child: Text(
                            name,
                            style: TextStyle(
                              color: deepTeal,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      Text(
                        timeLabel,
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
                        style: TextStyle(
                          color: teal,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Icon(Icons.star, color: gold, size: 15),
                      const SizedBox(width: 12),
                      TextButton(
                        onPressed: onHelpful,
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              helpfulActive
                                  ? Icons.thumb_up
                                  : Icons.thumb_up_outlined,
                              size: 14,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              helpfulCount == 0
                                  ? 'مفيد'
                                  : 'مفيد · $helpfulCount',
                            ),
                          ],
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
    required this.timeLabel,
    required this.onReply,
    this.userId,
  });
  final String? userId;
  final String name;
  final String initial;
  final String text;
  final String timeLabel;
  final VoidCallback onReply;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: userId == null
              ? null
              : () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => UserProfilePage(userId: userId!),
                  ),
                ),
          child: CircleAvatar(
            radius: 15,
            backgroundColor: const Color(0xFFE8F5F2),
            child: Text(
              initial,
              style: TextStyle(
                color: deepTeal,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      name,
                      style: TextStyle(
                        color: deepTeal,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    timeLabel,
                    style: const TextStyle(color: muted, fontSize: 10),
                  ),
                ],
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
    this.reviewId,
    this.initialQuality = 0,
    this.initialCommitment = 0,
    this.initialValue = 0,
    this.initialComment,
  });
  final String providerId;
  final String providerName;
  final String? reviewId;
  final int initialQuality;
  final int initialCommitment;
  final int initialValue;
  final String? initialComment;
  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  final api = ApiClient();
  late final scores = <String, int>{
    'الجودة': widget.initialQuality,
    'الالتزام': widget.initialCommitment,
    'السعر': widget.initialValue,
  };
  late final comment = TextEditingController(text: widget.initialComment);
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
      appBar: AppBar(
        title: Text(widget.reviewId == null ? 'إضافة تقييم' : 'تعديل التقييم'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
        children: [
          Text(
            'قيّم ${widget.providerName}',
            style: TextStyle(
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
            'التقييم يظهر باسمك الحقيقي بعد مراجعة الإدارة ويمكنك تعديله من مساهماتك.',
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
            child: Text(
              submitting
                  ? 'جارٍ الإرسال…'
                  : widget.reviewId == null
                  ? 'إرسال التقييم'
                  : 'حفظ وإرسال للمراجعة',
            ),
          ),
        ],
      ),
    ),
  );

  Future<void> _submit() async {
    setState(() => submitting = true);
    try {
      if (widget.reviewId == null) {
        await api.submitReview(
          providerId: widget.providerId,
          quality: scores['الجودة']!,
          commitment: scores['الالتزام']!,
          value: scores['السعر']!,
          comment: comment.text,
        );
      } else {
        await api.updateReview(
          reviewId: widget.reviewId!,
          quality: scores['الجودة']!,
          commitment: scores['الالتزام']!,
          value: scores['السعر']!,
          comment: comment.text,
        );
      }
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم إرسال التقييم للمراجعة وسيظهر بعد اعتماده'),
        ),
      );
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
            style: TextStyle(
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
  late Future<List<Map<String, dynamic>>> offersFuture;

  @override
  void initState() {
    super.initState();
    pricesFuture = ApiClient().fetchPrices();
    offersFuture = ApiClient().fetchOffers();
  }

  Future<void> _reload() async {
    setState(() {
      pricesFuture = ApiClient().fetchPrices();
      offersFuture = ApiClient().fetchOffers();
    });
    await Future.wait([pricesFuture, offersFuture]);
  }

  @override
  Widget build(BuildContext context) => BasePage(
    title: 'بكام؟',
    onRefresh: _reload,
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
              ? FutureBuilder<List<Map<String, dynamic>>>(
                  key: const ValueKey('offers'),
                  future: offersFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: CircularProgressIndicator(color: teal),
                      );
                    }
                    final items =
                        snapshot.data ?? const <Map<String, dynamic>>[];
                    if (snapshot.hasError || items.isEmpty) {
                      return const _StateMessage(
                        icon: Icons.local_offer_outlined,
                        title: 'لا توجد عروض سارية حالياً',
                        subtitle: 'العروض المعتمدة هتظهر هنا فور نشرها.',
                      );
                    }
                    return Column(
                      children: [
                        for (var index = 0; index < items.length; index++)
                          MotionIn(
                            delay: index * 50,
                            child: MiniItem(
                              icon: Icons.local_offer_outlined,
                              title: items[index]['title'] as String? ?? 'عرض',
                              subtitle:
                                  '${items[index]['provider']?['name'] ?? 'نشاط موثق'} · ${items[index]['description'] ?? 'عرض ساري'}',
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ProviderDetailPage(
                                    providerId:
                                        items[index]['providerId'] as String,
                                    title:
                                        items[index]['provider']?['name']
                                            as String? ??
                                        'نشاط',
                                    icon: Icons.storefront_outlined,
                                    subtitle:
                                        items[index]['provider']?['area']?['name']
                                            as String? ??
                                        'قنا',
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                )
              : FutureBuilder<List<Map<String, dynamic>>>(
                  key: const ValueKey('prices'),
                  future: pricesFuture,
                  builder: (context, snapshot) {
                    final items =
                        snapshot.data ?? const <Map<String, dynamic>>[];
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (items.isEmpty) {
                      return const MiniItem(
                        icon: Icons.sell_outlined,
                        title: 'لا توجد أسعار منشورة بعد',
                        subtitle:
                            'سيظهر هنا دليل الأسعار بعد اعتماده من الإدارة',
                      );
                    }
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
  bool loading = true;
  bool loadFailed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() => loading = true);
    await ApiClient()
        .fetchNow()
        .then((items) {
          if (mounted) {
            setState(() {
              nowItems = items;
              loadFailed = false;
            });
          }
        })
        .catchError((_) {
          if (mounted) setState(() => loadFailed = true);
        });
    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) => BasePage(
    title: 'دلوقتي',
    onRefresh: _load,
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
    if (loading) {
      return [
        Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator(color: teal)),
        ),
      ];
    }
    if (loadFailed) {
      return [
        _StateMessage(
          icon: Icons.cloud_off_outlined,
          title: 'تعذر تحميل التحديثات',
          subtitle: 'اسحب لأسفل أو اضغط للمحاولة مرة أخرى.',
          actionLabel: 'إعادة المحاولة',
          onAction: _load,
        ),
      ];
    }
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
                decoration: BoxDecoration(
                  color: teal,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          const SizedBox(width: 5),
          Text(
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

  Future<void> _reload() async {
    final next = api.fetchListings(category: category, query: search.text);
    if (!mounted) return;
    setState(() {
      listings = next;
    });
    await next;
  }

  void _search(String _) {
    debounce?.cancel();
    debounce = Timer(const Duration(milliseconds: 350), () {
      _reload();
    });
  }

  @override
  Widget build(BuildContext context) => BasePage(
    title: 'عندك؟',
    onRefresh: _reload,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'اعرض اللي عندك، ودوّر على اللي محتاجه',
          style: TextStyle(color: muted),
        ),
        const SizedBox(height: 14),
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: search,
          builder: (context, value, _) => TextField(
            controller: search,
            onChanged: _search,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.search, color: teal),
              hintText: 'ابحث في الإعلانات',
              suffixIcon: value.text.isEmpty
                  ? null
                  : IconButton(
                      icon: Icon(Icons.close, color: muted),
                      tooltip: 'مسح البحث',
                      onPressed: () {
                        search.clear();
                        _search('');
                      },
                    ),
            ),
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
              return Padding(
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
          onPressed: () async {
            if (!AuthSession.isSignedIn) {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AuthPage()),
              );
              if (!AuthSession.isSignedIn || !context.mounted) return;
            }
            if (context.mounted) {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreateListingPage()),
              );
              _reload();
            }
          },
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

  Future<void> _editListing(Map<String, dynamic> data) async {
    final title = TextEditingController(text: data['title'] as String?);
    final description = TextEditingController(
      text: data['description'] as String?,
    );
    final price = TextEditingController(text: '${data['price'] ?? ''}');
    var category = data['category'] as String? ?? 'للبيع';
    final save = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('تعديل الإعلان إداريًا'),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: title,
                    decoration: const InputDecoration(labelText: 'العنوان'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: description,
                    maxLines: 4,
                    decoration: const InputDecoration(labelText: 'الوصف'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: price,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'السعر'),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: category,
                    decoration: const InputDecoration(labelText: 'القسم'),
                    items: ['للبيع', 'للإيجار', 'وظائف', 'سيارات', 'عقارات']
                        .map(
                          (item) =>
                              DropdownMenuItem(value: item, child: Text(item)),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => category = value);
                      }
                    },
                  ),
                ],
              ),
            ),
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
      ),
    );
    if (save != true) {
      title.dispose();
      description.dispose();
      price.dispose();
      return;
    }
    final parsedPrice = double.tryParse(price.text.trim());
    if (title.text.trim().length < 3 ||
        parsedPrice == null ||
        parsedPrice <= 0) {
      title.dispose();
      description.dispose();
      price.dispose();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('اكتب عنوانًا وسعرًا صحيحين')),
        );
      }
      return;
    }
    try {
      await api.updateAdminListingContent(widget.listingId, {
        'title': title.text.trim(),
        'description': description.text.trim(),
        'price': parsedPrice,
        'category': category,
      });
      if (mounted) {
        setState(() {
          listing = api.fetchListing(widget.listingId);
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تم حفظ تعديلات الإعلان')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('راجع البيانات وحاول مرة أخرى')),
        );
      }
    } finally {
      title.dispose();
      description.dispose();
      price.dispose();
    }
  }

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
            ListTile(
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
                leading: Icon(Icons.flag_outlined, color: teal),
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
            return Center(child: CircularProgressIndicator(color: teal));
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return _StateMessage(
              icon: Icons.error_outline,
              title: 'الإعلان غير متاح',
              subtitle: 'ربما انتهت مدته أو تم حذفه.',
              actionLabel: 'إعادة المحاولة',
              onAction: () => setState(() {
                listing = api.fetchListing(widget.listingId);
              }),
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
                      style: TextStyle(
                        color: deepTeal,
                        fontSize: 21,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Chip(
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
              if (AuthSession.adminToken != null)
                OutlinedButton.icon(
                  onPressed: () => _editListing(data),
                  icon: const Icon(Icons.admin_panel_settings_outlined),
                  label: const Text('تعديل الإعلان بصلاحية الإدارة'),
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
                onTap: owner?['id'] == null
                    ? null
                    : () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              UserProfilePage(userId: owner!['id'] as String),
                        ),
                      ),
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
  bool submitting = false;
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
    if (submitting) return;
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
    setState(() => submitting = true);
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
    } finally {
      if (mounted) setState(() => submitting = false);
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
            onPressed: submitting ? null : next,
            style: FilledButton.styleFrom(
              backgroundColor: teal,
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              submitting
                  ? 'جارٍ الإرسال…'
                  : step == 2
                  ? 'إرسال للمراجعة'
                  : 'التالي',
            ),
          ),
        ],
      ),
    ),
  );
  Widget _body() {
    if (step == 0) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
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
          Text(
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
                return LinearProgressIndicator(color: teal);
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
    }
    if (step == 1) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
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
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
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
                      child: CachedNetworkImage(
                        imageUrl: widget.imageUrls[index],
                        fit: BoxFit.cover,
                        errorWidget: (_, error, stack) => Center(
                          child: Icon(
                            Icons.image_outlined,
                            color: deepTeal.withValues(alpha: .45),
                            size: 54,
                          ),
                        ),
                        placeholder: (_, _) => const SizedBox.expand(),
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
                        style: TextStyle(
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
                  color: i == active ? teal : Color(0xFFD6E3E0),
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
                        child: Icon(Icons.swipe, color: teal, size: 17),
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

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});
  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
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
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: teal));
          }
          if (snapshot.hasError || !AuthSession.isSignedIn) {
            return _StateMessage(
              icon: Icons.person_outline,
              title: 'أنت داخل كزائر',
              subtitle: 'سجّل الدخول لحفظ المفضلة ومتابعة إعلاناتك وتقييماتك.',
              actionLabel: 'تسجيل الدخول أو إنشاء حساب',
              onAction: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AuthPage()),
                );
                if (mounted) setState(() {});
              },
            );
          }
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
              Container(
                padding: const EdgeInsets.fromLTRB(14, 22, 14, 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(26),
                  gradient: LinearGradient(
                    colors: [
                      AppThemeController.current.deep,
                      AppThemeController.current.primary,
                    ],
                  ),
                ),
                child: Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(19),
                  clipBehavior: Clip.antiAlias,
                  child: ListTile(
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EditProfilePage(profile: profile),
                        ),
                      );
                      if (mounted) setState(() {});
                    },
                    contentPadding: const EdgeInsets.all(14),
                    leading: CircleAvatar(
                      radius: 25,
                      backgroundColor: AppThemeController.current.primary,
                      backgroundImage: profile?['avatarUrl'] == null
                          ? null
                          : CachedNetworkImageProvider(profile!['avatarUrl'] as String),
                      child: profile?['avatarUrl'] == null
                          ? Text(
                              profileName.isEmpty
                                  ? 'هـ'
                                  : profileName.characters.first,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                              ),
                            )
                          : null,
                    ),
                    title: Text(
                      profileName,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      '$levelLabel · $points نقطة',
                      style: TextStyle(
                        color: AppThemeController.current.primary,
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_left),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              _AccountTile(
                icon: Icons.notifications_none,
                title: 'الإشعارات',
                subtitle: 'راجع آخر التنبيهات والقرارات',
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

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key, required this.profile});
  final Map<String, dynamic>? profile;
  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late final name = TextEditingController(
    text: widget.profile?['name'] as String? ?? AuthSession.name ?? '',
  );
  late final email = TextEditingController(
    text: widget.profile?['email'] as String? ?? '',
  );
  XFile? avatar;
  bool submitting = false;

  @override
  void dispose() {
    name.dispose();
    email.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
      maxWidth: 800,
    );
    if (image != null && mounted) setState(() => avatar = image);
  }

  Future<void> _save() async {
    if (name.text.trim().length < 2) return;
    setState(() => submitting = true);
    try {
      final avatarUrl = avatar == null
          ? null
          : await ApiClient().uploadAvatar(avatar!);
      await ApiClient().updateProfile(
        name: name.text,
        email: email.text,
        avatarUrl: avatarUrl,
      );
      await AuthSession.updateName(name.text.trim());
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تعذر حفظ بيانات الحساب')));
      }
    } finally {
      if (mounted) setState(() => submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      appBar: AppBar(title: const Text('تعديل الحساب')),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Center(
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 46,
                  backgroundColor: const Color(0xFFD8EFEC),
                  backgroundImage: avatar == null
                      ? (widget.profile?['avatarUrl'] == null
                            ? null
                            : CachedNetworkImageProvider(
                                widget.profile!['avatarUrl'] as String,
                              ))
                      : FileImage(File(avatar!.path)) as ImageProvider,
                  child: avatar == null && widget.profile?['avatarUrl'] == null
                      ? Icon(
                          Icons.person_outline,
                          color: deepTeal,
                          size: 42,
                        )
                      : null,
                ),
                PositionedDirectional(
                  end: 0,
                  bottom: 0,
                  child: IconButton.filled(
                    onPressed: _pickAvatar,
                    icon: const Icon(Icons.camera_alt_outlined, size: 18),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          TextField(
            controller: name,
            decoration: const InputDecoration(labelText: 'الاسم الحقيقي'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: email,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'البريد الإلكتروني (اختياري)',
            ),
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: submitting ? null : _save,
            child: Text(submitting ? 'جارٍ الحفظ…' : 'حفظ التعديلات'),
          ),
        ],
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
  void _reload() {
    if (!mounted) return;
    setState(() {
      favorites = ApiClient().fetchFavorites();
    });
  }

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      appBar: AppBar(title: const Text('المفضلة')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: favorites,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: teal));
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
  void _reload() {
    if (!mounted) return;
    setState(() {
      contributions = api.fetchContributions();
    });
  }

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
            return Center(child: CircularProgressIndicator(color: teal));
          }
          final items =
              (snapshot.data?['listings'] as Map<String, dynamic>?)?['data']
                  as List<dynamic>? ??
              [];
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
  Future<void> _reload() async {
    final next = api.fetchNotifications();
    if (!mounted) return;
    setState(() {
      notifications = next;
    });
    await next;
  }

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
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: teal));
          }
          final items = snapshot.data ?? const <Map<String, dynamic>>[];
          if (items.isEmpty) {
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
          }
          return RefreshIndicator(
            onRefresh: _reload,
            color: teal,
            child: ListView(
              padding: const EdgeInsets.all(18),
              children: [
                Text(
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
              child: Icon(Icons.circle, size: 9, color: teal),
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
  final socialUrl = TextEditingController();
  String? socialPlatform;
  String? areaId;
  String? categoryId;
  String mode = 'LOCAL';
  String phoneType = 'BUSINESS';
  String opening = '09:00';
  String closing = '22:00';
  int imageCount = 0;
  final selectedImages = <XFile>[];
  bool preview = false;
  bool submitting = false;
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
    for (final controller in [
      name,
      description,
      address,
      phone,
      whatsapp,
      socialUrl,
    ]) {
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
              onPressed: submitting ? null : (preview ? _submit : _review),
              style: FilledButton.styleFrom(
                backgroundColor: teal,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: Text(
                submitting
                    ? 'جارٍ الإرسال…'
                    : preview
                    ? 'إرسال للمراجعة'
                    : 'معاينة النشاط',
              ),
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
    children: [
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
        builder: (_, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return LinearProgressIndicator(color: teal);
          }
          if (snapshot.hasError) {
            return const Text(
              'تعذر تحميل أنواع النشاط. تأكد من الاتصال ثم افتح الصفحة من جديد.',
              style: TextStyle(color: Colors.redAccent),
            );
          }
          return DropdownButtonFormField<String>(
            initialValue: categoryId,
            decoration: const InputDecoration(labelText: 'نوع النشاط *'),
            items: (snapshot.data ?? const <CategoryOption>[])
                .map(
                  (item) =>
                      DropdownMenuItem(value: item.id, child: Text(item.name)),
                )
                .toList(),
            onChanged: (value) => setState(() => categoryId = value),
            validator: (value) => value == null ? 'اختار نوع النشاط' : null,
          );
        },
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
        builder: (_, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return LinearProgressIndicator(color: teal);
          }
          if (snapshot.hasError) {
            return const Text(
              'تعذر تحميل المناطق. تأكد من الاتصال ثم افتح الصفحة من جديد.',
              style: TextStyle(color: Colors.redAccent),
            );
          }
          return DropdownButtonFormField<String>(
            initialValue: areaId,
            decoration: const InputDecoration(labelText: 'المنطقة *'),
            items: (snapshot.data ?? const <AreaOption>[])
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
          );
        },
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
      const SizedBox(height: 12),
      DropdownButtonFormField<String>(
        initialValue: socialPlatform,
        decoration: const InputDecoration(
          labelText: 'سوشيال ميديا إضافية (اختياري)',
        ),
        items: [
          const DropdownMenuItem(value: null, child: Text('بدون')),
          for (final entry in SocialPlatform.all.entries)
            DropdownMenuItem(
              value: entry.key,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FaIcon(entry.value.icon, size: 16, color: entry.value.color),
                  const SizedBox(width: 8),
                  Text(entry.value.label),
                ],
              ),
            ),
        ],
        onChanged: (value) => setState(() => socialPlatform = value),
      ),
      if (socialPlatform != null) ...[
        const SizedBox(height: 12),
        TextFormField(
          controller: socialUrl,
          keyboardType: TextInputType.url,
          decoration: InputDecoration(
            labelText: 'رابط ${SocialPlatform.of(socialPlatform)?.label}',
            hintText: 'https://...',
          ),
          validator: (value) => socialPlatform != null &&
                  (value == null || Uri.tryParse(value.trim())?.hasScheme != true)
              ? 'اكتب رابطًا صحيحًا'
              : null,
        ),
      ],
      const SizedBox(height: 14),
      if (mode == 'LOCAL')
        Row(
          children: [
            Expanded(
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
              style: TextStyle(
                color: deepTeal,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          IconButton(
            onPressed: selectedImages.length >= 10 ? null : _pickImages,
            icon: Icon(Icons.add_a_photo_outlined, color: teal),
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
        final value =
            '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
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
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: selectedImages.isEmpty
                ? Container(
                    height: 130,
                    color: const Color(0xFFD8EFEC),
                    child: Icon(
                      Icons.image_outlined,
                      color: deepTeal,
                      size: 52,
                    ),
                  )
                : Image.file(
                    File(selectedImages.first.path),
                    height: 130,
                    fit: BoxFit.cover,
                  ),
          ),
          const SizedBox(height: 14),
          Text(
            name.text,
            style: TextStyle(
              color: deepTeal,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${mode == 'LOCAL' ? 'محلي' : 'أونلاين'} · ${phoneType == 'BUSINESS' ? 'رقم نشاط' : 'رقم شخصي'}',
            style: TextStyle(color: teal),
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
          Row(
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
    if (submitting) return;
    setState(() => submitting = true);
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
          if (socialPlatform != null && socialUrl.text.trim().isNotEmpty) ...{
            'socialPlatform': socialPlatform,
            'socialUrl': socialUrl.text.trim(),
          },
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
      showTopToast(context, message: 'تم إرسال النشاط وصوره للمراجعة');
    } catch (error) {
      if (!mounted) return;
      if (error.toString().contains('unauthorized')) {
        await Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const AuthPage()));
        return;
      }
      final errorMsg = error.toString().contains('duplicate')
          ? 'النشاط موجود بالفعل أو قيد المراجعة'
          : error.toString().contains('upload_error')
          ? 'تعذر رفع الصور، جرّب صوراً أصغر'
          : 'تعذر إرسال النشاط حالياً';
      showTopToast(context, message: errorMsg, isError: true);
    } finally {
      if (mounted) setState(() => submitting = false);
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
  bool submitting = false;
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
            style: TextStyle(
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
            onPressed: submitting ? null : _submit,
            style: FilledButton.styleFrom(
              backgroundColor: teal,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            child: Text(submitting ? 'جارٍ الإرسال…' : 'إرسال للمراجعة'),
          ),
        ],
      ),
    ),
  );
  Future<void> _submit() async {
    if (name.text.trim().length < 2) {
      showTopToast(context, message: 'اكتب اسم النشاط', isError: true);
      return;
    }
    setState(() => submitting = true);
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
      showTopToast(context, message: 'تم إرسال الطلب للمراجعة');
    } catch (error) {
      if (!mounted) return;
      if (error.toString().contains('unauthorized')) {
        await Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const AuthPage()));
        return;
      }
      showTopToast(context, message: 'تعذر إرسال الطلب حالياً', isError: true);
    } finally {
      if (mounted) setState(() => submitting = false);
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
  bool notificationDigest = false;
  bool areaOnly = false;
  bool privateProfile = false;
  Set<String> selectedAreaIds = {};
  List<String> selectedAreaNames = const [];
  Set<String> selectedInterests = {};
  String? ageRange;
  String? gender;

  void _requireAccount(VoidCallback action) {
    if (AuthSession.isSignedIn) {
      action();
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AuthPage()),
    ).then((_) {
      if (mounted && AuthSession.isSignedIn) {
        setState(() {});
        _loadPreferences();
      }
    });
  }

  @override
  void initState() {
    super.initState();
    if (AuthSession.isSignedIn) _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final results = await Future.wait([api.fetchMe(), api.fetchAreas()]);
      final profile = results[0] as Map<String, dynamic>;
      final areas = results[1] as List<AreaOption>;
      final ids = (profile['preferredAreaIds'] as List<dynamic>? ?? [])
          .cast<String>()
          .toSet();
      if (!mounted) return;
      setState(() {
        privateProfile = profile['isProfilePrivate'] as bool? ?? false;
        areaOnly = profile['notificationScope'] == 'area';
        allNotifications = profile['notificationsEnabled'] as bool? ?? true;
        notificationDigest = profile['notificationDigest'] as bool? ?? false;
        selectedAreaIds = ids;
        selectedAreaNames = areas
            .where((area) => ids.contains(area.id))
            .map((area) => area.name)
            .toList();
        selectedInterests = (profile['interests'] as List<dynamic>? ?? [])
            .cast<String>()
            .toSet();
        ageRange = profile['ageRange'] as String?;
        gender = profile['gender'] as String?;
      });
    } catch (_) {}
  }

  Future<void> _pickAreas() async {
    final options = await api.fetchAreas();
    if (!mounted) return;
    final draft = {...selectedAreaIds};
    final result = await showModalBottomSheet<Set<String>>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'اختار حتى 3 مناطق',
                  style: TextStyle(
                    color: deepTeal,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                for (final area in options)
                  CheckboxListTile(
                    value: draft.contains(area.id),
                    title: Text(area.name),
                    onChanged: (checked) {
                      setSheetState(() {
                        if (checked == true && draft.length < 3) {
                          draft.add(area.id);
                        } else if (checked == false) {
                          draft.remove(area.id);
                        }
                      });
                    },
                  ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, draft),
                  child: const Text('حفظ المناطق'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      selectedAreaIds = result;
      selectedAreaNames = options
          .where((area) => result.contains(area.id))
          .map((area) => area.name)
          .toList();
    });
    await _savePreferences();
  }

  Future<void> _pickInterests() async {
    List<String> options;
    try {
      options = (await ApiClient().fetchCategories())
          .map((item) => item.name)
          .toList();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تعذر تحميل الفئات حالياً')));
      return;
    }
    if (!mounted) return;
    final draft = {...selectedInterests};
    final result = await showModalBottomSheet<Set<String>>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'اختار حتى 5 اهتمامات',
                  style: TextStyle(
                    color: deepTeal,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                for (final item in options)
                  CheckboxListTile(
                    value: draft.contains(item),
                    title: Text(item),
                    onChanged: (checked) {
                      setSheetState(() {
                        if (checked == true && draft.length < 5) {
                          draft.add(item);
                        } else if (checked == false) {
                          draft.remove(item);
                        }
                      });
                    },
                  ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, draft),
                  child: const Text('حفظ الاهتمامات'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (result == null || !mounted) return;
    setState(() => selectedInterests = result);
    await _savePreferences();
  }

  Future<void> _pickDemographics() async {
    var draftAge = ageRange;
    var draftGender = gender;
    final result = await showModalBottomSheet<Map<String, String?>>(
      context: context,
      useSafeArea: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Directionality(
          textDirection: TextDirection.rtl,
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
            children: [
              Text(
                'السن والنوع (اختياري)',
                style: TextStyle(color: deepTeal, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: draftAge,
                decoration: const InputDecoration(labelText: 'الفئة العمرية'),
                items:
                    [
                          'أقل من 18',
                          '18–24',
                          '25–34',
                          '35–49',
                          '50 أو أكثر',
                          'أفضل عدم الإفصاح',
                        ]
                        .map(
                          (item) =>
                              DropdownMenuItem(value: item, child: Text(item)),
                        )
                        .toList(),
                onChanged: (value) => setSheetState(() => draftAge = value),
              ),
              const SizedBox(height: 12),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'رجل', label: Text('رجل')),
                  ButtonSegment(value: 'امرأة', label: Text('امرأة')),
                  ButtonSegment(
                    value: 'أفضل عدم الإفصاح',
                    label: Text('عدم الإفصاح'),
                  ),
                ],
                emptySelectionAllowed: true,
                selected: draftGender == null ? {} : {draftGender!},
                onSelectionChanged: (value) => setSheetState(
                  () => draftGender = value.isEmpty ? null : value.first,
                ),
              ),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: () => Navigator.pop(context, {
                  'age': draftAge,
                  'gender': draftGender,
                }),
                child: const Text('حفظ'),
              ),
            ],
          ),
        ),
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      ageRange = result['age'];
      gender = result['gender'];
    });
    await _savePreferences();
  }

  Future<void> _pickTheme() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'اختاري شكل التطبيق',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 5),
              const Text(
                'الاختيار بيتحفظ على الجهاز وتقدري تغيريه في أي وقت.',
                style: TextStyle(color: muted),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: GridView.builder(
                  shrinkWrap: true,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1.5,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: AppThemeController.palettes.length,
                  itemBuilder: (context, index) {
                    final palette = AppThemeController.palettes[index];
                    final active =
                        palette.id == AppThemeController.selectedId.value;
                    return InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () => Navigator.pop(context, palette.id),
                      child: AnimatedContainer(
                        duration: AppMotion.quick,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: palette.background,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: active
                                ? palette.primary
                                : palette.primary.withValues(alpha: .16),
                            width: active ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                for (final color in [
                                  palette.deep,
                                  palette.primary,
                                  palette.accent,
                                  palette.surfaceTint,
                                ])
                                  Container(
                                    width: 24,
                                    height: 24,
                                    margin: const EdgeInsetsDirectional.only(
                                      end: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: color,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                const Spacer(),
                                if (active)
                                  Icon(
                                    Icons.check_circle,
                                    color: palette.primary,
                                    size: 20,
                                  ),
                              ],
                            ),
                            Text(
                              palette.name,
                              style: TextStyle(
                                color: palette.deep,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (selected == null) return;
    await AppThemeController.select(selected);
    if (mounted) setState(() {});
  }

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
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AdminControlPage()),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('بيانات الإدارة غير صحيحة')),
        );
      }
    }
  }

  Future<void> _logoutAll() async {
    try {
      await api.logoutAll();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const WelcomeScreen()),
          (_) => false,
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر تسجيل الخروج حالياً')),
        );
      }
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
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const WelcomeScreen()),
          (_) => false,
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تعذر حذف الحساب حالياً')));
      }
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
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تم تغيير كلمة المرور')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تأكد من كلمة المرور الجديدة والحالية')),
        );
      }
    }
  }

  Future<void> _savePreferences() async {
    try {
      await api.updatePreferences(
        profilePrivate: privateProfile,
        notificationScope: areaOnly ? 'area' : 'all',
        notificationsEnabled: allNotifications,
        notificationDigest: notificationDigest,
        preferredAreaIds: selectedAreaIds.toList(),
        interests: selectedInterests.toList(),
        ageRange: ageRange,
        gender: gender,
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر حفظ الإعدادات حالياً')),
        );
      }
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
              onTap: () => _requireAccount(
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddActivityPage()),
                ),
              ),
              leading: CircleAvatar(
                backgroundColor: teal,
                child: Icon(Icons.add_business_outlined, color: Colors.white),
              ),
              title: Text(
                'أضف نشاط',
                style: TextStyle(color: deepTeal, fontWeight: FontWeight.w700),
              ),
              subtitle: const Text(
                'ساعدنا نضيف نشاط موثوق لقنا',
                style: TextStyle(color: muted),
              ),
              trailing: Icon(Icons.chevron_left, color: deepTeal),
            ),
          ),
          const SizedBox(height: 18),
          _AccountTile(
            icon: Icons.verified_user_outlined,
            title: 'أملك نشاط',
            subtitle: 'اطلب إثبات ملكية نشاط موجود',
            onTap: () => _requireAccount(
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CommunityRequestPage(kind: 'CLAIM'),
                ),
              ),
            ),
          ),
          _AccountTile(
            icon: Icons.flag_outlined,
            title: 'أبلغ عن نشاط',
            subtitle: 'أرسل ملاحظة للإدارة للمراجعة',
            onTap: () => _requireAccount(
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CommunityRequestPage(kind: 'REPORT'),
                ),
              ),
            ),
          ),
          _AccountTile(
            icon: Icons.password_outlined,
            title: 'تغيير كلمة المرور',
            onTap: () => _requireAccount(_changePassword),
          ),
          _AccountTile(
            icon: Icons.verified_outlined,
            title: 'تأكيد الهاتف أو البريد',
            subtitle: 'واتساب أو رسالة أو بريد إلكتروني',
            onTap: () => _requireAccount(
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AccountVerificationPage(),
                ),
              ),
            ),
          ),
          _AccountTile(
            icon: Icons.logout,
            title: 'تسجيل الخروج من كل الأجهزة',
            onTap: () => _requireAccount(_logoutAll),
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
          Text(
            'شكل التطبيق',
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          _AccountTile(
            icon: Icons.palette_outlined,
            title: 'الثيم والألوان',
            subtitle: AppThemeController.current.name,
            onTap: _pickTheme,
          ),
          const Divider(height: 26),
          Text(
            'الإشعارات',
            style: TextStyle(color: deepTeal, fontWeight: FontWeight.w700),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('كل الإشعارات'),
            value: allNotifications,
            onChanged: (value) {
              _requireAccount(() {
                setState(() => allNotifications = value);
                _savePreferences();
              });
            },
            activeThumbColor: teal,
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('ملخص دوري للإشعارات'),
            subtitle: const Text(
              'اجمع التنبيهات غير العاجلة في ملخص',
              style: TextStyle(color: muted, fontSize: 12),
            ),
            value: notificationDigest,
            onChanged: (value) {
              _requireAccount(() {
                setState(() => notificationDigest = value);
                _savePreferences();
              });
            },
            activeThumbColor: teal,
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('إشعارات منطقتي فقط'),
            value: areaOnly,
            onChanged: (value) {
              _requireAccount(() {
                setState(() => areaOnly = value);
                _savePreferences();
              });
            },
            activeThumbColor: teal,
          ),
          const Divider(height: 26),
          Text(
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
              _requireAccount(() {
                setState(() => privateProfile = value);
                _savePreferences();
              });
            },
            activeThumbColor: teal,
          ),
          const Divider(height: 26),
          _AccountTile(
            icon: Icons.location_on_outlined,
            title: 'المناطق المختارة',
            subtitle: selectedAreaNames.isEmpty
                ? 'لم تحدد مناطق؛ سيظهر ترتيب قنا العام'
                : selectedAreaNames.join('، '),
            onTap: () => _requireAccount(_pickAreas),
          ),
          _AccountTile(
            icon: Icons.interests_outlined,
            title: 'الاهتمامات',
            subtitle: selectedInterests.isEmpty
                ? 'لم تحدد اهتمامات'
                : selectedInterests.join('، '),
            onTap: () => _requireAccount(_pickInterests),
          ),
          _AccountTile(
            icon: Icons.tune_outlined,
            title: 'بيانات الترشيحات',
            subtitle: [?ageRange, ?gender].isEmpty
                ? 'لم تحدد السن أو النوع'
                : [?ageRange, ?gender].join(' · '),
            onTap: () => _requireAccount(_pickDemographics),
          ),
          _AccountTile(
            icon: Icons.delete_forever_outlined,
            title: 'حذف الحساب نهائياً',
            onTap: () => _requireAccount(_deleteAccount),
            destructive: true,
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
  late Future<List<Map<String, dynamic>>> reviews = api.fetchAdminReviews();
  late Future<List<Map<String, dynamic>>> replies = api.fetchAdminReplies();
  late Future<List<Map<String, dynamic>>> providerReports = api
      .fetchAdminProviderReports();
  late Future<List<Map<String, dynamic>>> listingReports = api
      .fetchAdminListingReports();
  late Future<List<Map<String, dynamic>>> supportTickets = api
      .fetchAdminSupportTickets();
  Future<void> _reload() async {
    if (!mounted) return;
    setState(() {
      providers = api.fetchAdminProviders();
      listings = api.fetchAdminListings();
      reviews = api.fetchAdminReviews();
      replies = api.fetchAdminReplies();
      providerReports = api.fetchAdminProviderReports();
      listingReports = api.fetchAdminListingReports();
      supportTickets = api.fetchAdminSupportTickets();
    });
  }

  Future<String?> _rejectionReason() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('سبب الرفض'),
        content: TextField(
          controller: controller,
          autofocus: true,
          minLines: 2,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'اكتب سببًا واضحًا يصل لصاحب الطلب',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().length >= 3) {
                Navigator.pop(context, controller.text.trim());
              }
            },
            child: const Text('رفض وإرسال السبب'),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

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
              style: TextStyle(
                color: deepTeal,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            _AdminQueue(
              title: 'طلبات الأنشطة',
              future: providers,
              filter: (item) => item['status'] == 'PENDING',
              itemTitle: (item) => item['name'] as String? ?? 'نشاط',
              itemSubtitle: (item) => item['area']?['name'] as String? ?? 'قنا',
              onApprove: (item) async {
                await api.moderateAdminProvider(
                  id: item['id'] as String,
                  status: 'APPROVED',
                );
                await _reload();
              },
              onReject: (item) async {
                final reason = await _rejectionReason();
                if (reason == null) return;
                await api.moderateAdminProvider(
                  id: item['id'] as String,
                  status: 'REJECTED',
                  note: reason,
                );
                await _reload();
              },
            ),
            _AdminQueue(
              title: 'طلبات الإعلانات المحلية',
              future: listings,
              filter: (item) => item['status'] == 'PENDING',
              itemTitle: (item) => item['title'] as String? ?? 'إعلان',
              itemSubtitle: (item) =>
                  '${item['price']} جنيه · ${item['area']?['name'] ?? 'قنا'}',
              onApprove: (item) async {
                await api.moderateAdminListing(
                  id: item['id'] as String,
                  status: 'ACTIVE',
                );
                await _reload();
              },
              onReject: (item) async {
                final reason = await _rejectionReason();
                if (reason == null) return;
                await api.moderateAdminListing(
                  id: item['id'] as String,
                  status: 'REJECTED',
                  note: reason,
                );
                await _reload();
              },
            ),
            _AdminQueue(
              title: 'التقييمات الجديدة',
              future: reviews,
              filter: (item) => item['status'] == 'PENDING',
              itemTitle: (item) =>
                  item['author']?['name'] as String? ?? 'مستخدم',
              itemSubtitle: (item) =>
                  '${item['provider']?['name'] ?? 'نشاط'} · ${item['comment'] ?? 'تقييم بالنجوم فقط'}',
              onApprove: (item) async {
                await api.moderateAdminReview(
                  id: item['id'] as String,
                  status: 'APPROVED',
                );
                await _reload();
              },
              onReject: (item) async {
                final reason = await _rejectionReason();
                if (reason == null) return;
                await api.moderateAdminReview(
                  id: item['id'] as String,
                  status: 'REJECTED',
                  note: reason,
                );
                await _reload();
              },
            ),
            _AdminQueue(
              title: 'ردود التقييمات',
              future: replies,
              filter: (item) => item['status'] == 'PENDING',
              itemTitle: (item) =>
                  item['author']?['name'] as String? ?? 'مستخدم',
              itemSubtitle: (item) => item['text'] as String? ?? '',
              onApprove: (item) async {
                await api.moderateAdminReply(
                  id: item['id'] as String,
                  status: 'APPROVED',
                );
                await _reload();
              },
              onReject: (item) async {
                final reason = await _rejectionReason();
                if (reason == null) return;
                await api.moderateAdminReply(
                  id: item['id'] as String,
                  status: 'REJECTED',
                  note: reason,
                );
                await _reload();
              },
            ),
            _AdminQueue(
              title: 'بلاغات وملكية الأنشطة',
              future: providerReports,
              filter: (item) => item['status'] == 'PENDING',
              itemTitle: (item) => item['name'] as String? ?? 'طلب نشاط',
              itemSubtitle: (item) =>
                  '${item['kind'] == 'CLAIM' ? 'إثبات ملكية' : 'بلاغ'} · ${item['note'] ?? 'بدون ملاحظة'}',
              onApprove: (item) async {
                await api.moderateAdminProviderReport(
                  id: item['id'] as String,
                  status: 'APPROVED',
                );
                await _reload();
              },
              onReject: (item) async {
                await api.moderateAdminProviderReport(
                  id: item['id'] as String,
                  status: 'REJECTED',
                );
                await _reload();
              },
            ),
            _AdminQueue(
              title: 'بلاغات الإعلانات المحلية',
              future: listingReports,
              filter: (item) => item['status'] == 'PENDING',
              itemTitle: (item) =>
                  item['listing']?['title'] as String? ?? 'إعلان',
              itemSubtitle: (item) => item['reason'] as String? ?? 'بلاغ',
              onApprove: (item) async {
                await api.moderateAdminListingReport(
                  id: item['id'] as String,
                  status: 'APPROVED',
                );
                await _reload();
              },
              onReject: (item) async {
                await api.moderateAdminListingReport(
                  id: item['id'] as String,
                  status: 'REJECTED',
                );
                await _reload();
              },
            ),
            _AdminQueue(
              title: 'طلبات الدعم',
              future: supportTickets,
              filter: (item) => item['status'] == 'PENDING',
              itemTitle: (item) => item['subject'] as String? ?? 'طلب دعم',
              itemSubtitle: (item) =>
                  '${item['user']?['name'] ?? 'مستخدم'} · ${item['message'] ?? ''}',
              approveTooltip: 'إغلاق كمحلول',
              rejectTooltip: 'إغلاق دون إجراء',
              onApprove: (item) async {
                await api.moderateAdminSupportTicket(
                  id: item['id'] as String,
                  status: 'APPROVED',
                );
                await _reload();
              },
              onReject: (item) async {
                await api.moderateAdminSupportTicket(
                  id: item['id'] as String,
                  status: 'REJECTED',
                );
                await _reload();
              },
            ),
            const Divider(height: 30),
            Text(
              'تعديل المحتوى المنشور',
              style: TextStyle(
                color: deepTeal,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            _AdminBrowseSection(
              title: 'كل الأنشطة',
              future: providers,
              filter: (item) => item['status'] == 'APPROVED',
              itemTitle: (item) => item['name'] as String? ?? 'نشاط',
              itemSubtitle: (item) => item['area']?['name'] as String? ?? 'قنا',
              onTap: (item) => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProviderDetailPage(
                    providerId: item['id'] as String,
                    title: item['name'] as String? ?? 'نشاط',
                    icon: Icons.storefront_outlined,
                    subtitle: item['area']?['name'] as String? ?? 'قنا',
                  ),
                ),
              ),
            ),
            _AdminBrowseSection(
              title: 'كل الإعلانات المنشورة',
              future: listings,
              filter: (item) => item['status'] == 'ACTIVE',
              itemTitle: (item) => item['title'] as String? ?? 'إعلان',
              itemSubtitle: (item) => '${item['price']} جنيه',
              onTap: (item) => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      ListingDetailPage(listingId: item['id'] as String),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _AdminApprovalTile extends StatefulWidget {
  const _AdminApprovalTile({
    required this.title,
    required this.subtitle,
    required this.onApprove,
    required this.onReject,
    this.approveTooltip = 'اعتماد',
    this.rejectTooltip = 'رفض',
  });
  final String title;
  final String subtitle;
  final Future<void> Function() onApprove;
  final Future<void> Function() onReject;
  final String approveTooltip;
  final String rejectTooltip;

  @override
  State<_AdminApprovalTile> createState() => _AdminApprovalTileState();
}

class _AdminApprovalTileState extends State<_AdminApprovalTile> {
  bool busy = false;

  Future<void> _run(Future<void> Function() action) async {
    if (busy) return;
    setState(() => busy = true);
    try {
      await action();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر تنفيذ القرار. حاول مرة أخرى.')),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Card(
    elevation: 0,
    margin: const EdgeInsets.only(top: 8),
    child: ListTile(
      title: Text(
        widget.title,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Text(widget.subtitle),
      trailing: busy
          ? SizedBox.square(
              dimension: 24,
              child: CircularProgressIndicator(strokeWidth: 2, color: teal),
            )
          : Wrap(
              spacing: 4,
              children: [
                IconButton(
                  tooltip: widget.approveTooltip,
                  onPressed: () => _run(widget.onApprove),
                  color: teal,
                  icon: const Icon(Icons.check_circle_outline),
                ),
                IconButton(
                  tooltip: widget.rejectTooltip,
                  onPressed: () => _run(widget.onReject),
                  color: Colors.redAccent,
                  icon: const Icon(Icons.cancel_outlined),
                ),
              ],
            ),
    ),
  );
}

class _AdminQueue extends StatelessWidget {
  const _AdminQueue({
    required this.title,
    required this.future,
    required this.filter,
    required this.itemTitle,
    required this.itemSubtitle,
    required this.onApprove,
    required this.onReject,
    this.approveTooltip = 'اعتماد',
    this.rejectTooltip = 'رفض',
  });
  final String title;
  final Future<List<Map<String, dynamic>>> future;
  final bool Function(Map<String, dynamic>) filter;
  final String Function(Map<String, dynamic>) itemTitle;
  final String Function(Map<String, dynamic>) itemSubtitle;
  final Future<void> Function(Map<String, dynamic>) onApprove;
  final Future<void> Function(Map<String, dynamic>) onReject;
  final String approveTooltip;
  final String rejectTooltip;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: TextStyle(color: deepTeal, fontWeight: FontWeight.w700),
        ),
        FutureBuilder<List<Map<String, dynamic>>>(
          future: future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Padding(
                padding: EdgeInsets.all(14),
                child: LinearProgressIndicator(color: teal),
              );
            }
            if (snapshot.hasError) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Text(
                  'تعذر تحميل هذه الطلبات. اسحب لأسفل للمحاولة مجددًا.',
                  style: TextStyle(color: Colors.redAccent),
                ),
              );
            }
            final items = (snapshot.data ?? const <Map<String, dynamic>>[])
                .where(filter)
                .toList();
            if (items.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Text(
                  'لا توجد طلبات معلقة.',
                  style: TextStyle(color: muted),
                ),
              );
            }
            return Column(
              children: [
                for (final item in items)
                  _AdminApprovalTile(
                    title: itemTitle(item),
                    subtitle: itemSubtitle(item),
                    onApprove: () => onApprove(item),
                    onReject: () => onReject(item),
                    approveTooltip: approveTooltip,
                    rejectTooltip: rejectTooltip,
                  ),
              ],
            );
          },
        ),
      ],
    ),
  );
}

class _AdminBrowseSection extends StatelessWidget {
  const _AdminBrowseSection({
    required this.title,
    required this.future,
    required this.filter,
    required this.itemTitle,
    required this.itemSubtitle,
    required this.onTap,
  });
  final String title;
  final Future<List<Map<String, dynamic>>> future;
  final bool Function(Map<String, dynamic>) filter;
  final String Function(Map<String, dynamic>) itemTitle;
  final String Function(Map<String, dynamic>) itemSubtitle;
  final void Function(Map<String, dynamic>) onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        FutureBuilder<List<Map<String, dynamic>>>(
          future: future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return LinearProgressIndicator(color: teal);
            }
            final items = (snapshot.data ?? const <Map<String, dynamic>>[])
                .where(filter)
                .toList();
            if (snapshot.hasError) {
              return const Text(
                'تعذر تحميل المحتوى.',
                style: TextStyle(color: Colors.redAccent),
              );
            }
            if (items.isEmpty) {
              return const Text(
                'لا يوجد محتوى منشور.',
                style: TextStyle(color: muted),
              );
            }
            return Column(
              children: [
                for (final item in items)
                  _ContributionTile(
                    title: itemTitle(item),
                    subtitle: itemSubtitle(item),
                    onTap: () => onTap(item),
                  ),
              ],
            );
          },
        ),
      ],
    ),
  );
}
