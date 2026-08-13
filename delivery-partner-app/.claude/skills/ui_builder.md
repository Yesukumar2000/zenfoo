# UI Builder Skill

## Purpose
This skill helps you build Flutter UI screens following the project's design system guidelines. Use this when creating new screens, components, or updating existing UI elements.

## When to Use
- Creating new Flutter screens
- Building reusable UI components
- Updating existing UI to match design system
- Implementing forms, cards, buttons, or other UI elements
- Adding loading states, empty states, or error states

## Design System Reference
This project follows a comprehensive design system. Always reference `.claude/skills/design_system.md` for:
- Color palette (light and dark mode)
- Typography guidelines
- Component patterns
- Spacing rules
- Border radius standards
- Interaction principles

## Quick Start Checklist

### Before Building UI
- [ ] Read the design system documentation
- [ ] Understand the color scheme (use `colorScheme` properties)
- [ ] Plan component structure
- [ ] Identify reusable patterns

### During Implementation
- [ ] Use Google Fonts Inter with proper letter spacing
- [ ] Apply consistent spacing (12-16px rhythm)
- [ ] Use `colorScheme` properties (never hardcode colors except specific cases like green radio `#029100`)
- [ ] Add proper border radius (8-16px)
- [ ] Include card shadows for elevated surfaces
- [ ] Implement haptic feedback on interactive elements
- [ ] Support dark mode

### After Implementation
- [ ] Test in both light and dark mode
- [ ] Verify spacing consistency
- [ ] Check typography matches guidelines
- [ ] Ensure all interactive elements are clickable
- [ ] Add loading states where needed
- [ ] Handle empty/error states

## Common Patterns

### 1. Screen Structure
```dart
class NewScreen extends StatefulWidget {
  const NewScreen({super.key});

  @override
  State<NewScreen> createState() => _NewScreenState();
}

class _NewScreenState extends State<NewScreen> {
  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final colorScheme = themeProvider.colorScheme;

    return CustomScaffold(
      backgroundColor: colorScheme.background,
      body: Column(
        children: [
          // App Header
          const AppHeader(
            label: "SECTION",
            title: "Screen Title",
            showBackButton: true,
          ),

          // Body with padding
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 12-16),
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  // Content here
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

### 2. Creating Elevated Cards
```dart
Container(
  padding: const EdgeInsets.all(16),
  decoration: ShapeDecoration(
    color: colorScheme.surfaceElevated,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
    shadows: [
      BoxShadow(
        color: colorScheme.cardShadow,
        blurRadius: 22,
        offset: const Offset(0, 0),
        spreadRadius: 0,
      ),
    ],
  ),
  child: // Content
)
```

### 3. Interactive Elements with Haptic Feedback
```dart
GestureDetector(
  onTap: () {
    HapticFeedback.lightImpact();
    // Action
  },
  child: // Widget
)
```

### 4. Status Badges
```dart
Container(
  padding: const EdgeInsets.symmetric(horizontal: 8-10, vertical: 4-6),
  decoration: BoxDecoration(
    color: statusColor.withValues(alpha: 0.15),
    borderRadius: BorderRadius.circular(8-12),
  ),
  child: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, color: statusColor, size: 12-16),
      const SizedBox(width: 5),
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

### 5. Primary Button
```dart
GestureDetector(
  onTap: () {
    HapticFeedback.lightImpact();
    // Action
  },
  child: Container(
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
    decoration: BoxDecoration(
      color: colorScheme.primary,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: colorScheme.primary.withValues(alpha: 0.25),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Text(
      label,
      style: GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: Colors.white,
        letterSpacing: -0.3,
      ),
    ),
  ),
)
```

### 6. Radio Button (Green with Checkmark)
```dart
Container(
  width: 28,
  height: 28,
  decoration: const ShapeDecoration(
    color: isSelected ? Color(0xFF029100) : colorScheme.border.withValues(alpha: 0.4),
    shape: OvalBorder(),
  ),
  child: isSelected
      ? const Center(
          child: Icon(
            Icons.check,
            color: Colors.white,
            size: 18,
          ),
        )
      : null,
)
```

### 7. Divider
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

### 8. Shimmer Loading (Custom Gradient - Recommended)
```dart
class _ShimmerBox extends StatefulWidget {
  final double width;
  final double height;
  final double radius;

  const _ShimmerBox({
    required this.width,
    required this.height,
    this.radius = 8,
  });

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
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
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
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
      },
    );
  }
}

// Usage:
_ShimmerBox(width: 120, height: 20, radius: 4)
```

## Typography Examples

### Hierarchy-Based Typography

```dart
// Display / Hero (Large numbers, main CTAs)
Text(
  '₹2,450',
  style: GoogleFonts.inter(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.8,
    height: 1.2,
    color: colorScheme.textPrimary,
  ),
)

// Heading 1 (Screen titles, main section headers)
Text(
  'My Earnings',
  style: GoogleFonts.inter(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.55,
    height: 1.3,
    color: colorScheme.textPrimary,
  ),
)

// Heading 2 (Card headers, subsection titles)
Text(
  'Recent Transactions',
  style: GoogleFonts.inter(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.4,
    height: 1.35,
    color: colorScheme.textPrimary,
  ),
)

// Title (List item titles, prominent labels)
Text(
  'Order #12345',
  style: GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.3,
    height: 1.4,
    color: colorScheme.textPrimary,
  ),
)

// Body Large (Primary content, descriptions)
Text(
  'Your earnings will be credited to your account within 24 hours.',
  style: GoogleFonts.inter(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.25,
    height: 1.5,
    color: colorScheme.textPrimary,
  ),
)

// Body Regular (Secondary content, helper text)
Text(
  'Transaction processed successfully',
  style: GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.2,
    height: 1.5,
    color: colorScheme.textSecondary,
  ),
)

// Label / Small (Form labels, metadata, timestamps)
Text(
  'Transaction Date',
  style: GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.15,
    height: 1.4,
    color: colorScheme.textTertiary,
  ),
)

// Caption / Tiny (Fine print, subtle hints)
Text(
  'Updated 2 mins ago',
  style: GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.12,
    height: 1.35,
    color: colorScheme.textTertiary,
  ),
)
```

## State Management Patterns

### 1. Simple State
```dart
class _ScreenState extends State<Screen> {
  int _selectedIndex = 0;

  void _updateSelection(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
}
```

### 2. Loading State
```dart
class _ScreenState extends State<Screen> {
  bool _isLoading = false;

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // Load data
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildShimmerLoading();
    }
    return _buildContent();
  }
}
```

## Common Mistakes to Avoid

### ❌ Don't Do This
```dart
// Hardcoded colors
color: Colors.blue

// Inconsistent spacing
padding: EdgeInsets.all(13)

// No haptic feedback
onTap: () { /* action */ }

// Wrong font
fontFamily: 'Roboto'

// Missing dark mode support
color: Colors.white
```

### ✅ Do This Instead
```dart
// Use theme colors
color: colorScheme.primary

// Consistent spacing (12-16px)
padding: const EdgeInsets.all(16)

// With haptic feedback
onTap: () {
  HapticFeedback.lightImpact();
  /* action */
}

// Google Fonts Inter
style: GoogleFonts.inter(...)

// Theme-aware colors
color: colorScheme.textPrimary
```

## Testing Your UI

### Visual Checklist
1. **Dark Mode**: Switch to dark mode and verify all colors work
2. **Spacing**: Check that spacing follows 12-16px rhythm
3. **Typography**: Verify font sizes, weights, and letter spacing
4. **Interactions**: Test all buttons and interactive elements
5. **States**: Verify loading, empty, and error states display correctly
6. **Borders**: Check border radius is consistent (8-16px)
7. **Shadows**: Verify shadows are subtle and appropriate

### Code Checklist
1. No hardcoded colors (except `#029100` for green radio)
2. All interactive elements have `HapticFeedback`
3. Using `GoogleFonts.inter()` for all text
4. Consistent use of `const` where possible
5. Proper null safety handling
6. Loading states implemented
7. Error handling in place

## Example: Building a New Card Component

```dart
Widget _buildCustomCard(AppColorScheme colorScheme) {
  return GestureDetector(
    onTap: () {
      HapticFeedback.lightImpact();
      // Navigate or perform action
    },
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: ShapeDecoration(
        color: colorScheme.surfaceElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        shadows: [
          BoxShadow(
            color: colorScheme.cardShadow,
            blurRadius: 22,
            offset: const Offset(0, 0),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with icon
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.star,
                  color: colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Card Title',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                    color: colorScheme.textPrimary,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Content
          Text(
            'Card description or content goes here',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              letterSpacing: -0.2,
              color: colorScheme.textSecondary,
            ),
          ),

          const SizedBox(height: 12),

          // Footer with status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: colorScheme.success.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle,
                  color: colorScheme.success,
                  size: 12,
                ),
                const SizedBox(width: 4),
                Text(
                  'Active',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.success,
                    letterSpacing: -0.12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
```

## Resources
- Design System: `.claude/skills/design_system.md`
- Reference Screens:
  - Profile Screen: Complete design system implementation
  - Gig Availability Screen: Loading states and interactions
  - Home Screen: Card layouts and headers

## Tips for Success
1. **Always start with the design system** - Read it before coding
2. **Use theme colors** - Access via `colorScheme` properties
3. **Consistent spacing** - Stick to 12-16px rhythm
4. **Haptic feedback** - Add to all interactive elements
5. **Test dark mode** - Switch modes frequently during development
6. **Loading states** - Implement shimmer for all async operations
7. **Reuse patterns** - Look for existing implementations first
8. **Keep it simple** - Don't over-engineer, follow the patterns

## Quick Reference

### Spacing
- Extra Small: 4-6px
- Small: 8px
- Medium: 12-16px (most common)
- Large: 20-24px
- Extra Large: 32-40px

### Border Radius
- Small: 8px (badges)
- Medium: 12px (buttons)
- Large: 16px (cards)
- Extra Large: 24px (sheets)
- Pill: 999px

### Font Sizes
- Display: 32px
- Heading: 18-24px
- Title: 15-17px
- Body: 13-15px
- Label: 11-15px
- Caption: 11-12px

### Colors (Access via colorScheme)
- Primary: `colorScheme.primary`
- Background: `colorScheme.background`
- Surface: `colorScheme.surface`
- SurfaceElevated: `colorScheme.surfaceElevated`
- TextPrimary: `colorScheme.textPrimary`
- TextSecondary: `colorScheme.textSecondary`
- Border: `colorScheme.border`
- Success/Error/Info: `colorScheme.success/error/info`
- CardShadow: `colorScheme.cardShadow`

---

**Remember**: Consistency is key! Always reference the design system and existing implementations before creating new UI elements.
