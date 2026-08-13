# In-App Update Implementation Guide

This guide explains the in-app update system implemented for Zenfoo Delivery app supporting both Android (Google Play Store) and iOS (App Store).

## Overview

The implementation uses the `in_app_update` package which provides:
- **Flexible Updates**: Users can update later and continue using the app
- **Immediate Updates**: Forces update before the app can be used (for critical updates)
- **Dialog-based UI**: Professional update prompts

## Architecture

### 1. **InAppUpdateService** (`lib/services/in_app_update_service.dart`)
Core service handling update logic:
- Checks for available updates
- Shows update dialogs
- Manages flexible and immediate updates
- Handles errors gracefully

**Key Methods:**
- `checkForUpdate(context)` - Check and prompt for updates
- `checkForUpdateOnAppResume(context)` - Check on app foreground
- `_startUpdate()` - Execute update process

### 2. **UpdateProvider** (`lib/providers/update_provider.dart`)
State management for update status:
- Tracks update availability
- Manages checking state
- Provides methods to start/complete updates
- Integrates with provider pattern

**Getters:**
- `isCheckingForUpdate` - Is currently checking
- `updateAvailable` - Update is available
- `updateInfo` - Detailed update information

**Methods:**
- `checkForUpdate(context)` - Trigger update check
- `startFlexibleUpdate()` - Start flexible update
- `completeFlexibleUpdate()` - Restart app with update
- `resetUpdateAvailability()` - Clear update state

### 3. **UpdateNotificationWidget** (`lib/view/widgets/update_notification_widget.dart`)
UI widget displaying update availability:
- Shows in-app notification banner
- One-tap update button
- Clean, non-intrusive design

## Platform Configuration

### Android Setup

**Required in `android/app/build.gradle`:**
```gradle
dependencies {
    // Already included by in_app_update package
    implementation 'com.google.android.play:core:1.10.3'
}
```

**AndroidManifest.xml permissions:**
```xml
<uses-permission android:name="com.google.android.providers.gsf.permission.READ_GSERVICES" />
```

### iOS Setup

**Required in `ios/Podfile`:**
```ruby
# Already handled by in_app_update package
```

**Info.plist configuration:**
```xml
<key>SKStoreProductParameterITunesItemIdentifier</key>
<string>YOUR_APP_ID</string>
```

> **Note**: App Store in-app updates are limited. iOS primarily relies on App Store prompting users to update.

## Integration Points

### 1. **App Initialization** (main.dart)
```dart
// In MultiProvider list
ChangeNotifierProvider(
  create: (_) => UpdateProvider(),
),

// In Consumer5 builder
WidgetsBinding.instance.addPostFrameCallback((_) {
  if (context.mounted) {
    updateProvider.checkForUpdate(context);
  }
});
```

### 2. **Manual Check** (Any Screen)
```dart
final updateProvider = context.read<UpdateProvider>();
await updateProvider.checkForUpdate(context);
```

### 3. **Display Notification Banner**
```dart
// In home screen or any persistent widget
const UpdateNotificationWidget(),
```

## Update Flow

### Flexible Update (Default)
```
User sees notification → Taps "Update" → Download in background
→ "Update Ready" dialog → Restarts app with new version
```

### Immediate Update (Critical)
```
Update available → Forces update dialog → Cannot dismiss
→ User must update to continue using app
```

## Usage Examples

### Check for Update on App Start
Already configured in `main.dart` - runs automatically when app launches.

### Check on App Resume
```dart
@override
void didChangeAppLifecycleState(AppLifecycleState state) {
  if (state == AppLifecycleState.resumed) {
    context.read<UpdateProvider>().checkForUpdateOnAppResume(context);
  }
}
```

### Manual Update Button
```dart
TextButton(
  onPressed: () {
    context.read<UpdateProvider>().checkForUpdate(context);
  },
  child: const Text('Check for Updates'),
),
```

## Error Handling

The implementation gracefully handles:
- No network connection
- Update service unavailable
- User cancels update
- Update download fails
- Platform-specific errors

All errors are logged with `debugPrint()` for debugging.

## Testing

### Android
1. Install app on device from Play Store
2. Publish a new version to Play Store (internal testing track)
3. App will detect and prompt for update

### iOS
1. Install app from App Store
2. Publish new version
3. App Store handles updates (limited in-app control)

### Development/Testing
Use Play Console's **internal testing** or **closed testing** tracks:
1. Create new version with higher version code
2. Upload to internal test track
3. Install app from test link
4. In-app update will be triggered

## Performance Considerations

- Update check is non-blocking
- Uses background download on Android
- Minimal network usage
- Smart scheduling to avoid constant checks

## Future Enhancements

1. **Scheduled Updates**: Check for updates at specific times
2. **Staged Rollout**: Gradually roll out updates
3. **Update Metrics**: Track update completion rates
4. **Custom Update UI**: Create branded update screens
5. **Download Progress**: Show download percentage

## Troubleshooting

### Update not showing on Android
- Ensure app is from Play Store (not sideloaded)
- Check that new version has higher version code
- Wait 2-3 hours for Play Store to index update

### Update not showing on iOS
- Apple App Store updates are automatic
- In-app prompting is limited by App Store policies
- Consider requesting App Store to prompt users

### "Update Not Available" error
- Network issue - check internet connection
- Service temporarily unavailable - retry later
- No new version published yet

## Security Notes

- Updates are signed by Play Store/App Store
- No man-in-the-middle attacks possible
- Uses official platform APIs only
- No custom update servers required

## Dependencies

Add to `pubspec.yaml`:
```yaml
dependencies:
  in_app_update: ^4.2.2
```

The package is already added to the project.
