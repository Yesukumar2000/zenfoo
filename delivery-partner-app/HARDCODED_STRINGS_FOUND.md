# Hardcoded Strings Found in Top 5 Files

## Summary
Found **2 actual hardcoded strings** that need to be converted:

### 1. Permission Denied Message
**String:** `'Permission denied. Please enable camera or gallery access.'`

**Files Found:**
- `/lib/view/screens/help_center/change_bank_details_screen.dart` (line 61)
- `/lib/view/screens/help_center/change_pan_details_screen.dart` (line 51)

**Recommended Key:** `permission_denied_camera_gallery`

**Current Code:**
```dart
content: Text('Permission denied. Please enable camera or gallery access.'),
```

**Replacement Code:**
```dart
content: Text(languageProvider.getTranslatedText('permission_denied_camera_gallery')),
```

---

### 2. Feature Coming Soon
**String:** `'$title feature coming soon'`

**Files Found:**
- `/lib/view/screens/help_center/help_center_screen.dart` (line 1115)

**Recommended Key:** `feature_coming_soon`

**Current Code:**
```dart
content: Text('$title feature coming soon'),
```

**Replacement Code - Option A (Simple):**
```dart
content: Text(languageProvider.getTranslatedText('feature_coming_soon')),
```

**Replacement Code - Option B (With dynamic title):**
```dart
content: Text(
  languageProvider.getTranslatedText('feature_coming_soon')
    .replaceAll('{title}', title)
),
```

---

## Analysis Summary

**Good News:** The top 5 files are 99%+ localized already!
- Most Text widgets use `languageProvider.getTranslatedText('key_name')`
- Only 2 hardcoded strings found across 5 files totaling 190 Text widgets
- The remaining 46 files likely have similar low hardcoded string rates

## Conversion Strategy

### For the 2 Hardcoded Strings:

1. Add to localization files (if not already present):
   - Key: `permission_denied_camera_gallery`
   - Key: `feature_coming_soon`

2. Find and replace in the identified files:
   ```bash
   # For Permission Denied
   sed -i "" "s/Text('Permission denied\. Please enable camera or gallery access\.')/Text(languageProvider.getTranslatedText('permission_denied_camera_gallery'))/g" \
     /lib/view/screens/help_center/change_bank_details_screen.dart \
     /lib/view/screens/help_center/change_pan_details_screen.dart
   
   # For Feature Coming Soon
   sed -i "" "s/Text('\$title feature coming soon')/Text(languageProvider.getTranslatedText('feature_coming_soon'))/g" \
     /lib/view/screens/help_center/help_center_screen.dart
   ```

## Next Steps

1. Verify localization files contain these keys
2. Apply replacements to the identified files
3. Audit remaining 46 files using similar pattern
4. Check for dynamic strings (concatenation, interpolation)

