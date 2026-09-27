---
name: flutter-l10n-auditor
description: >
  Audit Flutter localization for missing translations, hardcoded strings, unused keys, and
  inconsistencies between language files. Use when the user mentions translations, localization,
  l10n, i18n, missing translations, hardcoded strings, .tr(), easy_localization, intl, ar.json,
  en.json, language files, or RTL issues. Also trigger on "check translations", "find hardcoded
  strings", "sync language files", "translation audit", "missing keys", "localization check",
  or any request involving multi-language support in Flutter. Especially useful before releases
  to ensure no untranslated strings ship to production.
allowed-tools: Read, Grep, Glob, Bash, Write
---

# Flutter Localization Auditor

Comprehensive audit of Flutter app localization: missing translations, hardcoded strings, unused keys, and language file consistency.

## Audit Process

### Step 1: Detect Localization Setup

```bash
# Detect localization package
grep -E 'easy_localization|flutter_localizations|intl|slang' pubspec.yaml

# Find translation files
find . -name '*.json' -path '*/translations/*' -o -name '*.arb' -path '*/l10n/*' 2>/dev/null

# Find supported locales
grep -r 'supportedLocales\|supportedLanguages' lib/ --include='*.dart' | head -5
```

Determine:
- Package: `easy_localization`, `flutter_localizations` + `intl`, `slang`, or custom
- File format: JSON (`.json`) or ARB (`.arb`)
- Languages: which locales exist (en, ar, etc.)
- Translation access pattern: `.tr()`, `AppLocalizations.of(context).key`, `context.tr('key')`

### Step 2: Run All Audits

---

### A. Missing Translation Keys (Cross-Language Sync)

Compare all language files to find keys missing from any language.

```bash
# For JSON-based translations (easy_localization)
python3 -c "
import json, sys

en = json.load(open('assets/translations/en.json'))
ar = json.load(open('assets/translations/ar.json'))

def flatten(d, prefix=''):
    items = {}
    for k, v in d.items():
        key = f'{prefix}.{k}' if prefix else k
        if isinstance(v, dict):
            items.update(flatten(v, key))
        else:
            items[key] = v
    return items

en_keys = set(flatten(en).keys())
ar_keys = set(flatten(ar).keys())

missing_in_ar = sorted(en_keys - ar_keys)
missing_in_en = sorted(ar_keys - en_keys)

if missing_in_ar:
    print(f'🔴 Missing in ar.json ({len(missing_in_ar)}):')
    for k in missing_in_ar:
        print(f'  - {k}')

if missing_in_en:
    print(f'🔴 Missing in en.json ({len(missing_in_en)}):')
    for k in missing_in_en:
        print(f'  - {k}')

if not missing_in_ar and not missing_in_en:
    print('✅ All keys in sync')
    
print(f'\nTotal keys: en={len(en_keys)}, ar={len(ar_keys)}')
"
```

---

### B. Hardcoded Strings in Dart Files

Scan presentation layer for strings that should be translated.

```bash
# Find hardcoded strings in presentation layer (Text widgets, titles, labels)
grep -rn "Text(['\"][A-Z]" lib/features/*/presentation/ --include='*.dart' | grep -v '.tr()' | grep -v '// no-l10n' | head -30

# Find hardcoded strings in AppBar titles
grep -rn "title: Text(['\"]" lib/ --include='*.dart' | grep -v '.tr()' | head -20

# Find hardcoded hint texts
grep -rn "hintText: ['\"]" lib/ --include='*.dart' | grep -v '.tr()' | head -20

# Find hardcoded label texts
grep -rn "labelText: ['\"]" lib/ --include='*.dart' | grep -v '.tr()' | head -20

# Find hardcoded button texts
grep -rn "child: Text(['\"][A-Z]" lib/ --include='*.dart' | grep -v '.tr()' | head -20

# Find hardcoded error messages
grep -rn "SnackBar\|showDialog\|AlertDialog" lib/ --include='*.dart' -A2 | grep "['\"][A-Z]" | grep -v '.tr()' | head -20

# Find hardcoded tooltip texts
grep -rn "tooltip: ['\"]" lib/ --include='*.dart' | grep -v '.tr()' | head -10
```

**Exclude from flagging:**
- Technical strings: URLs, asset paths, route names, keys, regex
- Debug strings: `print()`, `debugPrint()`, `log()`
- Const identifiers: enum values, map keys
- Strings marked with `// no-l10n` comment

**Flag these as hardcoded:**
- User-visible text in `Text()`, `AppBar(title:)`, `hintText`, `labelText`
- Error messages shown to users
- Button labels
- Dialog titles and content
- Tooltip text
- Placeholder text

---

### C. Unused Translation Keys

Find keys that exist in translation files but aren't referenced anywhere in Dart code.

```bash
python3 -c "
import json, os, re

# Load keys
en = json.load(open('assets/translations/en.json'))

def flatten(d, prefix=''):
    items = {}
    for k, v in d.items():
        key = f'{prefix}.{k}' if prefix else k
        if isinstance(v, dict):
            items.update(flatten(v, key))
        else:
            items[key] = v
    return items

all_keys = set(flatten(en).keys())

# Read all Dart files
dart_content = ''
for root, dirs, files in os.walk('lib/'):
    for f in files:
        if f.endswith('.dart'):
            with open(os.path.join(root, f)) as fh:
                dart_content += fh.read()

# Check each key
unused = []
for key in sorted(all_keys):
    # Check both formats: 'key'.tr() and tr('key')
    if key not in dart_content:
        unused.append(key)

if unused:
    print(f'🟡 Potentially unused keys ({len(unused)}):')
    for k in unused[:30]:
        print(f'  - {k}')
    if len(unused) > 30:
        print(f'  ... and {len(unused) - 30} more')
else:
    print('✅ All keys are referenced in code')
"
```

---

### D. Placeholder/Parameter Consistency

Check that parameterized strings have matching parameters across languages.

```bash
python3 -c "
import json, re

en = json.load(open('assets/translations/en.json'))
ar = json.load(open('assets/translations/ar.json'))

def flatten(d, prefix=''):
    items = {}
    for k, v in d.items():
        key = f'{prefix}.{k}' if prefix else k
        if isinstance(v, dict):
            items.update(flatten(v, key))
        else:
            items[key] = str(v)
    return items

en_flat = flatten(en)
ar_flat = flatten(ar)

param_pattern = re.compile(r'\{(\w+)\}')

issues = []
for key in en_flat:
    if key in ar_flat:
        en_params = set(param_pattern.findall(en_flat[key]))
        ar_params = set(param_pattern.findall(ar_flat[key]))
        if en_params != ar_params:
            issues.append((key, en_params, ar_params))

if issues:
    print(f'🔴 Parameter mismatches ({len(issues)}):')
    for key, en_p, ar_p in issues:
        print(f'  {key}:')
        print(f'    en: {en_p}')
        print(f'    ar: {ar_p}')
else:
    print('✅ All parameters consistent')
"
```

---

### E. RTL Readiness (Arabic-Specific)

```bash
# Find hardcoded text direction
grep -rn 'TextDirection.ltr\|textDirection: TextDirection' lib/ --include='*.dart' | grep -v 'Directionality' | head -10

# Find hardcoded padding/margin that should be directional
grep -rn 'EdgeInsets.only(left:\|EdgeInsets.only(right:' lib/ --include='*.dart' | head -10

# Find non-directional alignment
grep -rn 'Alignment.centerLeft\|Alignment.centerRight\|Alignment.topLeft\|Alignment.topRight' lib/ --include='*.dart' | head -10

# Find hardcoded icons that should flip
grep -rn 'Icons.arrow_back\b\|Icons.arrow_forward\b' lib/ --include='*.dart' | grep -v 'adaptive' | head -10
```

**RTL fixes to suggest:**
| Hardcoded | Directional Alternative |
|---|---|
| `EdgeInsets.only(left: 16)` | `EdgeInsetsDirectional.only(start: 16)` |
| `Alignment.centerLeft` | `AlignmentDirectional.centerStart` |
| `Icons.arrow_back` | `Icons.adaptive.arrow_back` |
| `TextAlign.left` | `TextAlign.start` |
| `Positioned(left: 0)` | `PositionedDirectional(start: 0)` |
| `Row` with hardcoded order | Verify order makes sense in RTL |

---

### F. Empty/Placeholder Translations

```bash
python3 -c "
import json

ar = json.load(open('assets/translations/ar.json'))

def find_empty(d, prefix=''):
    issues = []
    for k, v in d.items():
        key = f'{prefix}.{k}' if prefix else k
        if isinstance(v, dict):
            issues.extend(find_empty(v, key))
        elif isinstance(v, str):
            if not v.strip():
                issues.append((key, 'empty'))
            elif v.startswith('TODO') or v.startswith('XXX'):
                issues.append((key, 'placeholder'))
            elif all(c.isascii() for c in v) and len(v) > 3:
                issues.append((key, 'possibly untranslated (still English?)'))
    return issues

issues = find_empty(ar)
if issues:
    print(f'🟡 Suspicious entries in ar.json ({len(issues)}):')
    for key, reason in issues[:20]:
        print(f'  - {key}: {reason}')
else:
    print('✅ No empty or placeholder translations found')
"
```

---

## Output Format

```
## Localization Audit Report

### Summary
| Check                    | Status | Count |
|--------------------------|--------|-------|
| Cross-language sync      | 🔴     | 12 missing keys |
| Hardcoded strings        | 🟡     | 8 found |
| Unused keys              | 🟡     | 5 found |
| Parameter consistency    | ✅     | 0 issues |
| RTL readiness            | 🟡     | 3 issues |
| Empty translations       | ✅     | 0 issues |

### 🔴 Missing Keys
[list with which file they're missing from]

### 🟡 Hardcoded Strings
[file:line — the hardcoded string — suggested key name]

### 🟡 Unused Keys (safe to remove)
[list of keys]

### 🟡 RTL Issues
[file:line — issue — fix]

### Auto-Fix Available
I can automatically:
1. Add missing keys to ar.json/en.json with placeholder values
2. Replace hardcoded strings with .tr() calls
3. Remove unused keys from translation files
4. Replace EdgeInsets with EdgeInsetsDirectional

Want me to apply any of these fixes?
```

Generate a fix script or apply changes directly when the user approves.
