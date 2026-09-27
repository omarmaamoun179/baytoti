---
name: flutter-code-reviewer
description: >
  Perform an architecture-aware code review of Flutter/Dart code following Clean Architecture,
  BLoC/Cubit, and performance best practices. Use this skill whenever the user asks to review,
  audit, check, critique, improve, or refactor Flutter or Dart code. Also trigger when the user
  says "review this", "what's wrong with this code", "how can I improve this", "check my widget",
  "is this clean", "any issues here", "PR review", "code quality check", or pastes/uploads Dart
  code and asks for feedback. Trigger even for casual phrasing like "take a look at this" or
  "anything off here?" when Flutter/Dart code is involved. This skill catches architecture violations,
  performance anti-patterns, state management misuse, memory leaks, and maintainability issues
  that generic code review would miss.
---

# Flutter Code Reviewer

Perform a structured, senior-level code review of Flutter/Dart code with focus on architecture compliance, performance, and maintainability.

## Review Process

### 1. Determine Scope

- **Single file**: Review the file in isolation, but flag cross-cutting concerns.
- **Feature/module**: Review all files in the feature directory holistically.
- **Diff/PR**: Focus only on changed lines but consider surrounding context.

If the user just pastes code without specifying, treat it as a single-file review.

### 2. Run the Review Checklist

Go through each category below. For each finding, report:
- **Severity**: 🔴 Critical | 🟡 Warning | 🔵 Suggestion
- **Location**: File + line (or code snippet)
- **Issue**: What's wrong
- **Fix**: Concrete code fix or refactor

---

## Review Categories

### A. Architecture & Layer Violations

Check for Clean Architecture compliance:

| Violation | What to look for |
|-----------|-----------------|
| Layer breach | Presentation importing from `data/` directly (bypassing domain) |
| Fat widget | Business logic inside `build()` or widget class |
| God class | A single BLoC/Cubit handling more than one feature's concerns |
| Missing abstraction | Repository impl used directly without abstract contract |
| Use case bypass | Cubit calling repository directly instead of through use case |
| Model leak | Data model (`fromJson`/`toJson`) exposed to presentation layer |

**Judgment call**: For small apps or prototypes, some of these are acceptable. Calibrate severity based on project context. If the project clearly uses Clean Architecture, enforce strictly.

### B. State Management

#### BLoC/Cubit Issues
| Issue | Detection |
|-------|-----------|
| Missing state handling | `BlocBuilder` that doesn't handle all state variants |
| Emit after close | Async operation that emits without checking `isClosed` |
| Unnecessary BlocBuilder scope | `BlocBuilder` wrapping an entire page when only one widget needs it |
| State not equatable | State class missing `Equatable` or `props` override → unnecessary rebuilds |
| Event not sealed | BLoC events that aren't sealed classes (Dart 3+) |
| Nested BlocBuilders | Multiple nested `BlocBuilder`s that could be a `BlocSelector` or `MultiBlocListener` |

#### Common Patterns to Flag
```dart
// 🔴 Emit after close — can crash
Future<void> fetchData() async {
  final result = await _useCase();
  emit(Loaded(result)); // No isClosed check
}

// ✅ Safe version
Future<void> fetchData() async {
  final result = await _useCase();
  if (!isClosed) emit(Loaded(result));
}
```

### C. Performance

| Anti-pattern | Detection | Fix |
|-------------|-----------|-----|
| Missing `const` constructor | Widget class without `const` that has no mutable fields | Add `const` |
| Rebuild-heavy `BlocBuilder` | `BlocBuilder` with no `buildWhen` on chatty state | Add `buildWhen` or use `BlocSelector` |
| Heavy `build()` | Computation, list processing, or formatting inside `build()` | Move to cubit/bloc or cache |
| Unbounded list | `ListView` without `.builder` for dynamic/large lists | Use `ListView.builder` |
| Image without cache | `Image.network` without `cacheWidth`/`cacheHeight` or package like `cached_network_image` | Add caching |
| Excessive `setState` | Multiple `setState` calls in sequence | Batch into one |
| Deep widget tree | Single widget file with 5+ levels of nesting | Extract sub-widgets |

### D. Memory & Resource Leaks

| Leak | Detection |
|------|-----------|
| Stream not cancelled | `StreamSubscription` created but never cancelled in `dispose()` / `close()` |
| Controller not disposed | `TextEditingController`, `ScrollController`, `AnimationController` without `dispose()` |
| Timer not cancelled | `Timer` or `Timer.periodic` without cancel |
| Listener not removed | `addListener` without corresponding `removeListener` |
| Context used after async gap | `context` used after `await` without `mounted` check |

```dart
// 🔴 Context after async gap
onPressed: () async {
  await someOperation();
  Navigator.of(context).pop(); // Widget might be unmounted
}

// ✅ Safe
onPressed: () async {
  await someOperation();
  if (!context.mounted) return;
  Navigator.of(context).pop();
}
```

### E. Dart Best Practices

| Issue | Rule |
|-------|------|
| Dynamic typing | Avoid `dynamic` — use proper types or generics |
| Implicit nulls | Prefer explicit null handling (`??`, `?.`, `required`) over silent `null` |
| String interpolation | Use `$var` / `${expr}` instead of concatenation |
| Collection literals | Use `[]`, `{}`, `<Type>[]` instead of `List()`, `Map()` |
| Cascade notation | Use `..` for chained calls on same object |
| Pattern matching | Use Dart 3 `switch` expressions and patterns for state handling |
| Late without need | `late` used where nullable + null check would be safer |

### F. Error Handling

| Issue | Detection |
|-------|-----------|
| Empty catch | `catch (e) {}` swallowing errors silently |
| Generic catch | `catch (e)` without specific exception types |
| No error state | Feature that calls API but cubit has no error state variant |
| No retry/recovery | Network call fails with no retry mechanism or user-facing recovery action |
| Unhandled Either | `Either` result from use case with only `fold` on success path |

### G. Testing Readiness

Flag code that is hard to test:
- Static method calls that can't be mocked
- Direct instantiation of dependencies (no DI)
- Private methods containing business logic that should be in a use case
- Tight coupling to `BuildContext` in logic classes

---

## Output Format

Structure the review as:

```
## Review Summary
- Files reviewed: N
- 🔴 Critical: N  |  🟡 Warnings: N  |  🔵 Suggestions: N

## Critical Issues
### 1. [Issue title]
**File**: `path/to/file.dart` line N
**Issue**: Description
**Fix**:
\`\`\`dart
// corrected code
\`\`\`

## Warnings
...

## Suggestions
...

## What's Good
- Highlight 2-3 things done well (positive reinforcement matters)
```

Keep it actionable — every finding must have a concrete fix, not just "consider improving this".
