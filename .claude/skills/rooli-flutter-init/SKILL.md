---
name: rooli-flutter-init
description: >
  Initialize a new Flutter project for the Rolli B2B school transportation app.
  Use this skill whenever the user runs /init or asks to scaffold/bootstrap/setup 
  the Rolli Flutter project from scratch. This covers: project creation, design system 
  extraction from Figma via MCP, Flutter theme generation, atomic component library, 
  Clean Architecture folder structure, core dependencies, and developer tooling.
  Also use when the user says "start the project", "setup the app", "create the base",
  or any variant of initializing the Rolli codebase.
---

# Rolli Flutter Project Initialization

This skill bootstraps the complete Rolli school transportation Flutter project
with pixel-perfect design system integration from Figma.

## Prerequisites Check

Before starting, verify:

```
1. Flutter SDK installed (>=3.24.0)
2. Figma MCP connected (check via "list MCP tools")
3. Figma file: "Rolli Design System" accessible
4. Target: 2 separate apps (Driver, Supervisor) — NO Parent app in current scope
```

If Figma MCP is not connected, STOP and ask the user to connect it first.

---

## Phase 1: Project Scaffolding

### 1.1 Create Flutter Project

```bash
flutter create rooli_app --org com.rooli --platforms android,ios
cd rooli_app
```

### 1.2 Folder Structure

Create the full Clean Architecture structure:

```
lib/
├── main.dart
├── main_development.dart
├── main_staging.dart
├── main_production.dart
├── app.dart                           # MaterialApp + GoRouter + Theme
│
├── core/
│   ├── constants/
│   │   └── app_constants.dart         # API URLs, timeouts, keys
│   │
│   ├── di/
│   │   └── injection.dart             # get_it + injectable setup
│   │
│   ├── error/
│   │   ├── failures.dart              # Failure base + subtypes
│   │   └── exceptions.dart
│   │
│   ├── network/
│   │   ├── dio_client.dart            # Dio + interceptors → Either<ServerException, T>
│   │   └── network_info.dart
│   │
│   ├── router/
│   │   ├── app_router.dart            # GoRouter configuration
│   │   └── route_names.dart
│   │
│   ├── theme/
│   │   ├── app_colors.dart            # ← Generated from Figma
│   │   ├── app_typography.dart        # ← Generated from Figma
│   │   ├── app_spacing.dart           # ← Generated from Figma
│   │   ├── app_radius.dart            # ← Generated from Figma
│   │   ├── app_shadows.dart           # ← Generated from Figma
│   │   └── app_theme.dart             # ThemeData combining all tokens
│   │
│   ├── widgets/                       # ← Atomic design components from Figma
│   │   ├── buttons/
│   │   │   ├── app_button.dart
│   │   │   └── app_icon_button.dart
│   │   ├── inputs/
│   │   │   ├── app_text_field.dart
│   │   │   └── app_dropdown.dart
│   │   ├── feedback/
│   │   │   ├── app_snackbar.dart
│   │   │   ├── app_dialog.dart
│   │   │   └── app_loading.dart
│   │   ├── layout/
│   │   │   ├── app_card.dart
│   │   │   ├── app_scaffold.dart
│   │   │   └── app_divider.dart
│   │   ├── navigation/
│   │   │   └── app_bottom_nav.dart
│   │   └── data_display/
│   │       ├── app_avatar.dart
│   │       ├── app_badge.dart
│   │       ├── app_chip.dart
│   │       └── app_status_chip.dart
│   │
│   ├── extensions/
│   │   ├── context_extensions.dart
│   │   ├── string_extensions.dart
│   │   └── date_extensions.dart
│   │
│   ├── utils/
│   │   ├── validators.dart
│   │   ├── formatters.dart            # Currency, date, phone
│   │   └── logger.dart
│   │
│   └── localization/
│       ├── en.json
│       └── ar.json
│
├── features/
│   ├── auth/
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   ├── models/
│   │   │   └── repositories/
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   ├── repositories/
│   │   │   └── usecases/
│   │   └── presentation/
│   │       ├── cubit/
│   │       ├── pages/
│   │       └── widgets/
│   │
│   ├── tracking/                      # Real-time GPS tracking
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │
│   ├── trips/                         # Trip management
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │
│   ├── check_in/                      # Student check-in/check-out
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │
│   ├── absence/                       # Absence reporting
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │
│   ├── notifications/                 # Push notification handling
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │
│   ├── route_management/              # Route viewing & optimization display
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │
│   └── profile/                       # User profile & settings
│       ├── data/
│       ├── domain/
│       └── presentation/
│
├── ai_docs/                           # Claude Code reference docs
│   ├── DESIGN_SYSTEM.md               # ← Generated: complete token reference
│   ├── ARCHITECTURE.md                # Architecture decisions & patterns
│   └── COMPONENT_CATALOG.md           # ← Generated: all available widgets
│
└── ai_specs/                          # Feature specs for Claude Code
    └── (feature specs go here)
```

### 1.3 Core Dependencies

```yaml
# pubspec.yaml
name: rooli_app
description: Rolli - School Transportation Platform
version: 1.0.0+1

environment:
  sdk: ">=3.5.0 <4.0.0"

dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter

  # State Management
  flutter_bloc: ^9.0.0
  bloc: ^9.0.0

  # DI
  get_it: ^8.0.2
  injectable: ^2.5.0

  # Navigation
  go_router: ^14.6.2

  # Network
  dio: ^5.7.0
  pretty_dio_logger: ^1.4.0

  # Localization
  easy_localization: ^3.0.7

  # UI
  flutter_screenutil: ^5.9.3
  flutter_svg: ^2.0.16
  cached_network_image: ^3.4.1
  shimmer: ^3.0.0

  # Maps & Location
  google_maps_flutter: ^2.10.0
  geolocator: ^13.0.1

  # Storage
  shared_preferences: ^2.3.3
  # Hive Community Edition — maintained, API-compatible fork of Hive 2
  # (original hive/hive_flutter is unmaintained). Backs the offline-first cache,
  # write outbox, and location buffer. See ai_docs/OFFLINE_FIRST_PLAN.md.
  hive_ce: ^2.19.3
  hive_ce_flutter: ^2.2.0

  # Firebase
  firebase_core: ^3.8.0
  firebase_messaging: ^15.1.5

  # Functional
  dartz: ^0.10.1
  equatable: ^2.0.7
  freezed_annotation: ^2.4.4
  json_annotation: ^4.9.0

  # Utils
  intl: ^0.19.0
  url_launcher: ^6.3.1
  permission_handler: ^11.3.1

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0
  build_runner: ^2.4.13
  injectable_generator: ^2.6.2
  freezed: ^2.5.7
  json_serializable: ^6.8.0
  hive_ce_generator: ^1.9.0   # @GenerateAdapters / HiveRegistrar codegen (replaces hive_generator)
  bloc_test: ^9.1.7
  mocktail: ^1.0.4
```

Run after creating pubspec.yaml:

```bash
flutter pub get
```

---

## Phase 2: Design System Extraction from Figma

**This is the most critical phase. Every UI decision flows from here.**

### 2.1 Extract Color Tokens

Using Figma MCP, read the **"Colors"** page in the Rolli Design System file.

For EACH color, extract:
- Token name (e.g., `primary/500`, `neutral/100`, `error/default`)
- Hex value
- Opacity (if not 100%)
- Light/dark mode variants (if defined)

Generate `lib/core/theme/app_colors.dart`:

```dart
// GENERATED FROM FIGMA — DO NOT EDIT MANUALLY
// Source: Rolli Design System > Colors
// Last synced: {current_date}

import 'package:flutter/material.dart';

abstract class AppColors {
  // ---- Primary ----
  // Extract all primary shades from Figma
  
  // ---- Secondary ----
  // Extract all secondary shades from Figma
  
  // ---- Neutral / Gray ----
  // Extract all neutral shades from Figma
  
  // ---- Semantic ----
  // success, warning, error, info from Figma
  
  // ---- Surface / Background ----
  // surface, background, card colors from Figma
}
```

**IMPORTANT:** Use EXACT Figma token names as Dart identifiers (converted to camelCase).
Map `primary/500` → `primary500`, `neutral/50` → `neutral50`.

### 2.2 Extract Typography

Using Figma MCP, read the **"Typography"** page.

For EACH text style, extract:
- Style name
- Font family
- Font size (px)
- Font weight (number: 400, 500, 600, 700...)
- Line height (as multiplier: lineHeight / fontSize)
- Letter spacing (px)

Generate `lib/core/theme/app_typography.dart`:

```dart
// GENERATED FROM FIGMA — DO NOT EDIT MANUALLY
// Source: Rolli Design System > Typography
// Last synced: {current_date}

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

abstract class AppTypography {
  static const _fontFamily = '{FONT_FROM_FIGMA}';
  
  // Map every Figma text style to a static TextStyle
  // ALWAYS use .sp for fontSize
  // ALWAYS calculate height as lineHeight / fontSize
}
```

**IMPORTANT:** If the font is a Google Font, add `google_fonts` package. If custom,
ensure the font files are in `assets/fonts/` and registered in `pubspec.yaml`.

### 2.3 Extract Spacing Scale

Using Figma MCP, read the **"Spacing"** page.

Extract the spacing scale (usually: 2, 4, 8, 12, 16, 20, 24, 32, 40, 48, 64...).

Generate `lib/core/theme/app_spacing.dart`:

```dart
// GENERATED FROM FIGMA
import 'package:flutter_screenutil/flutter_screenutil.dart';

abstract class AppSpacing {
  // Map each Figma spacing token
  // Use .w for horizontal, .h for vertical
  // Also provide EdgeInsets helpers:
  //   static EdgeInsets paddingH(double value) => EdgeInsets.symmetric(horizontal: value);
  //   static EdgeInsets paddingV(double value) => EdgeInsets.symmetric(vertical: value);
  //   static EdgeInsets paddingAll(double value) => EdgeInsets.all(value);
}
```

### 2.4 Extract Corner Radius

Using Figma MCP, read the **"Corner Radius"** page.

Generate `lib/core/theme/app_radius.dart`:

```dart
// GENERATED FROM FIGMA
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

abstract class AppRadius {
  // Radius values
  // Pre-built BorderRadius constants
}
```

### 2.5 Extract Shadows

Using Figma MCP, read the **"Shadows"** page.

For EACH shadow, extract: color, opacity, x offset, y offset, blur, spread.

Generate `lib/core/theme/app_shadows.dart`:

```dart
// GENERATED FROM FIGMA
abstract class AppShadows {
  // Each shadow as List<BoxShadow>
}
```

### 2.6 Extract Icons

Using Figma MCP, read the **"Icons"** page.

Determine:
- Is it a standard icon set (Material, Lucide, Phosphor, etc.)?
- Or custom icons that need SVG export?

If custom icons: export as SVGs to `assets/icons/` and use `flutter_svg`.
If standard set: install the matching package.

### 2.7 Assemble ThemeData

Generate `lib/core/theme/app_theme.dart` that combines all tokens into
`ThemeData` for both light and dark mode:

```dart
import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.light(
      primary: AppColors.primary500,
      // ... map all semantic colors
    ),
    textTheme: TextTheme(
      displayLarge: AppTypography.displayLarge,
      // ... map all text styles
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: // ... default button style from design
    ),
    inputDecorationTheme: InputDecorationTheme(
      // ... default input style from design
    ),
    // ... card, dialog, appbar, bottomNav themes
  );

  static ThemeData get dark => ThemeData(
    // ... dark variant if design system has one
  );
}
```

---

## Phase 3: Build Atomic Components from Figma

For EACH component in the design system, follow this exact process:

### Process per Component:

1. **Read from Figma MCP** — get the component page/frame
2. **Identify all variants** — variant names, sizes, states
3. **Extract exact specs** — padding, height, radius, colors per state
4. **Implement in Flutter** — using ONLY theme tokens from Phase 2
5. **Document in COMPONENT_CATALOG.md**

### 3.1 Button Component

Read **"Button"** page from Figma via MCP.

Expected variants from the screenshot:
- Colors: Primary (green), Destructive (red), possibly Secondary, Outline, Ghost
- Sizes: Small, Medium, Large
- States: Default, Hover/Pressed, Disabled, Loading
- Content: Text only, Icon + Text, Text + Icon, Icon only

```dart
// lib/core/widgets/buttons/app_button.dart

enum AppButtonVariant { primary, secondary, outline, ghost, destructive }
enum AppButtonSize { sm, md, lg }

class AppButton extends StatelessWidget {
  final String? label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool isLoading;
  final bool isExpanded;
  final bool iconOnly;

  // Implementation uses ONLY AppColors, AppTypography, AppSpacing, AppRadius
  // NEVER hardcode any value
  // Heights, padding, radius — all from Figma extraction
}
```

### 3.2 Remaining Components

Repeat the same process for each component in this priority order:

```
Priority 1 (build first — used everywhere):
  ✅ Button
  ✅ Input / TextField
  ✅ Bottom Navigation Bar

Priority 2 (build next — used in most screens):
  ✅ Dropdown
  ✅ Checkbox & Radio Button
  ✅ Toggle
  ✅ Avatar
  ✅ Badge

Priority 3 (build last — used in specific screens):
  ✅ Chip
  ✅ Tooltip
```

For each component, the Figma MCP prompt is:

```
Using Figma MCP, read the "{Component Name}" page in Rolli Design System.

Extract:
1. All variant names and what differentiates them
2. All size variants with exact: height, padding (horizontal & vertical),
   icon size, font style, spacing between elements
3. All state variants with exact: background color, text color, border color,
   border width, shadow, opacity
4. Border radius used
5. Any animation/transition specs

Then implement as lib/core/widgets/{category}/{file_name}.dart
using ONLY tokens from app_colors.dart, app_typography.dart, 
app_spacing.dart, app_radius.dart, app_shadows.dart.
```

---

## Phase 4: Generate Reference Documents

### 4.1 DESIGN_SYSTEM.md

After Phases 2 and 3, generate `ai_docs/DESIGN_SYSTEM.md`:

```markdown
# Rolli Design System — Flutter Reference

## Source
Figma File: Rolli Design System
Last synced: {date}

## How to Use
When implementing ANY screen or widget:
1. Read this file first
2. Use ONLY the tokens listed below
3. Use ONLY the components listed in COMPONENT_CATALOG.md
4. NEVER hardcode colors, sizes, fonts, spacing, or radius

## Color Tokens
{List every color with its Dart reference: AppColors.primary500}

## Typography Tokens
{List every text style with its Dart reference: AppTypography.h1}

## Spacing Scale
{List the scale: AppSpacing.xs (4), AppSpacing.sm (8), ...}

## Radius Tokens
{List: AppRadius.sm (4), AppRadius.md (8), ...}

## Shadow Tokens
{List: AppShadows.sm, AppShadows.md, ...}

## Enforcement Rules
- grep for Color(0x → ONLY in app_colors.dart
- grep for fontSize: without .sp → VIOLATION
- grep for EdgeInsets with raw numbers → use AppSpacing
- grep for BorderRadius with raw numbers → use AppRadius
- grep for left:/right: → use start:/end: (RTL)
- grep for hardcoded strings → use .tr()
```

### 4.2 COMPONENT_CATALOG.md

```markdown
# Rolli Component Catalog

## Usage Rule
If a component exists below, you MUST use it.
NEVER use raw Material widgets (ElevatedButton, TextFormField, etc.)
when an App-prefixed equivalent exists.

## Components

### AppButton
- File: lib/core/widgets/buttons/app_button.dart
- Variants: primary, secondary, outline, ghost, destructive
- Sizes: sm, md, lg
- Props: label, onPressed, variant, size, prefixIcon, suffixIcon,
         isLoading, isExpanded, iconOnly
- Example:
  AppButton(
    label: 'confirm'.tr(),
    variant: AppButtonVariant.primary,
    size: AppButtonSize.md,
    onPressed: () {},
  )

### AppTextField
{same format}

### AppBottomNav
{same format}

... (every component)
```

### 4.3 ARCHITECTURE.md

```markdown
# Rolli Architecture Guide

## Stack
- Architecture: Clean Architecture (data / domain / presentation)
- State: BLoC / Cubit (flutter_bloc)
- DI: get_it + injectable
- Routing: go_router
- API: REST (Dio) → Either<ServerException, T>
- Localization: easy_localization (en.json + ar.json)
- Scaling: flutter_screenutil
- Error monitoring: Sentry (when configured)

## Feature Structure
Every feature follows:
  feature_name/
  ├── data/
  │   ├── datasources/   remote + local
  │   ├── models/         DTOs with fromJson/toJson (freezed)
  │   └── repositories/   implements domain repo
  ├── domain/
  │   ├── entities/       pure Dart (equatable)
  │   ├── repositories/   abstract interface
  │   └── usecases/       single-responsibility
  └── presentation/
      ├── cubit/          state management
      ├── pages/          full screens
      └── widgets/        screen-specific widgets

## Rules
1. Data layer NEVER imports presentation layer
2. Domain layer imports NOTHING from data or presentation
3. Presentation layer imports domain (not data directly)
4. All dependencies injected via get_it (no manual instantiation)
5. All API returns Either<Failure, T> — handle both sides
6. No business logic in widgets — only in cubits/usecases
7. No mocked/hardcoded data in UI — always real data or proper loading state

## Localization Rules
- Every user-visible string uses .tr() extension
- Keys in en.json and ar.json must stay in sync
- Date/currency formatting uses intl with locale-aware formatters
- Numbers always Latin (enforced in Arabic locale)
- RTL: use start/end, never left/right

## Commit Format
feat(feature): short description
fix(feature): short description
refactor(feature): short description
chore: short description
```

---

## Phase 5: Developer Tooling

### 5.1 Claude Code Settings

Create `.claude/settings.json`:

```json
{
  "instructions": [
    "ALWAYS read ai_docs/DESIGN_SYSTEM.md before implementing any UI screen or widget",
    "ALWAYS read ai_docs/COMPONENT_CATALOG.md and use existing components instead of raw Material widgets",
    "NEVER hardcode colors — use AppColors.xxx",
    "NEVER hardcode font sizes — use AppTypography.xxx with .sp",
    "NEVER hardcode spacing — use AppSpacing.xxx",
    "NEVER hardcode radius — use AppRadius.xxx",
    "NEVER use left/right — use start/end for RTL support",
    "ALWAYS use .tr() for user-visible strings",
    "ALWAYS use flutter_screenutil (.w, .h, .sp, .r) for dimensions",
    "Follow Clean Architecture: data → domain → presentation separation",
    "Use Cubit for state management in every screen",
    "When implementing a screen from Figma, use Figma MCP to read the exact frame first"
  ]
}
```

### 5.2 Design Token Verification Script

Create `scripts/check_design_tokens.sh`:

```bash
#!/bin/bash
echo "🎨 Checking design token compliance..."

ERRORS=0

# Hardcoded colors
echo "--- Hardcoded Colors ---"
RESULT=$(grep -rn "Color(0x" lib/features/ lib/core/widgets/ --include="*.dart" 2>/dev/null)
if [ -n "$RESULT" ]; then
  echo "$RESULT"
  ERRORS=$((ERRORS + 1))
fi

# Missing ScreenUtil
echo "--- Missing ScreenUtil ---"
RESULT=$(grep -rn "fontSize: [0-9]" lib/ --include="*.dart" 2>/dev/null | grep -v "\.sp")
if [ -n "$RESULT" ]; then
  echo "$RESULT"
  ERRORS=$((ERRORS + 1))
fi

# Raw spacing
echo "--- Raw Spacing Values ---"
RESULT=$(grep -rn "SizedBox(width: [0-9]" lib/features/ --include="*.dart" 2>/dev/null | grep -v "\.w")
if [ -n "$RESULT" ]; then
  echo "$RESULT"
  ERRORS=$((ERRORS + 1))
fi
RESULT=$(grep -rn "SizedBox(height: [0-9]" lib/features/ --include="*.dart" 2>/dev/null | grep -v "\.h")
if [ -n "$RESULT" ]; then
  echo "$RESULT"
  ERRORS=$((ERRORS + 1))
fi

# LTR/RTL violations
echo "--- RTL Issues ---"
RESULT=$(grep -rn "EdgeInsets.only(left:" lib/features/ --include="*.dart" 2>/dev/null)
if [ -n "$RESULT" ]; then
  echo "$RESULT"
  ERRORS=$((ERRORS + 1))
fi

# Missing .tr()
echo "--- Possible Missing Translations ---"
RESULT=$(grep -rn "Text('" lib/features/ --include="*.dart" 2>/dev/null | grep -v "\.tr()" | grep -v "// no-tr")
if [ -n "$RESULT" ]; then
  echo "⚠️  Strings that may need .tr():"
  echo "$RESULT"
fi

if [ $ERRORS -eq 0 ]; then
  echo "✅ All checks passed!"
else
  echo "❌ Found $ERRORS violation(s)"
fi
```

### 5.3 Figma-to-Screen Prompt Template

Create `ai_specs/_SCREEN_TEMPLATE.md`:

```markdown
# Screen: {SCREEN_NAME}

## Figma Reference
- File: Rolli Design System (or App file)
- Page: {PAGE_NAME}
- Frame: {FRAME_NAME}

## Pre-Implementation Checklist
- [ ] Read ai_docs/DESIGN_SYSTEM.md
- [ ] Read ai_docs/COMPONENT_CATALOG.md
- [ ] Read this spec
- [ ] Read Figma frame via MCP

## Description
{What this screen does}

## User Stories
- As a {role}, I want to {action} so that {benefit}

## Data Requirements
- Entities: {list domain entities needed}
- API: {REST endpoint URL and HTTP method}
- State: {what the cubit manages}

## Screen States
- Loading: shimmer placeholders matching layout
- Empty: {empty state message + illustration}
- Error: {error handling — retry button}
- Success: {normal data display}

## Interactions
- {tap, swipe, scroll behaviors}
- {navigation destinations}

## Localization Keys
- {list keys needed in en.json and ar.json}

## Acceptance Criteria
- [ ] Matches Figma frame exactly (screenshot compare)
- [ ] Works in English (LTR) and Arabic (RTL)
- [ ] All strings use .tr()
- [ ] All dimensions use screenutil
- [ ] No hardcoded colors/fonts/spacing
- [ ] Loading state shows shimmer
- [ ] Error state shows retry
- [ ] Passes scripts/check_design_tokens.sh
```

---

## Phase 6: Post-Init Verification

After completing all phases, run this checklist:

```
Project Structure:
  [ ] lib/core/theme/ has all 6 theme files
  [ ] lib/core/widgets/ has all component files
  [ ] ai_docs/ has DESIGN_SYSTEM.md, ARCHITECTURE.md, COMPONENT_CATALOG.md
  [ ] .claude/settings.json has enforcement rules
  [ ] scripts/check_design_tokens.sh is executable

Design Tokens:
  [ ] Every Figma color token has a Dart equivalent
  [ ] Every Figma text style has a Dart equivalent
  [ ] Spacing scale matches Figma exactly
  [ ] Radius values match Figma exactly
  [ ] Shadow values match Figma exactly

Components:
  [ ] Every Figma component has a Flutter widget
  [ ] Every widget uses only theme tokens
  [ ] Every widget handles all Figma variants and states
  [ ] Components documented in COMPONENT_CATALOG.md

App Runs:
  [ ] flutter pub get succeeds
  [ ] flutter analyze shows no errors
  [ ] App launches and shows themed splash/home
```

---

## Execution Order Summary

When the user runs `/init`, execute these phases IN ORDER:

```
Phase 1 → Scaffold project + folder structure + dependencies
Phase 2 → Extract ALL design tokens from Figma MCP → generate theme files
Phase 3 → Build ALL components from Figma MCP → generate widget files
Phase 4 → Generate reference docs (DESIGN_SYSTEM.md, COMPONENT_CATALOG.md, ARCHITECTURE.md)
Phase 5 → Setup developer tooling (.claude/settings.json, scripts, templates)
Phase 6 → Verify everything works
```

**CRITICAL:** Do NOT skip Phase 2. Every component in Phase 3 and every
screen built later depends on accurate token extraction from Figma. If
Figma MCP is unavailable, STOP and ask the user to provide token values manually.

**CRITICAL:** Commit after each phase with a descriptive message:
```
chore: scaffold project structure (Phase 1)
feat(theme): extract design tokens from Figma (Phase 2)
feat(widgets): implement atomic components from Figma (Phase 3)
docs: generate design system reference docs (Phase 4)
chore: setup developer tooling and verification (Phase 5)
```
