# Transliteration Detection

## Overview

The app now automatically detects when users type Russian words using English letters (transliteration) and converts them to search the Russian dictionary.

## How It Works

### 1. Pattern Detection
The system first checks if the input contains Russian-specific letter combinations:
- Digraphs: `zh`, `kh`, `sh`, `ch`, `ts`, `shch`, etc.
- Common endings: `ov`, `ova`, `ovich`, `sky`, `aya`, etc.

### 2. Transliteration Conversion
If patterns are detected, the text is converted to Cyrillic using standard mappings:
- `zh` → `ж`
- `kh` → `х`
- `ch` → `ч`
- `sh` → `ш`
- `yu` → `ю`
- `ya` → `я`
- And more...

### 3. Database Verification
Multiple Cyrillic variants are generated to handle ambiguous cases (e.g., `e` → `е` or `э`), then each variant is checked against the Russian dictionary.

### 4. Result Display
If a match is found in the Russian dictionary, those results are displayed. Otherwise, the app falls back to searching the English dictionary.

## Examples

### Basic Transliteration
| User Types | Detects As | Finds |
|------------|-----------|-------|
| `privet` | `привет` | Russian word for "hello" |
| `spasibo` | `спасибо` | Russian word for "thank you" |
| `khorosho` | `хорошо` | Russian word for "good" |
| `zhizn` | `жизнь` | Russian word for "life" |

### Common Patterns
- `kh` → `х`: `khleb` → `хлеб` (bread)
- `zh` → `ж`: `zhena` → `жена` (wife)
- `sh` → `ш`: `shkola` → `школа` (school)
- `ch` → `ч`: `chay` → `чай` (tea)
- `shch` → `щ`: `shchi` → `щи` (cabbage soup)
- `yu` → `ю`: `lyubov` → `любовь` (love)
- `ya` → `я`: `yabloko` → `яблоко` (apple)

### Endings Detection
Words ending in typical Russian patterns are flagged:
- `-ov`: `ivanov` → `иванов`
- `-sky`: `dostoevsky` → `достоевский`
- `-ovich`: `petrovich` → `петрович`

## Implementation

### Files
- `Dictionary/Helpers/TransliterationDetector.swift` - Core transliteration logic
- `Dictionary/ViewModels/MainModelView.swift` - Search integration

### Key Methods
```swift
// Check if text looks like transliteration
TransliterationDetector.looksLikeTransliteration("privet") // true

// Convert to Cyrillic variants
TransliterationDetector.transliterateToCyrillic("privet") // ["привет", "привэт"]
```

## Limitations

1. **Ambiguous mappings**: Some letters have multiple possible conversions
   - `e` → `е` or `э`
   - `y` → `и`, `й`, or `ы`
   - `c` → `к` or `ц`

2. **Informal variations**: Users may type differently than standard transliteration
   - `schast'ye` vs `schastie` vs `shastye` (счастье - happiness)

3. **English word false positives**: Some English words may trigger detection
   - Words containing `zh`, `kh` might be checked unnecessarily
   - Fallback to English search prevents issues

## Future Enhancements

- [ ] Learn from user corrections
- [ ] Support mixed language input
- [ ] Add transliteration suggestions in UI
- [ ] Handle more phonetic variations
- [ ] Add quick toggle between dictionaries

