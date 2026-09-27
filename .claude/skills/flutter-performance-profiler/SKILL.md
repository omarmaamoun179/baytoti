---
name: flutter-performance-profiler
description: >
  Analyze Flutter app performance and identify optimization opportunities. Use when the user
  mentions jank, slow, lag, performance, rebuild, FPS, frame drops, memory leak, expensive build,
  RepaintBoundary, DevTools, timeline, profiling, or pastes DevTools output. Also trigger when
  they say "this screen is slow", "too many rebuilds", "why is this laggy", "optimize this page",
  "profile this widget", or any performance-related concern in a Flutter context.
allowed-tools: Read, Grep, Glob, Bash
---

# Flutter Performance Profiler

Analyze Flutter code for performance issues and provide concrete optimizations.

## Analysis Process

### Step 1: Gather Context

The user may provide:
- A widget file or feature directory to analyze
- DevTools timeline data or screenshot
- A description of the jank ("list scrolling is choppy", "page takes 2s to load")
- Nothing specific — just "check performance"

If no specific target, scan the most likely culprits:
```bash
# Find largest widget files (often the most complex builds)
find lib/ -path '*/presentation/*' -name '*.dart' | xargs wc -l | sort -rn | head -10

# Find files with multiple BlocBuilders
grep -rl 'BlocBuilder\|BlocConsumer' lib/ | xargs grep -c 'BlocBuilder\|BlocConsumer' | sort -t: -k2 -rn | head -10
```

### Step 2: Run Performance Audit

Check each category below. For every finding, provide severity, location, and a concrete fix.

---

## Audit Categories

### A. Unnecessary Rebuilds (Most Common Issue)

| Anti-pattern | Detection | Fix |
|---|---|---|
| Wide BlocBuilder | `BlocBuilder` wrapping widgets that don't use state | Narrow scope or use `BlocSelector` |
| Missing `buildWhen` | `BlocBuilder` without `buildWhen` on chatty state | Add `buildWhen: (prev, curr) => prev.field != curr.field` |
| Missing `const` | Widget without `const` that has only literal args | Add `const` keyword |
| Method instead of widget | `Widget _buildX()` method for large UI sections | Extract to `StatelessWidget` class |
| Whole-context MediaQuery | `MediaQuery.of(context)` | Use `MediaQuery.sizeOf(context)` or specific getters |
| Theme.of over-subscription | `Theme.of(context)` in deep widgets | Cache in local variable, or use `Theme.of(context).textTheme` at top |

```dart
// 🔴 BEFORE: Entire column rebuilds when only name changes
BlocBuilder<ProfileCubit, ProfileState>(
  builder: (context, state) {
    return Column(
      children: [
        Text(state.name),
        const HeavyChart(),    // rebuilds for no reason
        const Footer(),         // rebuilds for no reason
      ],
    );
  },
)

// ✅ AFTER: Only Text rebuilds
Column(
  children: [
    BlocSelector<ProfileCubit, ProfileState, String>(
      selector: (state) => state.name,
      builder: (context, name) => Text(name),
    ),
    const HeavyChart(),
    const Footer(),
  ],
)
```

### B. Expensive Build Methods

| Issue | Detection | Fix |
|---|---|---|
| Computation in build | Sorting, filtering, mapping inside `build()` | Move to cubit or cache with `late final` |
| String formatting in build | `DateFormat`, `NumberFormat` created in `build()` | Create once as static/final |
| build() > 80 lines | Long build method | Decompose into sub-widgets |
| Repeated Theme/MediaQuery | Multiple `Theme.of(context)` calls | Cache at top of build |

```dart
// 🔴 BEFORE: Sorts every rebuild
Widget build(BuildContext context) {
  final sorted = items.toList()..sort((a, b) => a.name.compareTo(b.name));
  // ...
}

// ✅ AFTER: Sorted in cubit, arrives pre-sorted
// In cubit:
void loadItems() {
  final sorted = items.toList()..sort((a, b) => a.name.compareTo(b.name));
  emit(ItemsLoaded(sorted));
}
```

### C. List & Scroll Performance

| Issue | Detection | Fix |
|---|---|---|
| `ListView` without `.builder` | `ListView(children: [...])` with dynamic list | Use `ListView.builder` |
| Missing `itemExtent` | `ListView.builder` with uniform items | Add `itemExtent` or `prototypeItem` |
| No `const` list items | List item widget not `const`-constructable | Add `const` or wrap in `RepaintBoundary` |
| Heavy items without caching | Complex widgets in list items | Use `AutomaticKeepAliveClientMixin` selectively |
| Missing keys | Dynamic list without explicit `Key` | Add `ValueKey(item.id)` |

```dart
// 🔴 BEFORE
ListView(
  children: orders.map((o) => OrderCard(order: o)).toList(),
)

// ✅ AFTER
ListView.builder(
  itemCount: orders.length,
  itemExtent: 72.0,  // if items are uniform height
  itemBuilder: (context, i) => OrderCard(
    key: ValueKey(orders[i].id),
    order: orders[i],
  ),
)
```

### D. Image Performance

| Issue | Detection | Fix |
|---|---|---|
| No cacheWidth/cacheHeight | `Image.network` or `Image.asset` without sizing | Add `cacheWidth`/`cacheHeight` |
| No placeholder/error | `Image.network` without fallback | Use `CachedNetworkImage` with placeholder |
| Large images in list | Full-res images in scrollable list | Resize server-side or use `cacheWidth` |
| SVG in hot path | `SvgPicture` in frequently rebuilt widget | Pre-render to `Picture` or use PNG |

```dart
// 🔴 BEFORE: Decodes full image every time
Image.network(url)

// ✅ AFTER: Decodes at display size
CachedNetworkImage(
  imageUrl: url,
  memCacheWidth: 200,
  placeholder: (_, __) => const Shimmer(),
  errorWidget: (_, __, ___) => const Icon(Icons.error),
)
```

### E. Animation & Paint

| Issue | Detection | Fix |
|---|---|---|
| Missing RepaintBoundary | Animated widget inside large static tree | Wrap animated section in `RepaintBoundary` |
| AnimationController not disposed | Created without `dispose()` | Add `dispose()` in State |
| Opacity widget for fade | `Opacity` widget used for animations | Use `AnimatedOpacity` or `FadeTransition` |
| Color animation with Opacity | `Opacity` to hide/show | Use `Visibility` (skips paint entirely) |

### F. Async & Data Loading

| Issue | Detection | Fix |
|---|---|---|
| No loading skeleton | Loading shows spinner instead of shimmer | Use shimmer/skeleton matching final layout |
| Sequential API calls | Multiple `await` in series that could be parallel | Use `Future.wait([...])` |
| No pagination | Loading full list at once | Add cursor/offset pagination |
| No debounce on search | TextField triggering search on every keystroke | Add debounce (300ms) |
| No caching | Same API call on every screen visit | Cache in repository or use `HydratedBloc` |

### G. Memory Issues

| Issue | Detection | Fix |
|---|---|---|
| Stream not cancelled | `listen()` without `cancel()` in dispose | Cancel in dispose |
| Controller not disposed | TextEditingController, ScrollController | Dispose all controllers |
| Large object retained | Cubit holding large data after screen popped | Clear or use `AutoDispose` pattern |
| Image cache unbounded | CachedNetworkImage without max cache | Configure `maxNrOfCacheObjects` |

---

## Output Format

```
## Performance Report

### Scorecard
| Category          | Issues | Severity |
|-------------------|--------|----------|
| Unnecessary Rebuilds | 4   | 🔴       |
| Expensive Builds     | 2   | 🟡       |
| List Performance     | 1   | 🟡       |
| Image Performance    | 0   | ✅       |
| Memory               | 1   | 🔴       |

### Critical Fixes (do these first)

#### 1. BlocBuilder scope too wide in OrdersPage
**File:** `lib/features/orders/presentation/pages/orders_page.dart:45`
**Impact:** HeavyChart and Footer rebuild on every state change
**Fix:**
[before/after code]

#### 2. Stream subscription leak in TrackingCubit
**File:** `lib/features/tracking/presentation/cubit/tracking_cubit.dart:23`
**Impact:** GPS stream keeps running after screen is popped
**Fix:**
[before/after code]

### Warnings
...

### Quick Wins (const, keys, cacheWidth)
- Line 12: add `const` to SizedBox
- Line 45: add `ValueKey` to list item
- Line 78: add `cacheWidth: 200` to Image

### Estimated Impact
- Reducing BlocBuilder scope: ~30% fewer rebuilds on OrdersPage
- Fixing stream leak: prevents battery drain on tracking screen
```

Always provide the actual refactored code, not just descriptions.
