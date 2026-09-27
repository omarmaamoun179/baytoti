---
name: flutter-component-builder
description: >
  Build Flutter widgets from Figma component designs via MCP. Use this skill
  whenever the user asks to implement a component from the design system,
  build a widget matching Figma, create a reusable component, or says
  "build the button", "implement the input", "create the card component",
  "make the widget match Figma", or "build component X from the design system".
  Also triggers on: "component doesn't match design", "fix the button styling",
  "the widget looks different from Figma".
---

# Flutter Component Builder

Builds production-grade Flutter widgets from Figma component designs,
ensuring pixel-perfect match with the design system.

## Prerequisites
- Figma MCP connected
- Theme files already generated (app_colors.dart, app_typography.dart, etc.)
  - If not, run flutter-design-system-extractor first
- ai_docs/DESIGN_SYSTEM.md exists

## Pre-read
Before building any component, ALWAYS read:
1. `ai_docs/DESIGN_SYSTEM.md` — token reference
2. `ai_docs/COMPONENT_CATALOG.md` — check if component already exists
3. The relevant theme files in `lib/core/theme/`

---

## Step 1: Read Component from Figma

Use Figma MCP to read the specific component page.

Extract this data structure for the component:

```
Component: {name}
├── Variants
│   ├── Variant A (e.g., primary, secondary, outline, ghost, destructive)
│   ├── Variant B
│   └── ...
├── Sizes
│   ├── Small
│   ├── Medium
│   └── Large
├── States
│   ├── Default
│   ├── Hover / Pressed
│   ├── Focused
│   ├── Disabled
│   └── Loading (if applicable)
├── Specs (per variant × size × state)
│   ├── Height
│   ├── Padding (horizontal, vertical)
│   ├── Background color
│   ├── Text color
│   ├── Text style (maps to AppTypography.xxx)
│   ├── Border (color, width)
│   ├── Border radius (maps to AppRadius.xxx)
│   ├── Shadow (maps to AppShadows.xxx)
│   ├── Icon size
│   ├── Icon-to-text spacing
│   └── Opacity (for disabled state)
└── Content Slots
    ├── Leading icon (optional)
    ├── Label text
    └── Trailing icon (optional)
```

---

## Step 2: Implement the Widget

### File Location
```
lib/core/widgets/{category}/{component_name}.dart

Categories:
  buttons/     → AppButton, AppIconButton
  inputs/      → AppTextField, AppDropdown, AppSearchBar
  feedback/    → AppSnackbar, AppDialog, AppLoading, AppTooltip
  layout/      → AppCard, AppDivider, AppScaffold
  navigation/  → AppBottomNav
  data_display/ → AppAvatar, AppBadge, AppChip, AppStatusChip
  selection/   → AppCheckbox, AppRadioButton, AppToggle
```

### Implementation Rules

**Rule 1: Token-only styling**
```dart
// ✅ CORRECT
color: AppColors.primary500,
style: AppTypography.labelLarge,
padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
borderRadius: AppRadius.borderMd,

// ❌ WRONG
color: Color(0xFF4CAF50),
style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
padding: EdgeInsets.symmetric(horizontal: 16),
borderRadius: BorderRadius.circular(8),
```

**Rule 2: Enum-driven variants**
```dart
// Variant enum names should match Figma variant names
enum AppButtonVariant { primary, secondary, outline, ghost, destructive }
enum AppButtonSize { sm, md, lg }
```

**Rule 3: Complete state handling**
```dart
// Every component must handle:
// - enabled (default interaction)
// - disabled (onPressed == null || explicit flag)
// - loading (shows indicator, disables interaction)
// - pressed/active (visual feedback)
```

**Rule 4: RTL-safe**
```dart
// ✅ CORRECT
padding: EdgeInsetsDirectional.only(start: AppSpacing.sm)
alignment: AlignmentDirectional.centerStart

// ❌ WRONG
padding: EdgeInsets.only(left: AppSpacing.sm)
alignment: Alignment.centerLeft
```

**Rule 5: ScreenUtil everywhere**
```dart
// ✅ CORRECT
height: 44.h,
width: 24.w,
fontSize: 14.sp,
borderRadius: 8.r,

// ❌ WRONG (raw numbers)
height: 44,
```

**Rule 6: Accessibility**
```dart
// Every interactive component needs:
Semantics(
  button: true,  // or checkbox, etc.
  label: semanticLabel ?? label,
  enabled: onPressed != null && !isLoading,
  child: ...
)
```

### Widget Template

```dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_radius.dart';

enum {Component}Variant { /* from Figma */ }
enum {Component}Size { /* from Figma */ }

class App{Component} extends StatelessWidget {
  // Required props
  // Optional props with defaults matching Figma "default" variant
  
  const App{Component}({
    super.key,
    // ...
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      // accessibility
      child: // implementation
    );
  }

  // Private helpers — one per concern:
  // _buildStyle() → ButtonStyle / decoration
  // _height → per size
  // _padding → per size
  // _backgroundColor → per variant × state
  // _textColor → per variant × state
  // _textStyle → per size
  // _borderRadius → per variant (usually same)
}
```

---

## Step 3: Document the Component

Add entry to `ai_docs/COMPONENT_CATALOG.md`:

```markdown
### App{Component}
- **File:** lib/core/widgets/{category}/{file}.dart
- **Figma:** Rolli Design System > {Component Name}
- **Variants:** {list all}
- **Sizes:** {list all}
- **Props:**
  | Prop | Type | Default | Description |
  |------|------|---------|-------------|
  | label | String | required | Button text |
  | ... | ... | ... | ... |
- **Usage:**
  ```dart
  App{Component}(
    // example with common props
  )
  ```
```

---

## Step 4: Verify

```bash
# 1. Compiles
dart analyze lib/core/widgets/{category}/{file}.dart

# 2. No hardcoded values
grep -n "Color(0x\|fontSize: [0-9]\|BorderRadius.circular([0-9]" lib/core/widgets/{category}/{file}.dart

# 3. No left/right
grep -n "left:\|right:\|\.left\|\.right" lib/core/widgets/{category}/{file}.dart
```

---

## Component-Specific Notes

### Button
- Most complex — has the most variant × size × state combinations
- Must support: label only, icon+label, label+icon, icon only
- Loading state replaces content with CircularProgressIndicator (matching size)
- Disabled state: reduce opacity to ~0.5, remove interaction
- InkWell/GestureDetector for pressed state feedback

### Input / TextField
- States: empty, focused, filled, error, disabled
- Must show: label, hint, helper text, error text, prefix icon, suffix icon
- Error state: border color changes to AppColors.error
- Character counter if maxLength set
- Obscure text toggle for password fields

### Bottom Navigation Bar
- Fixed at bottom, above safe area
- Active/inactive states with color + icon changes
- Badge support on icons (notification count)
- Must handle 3-5 items

### Checkbox & Radio
- Custom painted or wrapped Material with design system colors
- Must support: unchecked, checked, indeterminate (checkbox), disabled
- Label text clickable (toggles the control)

### Toggle / Switch
- Custom thumb + track colors per state
- Animate between on/off

### Avatar
- Sizes: sm, md, lg, xl
- Supports: image, initials, icon fallback
- Online/offline status dot (optional)
- Border support

### Badge
- Dot variant (no text) and count variant
- Position: top-end of parent (use Stack)
- Max count display (e.g., "99+")

### Chip
- Variants: filled, outlined
- Optional: leading icon, trailing X (removable)
- Selected/unselected states
