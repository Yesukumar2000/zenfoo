/// One size for every product card in the app.
///
/// Before this, each screen invented its own: grids ran from 2dp of page
/// padding with a 4dp gutter (category products) to 12dp gutters (bookmarks,
/// wishlist) to three columns (campaign products), and rails ranged over 160,
/// 165 and 180dp wide with heights of 259, 270, 275, 312 and 330. The same card
/// therefore looked like a different component on every screen.
///
/// Host screens should reference these rather than hardcoding numbers, so the
/// card can be resized in one place.
library;

/// Horizontal page padding either side of a product grid.
const double productGridPagePadding = 16;

/// Gap between cards, both axes. Also the gap between cards in a rail.
const double productGridGutter = 12;

/// Fixed cell height for a product card.
///
/// Deliberately a fixed extent rather than a `childAspectRatio`. A ratio
/// derives height from width, so a narrower screen — or a narrower grid — also
/// shortens the card, and since the card's text block is sized to its content
/// and the image takes whatever is left, the image absorbs the whole loss. The
/// two are better kept independent.
///
/// 296 clears the tallest text block the card produces (a two-line name, pack
/// size, price, savings and the ADD button come to ~150dp) and leaves the image
/// roughly square at the standard widths below.
const double productCardExtent = 296;

/// Card width in a horizontal rail. Grid cards derive their width from the
/// column count instead, landing at ~158dp on a 360dp screen — close enough
/// that a rail card and a grid card read as the same object.
const double productRailCardWidth = 165;
