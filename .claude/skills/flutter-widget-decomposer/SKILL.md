---
name: flutter-widget-decomposer
description: >
  Analyze Flutter widget trees and advise on decomposition, extraction, and rebuild optimization.
  Use this skill whenever the user asks to break down a widget, reduce nesting, extract widgets,
  optimize rebuilds, simplify a large widget, refactor a build method, or improve widget structure.
  Also trigger when the user says "this widget is too big", "too much nesting", "split this widget",
  "extract sub-widgets", "reduce rebuilds", "optimize my widget tree", "my build method is huge",
  "decompose this", or pastes a Flutter widget and asks how to clean it up. Trigger even for casual
  phrasing like "this file is a mess" or "how do I break this down" when Flutter widget code is
  involved. This skill catches deep nesting, unnecessary rebuilds, missed const opportunities,
  fat build methods, and gives concrete extraction points with ready-to-use refactored code.
---

# Flutter Widget Decomposition Advisor

Analyze a Flutter widget tree and provide actionable decomposition recommendations to improve readability, reusability, and render performance.

## Analysis Process

### 1. Receive the Widget

The user will provide code in one of these forms:
- A single widget file (most common)
- Multiple related widget files
- A screenshot of a UI with the backing code
- A description like "I have a 300-line widget that does X"

If the user describes but doesn't share code, ask for the file. You can't decompose what you can't see.

### 2. Measure Complexity

Run these heuristics on the widget:

| Metric | Threshold | Severity |
|--------|-----------|----------|
| `build()` method line count | > 80 lines | 🔴 Needs splitting |
| `build()` method line count | 40–80 lines | 🟡 Consider splitting |
| Widget nesting depth | > 5 levels deep | 🔴 Extract inner widgets |
| Widget nesting depth | 4 levels deep | 🟡 Worth extracting |
| Number of `BlocBuilder`/`BlocSelector` | > 2 in same `build()` | 🟡 Extract per-bloc widgets |
| Conditional branches in `build()` | > 3 if/switch branches | 🟡 Extract branch widgets |
| Inline callbacks (onPressed, etc.) | > 10 lines | 🟡 Extract to method or widget |
| Local variables computed in `build()` | > 5 | 🟡 Move to cubit or cache |
| File total line count | > 250 lines | 🔴 Decompose feature |
| Parameters passed > 3 levels deep | Any occurrence | 🟡 Prop drilling — use DI or InheritedWidget |

Report these metrics as a quick scorecard before diving into recommendations.

### 3. Identify Extraction Points

For each extraction candidate, classify it:

#### A. Extract as Separate StatelessWidget (most common)

**When to use:**
- A visually distinct section of the UI (header, card, list item, form section)
- A subtree that has its own logical boundary
- A chunk that could be reused elsewhere
- A subtree wrapped in `BlocBuilder`/`BlocSelector` that only needs specific state

**Benefits:** Gets its own `build()` lifecycle, can be `const`, independently testable.

```dart
// BEFORE — nested inside parent build()
Padding(
  padding: const EdgeInsets.all(16),
  child: Column(
    children: [
      CircleAvatar(radius: 40, backgroundImage: NetworkImage(user.avatar)),
      const SizedBox(height: 8),
      Text(user.name, style: Theme.of(context).textTheme.titleLarge),
      Text(user.email, style: Theme.of(context).textTheme.bodyMedium),
    ],
  ),
)

// AFTER — extracted
class UserProfileHeader extends StatelessWidget {
  final UserEntity user;
  const UserProfileHeader({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          CircleAvatar(radius: 40, backgroundImage: NetworkImage(user.avatar)),
          const SizedBox(height: 8),
          Text(user.name, style: theme.titleLarge),
          Text(user.email, style: theme.bodyMedium),
        ],
      ),
    );
  }
}
```

#### B. Extract as Private Widget in Same File

**When to use:**
- The section is specific to this page (not reusable)
- It reduces nesting but doesn't justify its own file
- Intermediate step before full extraction

```dart
class _OrderSummaryCard extends StatelessWidget {
  final Order order;
  const _OrderSummaryCard({required this.order});
  // ...
}
```

**Note:** Private widgets (`_WidgetName`) can't be `const`-constructed from outside the file, but that's fine since they're only used internally.

#### C. Extract as Method (Use Sparingly)

**When to use:**
- Very small builder logic (< 10 lines)
- A `builder` callback parameter (e.g., `itemBuilder` in `ListView.builder`)
- NOT for general UI sections — methods don't get their own Element, so they rebuild with the parent

```dart
// OK — small builder for list items
Widget _buildOrderItem(Order order) {
  return ListTile(
    title: Text(order.title),
    subtitle: Text(order.date.toString()),
  );
}
```

**Avoid this anti-pattern:**
```dart
// 🔴 BAD — large UI section as method. Rebuilds with parent every time.
Widget _buildHeader() {
  return Container(/* 50 lines of UI */);
}
```

The method approach doesn't create a separate Element in the widget tree, meaning Flutter can't skip rebuilding it independently. Always prefer a separate Widget class for anything substantial.

#### D. Extract with BlocSelector/BlocBuilder Scoping

**When to use:**
- A `BlocBuilder` wraps more widgets than it needs to
- Only one small part of the tree depends on the bloc state

```dart
// BEFORE — entire Column rebuilds when name changes
BlocBuilder<ProfileCubit, ProfileState>(
  builder: (context, state) {
    return Column(
      children: [
        Text(state.name),          // depends on state
        const HeavyChartWidget(),  // does NOT depend on state — unnecessary rebuild
        const FooterWidget(),
      ],
    );
  },
)

// AFTER — only the Text rebuilds
Column(
  children: [
    BlocSelector<ProfileCubit, ProfileState, String>(
      selector: (state) => state.name,
      builder: (context, name) => Text(name),
    ),
    const HeavyChartWidget(),
    const FooterWidget(),
  ],
)
```

### 4. Const Optimization Pass

After decomposition, scan for `const` opportunities:

| Pattern | Action |
|---------|--------|
| Widget with only literal/const fields | Add `const` constructor + `const` at call site |
| `SizedBox(height: 16)` | → `const SizedBox(height: 16)` |
| `EdgeInsets.all(8)` | → `const EdgeInsets.all(8)` |
| `Text('Hello')` | → `const Text('Hello')` |
| Extracted widget with no dynamic params | Make it a `const` singleton call |
| `Icon(Icons.check)` | → `const Icon(Icons.check)` |

**Rule of thumb:** If the Dart analyzer can prove all constructor arguments are compile-time constants, add `const`. The analyzer will tell you — but it's good to be proactive.

### 5. Check for Prop Drilling

If data flows through 3+ widget constructors just to reach a deeply nested widget:

**Solutions (pick the lightest-weight one that works):**
1. **`context.read<Cubit>()`** — if using BLoC, the cubit is already provided above
2. **`BlocSelector`** — select just the field you need at the point of use
3. **`InheritedWidget` / `InheritedModel`** — for non-BLoC data that multiple descendants need
4. **Provider** — if already in the dependency tree

### 6. File Organization After Decomposition

Recommend one of these structures based on complexity:

**Small feature (1–3 extracted widgets):**
```
presentation/
├── pages/
│   └── order_page.dart
└── widgets/
    ├── order_header.dart
    ├── order_item_card.dart
    └── order_summary.dart
```

**Large feature (4+ extracted widgets):**
```
presentation/
├── pages/
│   └── order_page.dart
└── widgets/
    ├── header/
    │   └── order_header.dart
    ├── items/
    │   ├── order_item_card.dart
    │   └── order_item_list.dart
    └── summary/
        └── order_summary.dart
```

---

## Output Format

```
## Widget Decomposition Report

### Complexity Scorecard
| Metric              | Value | Status |
|---------------------|-------|--------|
| build() lines       | 142   | 🔴     |
| Max nesting depth   | 7     | 🔴     |
| BlocBuilders        | 3     | 🟡     |
| Inline callbacks    | 2     | ✅     |
| File total lines    | 310   | 🔴     |

### Recommended Extractions

#### 1. `UserProfileHeader` → New StatelessWidget
**Lines 24–58** | Reduces parent build() by 34 lines
**Why:** Self-contained visual section, no state dependency, reusable.
**Rebuild impact:** Can be const-constructed — zero unnecessary rebuilds.
[Show before/after code]

#### 2. Scope `BlocBuilder` to `UserNameText` only
**Lines 60–85** | Prevents rebuild of HeavyChartWidget
**Why:** Only line 62 (Text) depends on ProfileState.name.
[Show before/after code]

#### 3. `OrderItemCard` → New StatelessWidget in separate file
**Lines 90–140** | Used in ListView.builder — clear component boundary
[Show before/after code]

### Const Opportunities
- Line 15: `SizedBox(height: 16)` → add `const`
- Line 72: `EdgeInsets.symmetric(...)` → add `const`
- `FooterWidget()` → add `const` constructor + `const` call

### Suggested File Structure
[Show recommended folder layout]
```

Always provide the actual refactored code, not just descriptions. The user should be able to copy-paste the result.
