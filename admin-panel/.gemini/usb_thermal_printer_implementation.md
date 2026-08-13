# Direct USB Thermal Printer Support for Pre-Orders

## Overview
Added direct USB thermal printing functionality to the Pre-Orders section, allowing users to print directly to thermal printers without needing printer drivers.

## Implementation Details

### 1. Updated Print Modal UI
**File**: `StorePreOrders.vue` (Template Section)

**Changes**:
- Added dual print buttons for each print option:
  - **Browser Print**: Opens standard browser print dialog (existing functionality)
  - **USB Direct Print**: Sends ESC/POS commands directly to thermal printer via Web Serial API

**Three Print Options Enhanced**:
1. **Print Single Seller** - Print orders for a specific selected seller
2. **Print All Sellers** - Print all orders grouped by seller
3. **Print All Orders** - Print all orders chronologically

### 2. Added Three USB Direct Print Methods

#### Method 1: `printAllOrdersDirect()`
**Purpose**: Print all orders chronologically to thermal printer

**Features**:
- Header with store name and timestamp
- Each order shows:
  - Order ID, customer name, mobile, dates
  - Status and assigned seller (if applicable)
  - Regular items with quantities and prices
  - Combo items with product breakdown
  - Order total
- Summary section with total orders, items, and amount

#### Method 2: `printSellerWiseOrdersDirect()`
**Purpose**: Print orders grouped by seller

**Features**:
- Groups all assigned orders by seller name
- For each seller:
  - Seller name header
  - Order count and seller total
  - All orders with full item details
  - Seller subtotal
- Sorted alphabetically by seller name

#### Method 3: `printSingleSellerOrdersDirect()`
**Purpose**: Print orders for a specific seller

**Features**:
- Validates seller selection before printing
- Seller name prominently displayed in header
- All orders for that seller with full details
- Seller summary at the end

### 3. ESC/POS Commands Used

```javascript
INIT = ESC + '@'              // Initialize printer
ALIGN_CENTER/LEFT             // Text alignment
BOLD_ON/OFF                   // Bold text
DOUBLE_HEIGHT                 // Large text for headers
NORMAL_SIZE                   // Normal text size
CUT = GS + 'V' + '\x00'      // Paper cut
```

### 4. Thermal Printer Specifications
- **Paper Width**: 42 characters (80mm thermal paper)
- **Baud Rate**: 9600
- **Format**: ESC/POS compatible
- **Browser Support**: Chrome, Edge (Web Serial API)

### 5. Helper Functions
- `formatRow(label, value)` - Format label-value pairs with proper spacing
- `padLeft(str, len)` - Right-align text
- `padRight(str, len)` - Left-align text
- `wrapText(text, maxLen)` - Wrap long text to fit paper width

### 6. Error Handling
- Browser compatibility check (Web Serial API)
- Printer selection validation
- Connection error handling
- Empty order list validation
- User-friendly error messages via toast notifications

### 7. User Experience
**Browser Print Flow**:
1. Click print button
2. Select print option
3. Browser print dialog opens
4. Choose printer or save as PDF

**USB Direct Print Flow**:
1. Click USB Direct Print button
2. Browser prompts to select USB device
3. Select thermal printer
4. Print sent directly to printer
5. Success notification shown

### 8. CSS Enhancements
- Added `gap-2` utility class for button spacing
- Maintained existing print modal styling
- Responsive button layout

## Browser Compatibility
- **Supported**: Chrome 89+, Edge 89+
- **Not Supported**: Firefox, Safari (Web Serial API not available)
- Graceful fallback with clear error message for unsupported browsers

## Testing Checklist
- [ ] Test "Print All Orders" with browser print
- [ ] Test "Print All Orders" with USB direct print
- [ ] Test "Print All Sellers" with browser print
- [ ] Test "Print All Sellers" with USB direct print
- [ ] Test "Print Single Seller" with browser print
- [ ] Test "Print Single Seller" with USB direct print
- [ ] Test with no orders
- [ ] Test with orders containing combo items
- [ ] Test with orders containing only regular items
- [ ] Test error handling (no printer selected)
- [ ] Test in unsupported browser (Firefox/Safari)

## Benefits
1. **No Driver Required**: Direct USB communication eliminates printer driver installation
2. **Faster Printing**: Bypasses browser print dialog for quick thermal printing
3. **Dual Options**: Users can choose between browser print (PDF) or direct thermal print
4. **Professional Output**: Optimized formatting for thermal receipt printers
5. **Consistent Format**: ESC/POS ensures consistent output across compatible printers

## Future Enhancements (Optional)
- QR code support for order tracking
- Logo printing (bitmap conversion)
- Bluetooth thermal printer support
- Print settings UI (paper width, copies, etc.)
- Save printer preferences
- Print preview for direct print
