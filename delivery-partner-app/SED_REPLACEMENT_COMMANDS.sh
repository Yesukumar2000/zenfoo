#!/bin/bash

# ============================================================================
# SED REPLACEMENT COMMANDS FOR HARDCODED STRINGS
# Generated: 2026-02-02
# ============================================================================

# IMPORTANT NOTES:
# - Test each sed command on a backup copy first
# - Use -i "" (empty string) for macOS, -i for Linux
# - Escape special characters properly in sed patterns
# - Use / as delimiter (or | if working with paths)

echo "=== HARDCODED STRING REPLACEMENTS ==="
echo ""

# ============================================================================
# REPLACEMENT 1: Permission Denied - Camera/Gallery Access
# ============================================================================
echo "1. Fixing: 'Permission denied. Please enable camera or gallery access.'"
echo "   Files: 2 (change_bank_details_screen.dart, change_pan_details_screen.dart)"
echo ""
echo "Command for macOS:"
echo 'sed -i "" "s/Text('"'"'Permission denied\. Please enable camera or gallery access\.\'"'"')/Text(languageProvider.getTranslatedText('"'"'permission_denied_camera_gallery'"'"'))/g" \\'
echo '  "/Users/ramprasadsreerama/Development/zenfoo/lib/view/screens/help_center/change_bank_details_screen.dart" \\'
echo '  "/Users/ramprasadsreerama/Development/zenfoo/lib/view/screens/help_center/change_pan_details_screen.dart"'
echo ""
echo "Command for Linux:"
echo 'sed -i "s/Text('"'"'Permission denied\. Please enable camera or gallery access\.\'"'"')/Text(languageProvider.getTranslatedText('"'"'permission_denied_camera_gallery'"'"'))/g" \\'
echo '  "/Users/ramprasadsreerama/Development/zenfoo/lib/view/screens/help_center/change_bank_details_screen.dart" \\'
echo '  "/Users/ramprasadsreerama/Development/zenfoo/lib/view/screens/help_center/change_pan_details_screen.dart"'
echo ""
echo "Verification after replacement:"
echo 'grep -n "permission_denied_camera_gallery" /Users/ramprasadsreerama/Development/zenfoo/lib/view/screens/help_center/change_bank_details_screen.dart'
echo 'grep -n "permission_denied_camera_gallery" /Users/ramprasadsreerama/Development/zenfoo/lib/view/screens/help_center/change_pan_details_screen.dart'
echo ""
echo "---"
echo ""

# ============================================================================
# REPLACEMENT 2: Feature Coming Soon
# ============================================================================
echo "2. Fixing: '\$title feature coming soon'"
echo "   Files: 1 (help_center_screen.dart)"
echo ""
echo "Command for macOS:"
echo 'sed -i "" "s/Text('"'"'\$title feature coming soon'"'"')/Text(languageProvider.getTranslatedText('"'"'feature_coming_soon'"'"'))/g" \\'
echo '  "/Users/ramprasadsreerama/Development/zenfoo/lib/view/screens/help_center/help_center_screen.dart"'
echo ""
echo "Command for Linux:"
echo 'sed -i "s/Text('"'"'\$title feature coming soon'"'"')/Text(languageProvider.getTranslatedText('"'"'feature_coming_soon'"'"'))/g" \\'
echo '  "/Users/ramprasadsreerama/Development/zenfoo/lib/view/screens/help_center/help_center_screen.dart"'
echo ""
echo "Verification after replacement:"
echo 'grep -n "feature_coming_soon" /Users/ramprasadsreerama/Development/zenfoo/lib/view/screens/help_center/help_center_screen.dart'
echo ""
echo "---"
echo ""

# ============================================================================
# VERIFICATION SCRIPT
# ============================================================================
echo "3. Complete verification commands:"
echo ""
echo "# Check if replacements were successful"
echo 'echo "=== Checking change_bank_details_screen.dart ===" '
echo 'grep -n "permission_denied_camera_gallery" /Users/ramprasadsreerama/Development/zenfoo/lib/view/screens/help_center/change_bank_details_screen.dart'
echo ''
echo 'echo "=== Checking change_pan_details_screen.dart ===" '
echo 'grep -n "permission_denied_camera_gallery" /Users/ramprasadsreerama/Development/zenfoo/lib/view/screens/help_center/change_pan_details_screen.dart'
echo ''
echo 'echo "=== Checking help_center_screen.dart ===" '
echo 'grep -n "feature_coming_soon" /Users/ramprasadsreerama/Development/zenfoo/lib/view/screens/help_center/help_center_screen.dart'
echo ''
echo "# Make sure no old hardcoded strings remain"
echo 'echo "=== Looking for remaining hardcoded permission strings ===" '
echo 'grep -rn "Permission denied" /Users/ramprasadsreerama/Development/zenfoo/lib/view/screens/help_center/ || echo "None found (good!)"'
echo ''
echo 'echo "=== Looking for remaining feature_coming_soon hardcoded ===" '
echo "grep -rn '\$title feature coming soon' /Users/ramprasadsreerama/Development/zenfoo/lib/view/screens/help_center/ || echo \"None found (good!)\""
echo ""

# ============================================================================
# LOCALIZATION FILE UPDATES
# ============================================================================
echo "4. Required additions to localization files:"
echo ""
echo "Add these keys to your language files (en.json, es.json, etc.):"
echo ""
echo '"permission_denied_camera_gallery": "Permission denied. Please enable camera or gallery access.",'
echo '"feature_coming_soon": "Feature coming soon",'
echo ""
echo "For dynamic title version, use:"
echo '"feature_coming_soon": "{title} feature coming soon",'
echo "And replace in code with:"
echo 'languageProvider.getTranslatedText('"'"'feature_coming_soon'"'"').replaceAll('"'"'{title}'"'"', title)'
echo ""

# ============================================================================
# NOTES FOR REMAINING 46 FILES
# ============================================================================
echo ""
echo "=== FOR REMAINING 46 FILES ==="
echo ""
echo "Run this audit command on each remaining file:"
echo 'grep -n "Text(['"'"'\"][^'"'"'\"]*['"'"'\"]" <filename> | grep -v "languageProvider\|getTranslatedText"'
echo ""
echo "This will show any Text widgets that are NOT using localization."
echo ""

