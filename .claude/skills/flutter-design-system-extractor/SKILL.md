---
name: flutter-design-system-extractor
description: >
  Extract design tokens from Figma via MCP and generate Flutter theme files.
  Use this skill whenever the user asks to sync the design system, extract tokens
  from Figma, update colors/typography/spacing, generate theme files, or says
  "sync from Figma", "update design system", "extract tokens", "generate theme".
  Also use when the user says "the design changed" or "designer updated the colors".
---

# Flutter Design System Extractor

Extracts design tokens from Figma via MCP and generates Flutter-ready theme files.

## When to Use
- Initial project setup (called by rooli-flutter-init Phase 2)
- Designer updated the design system in Figma
- Adding new tokens (new color, new text style)
- Verifying Flutter code matches Figma source of truth

## Prerequisites
- Figma MCP must be connected
- flutter_screenutil must be in pubspec.yaml

---

## Step 1: Read Figma Design System

Use Figma MCP to read EACH utility page. The Rolli Design System file has:

```
Utilities:
  - Colors
  - Typography  
  - Spacing
  - Layout Grid
  - Corner Radius
  - Shadows
  - Icons
```

For each page, extract raw data before generating any code.

---

## Step 2: Generate Theme Files

### 2.1 Colors → `lib/core/theme/app_colors.dart`

Read the **Colors** page via Figma MCP.

Extract every color token with:
- Token name (e.g., `primary/500`, `neutral/100`, `success/default`)
- Hex value (6 or 8 digit)
- Opacity if separate from hex

Naming convention — convert Figma token path to camelCase:
- `primary/500` → `primary500`
- `neutral/50` → `neutral50`
- `error/default` → `errorDefault`
- `surface/light` → `surfaceLight`

Output format:
```dart
// GENERATED FROM FIGMA — Rolli Design System > Colors
// Last synced: {YYYY-MM-DD}
// DO NOT EDIT MANUALLY — re-run extraction to update

import 'package:flutter/material.dart';

abstract class AppColors {
  // ---- Primary ----
  static const primary50 = Color(0xFFxxxxxx);
  static const primary100 = Color(0xFFxxxxxx);
  // ... every shade
  
  // ---- Secondary ----
  // ... every shade
  
  // ---- Neutral ----
  // ... every shade
  
  // ---- Semantic ----
  static const success = Color(0xFFxxxxxx);
  static const warning = Color(0xFFxxxxxx);
  static const error = Color(0xFFxxxxxx);
  static const info = Color(0xFFxxxxxx);
  
  // ---- Surface / Background ----
  // ... as defined in Figma
}
```

**Rules:**
- EVERY color from Figma must have a Dart constant
- Group by category matching Figma structure
- Include the sync date in the header comment
- If Figma has light/dark variants, generate both

### 2.2 Typography → `lib/core/theme/app_typography.dart`

Read the **Typography** page via Figma MCP.

Extract every text style with:
- Style name
- Font family
- Font size (px → .sp)
- Font weight (100-900 numeric)
- Line height (convert: Figma gives px, Flutter needs multiplier = lineHeight / fontSize)
- Letter spacing (px → raw value, screenutil not needed for letter spacing)

Output format:
```dart
// GENERATED FROM FIGMA — Rolli Design System > Typography
// Last synced: {YYYY-MM-DD}

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

abstract class AppTypography {
  static const _fontFamily = '{DETECTED_FONT}';
  
  static TextStyle get displayLarge => TextStyle(
    fontFamily: _fontFamily,
    fontSize: XX.sp,
    fontWeight: FontWeight.wXXX,
    height: X.XX,           // lineHeight / fontSize
    letterSpacing: X.XX,
  );
  
  // ... every text style from Figma
}
```

**Rules:**
- ALWAYS use .sp for fontSize
- Calculate height as: figma_line_height / figma_font_size
- Use getter (get) not static final — for screenutil to recalculate
- If font is custom, note it needs to be added to assets/fonts/
- If font is Google Font, note google_fonts package is needed

### 2.3 Spacing → `lib/core/theme/app_spacing.dart`

Read the **Spacing** page via Figma MCP.

Extract the spacing scale values.

Output format:
```dart
// GENERATED FROM FIGMA — Rolli Design System > Spacing
// Last synced: {YYYY-MM-DD}

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

abstract class AppSpacing {
  // Named tokens matching Figma
  static double get xxs => X.w;
  static double get xs => X.w;
  static double get sm => X.w;
  static double get md => X.w;
  static double get lg => X.w;
  static double get xl => X.w;
  static double get xxl => X.w;
  
  // Vertical equivalents (if scale differs)
  static double get vXs => X.h;
  static double get vSm => X.h;
  // ...
  
  // Convenience helpers
  static EdgeInsets all(double v) => EdgeInsets.all(v);
  static EdgeInsets horizontal(double v) => EdgeInsets.symmetric(horizontal: v);
  static EdgeInsets vertical(double v) => EdgeInsets.symmetric(vertical: v);
}
```

### 2.4 Corner Radius → `lib/core/theme/app_radius.dart`

Read the **Corner Radius** page via Figma MCP.

```dart
// GENERATED FROM FIGMA — Rolli Design System > Corner Radius
// Last synced: {YYYY-MM-DD}

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

abstract class AppRadius {
  static double get none => 0;
  static double get sm => X.r;
  static double get md => X.r;
  static double get lg => X.r;
  static double get xl => X.r;
  static double get full => 999.r;
  
  // Pre-built BorderRadius
  static BorderRadius get borderNone => BorderRadius.zero;
  static BorderRadius get borderSm => BorderRadius.circular(sm);
  static BorderRadius get borderMd => BorderRadius.circular(md);
  static BorderRadius get borderLg => BorderRadius.circular(lg);
  static BorderRadius get borderXl => BorderRadius.circular(xl);
  static BorderRadius get borderFull => BorderRadius.circular(full);
}
```

### 2.5 Shadows → `lib/core/theme/app_shadows.dart`

Read the **Shadows** page via Figma MCP.

For each shadow, extract: color, opacity, x-offset, y-offset, blur-radius, spread-radius.

```dart
// GENERATED FROM FIGMA — Rolli Design System > Shadows
// Last synced: {YYYY-MM-DD}

import 'package:flutter/material.dart';

abstract class AppShadows {
  static List<BoxShadow> get sm => [
    BoxShadow(
      color: Color(0xFFxxxxxx).withValues(alpha: X.XX),
      offset: Offset(X, X),
      blurRadius: X,
      spreadRadius: X,
    ),
  ];
  // ... every shadow level
}
```

### 2.6 Icons

Read the **Icons** page via Figma MCP.

Determine:
1. Standard set? (Material, Lucide, Phosphor, etc.) → install matching package
2. Custom SVGs? → export and save to `assets/icons/`, create icon registry

---

## Step 3: Generate AppTheme

Combine all tokens into `lib/core/theme/app_theme.dart`:

```dart
import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    fontFamily: AppTypography._fontFamily,
    colorScheme: ColorScheme.light(
      primary: AppColors.primaryXXX,
      secondary: AppColors.secondaryXXX,
      error: AppColors.error,
      surface: AppColors.surfaceLight,
    ),
    scaffoldBackgroundColor: AppColors.surfaceLight,
    textTheme: _textTheme,
    elevatedButtonTheme: _buttonTheme,
    inputDecorationTheme: _inputTheme,
    cardTheme: _cardTheme,
    appBarTheme: _appBarTheme,
    bottomNavigationBarTheme: _bottomNavTheme,
  );
  
  // Build each sub-theme from tokens
}
```

---

## Step 4: Update Reference Docs

After generating all files, update `ai_docs/DESIGN_SYSTEM.md` with:
- Complete list of every token and its Dart reference
- The sync date
- Any notes about changes from last sync

---

## Step 5: Verification

Run these checks:
```bash
# Ensure all files compile
dart analyze lib/core/theme/

# Check no tokens were missed (compare Figma count vs Dart count)
echo "Colors in Figma: X | Colors in app_colors.dart: $(grep -c 'static const' lib/core/theme/app_colors.dart)"
echo "Styles in Figma: X | Styles in app_typography.dart: $(grep -c 'TextStyle' lib/core/theme/app_typography.dart)"
```

---

## Re-sync Workflow

When the designer updates the Figma file:

1. Re-read the changed page via Figma MCP
2. Diff against current Dart file
3. Update ONLY the changed tokens
4. Add changelog entry in the file header
5. Run `dart analyze` to catch any breaks
6. Update DESIGN_SYSTEM.md
