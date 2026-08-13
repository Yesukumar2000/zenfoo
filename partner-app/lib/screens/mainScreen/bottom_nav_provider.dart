import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BottomNavProvider extends ChangeNotifier {
  int _selected = 0;
  int get selected => _selected;
  void select(int idx) {
    _selected = idx;
    HapticFeedback.lightImpact();
    notifyListeners();
  }
}
