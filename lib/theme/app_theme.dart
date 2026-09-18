// lib/theme/app_theme.dart
import 'package:flutter/material.dart';

class AppColors {
  // ────────────────────── SURFACE ──────────────────────
  static const surface = Color(0xFFF8F9FF);
  static const surfaceDim = Color(0xFFCBD8F5);
  static const surfaceBright = Color(0xFFF8F9FF);
  static const surfaceContainerLowest = Color(0xFFFFFFFF);
  static const surfaceContainerLow = Color(0xFFEFF4FF);
  static const surfaceContainer = Color(0xFFE5EEFF);
  static const surfaceContainerHigh = Color(0xFFDCE9FF);
  static const surfaceContainerHighest = Color(0xFFD3E4FE);
  static const surfaceVariant = Color(0xFFD3E4FE);

  // ────────────────────── ON SURFACE ──────────────────────
  static const onSurface = Color(0xFF0B1C30);
  static const onSurfaceVariant = Color(0xFF434655);
  static const inverseSurface = Color(0xFF213145);
  static const inverseOnSurface = Color(0xFFEAF1FF);

  // ────────────────────── OUTLINE ──────────────────────
  static const outline = Color(0xFF737686);
  static const outlineVariant = Color(0xFFC3C6D7);

  // ────────────────────── SURFACE TINT ──────────────────────
  static const surfaceTint = Color(0xFF0053DB);
  static const inversePrimary = Color(0xFFB4C5FF);

  // ────────────────────── PRIMARY ──────────────────────
  static const primary = Color(0xFF004AC6);
  static const onPrimary = Color(0xFFFFFFFF);
  static const primaryContainer = Color(0xFF2563EB);
  static const onPrimaryContainer = Color(0xFFEEEEFF);
  static const primaryFixed = Color(0xFFDBE1FF);
  static const primaryFixedDim = Color(0xFFB4C5FF);
  static const onPrimaryFixed = Color(0xFF00174B);
  static const onPrimaryFixedVariant = Color(0xFF003EA8);

  // ────────────────────── SECONDARY ──────────────────────
  static const secondary = Color(0xFF006C49);
  static const onSecondary = Color(0xFFFFFFFF);
  static const secondaryContainer = Color(0xFF6CF8BB);
  static const onSecondaryContainer = Color(0xFF00714D);
  static const secondaryFixed = Color(0xFF6FFBBE);
  static const secondaryFixedDim = Color(0xFF4EDEA3);
  static const onSecondaryFixed = Color(0xFF002113);
  static const onSecondaryFixedVariant = Color(0xFF005236); // ✅ AGREGADO

  // ────────────────────── TERTIARY ──────────────────────
  static const tertiary = Color(0xFF4D556B);
  static const onTertiary = Color(0xFFFFFFFF);
  static const tertiaryContainer = Color(0xFF656D84);
  static const onTertiaryContainer = Color(0xFFEEF0FF);
  static const tertiaryFixed = Color(0xFFDAE2FD);
  static const tertiaryFixedDim = Color(0xFFBEC6E0);
  static const onTertiaryFixed = Color(0xFF131B2E);
  static const onTertiaryFixedVariant = Color(0xFF3F465C); // ✅ AGREGADO

  // ────────────────────── ERROR ──────────────────────
  static const error = Color(0xFFBA1A1A);
  static const onError = Color(0xFFFFFFFF);
  static const errorContainer = Color(0xFFFFDAD6);
  static const onErrorContainer = Color(0xFF93000A);

  // ────────────────────── BACKGROUND ──────────────────────
  static const background = Color(0xFFF8F9FF);
  static const onBackground = Color(0xFF0B1C30);

  // ────────────────────── SEMANTIC (DESIGN.md brand colors) ──────────────────────
  /// Primary Sapphire - focus frames, active camera targeting
  static const scanSapphire = Color(0xFF2563EB);

  /// Secondary Emerald - success confirmations, verified badges
  static const scanEmerald = Color(0xFF10B981);

  /// Tertiary Slate Navy - critical headers, HUD overlays
  static const slateNavy = Color(0xFF0F172A);

  /// Neutral Steel - auxiliary data, metadata
  static const neutralSteel = Color(0xFF64748B);

  /// Base canvas - soft cool stone
  static const baseCanvas = Color(0xFFF8FAFC);

  /// Optical scrim - 60% translucent overlay for camera
  static const opticalScrim = Color(0xFF020617);
}

class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const gutter = 16.0;
  static const margin = 16.0;
}

class AppRadius {
  static const sm = 4.0;
  static const md = 8.0;
  static const lg = 12.0;
  static const xl = 16.0;
  static const xxl = 24.0;
  static const full = 9999.0;
}

// ────────────────────── MONOSPACE TEXT STYLES ──────────────────────
class AppMonoText {
  /// JetBrains Mono 13px - for barcode numbers, codes, timestamps
  static TextStyle code = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    height: 1.38,
    color: AppColors.onSurface,
  );

  /// JetBrains Mono 11px - for badges, symbology tags, uppercase tracking
  static TextStyle badge = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    height: 1.27,
    color: AppColors.onSurfaceVariant,
    letterSpacing: 0.55, // +0.05em tracking
  );
}

class AppTheme {
  static ThemeData get light {
    final base = ThemeData.light(useMaterial3: true);

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.surface,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        primaryContainer: AppColors.primaryContainer,
        onPrimaryContainer: AppColors.onPrimaryContainer,
        secondary: AppColors.secondary,
        onSecondary: AppColors.onSecondary,
        secondaryContainer: AppColors.secondaryContainer,
        onSecondaryContainer: AppColors.onSecondaryContainer,
        tertiary: AppColors.tertiary,
        onTertiary: AppColors.onTertiary,
        tertiaryContainer: AppColors.tertiaryContainer,
        onTertiaryContainer: AppColors.onTertiaryContainer,
        surface: AppColors.surface,
        onSurface: AppColors.onSurface,
        surfaceContainerLowest: AppColors.surfaceContainerLowest,
        surfaceContainerLow: AppColors.surfaceContainerLow,
        surfaceContainer: AppColors.surfaceContainer,
        surfaceContainerHigh: AppColors.surfaceContainerHigh,
        surfaceContainerHighest: AppColors.surfaceContainerHighest,
        surfaceTint: AppColors.surfaceTint,
        onSurfaceVariant: AppColors.onSurfaceVariant,
        inverseSurface: AppColors.inverseSurface,
        onInverseSurface: AppColors.inverseOnSurface,
        inversePrimary: AppColors.inversePrimary,
        outline: AppColors.outline,
        outlineVariant: AppColors.outlineVariant,
        error: AppColors.error,
        onError: AppColors.onError,
        errorContainer: AppColors.errorContainer,
        onErrorContainer: AppColors.onErrorContainer,
      ),
      textTheme: TextTheme(
        // headline-xl
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          height: 1.25, // 40/32
          color: AppColors.onSurface,
        ),
        // headline-lg
        displayMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          height: 1.333, // 32/24
          color: AppColors.onSurface,
        ),
        // headline-md
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          height: 1.4, // 28/20
          color: AppColors.onSurface,
        ),
        // body-lg
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          height: 1.5, // 24/16
          color: AppColors.onSurface,
        ),
        // body-md
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          height: 1.428, // 20/14
          color: AppColors.onSurface,
        ),
        // body-sm
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          height: 1.333, // 16/12
          color: AppColors.onSurfaceVariant,
        ),
        // label-action
        labelLarge: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          height: 1.333, // 20/15
          color: AppColors.onSurface,
        ),
        // label-code
        labelMedium: AppMonoText.code,
        // label-badge
        labelSmall: AppMonoText.badge,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceContainerLowest,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(color: AppColors.outlineVariant.withOpacity(0.5)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceContainerLow,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 14,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          textStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          elevation: 0,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceContainer,
        labelStyle: AppMonoText.badge,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.inverseSurface,
        contentTextStyle: TextStyle(
          fontSize: 13,
          color: AppColors.inverseOnSurface,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
      ),
    );
  }
}
