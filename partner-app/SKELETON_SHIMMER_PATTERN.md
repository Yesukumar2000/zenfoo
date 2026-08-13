# Skeleton Loading Pattern - Transaction Card

## Overview
Skeleton loading (shimmer effect) is used to show a placeholder while transaction data is loading. The skeleton should match the **exact structure and dimensions** of the actual transaction card UI.

---

## Actual Transaction Card Structure

### 1. **Header Row** (Lines 232-277)
```
[Transaction #ID] ─────────────── [Credit/Debit Badge]
   (Text: ~140px wide)              (Container: 80px wide)
```

**Elements:**
- Left: Transaction ID text (15px font, 600 weight)
- Right: Status badge with icon & text
  - Container: 80px wide, 28px tall
  - Background: `statusBgColor` (green/red tinted)
  - Contains: Icon + "Credit"/"Debit" label

---

### 2. **Divider** (Lines 280-283)
```
─────────────────────────────────
   (1px height, border color)
```

---

### 3. **Amount Section** (Lines 286-332)
```
[Icon Box] Amount
[40×40]    "Amount" label
           "+₹1,234.56" (amount text, 20px, bold)
```

**Elements:**
- Icon container: 40×40, borderRadius: 10
  - Background: Status color with 10% opacity
  - Icon: add_circle_outline (credit) or remove_circle_outline (debit), 20px
- Right side: Column with 2 text lines
  - Label: "Amount" (12px, secondary color)
  - Value: Amount with rupee sign (20px, 700 weight, status color)

---

### 4. **Date Section** (Lines 335-379)
```
[Icon Box] Transaction Date
[40×40]    "Transaction Date" label
           "dd MMMM yyyy, hh:mm a"
```

**Elements:**
- Icon container: 40×40, borderRadius: 10
  - Background: Blue tinted (#EFF6FF)
  - Icon: access_time_rounded, color: #3B82F6, 20px
- Right side: Column with 2 text lines
  - Label: "Transaction Date" (12px, secondary color)
  - Value: Formatted date/time (13px, 600 weight)

---

### 5. **Message Section** (Optional, Lines 381-428)
```
Only shown if transaction.message is not null/empty

[ℹ️] Details
─────────────
Message text content here...
```

**Elements:**
- Full-width container with 12px padding
- Background: `surfaceVariant`
- Border: 1px, border color
- Header row: Info icon + "Details" label
- Message text below

---

## Skeleton/Shimmer Implementation Guide

### Animation Setup (Required for all elements)
```dart
class _ShimmerTransactionCard extends StatefulWidget {
  const _ShimmerTransactionCard({Key? key}) : super(key: key);

  @override
  State<_ShimmerTransactionCard> createState() =>
      _ShimmerTransactionCardState();
}

class _ShimmerTransactionCardState extends State<_ShimmerTransactionCard>
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

  // ... build() method below
}
```

---

## Skeleton Card Structure

### Card Container
```dart
Container(
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
      // 1. Header Row - Skeleton
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Transaction ID placeholder (140×18)
          _buildShimmerBox(width: 140, height: 18, borderRadius: 4),

          // Status badge placeholder (80×28)
          _buildShimmerBox(width: 80, height: 28, borderRadius: 8),
        ],
      ),

      const SizedBox(height: 16),

      // 2. Divider
      Container(height: 1, color: colorScheme.border),

      const SizedBox(height: 16),

      // 3. Amount Section
      Row(
        children: [
          // Icon box (40×40)
          _buildShimmerBox(width: 40, height: 40, borderRadius: 10),

          const SizedBox(width: 12),

          // Amount text area
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // "Amount" label (60×12)
                _buildShimmerBox(width: 60, height: 12, borderRadius: 4),

                const SizedBox(height: 6),

                // Amount value (120×20)
                _buildShimmerBox(width: 120, height: 20, borderRadius: 4),
              ],
            ),
          ),
        ],
      ),

      const SizedBox(height: 14),

      // 4. Date Section
      Row(
        children: [
          // Icon box (40×40)
          _buildShimmerBox(width: 40, height: 40, borderRadius: 10),

          const SizedBox(width: 12),

          // Date text area
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // "Transaction Date" label (100×12)
                _buildShimmerBox(width: 100, height: 12, borderRadius: 4),

                const SizedBox(height: 6),

                // Date value (180×14)
                _buildShimmerBox(width: 180, height: 14, borderRadius: 4),
              ],
            ),
          ),
        ],
      ),

      // 5. Message section (optional)
      // Note: In skeleton, typically show/hide randomly or always show
      const SizedBox(height: 14),

      // Message container (full width)
      _buildShimmerMessageBox(),
    ],
  ),
)
```

### Shimmer Box Helper
```dart
Widget _buildShimmerBox({
  required double width,
  required double height,
  required double borderRadius,
}) {
  return Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(borderRadius),
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

Widget _buildShimmerMessageBox() {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: colorScheme.surfaceVariant,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: colorScheme.border, width: 1),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header line
        _buildShimmerBox(width: 80, height: 12, borderRadius: 4),

        const SizedBox(height: 12),

        // Content lines (simulate text wrapping)
        _buildShimmerBox(width: double.infinity, height: 12, borderRadius: 4),
        const SizedBox(height: 6),
        _buildShimmerBox(width: 280, height: 12, borderRadius: 4),
      ],
    ),
  );
}
```

---

## Key Dimensions Reference

| Element | Width | Height | Border Radius |
|---------|-------|--------|---------------|
| Card | 100% | auto | 16 |
| TX ID placeholder | 140 | 18 | 4 |
| Status badge | 80 | 28 | 8 |
| Icon boxes | 40 | 40 | 10 |
| Label text | 60-100 | 12 | 4 |
| Value text | 120-180 | 14-20 | 4 |
| Message container | 100% | auto | 10 |

---

## Usage in Screen

```dart
if (_isLoading) {
  return ListView.separated(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    itemCount: 5, // Number of skeleton cards to show
    separatorBuilder: (context, index) => const SizedBox(height: 12),
    itemBuilder: (context, index) => const _ShimmerTransactionCard(),
  );
}
```

---

## Color Scheme

- **Background**: `colorScheme.surfaceVariant` (darker shade)
- **Highlight**: `colorScheme.surface` (lighter shade, middle of wave)
- **Borders**: `colorScheme.border`
- **Card bg**: `colorScheme.cardBackground`

---

## Tips & Best Practices

1. **Match dimensions exactly** to avoid layout shift when real data loads
2. **Animation duration**: 1500ms is smooth but not too fast
3. **Wave width**: The ±0.3 offset creates a nice shimmer spread
4. **Show 5-7 cards** initially, not more (better perceived performance)
5. **Keep message section optional** - either always show or randomly show ~30% of the time
6. **Clamp animation values** to 0.0-1.0 to prevent out-of-bounds gradients
