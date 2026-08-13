# Flutter App Design System

## Overview
This skill provides the complete design system guidelines for building premium, modern, and clean Flutter mobile app UIs with a sophisticated aesthetic.

## Design Philosophy
- **Premium & Modern**: Sophisticated aesthetic with polished details
- **Clarity & Hierarchy**: Clear information architecture
- **Refinement**: Subtle animations and micro-interactions
- **Consistency**: Unified design language across all screens

---

## Color Palette

### Light Mode
```dart
Primary: #9AC444 (lime green accent)
Background: #FAFAFA (soft gray)
Surface/Cards: #FFFFFF (pure white)
SurfaceElevated: #FFFFFF (pure white with shadows)
SurfaceVariant: #F9FAFB (light gray for shimmer/subtle backgrounds)
TextPrimary: #111827 (near-black)
TextSecondary: #6B7280 (medium gray)
TextTertiary: #9CA3AF (light gray)
Border: #F0F0F0 (subtle border)
CardShadow: #0A000000 (very subtle, 10% opacity)

// Status Colors
Success: #16A34A / Background: #DCFCE7
Error: #EF4444 / Background: #FEE2E2
Info: #3B82F6 / Background: #EFF6FF
Warning: #F59E0B / Background: #FEF3C7
```

### Dark Mode
```dart
Primary: #9AC444 (same lime green)
Background: #111827 (very dark gray)
Surface/Cards: #1F2937 (dark gray)
SurfaceElevated: #1F2937 (dark gray with shadows)
SurfaceVariant: #374151 (medium dark gray)
TextPrimary: #F9FAFB (near-white)
TextSecondary: #D1D5DB (light gray)
TextTertiary: #9CA3AF (medium gray)
Border: #374151 (subtle dark border)
CardShadow: #1A000000 (increased opacity for dark mode, 26%)

// Status colors remain the same as light mode
```

---

## Typography

### Font Family
- **Primary**: Google Fonts Inter
- **Letter Spacing**: Tight (-0.3 to -0.8) for modern, condensed feel

### Hierarchy Principles
1. **Clear distinction** between levels (min 2px difference)
2. **Consistent weight pairing**: Bold headings with regular body
3. **Optimal line height**: 1.2-1.5 for headings, 1.4-1.6 for body
4. **Limited scale**: Use 4-6 sizes maximum per screen

### Font Scales
```dart
Display (Hero/Large Numbers):
  fontSize: 32-36px
  fontWeight: 700-800
  letterSpacing: -0.8 to -1.0
  lineHeight: 1.2
  usage: Main CTAs, large amounts, hero text

Heading 1 (Section Headers):
  fontSize: 22-24px
  fontWeight: 700
  letterSpacing: -0.55 to -0.6
  lineHeight: 1.3
  usage: Screen titles, main section headers

Heading 2 (Card Headers):
  fontSize: 18-20px
  fontWeight: 600-700
  letterSpacing: -0.4 to -0.5
  lineHeight: 1.35
  usage: Card titles, subsection headers

Title (List Items):
  fontSize: 16-17px
  fontWeight: 600
  letterSpacing: -0.3 to -0.35
  lineHeight: 1.4
  usage: List item titles, prominent labels

Body Large:
  fontSize: 15-16px
  fontWeight: 400-500
  letterSpacing: -0.25 to -0.3
  lineHeight: 1.5
  usage: Primary content, descriptions

Body Regular:
  fontSize: 14px
  fontWeight: 400-500
  letterSpacing: -0.2 to -0.25
  lineHeight: 1.5
  usage: Secondary content, helper text

Label/Small:
  fontSize: 12-13px
  fontWeight: 500-600
  letterSpacing: -0.15 to -0.2
  lineHeight: 1.4
  usage: Form labels, metadata, timestamps

Caption/Tiny:
  fontSize: 11px
  fontWeight: 400-500
  letterSpacing: -0.12
  lineHeight: 1.35
  usage: Fine print, subtle hints
```

---

## Component Guidelines

### 1. Card Design

#### Standard Card
```dart
Container(
  padding: EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: colorScheme.surface,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(
      color: colorScheme.border,
      width: 1,
    ),
  ),
)
```

#### Elevated Card
```dart
Container(
  padding: EdgeInsets.all(16),
  decoration: ShapeDecoration(
    color: colorScheme.surfaceElevated,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
    shadows: [
      BoxShadow(
        color: colorScheme.cardShadow, // 0x0A000000 light, 0x1A000000 dark
        blurRadius: 22,
        offset: Offset(0, 0),
        spreadRadius: 0,
      ),
    ],
  ),
)
```

### 2. Shimmer Loading Effect

#### Custom Gradient Implementation (Recommended)
Use `AnimationController` with `LinearGradient` for smooth, performant shimmer:

```dart
class _ShimmerCard extends StatefulWidget {
  const _ShimmerCard({Key? key}) : super(key: key);

  @override
  State<_ShimmerCard> createState() => _ShimmerCardState();
}

class _ShimmerCardState extends State<_ShimmerCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<ThemeProvider>().colorScheme;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colorScheme.border, width: 1),
            boxShadow: colorScheme.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildShimmerBox(140, 18, 4, colorScheme),
                  _buildShimmerBox(80, 28, 8, colorScheme),
                ],
              ),
              const SizedBox(height: 16),
              Container(height: 1, color: colorScheme.border),
              const SizedBox(height: 16),

              // Content row with icon
              Row(
                children: [
                  _buildShimmerBox(40, 40, 10, colorScheme),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildShimmerBox(60, 12, 4, colorScheme),
                        const SizedBox(height: 6),
                        _buildShimmerBox(120, 20, 4, colorScheme),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildShimmerBox(double width, double height, double radius, AppColorScheme colorScheme) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            colorScheme.surfaceVariant,
            colorScheme.surface,
            colorScheme.surfaceVariant,
          ],
          stops: [
            _animation.value - 0.3,
            _animation.value,
            _animation.value + 0.3,
          ].map((e) => e.clamp(0.0, 1.0)).toList(),
        ),
      ),
    );
  }
}
```

#### Alternative: Package Implementation
```dart
Shimmer.fromColors(
  baseColor: colorScheme.border.withValues(alpha: 0.3),
  highlightColor: colorScheme.surface,
  period: Duration(milliseconds: 1500),
  child: Container(
    decoration: BoxDecoration(
      color: colorScheme.surfaceVariant,
      borderRadius: BorderRadius.circular(8-16),
    ),
  ),
)
```

**Guidelines**:
- 3-color gradient: `surfaceVariant → surface → surfaceVariant`
- Animation: 1500ms duration with `Curves.easeInOut`
- Animation sweeps from left to right (-1.0 to 2.0)
- Border radius matches final content (4-16px)
- **Critical**: Replicate exact content structure during loading
- Use `SingleTickerProviderStateMixin` for efficient animation
- Always dispose `AnimationController` in `dispose()`
- Clamp gradient stops to 0.0-1.0 range to avoid overflow

### 3. App Header Component

```dart
Container(
  width: double.infinity,
  decoration: BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        colorScheme.primary,
        colorScheme.background,
      ],
      stops: [0, 0.85],
    ),
  ),
  child: SafeArea(
    bottom: false,
    child: Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Back button (optional)
          if (showBackButton)
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.pop(context);
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colorScheme.textPrimary.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colorScheme.textPrimary.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: colorScheme.textPrimary.withValues(alpha: 0.9),
                  size: 18,
                ),
              ),
            ),
          // Title section
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 12-14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.55,
                    color: colorScheme.textSecondary.withValues(alpha: 0.9),
                  ),
                ),
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.55,
                    color: colorScheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  ),
)
```

### 4. Status Badges

```dart
Container(
  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
  decoration: BoxDecoration(
    color: statusColor.withValues(alpha: 0.15), // 15% tint
    borderRadius: BorderRadius.circular(8-12),
  ),
  child: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(statusIcon, color: statusColor, size: 12-16),
      SizedBox(width: 5),
      Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 11-12,
          fontWeight: FontWeight.w600,
          color: statusColor,
          letterSpacing: -0.12,
        ),
      ),
    ],
  ),
)
```

### 5. Icon Containers

```dart
Container(
  width: 40,
  height: 40,
  padding: EdgeInsets.all(10),
  decoration: BoxDecoration(
    color: statusColor.withValues(alpha: 0.1), // 10% opacity
    borderRadius: BorderRadius.circular(10),
  ),
  child: Icon(
    icon,
    size: 20,
    color: statusColor,
  ),
)
```

### 6. Buttons

#### Primary Button
```dart
GestureDetector(
  onTap: () {
    HapticFeedback.lightImpact();
    // Action
  },
  child: Container(
    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
    decoration: BoxDecoration(
      color: colorScheme.primary,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: colorScheme.primary.withValues(alpha: 0.25),
          blurRadius: 12,
          offset: Offset(0, 4),
        ),
      ],
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white, size: 20),
        SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            letterSpacing: -0.3,
          ),
        ),
      ],
    ),
  ),
)
```

#### Secondary Button
```dart
Container(
  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
  decoration: BoxDecoration(
    color: colorScheme.border.withValues(alpha: 0.3),
    borderRadius: BorderRadius.circular(12),
  ),
  child: Text(
    label,
    style: GoogleFonts.inter(
      fontSize: 15,
      fontWeight: FontWeight.w600,
      color: colorScheme.textPrimary,
      letterSpacing: -0.3,
    ),
  ),
)
```

### 7. Radio Buttons

```dart
Container(
  width: 28,
  height: 28,
  decoration: ShapeDecoration(
    color: isSelected
        ? Color(0xFF029100) // Green when selected
        : colorScheme.border.withValues(alpha: 0.4),
    shape: OvalBorder(),
  ),
  child: isSelected
      ? Center(
          child: Icon(
            Icons.check,
            color: Colors.white,
            size: 18,
          ),
        )
      : null,
)
```

### 8. Dividers

```dart
Container(
  width: double.infinity,
  height: 1,
  decoration: ShapeDecoration(
    shape: RoundedRectangleBorder(
      side: BorderSide(
        width: 1,
        strokeAlign: BorderSide.strokeAlignCenter,
        color: colorScheme.border.withValues(alpha: 0.3),
      ),
    ),
  ),
)
```

---

## Spacing System

### Standard Spacing
```dart
Extra Small: 4-6px
Small: 8px
Medium: 12-16px (most common)
Large: 20-24px
Extra Large: 32-40px
```

### Content Sections
- **Between major sections**: 12-16px
- **Between label-value pairs**: 6px
- **Card internal padding**: 16px
- **Screen horizontal margins**: 12-16px
- **List item spacing**: 8-12px

---

## Border Radius

```dart
Small: 8px (badges, chips)
Medium: 12px (buttons, inputs)
Large: 16px (cards, containers)
Extra Large: 24px (bottom sheets)
Circular: 999px (pills, rounded buttons)
```

---

## Interaction Principles

### 1. Haptic Feedback
```dart
HapticFeedback.lightImpact(); // On all button presses
HapticFeedback.mediumImpact(); // On important actions
HapticFeedback.heavyImpact(); // On critical actions
```

### 2. Pull-to-Refresh
```dart
RefreshIndicator(
  color: colorScheme.primary,
  backgroundColor: colorScheme.surface,
  onRefresh: () async {
    // Refresh logic
  },
  child: // Scrollable content
)
```

### 3. Search Fields
```dart
TextField(
  decoration: InputDecoration(
    prefixIcon: Icon(
      Icons.search,
      size: 22,
      color: colorScheme.textSecondary,
    ),
    hintText: 'Search...',
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: colorScheme.border),
    ),
  ),
)
```

---

## Empty & Error States

```dart
Center(
  child: Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: colorScheme.border.withValues(alpha: 0.3),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 48,
          color: colorScheme.textSecondary,
        ),
      ),
      SizedBox(height: 16),
      Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: colorScheme.textPrimary,
          letterSpacing: -0.5,
        ),
      ),
      SizedBox(height: 8),
      Text(
        description,
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: colorScheme.textSecondary,
        ),
        textAlign: TextAlign.center,
      ),
      SizedBox(height: 24),
      // Action button
    ],
  ),
)
```

---

## Dark Mode Adaptations

### Key Differences
1. **Increase shadow opacity**: `0x1A000000` vs `0x0A000000`
2. **Maintain status colors**: Keep consistent for recognition
3. **Higher contrast borders**: `#374151` instead of lighter borders
4. **Primary accent unchanged**: `#9AC444` works in both modes
5. **Subtle translucent overlays**: For depth and hierarchy

---

## Visual Hierarchy Principles

### 1. Size Hierarchy
**Rule**: Create clear distinction between heading levels (min 2px difference)

```dart
// Good Hierarchy
Screen Title: 22px, w700
Card Header: 18px, w600
List Item: 16px, w600
Body Text: 14-15px, w400
Metadata: 12px, w500
Fine Print: 11px, w400

// Bad - Too similar
Section Title: 16px
Card Title: 15px
Body: 14px
// Hard to distinguish!
```

### 2. Weight Hierarchy
**Rule**: Pair bold headings with regular body for maximum contrast

```dart
// Good Pairing
Heading: FontWeight.w600-w700
Body: FontWeight.w400-w500
Contrast ratio: Strong

// Bad Pairing
Heading: FontWeight.w600
Body: FontWeight.w500
Contrast ratio: Weak
```

### 3. Color Hierarchy
**Rule**: Use color to reinforce importance

```
Primary Info: textPrimary (#111827 light, #F9FAFB dark)
Secondary Info: textSecondary (#6B7280 light, #D1D5DB dark)
Tertiary/Meta: textTertiary (#9CA3AF both)
```

### 4. Spacing Hierarchy
**Rule**: More important content gets more breathing room

```dart
Screen Title: 24-32px top margin
Major Sections: 20-24px spacing
Card Groups: 16px spacing
List Items: 12px spacing
Label-Value Pairs: 6-8px spacing
```

### 5. Content Structure Best Practices

**Card Content Order** (Top to Bottom):
1. **Header** (18-20px, w600-700) - Most important
2. **Divider** (optional)
3. **Primary Content** (15-16px, w400-500)
4. **Metadata** (12px, w500, textTertiary)
5. **Action Button** (bottom-aligned)

**List Item Structure** (Left to Right):
1. **Icon Container** (40x40px, colored background)
2. **Primary Text** (16px, w600, textPrimary)
3. **Secondary Text** (14px, w400, textSecondary)
4. **Trailing** (Arrow/Badge/Switch)

**Information Density**:
- High importance screens: Low density, more whitespace
- List/Overview screens: Medium density
- Detail screens: Higher density acceptable

## Key Design Patterns

### 1. Information Hierarchy
```
Icon Container (40x40) + Label (16px w600) + Value (14px w400)
Consistent spacing: 12px between elements
```

### 2. Status Communication
```
Color-coded badges (8-12px radius)
Icon (12-16px) + Text (11-12px w600)
15% opacity background tint
```

### 3. Loading States
```
Custom gradient shimmer (surfaceVariant → surface → surfaceVariant)
1500ms animation, Curves.easeInOut
Match exact content structure
```

### 4. Spacing Consistency
```
Major sections: 20-24px
Card spacing: 16px
List items: 12px
Label-value: 6-8px
```

### 5. Micro-interactions
```
HapticFeedback.lightImpact() on all taps
Smooth animations (200-300ms)
Scale animations for buttons (0.95)
```

### 6. Professional Polish
```
Tight letter spacing (-0.2 to -0.8)
Precise alignment (Center/Start/End)
Subtle shadows (10-26% opacity)
Consistent border radius (8-16px)
```

---

## Usage Guidelines

### When Building New Screens
1. Always use `colorScheme` properties (never hardcoded colors except green radio)
2. Use Google Fonts Inter with specified letter spacing
3. Apply consistent spacing (12-16px rhythm)
4. Add card shadows for elevated surfaces
5. Include haptic feedback on all interactive elements
6. Implement shimmer loading states
7. Follow border radius guidelines
8. Use status badges for state communication

### Common Mistakes to Avoid
- ❌ Hardcoding colors
- ❌ Inconsistent spacing
- ❌ Missing haptic feedback
- ❌ No loading states
- ❌ Ignoring dark mode
- ❌ Wrong font weights or letter spacing
- ❌ Mismatched border radius

---

## Testing Checklist

- [ ] Dark mode looks correct
- [ ] All interactive elements have haptic feedback
- [ ] Loading states are implemented
- [ ] Spacing is consistent (12-16px rhythm)
- [ ] Typography follows guidelines
- [ ] Colors use theme properties
- [ ] Border radius is consistent
- [ ] Shadows are subtle
- [ ] Status communication is clear
- [ ] Empty/error states are handled

---

## Examples

See the following screens for reference implementation:
- Profile Screen: Complete implementation with all patterns
- Gig Availability Screen: Loading states and status badges
- Home Screen: App header and card design
