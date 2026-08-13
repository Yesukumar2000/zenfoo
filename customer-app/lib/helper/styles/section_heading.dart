import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';

/// One heading style for every section on the home feed — Special Items,
/// Combos, Buy it again, Shop by Category, Top Rated Restaurants and the
/// API-driven product sections.
///
/// Lives here rather than in a screen file because the sections are spread
/// across several widgets, and every time it was re-declared inline it drifted
/// (18/w900/centred in one place, 18/w700/height 1.0 in another).
TextStyle sectionHeadingStyle(Color color) => GoogleFonts.inter(
      color: color,
      fontSize: 18,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.4,
      height: 1.2,
    );
