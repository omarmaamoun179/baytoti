---
name: flutter-screen-implementer
description: >
  Implement Flutter screens matching Figma designs pixel-perfectly via MCP.
  Use this skill whenever the user asks to build a screen, implement a page,
  create a view from Figma, or says "build this screen", "implement this page",
  "make this match the design", "code this Figma frame", "implement the home screen",
  "build the tracking page", or any request to turn a Figma frame into Flutter code.
  Also use when the user pastes a screenshot and says "build this".
---

# Flutter Screen Implementer

Implements complete Flutter screens from Figma designs with Clean Architecture,
BLoC/Cubit state management, and pixel-perfect design system compliance.

## Prerequisites
- Figma MCP connected
- Theme files generated (run flutter-design-system-extractor if missing)
- Atomic components built (run flutter-component-builder if missing)
- `ai_docs/DESIGN_SYSTEM.md` exists
- `ai_docs/COMPONENT_CATALOG.md` exists

## Pre-read (MANDATORY)
Before implementing ANY screen, read these files:
1. `ai_docs/DESIGN_SYSTEM.md`
2. `ai_docs/COMPONENT_CATALOG.md`
3. `ai_docs/ARCHITECTURE.md`

---

## Step 1: Read the Figma Frame

Use Figma MCP to read the target frame/page.

Extract a complete element inventory:

```
Frame: {Screen Name}
├── AppBar / Header
│   ├── Title text → which AppTypography?
│   ├── Back button? Leading action?
│   └── Trailing actions?
├── Body
│   ├── Element 1
│   │   ├── Type: Text / Image / Card / List / Map / etc.
│   │   ├── Design token mapping (color, typography, spacing)
│   │   └── Component mapping (AppButton, AppCard, etc.)
│   ├── Element 2
│   │   └── ...
│   └── ...
├── Bottom element (FAB, bottom bar, CTA button)
├── Spacing between elements (map to AppSpacing.xxx)
└── Screen-level properties
    ├── Background color → AppColors.xxx
    ├── Safe area handling
    └── Scroll behavior (fixed, scrollable, nested scroll)
```

---

## Step 2: Plan the Implementation

Before writing code, create a plan:

```
Screen: {name}
Feature: {feature_name}

Files to create:
  lib/features/{feature}/presentation/
  ├── pages/{screen_name}_page.dart        ← main screen
  ├── widgets/{widget_1}.dart              ← extracted sub-widgets
  ├── widgets/{widget_2}.dart
  └── cubit/
      ├── {screen_name}_cubit.dart         ← state management
      └── {screen_name}_state.dart         ← states (freezed)

Dependencies:
  - Entities: {list from domain/entities/}
  - Use cases: {list from domain/usecases/}
  - Existing components: {AppButton, AppTextField, etc.}

States:
  - Initial / Loading → shimmer matching layout shape
  - Loaded / Success → real data display
  - Empty → empty state with message + illustration
  - Error → error message + retry action
```

---

## Step 3: Implement

### 3.1 Cubit + State

```dart
// {screen_name}_state.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part '{screen_name}_state.freezed.dart';

@freezed
class {ScreenName}State with _${ ScreenName}State {
  const factory {ScreenName}State.initial() = _Initial;
  const factory {ScreenName}State.loading() = _Loading;
  const factory {ScreenName}State.loaded({required DataType data}) = _Loaded;
  const factory {ScreenName}State.empty() = _Empty;
  const factory {ScreenName}State.error({required String message}) = _Error;
}
```

```dart
// {screen_name}_cubit.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

@injectable
class {ScreenName}Cubit extends Cubit<{ScreenName}State> {
  final {UseCaseName} _useCase;
  
  {ScreenName}Cubit(this._useCase) : super(const {ScreenName}State.initial());
  
  Future<void> load() async {
    emit(const {ScreenName}State.loading());
    
    final result = await _useCase();
    result.fold(
      (failure) => emit({ScreenName}State.error(message: failure.message)),
      (data) => data.isEmpty
          ? emit(const {ScreenName}State.empty())
          : emit({ScreenName}State.loaded(data: data)),
    );
  }
}
```

### 3.2 Page

```dart
// {screen_name}_page.dart

class {ScreenName}Page extends StatelessWidget {
  const {ScreenName}Page({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<{ScreenName}Cubit>()..load(),
      child: const _{ ScreenName}View(),
    );
  }
}

class _{ScreenName}View extends StatelessWidget {
  const _{ScreenName}View({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.{from_figma},
      appBar: _buildAppBar(context),
      body: BlocBuilder<{ScreenName}Cubit, {ScreenName}State>(
        builder: (context, state) => state.when(
          initial: () => const SizedBox.shrink(),
          loading: () => const _{ScreenName}Shimmer(),
          loaded: (data) => _{ScreenName}Content(data: data),
          empty: () => const _{ScreenName}Empty(),
          error: (message) => _{ScreenName}Error(
            message: message,
            onRetry: () => context.read<{ScreenName}Cubit>().load(),
          ),
        ),
      ),
    );
  }
}
```

### 3.3 Extract Sub-Widgets

**Rule: If a section of the screen is >40 lines, extract it into its own widget file.**

Each extracted widget goes in:
`lib/features/{feature}/presentation/widgets/{widget_name}.dart`

These are screen-specific widgets, NOT reusable design system components.

### 3.4 Shimmer Loading State

Build a shimmer that matches the screen layout shape:

```dart
class _{ScreenName}Shimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.neutral200,
      highlightColor: AppColors.neutral100,
      child: Column(
        children: [
          // Mirror the layout structure with containers
          // Same heights, widths, spacing as the real content
          Container(
            height: 20.h,
            width: 150.w,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: AppRadius.borderSm,
            ),
          ),
          SizedBox(height: AppSpacing.md),
          // ... match real layout
        ],
      ),
    );
  }
}
```

---

## Step 4: Design Compliance Check

After implementation, verify:

### Visual Check
```
[ ] Screenshot the running screen
[ ] Compare side-by-side with Figma frame
[ ] Check spacing between every element
[ ] Check typography matches (font, size, weight, color)
[ ] Check colors match exactly
[ ] Check border radius matches
[ ] Check shadows match
```

### Code Check
```bash
# Run token compliance
bash scripts/check_design_tokens.sh

# Check this specific file
grep -n "Color(0x" lib/features/{feature}/presentation/**/*.dart
grep -n "fontSize: [0-9]" lib/features/{feature}/presentation/**/*.dart
grep -n "left:\|right:" lib/features/{feature}/presentation/**/*.dart
```

### RTL Check
```
[ ] Switch locale to Arabic
[ ] Verify layout mirrors correctly
[ ] Verify text alignment is correct
[ ] Verify icons/arrows flip where appropriate
[ ] Numbers remain Latin (not Arabic numerals)
```

### Responsive Check
```
[ ] Test on small phone (375×667 — iPhone SE)
[ ] Test on large phone (428×926 — iPhone 14 Pro Max)
[ ] No overflow errors
[ ] Content scales properly with ScreenUtil
```

---

## Common Patterns

### List Screen
```dart
// Pull-to-refresh + infinite scroll
RefreshIndicator(
  onRefresh: () => context.read<XCubit>().refresh(),
  child: ListView.separated(
    padding: EdgeInsets.symmetric(
      horizontal: AppSpacing.lg,
      vertical: AppSpacing.md,
    ),
    itemCount: items.length,
    separatorBuilder: (_, __) => SizedBox(height: AppSpacing.sm),
    itemBuilder: (_, index) => _ItemCard(item: items[index]),
  ),
)
```

### Map Screen
```dart
// Google Map with custom markers
GoogleMap(
  initialCameraPosition: CameraPosition(target: center, zoom: 14),
  markers: markers,
  polylines: routePolylines,
  myLocationEnabled: false,  // custom location indicator
  zoomControlsEnabled: false, // custom zoom buttons
  mapToolbarEnabled: false,
)
```

### Form Screen
```dart
// Wrap in Form, use AppTextField, validate on submit
Form(
  key: _formKey,
  child: Column(
    children: [
      AppTextField(
        label: 'field_label'.tr(),
        controller: _controller,
        validator: Validators.required,
      ),
      SizedBox(height: AppSpacing.lg),
      AppButton(
        label: 'submit'.tr(),
        isExpanded: true,
        isLoading: state is Loading,
        onPressed: _submit,
      ),
    ],
  ),
)
```

---

## Localization

For every screen, add translation keys to both files:

```json
// assets/localization/en.json
{
  "{screen}_{element}": "English text"
}

// assets/localization/ar.json  
{
  "{screen}_{element}": "النص العربي"
}
```

Key naming: `{screen}_{element}_{context}`
Examples:
- `tracking_title` → "Live Tracking"
- `tracking_eta_label` → "Arriving in"
- `tracking_bus_approaching` → "Bus is approaching your stop"

**Every user-visible string MUST use `.tr()` — no exceptions.**
