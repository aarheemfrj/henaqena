import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Mutable shorthand for the *currently selected* theme's colors. Many widgets
// across the app reference `teal`/`deepTeal`/`gold` directly instead of
// threading BuildContext, so AppThemeController keeps these in sync with the
// active palette on every restore()/select() call.
Color teal = const Color(0xFF0D8F8A);
Color deepTeal = const Color(0xFF085E5A);
Color gold = const Color(0xFFE9B44C);
const paper = Color(0xFFF7F6F2);
const ink = Color(0xFF1F2933);
const muted = Color(0xFF66737A);

class AppPalette {
  const AppPalette({
    required this.id,
    required this.name,
    required this.primary,
    required this.deep,
    required this.accent,
    required this.background,
    required this.surfaceTint,
  });
  final String id;
  final String name;
  final Color primary;
  final Color deep;
  final Color accent;
  final Color background;
  final Color surfaceTint;
}

class AppThemeController {
  static const _storageKey = 'app_color_theme';
  static const palettes = <AppPalette>[
    AppPalette(
      id: 'qena',
      name: 'قنا الأصلية',
      primary: Color(0xFF0D8F8A),
      deep: Color(0xFF085E5A),
      accent: Color(0xFFE9B44C),
      background: paper,
      surfaceTint: Color(0xFFD8EFEC),
    ),
    AppPalette(
      id: 'nile',
      name: 'نسمة النيل',
      primary: Color(0xFF018ABE),
      deep: Color(0xFF02457A),
      accent: Color(0xFF97CADB),
      background: Color(0xFFF3F9FC),
      surfaceTint: Color(0xFFD6E8EE),
    ),
    AppPalette(
      id: 'nile_sun',
      name: 'النيل والشمس',
      primary: Color(0xFF429EBD),
      deep: Color(0xFF053F5C),
      accent: Color(0xFFF7AD19),
      background: Color(0xFFF7FBFC),
      surfaceTint: Color(0xFFDEF5FA),
    ),
    AppPalette(
      id: 'berry',
      name: 'توت قنا',
      primary: Color(0xFFD22F62),
      deep: Color(0xFF800021),
      accent: Color(0xFFEB7694),
      background: Color(0xFFFFF5F7),
      surfaceTint: Color(0xFFFFDCE5),
    ),
    AppPalette(
      id: 'violet',
      name: 'ليالي بنفسجية',
      primary: Color(0xFF8B4F67),
      deep: Color(0xFF3A004D),
      accent: Color(0xFFB889B0),
      background: Color(0xFFFBF6FA),
      surfaceTint: Color(0xFFF0E0EB),
    ),
    AppPalette(
      id: 'coffee',
      name: 'قهوة الصعيد',
      primary: Color(0xFF8C6E63),
      deep: Color(0xFF3E2522),
      accent: Color(0xFFD3A376),
      background: Color(0xFFFFF8EF),
      surfaceTint: Color(0xFFFFE0B2),
    ),
    AppPalette(
      id: 'sunset',
      name: 'شمس قنا',
      primary: Color(0xFF01757A),
      deep: Color(0xFF3E2922),
      accent: Color(0xFFE57734),
      background: Color(0xFFFFF8F1),
      surfaceTint: Color(0xFFF6C0A6),
    ),
    AppPalette(
      id: 'calm',
      name: 'صباح هادي',
      primary: Color(0xFF657166),
      deep: Color(0xFF40534A),
      accent: Color(0xFFF3C3B2),
      background: Color(0xFFFAFBF7),
      surfaceTint: Color(0xFFDAEBE3),
    ),
    AppPalette(
      id: 'peach',
      name: 'خوخي ناعم',
      primary: Color(0xFFF08E82),
      deep: Color(0xFF9D5960),
      accent: Color(0xFFFBA2AB),
      background: Color(0xFFFFF8F4),
      surfaceTint: Color(0xFFFFDFC3),
    ),
  ];

  static final selectedId = ValueNotifier<String>('qena');
  static AppPalette get current => palettes.firstWhere(
    (item) => item.id == selectedId.value,
    orElse: () => palettes.first,
  );

  static void _syncGlobals() {
    final palette = current;
    teal = palette.primary;
    deepTeal = palette.deep;
    gold = palette.accent;
  }

  static Future<void> restore() async {
    final preferences = await SharedPreferences.getInstance();
    final stored = preferences.getString(_storageKey);
    if (stored != null && palettes.any((item) => item.id == stored)) {
      selectedId.value = stored;
    }
    _syncGlobals();
  }

  static Future<void> select(String id) async {
    if (!palettes.any((item) => item.id == id)) return;
    selectedId.value = id;
    _syncGlobals();
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_storageKey, id);
  }

  static ThemeData theme(AppPalette palette) {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: palette.primary,
          brightness: Brightness.light,
        ).copyWith(
          primary: palette.primary,
          onPrimary: Colors.white,
          secondary: palette.accent,
          surface: Colors.white,
          onSurface: ink,
        );
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: palette.background,
      colorScheme: scheme,
      fontFamily: 'Tajawal',
      textTheme: TextTheme(
        headlineMedium: TextStyle(
          fontFamily: 'Cairo',
          fontWeight: FontWeight.w700,
          color: palette.deep,
        ),
        headlineSmall: TextStyle(
          fontFamily: 'Cairo',
          fontWeight: FontWeight.w700,
          color: palette.deep,
        ),
        titleLarge: TextStyle(
          fontFamily: 'Cairo',
          fontWeight: FontWeight.w700,
          color: palette.deep,
        ),
        titleMedium: const TextStyle(fontWeight: FontWeight.w500, color: ink),
        bodyLarge: const TextStyle(fontWeight: FontWeight.w400, color: ink),
        bodyMedium: const TextStyle(fontWeight: FontWeight.w400, color: ink),
        labelLarge: const TextStyle(fontWeight: FontWeight.w500),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: palette.primary.withValues(alpha: .12)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        indicatorColor: palette.surfaceTint,
        labelTextStyle: const WidgetStatePropertyAll(
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
      appBarTheme: AppBarTheme(
        backgroundColor: palette.background,
        foregroundColor: palette.deep,
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
          borderSide: BorderSide(color: palette.primary.withValues(alpha: .15)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: palette.primary, width: 1.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: palette.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? palette.primary : null,
        ),
      ),
    );
  }
}

class AppMotion {
  static const quick = Duration(milliseconds: 180);
  static const standard = Duration(milliseconds: 240);
  static const gentle = Duration(milliseconds: 320);
  static const page = Duration(milliseconds: 420);
}

class SmoothPageTransitionsBuilder extends PageTransitionsBuilder {
  const SmoothPageTransitionsBuilder();
  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    final incomingSlide = Tween<Offset>(
      begin: const Offset(.12, 0),
      end: Offset.zero,
    ).animate(curved);
    final incomingScale = Tween<double>(begin: .94, end: 1).animate(curved);

    // Give the page underneath a subtle push-back while the new page arrives.
    // This creates the shared-axis feeling from the visual references without
    // making navigation feel slow or theatrical.
    return AnimatedBuilder(
      animation: secondaryAnimation,
      child: child,
      builder: (context, page) {
        final pushed = secondaryAnimation.value;
        return Opacity(
          opacity: 1 - (pushed * .12),
          child: Transform.translate(
            offset: Offset(-18 * pushed, 0),
            child: Transform.scale(
              alignment: Alignment.center,
              scale: 1 - (pushed * .025),
              child: FadeTransition(
                opacity: curved,
                child: SlideTransition(
                  position: incomingSlide,
                  child: ScaleTransition(scale: incomingScale, child: page),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
