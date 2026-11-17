import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Palet mode malam: lembut, tanpa warna yang menyilaukan, tetap kontras untuk dibaca.
class D {
  D._();
  static const bg = Color(0xFF0B1019);
  static const surface = Color(0xFF131A27);
  static const surface2 = Color(0xFF1A2333);
  static const line = Color(0xFF273248);
  static const text = Color(0xFFDCE3EF); // putih lembut (bukan putih murni)
  static const muted = Color(0xFF9AA8BF);

  static const brand = Color(0xFF7C9DF2);
  static const brandFill = Color(0xFF3A63D0); // untuk tombol / FAB berisi
  static const brandSoft = Color(0xFF1B2A47);
  static const brandLine = Color(0xFF2C4272);

  static const ok = Color(0xFF45B98F);
  static const okBg = Color(0xFF12302A);
  static const warn = Color(0xFFE3A94B);
  static const warnBg = Color(0xFF332811);
  static const danger = Color(0xFFF08585);
  static const dangerBg = Color(0xFF371C22);
  static const violet = Color(0xFFA796F5);
  static const violetBg = Color(0xFF251F40);
  static const info = Color(0xFF7FA6F5);
  static const infoBg = Color(0xFF162A4A);
  static const cyan = Color(0xFF4FC3DC);
  static const cyanBg = Color(0xFF123038);

  static const heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0F1830), Color(0xFF16274D), Color(0xFF1F3B7A)],
  );
}

/// Palet warna - disamakan dengan versi web (brand biru + ink gelap).
class C {
  C._();
  static const brand = Color(0xFF2757D6);
  static const brand50 = Color(0xFFEFF5FF);
  static const brand100 = Color(0xFFDBE8FF);
  static const brand500 = Color(0xFF3A6DF0);
  static const brand800 = Color(0xFF1E3A8A);
  static const ink = Color(0xFF0E1626);
  static const text = Color(0xFF152033);
  static const muted = Color(0xFF64748B);
  static const line = Color(0xFFE5E9F2);
  static const bg = Color(0xFFF4F6FB);
  static const ok = Color(0xFF059669);
  static const okBg = Color(0xFFECFDF5);
  static const warn = Color(0xFFD97706);
  static const warnBg = Color(0xFFFFFBEB);
  static const danger = Color(0xFFDC2626);
  static const dangerBg = Color(0xFFFEF2F2);
  static const violet = Color(0xFF7C3AED);
  static const violetBg = Color(0xFFF5F3FF);
  static const info = Color(0xFF2563EB);
  static const infoBg = Color(0xFFEFF6FF);
  static const accent = Color(0xFFFBBF24);
  static const cyan = Color(0xFF0891B2);
  static const cyanBg = Color(0xFFECFEFF);
  static const slateBg = Color(0xFFF1F5F9);

  static const heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF14224F), brand800, brand500],
  );

  static bool isDark(BuildContext context) => Theme.of(context).brightness == Brightness.dark;

  // ---- warna dasar yang menyesuaikan tema
  static Color textOf(BuildContext context) => isDark(context) ? D.text : text;
  static Color mutedOf(BuildContext context) => isDark(context) ? D.muted : muted;
  static Color bgOf(BuildContext context) => isDark(context) ? D.bg : bg;
  static Color cardOf(BuildContext context) => isDark(context) ? D.surface : Colors.white;
  static Color card2Of(BuildContext context) => isDark(context) ? D.surface2 : Colors.white;
  static Color lineOf(BuildContext context) => isDark(context) ? D.line : line;
  static Color brandOf(BuildContext context) => isDark(context) ? D.brand : brand;
  static Color fillOf(BuildContext context) => isDark(context) ? D.brandFill : brand;
  static LinearGradient heroOf(BuildContext context) => isDark(context) ? D.heroGradient : heroGradient;

  /// Warna latar lembut (tint) -> padanan gelapnya. Warna lain dikembalikan apa adanya.
  static Color soft(BuildContext context, Color c) {
    if (!isDark(context)) return c;
    if (c == brand50) return D.brandSoft;
    if (c == brand100) return D.brandLine;
    if (c == okBg) return D.okBg;
    if (c == warnBg) return D.warnBg;
    if (c == dangerBg) return D.dangerBg;
    if (c == violetBg) return D.violetBg;
    if (c == infoBg) return D.infoBg;
    if (c == cyanBg) return D.cyanBg;
    if (c == slateBg) return D.surface2;
    if (c == bg) return D.bg;
    if (c == Colors.white) return D.surface;
    if (c == const Color(0xFF382E12)) return D.warnBg;
    return c;
  }

  /// Warna aksen (ikon/teks) -> padanan yang lebih terbaca di latar gelap.
  static Color tone(BuildContext context, Color c) {
    if (!isDark(context)) return c;
    if (c == brand || c == brand500 || c == brand800) return D.brand;
    if (c == ok) return D.ok;
    if (c == warn) return D.warn;
    if (c == danger) return D.danger;
    if (c == violet) return D.violet;
    if (c == info) return D.info;
    if (c == cyan) return D.cyan;
    if (c == muted) return D.muted;
    if (c == text) return D.text;
    if (c == Colors.amber) return D.warn;
    return c;
  }
}

// =============================================================== Transisi halaman

/// Transisi halaman: memudar + naik sedikit + skala halus (semua platform).
class SoftPageTransitionsBuilder extends PageTransitionsBuilder {
  const SoftPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(PageRoute<T> route, BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation, Widget child) {
    final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInCubic);
    final fadeOutBack = CurvedAnimation(parent: secondaryAnimation, curve: Curves.easeInOut);
    return FadeTransition(
      opacity: Tween<double>(begin: 0, end: 1).animate(curved),
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero).animate(curved),
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.98, end: 1).animate(curved),
          // halaman di belakang sedikit meredup saat halaman baru muncul
          child: FadeTransition(
            opacity: Tween<double>(begin: 1, end: 0.85).animate(fadeOutBack),
            child: child,
          ),
        ),
      ),
    );
  }
}

OutlineInputBorder _inputBorder(Color c, [double w = 1]) =>
    OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: c, width: w));

ThemeData buildTheme({Brightness brightness = Brightness.light}) {
  final isDark = brightness == Brightness.dark;

  var scheme = ColorScheme.fromSeed(seedColor: C.brand, brightness: brightness);
  scheme = isDark
      ? scheme.copyWith(
          primary: D.brandFill,
          onPrimary: Colors.white,
          primaryContainer: D.brandSoft,
          onPrimaryContainer: D.text,
          secondary: D.brand,
          secondaryContainer: D.brandSoft,
          onSecondaryContainer: D.text,
          error: D.danger,
          surface: D.surface,
          onSurface: D.text,
          onSurfaceVariant: D.muted,
          outline: D.line,
          outlineVariant: D.line,
          surfaceTint: Colors.transparent,
          surfaceContainerLowest: D.bg,
          surfaceContainerLow: D.surface,
          surfaceContainer: D.surface,
          surfaceContainerHigh: D.surface2,
          surfaceContainerHighest: D.surface2,
          inverseSurface: D.surface2,
          onInverseSurface: D.text,
        )
      : scheme.copyWith(
          primary: C.brand,
          onPrimary: Colors.white,
          error: C.danger,
          surface: Colors.white,
          onSurface: C.text,
        );

  final bg = isDark ? D.bg : C.bg;
  final cardColor = isDark ? D.surface : Colors.white;
  final textColor = isDark ? D.text : C.text;
  final mutedColor = isDark ? D.muted : C.muted;
  final line = isDark ? D.line : C.line;
  final accent = isDark ? D.brand : C.brand;

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: bg,
    cardColor: cardColor,
    canvasColor: cardColor,
    dialogBackgroundColor: cardColor,
    splashColor: accent.withAlpha(isDark ? 28 : 22),
    highlightColor: accent.withAlpha(isDark ? 14 : 10),
    pageTransitionsTheme: const PageTransitionsTheme(builders: {
      TargetPlatform.android: SoftPageTransitionsBuilder(),
      TargetPlatform.iOS: SoftPageTransitionsBuilder(),
      TargetPlatform.fuchsia: SoftPageTransitionsBuilder(),
      TargetPlatform.linux: SoftPageTransitionsBuilder(),
      TargetPlatform.macOS: SoftPageTransitionsBuilder(),
      TargetPlatform.windows: SoftPageTransitionsBuilder(),
    }),
    textTheme: (isDark ? ThemeData.dark() : ThemeData.light()).textTheme.apply(
      bodyColor: textColor,
      displayColor: textColor,
    ),
    iconTheme: IconThemeData(color: isDark ? D.text : null),
    appBarTheme: AppBarTheme(
      backgroundColor: bg,
      foregroundColor: textColor,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      systemOverlayStyle: (isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark).copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: isDark ? D.surface : Colors.white,
        systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      ),
      titleTextStyle: TextStyle(color: textColor, fontSize: 19, fontWeight: FontWeight.w800),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: cardColor,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.black,
      elevation: isDark ? 0 : 10,
      height: 68,
      indicatorColor: isDark ? D.brandSoft : C.brand100,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final sel = states.contains(WidgetState.selected);
        return TextStyle(
          fontSize: 11.5,
          fontWeight: sel ? FontWeight.w800 : FontWeight.w600,
          color: sel ? accent : mutedColor,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final sel = states.contains(WidgetState.selected);
        return IconThemeData(color: sel ? accent : mutedColor, size: 25);
      }),
    ),
    dividerTheme: DividerThemeData(color: line, thickness: 1, space: 1),
    cardTheme: CardThemeData(color: cardColor, surfaceTintColor: Colors.transparent),
    dialogTheme: DialogThemeData(
      backgroundColor: cardColor,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titleTextStyle: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.w800),
      contentTextStyle: TextStyle(color: mutedColor, fontSize: 14, height: 1.4),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: cardColor,
      surfaceTintColor: Colors.transparent,
      modalBackgroundColor: cardColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: isDark ? D.surface2 : Colors.white,
      surfaceTintColor: Colors.transparent,
      textStyle: TextStyle(color: textColor, fontWeight: FontWeight.w600),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    listTileTheme: ListTileThemeData(
      textColor: textColor,
      iconColor: mutedColor,
      tileColor: Colors.transparent,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: isDark ? D.surface2 : Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
      hintStyle: TextStyle(color: mutedColor.withAlpha(isDark ? 200 : 190), fontWeight: FontWeight.normal),
      prefixIconColor: mutedColor,
      suffixIconColor: mutedColor,
      border: _inputBorder(line),
      enabledBorder: _inputBorder(line),
      focusedBorder: _inputBorder(accent, 1.6),
      errorBorder: _inputBorder(isDark ? D.danger : C.danger),
      focusedErrorBorder: _inputBorder(isDark ? D.danger : C.danger, 1.6),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: cardColor,
      selectedColor: isDark ? D.brandSoft : C.brand50,
      surfaceTintColor: Colors.transparent,
      side: BorderSide(color: line),
      labelStyle: TextStyle(color: textColor, fontWeight: FontWeight.w600),
      checkmarkColor: accent,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? Colors.white : (isDark ? D.muted : null)),
      trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? (isDark ? D.brandFill : C.brand) : (isDark ? D.surface2 : null)),
      trackOutlineColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? Colors.transparent : (isDark ? D.line : null)),
    ),
    textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: accent)),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: accent, linearTrackColor: isDark ? D.surface2 : null),
    datePickerTheme: DatePickerThemeData(
      backgroundColor: cardColor,
      surfaceTintColor: Colors.transparent,
      headerBackgroundColor: isDark ? D.surface2 : null,
      headerForegroundColor: isDark ? D.text : null,
    ),
    timePickerTheme: TimePickerThemeData(backgroundColor: cardColor),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: isDark ? D.surface2 : C.ink,
      contentTextStyle: TextStyle(color: isDark ? D.text : Colors.white, fontWeight: FontWeight.w600),
      behavior: SnackBarBehavior.floating,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: isDark ? D.brandFill : C.brand,
      foregroundColor: Colors.white,
      elevation: isDark ? 2 : 6,
      extendedTextStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  );
}

ThemeData buildLightTheme() => buildTheme(brightness: Brightness.light);
ThemeData buildDarkTheme() => buildTheme(brightness: Brightness.dark);
