import 'package:flutter/material.dart';
import 'package:project/models/thinking_item.dart';
import 'package:project/repositories/thinkingItemsApi.dart';

enum ThinkingItemsState { initial, loading, loaded, error }

class ThinkingItemsProvider extends ChangeNotifier {
  ThinkingItemsState state = ThinkingItemsState.initial;
  List<ThinkingItem> items = [];
  String? sectionTitle;
  String message = "";

  Future<void> fetchThinkingItems(BuildContext context) async {
    state = ThinkingItemsState.loading;
    notifyListeners();

    await Future.wait([
      _fetchItems(context),
      _fetchTitle(context),
    ]);

    notifyListeners();
  }

  Future<void> _fetchItems(BuildContext context) async {
    try {
      final response = await getThinkingItems(context: context);
      if (response['status'] == 1 && response['data'] != null) {
        items = (response['data'] as List)
            .map((e) => ThinkingItem.fromJson(e))
            .toList();
        state = ThinkingItemsState.loaded;
      } else {
        message = response['message'] ?? "Failed to load";
        state = ThinkingItemsState.error;
      }
    } catch (e) {
      message = e.toString();
      state = ThinkingItemsState.error;
    }
  }

  Future<void> _fetchTitle(BuildContext context) async {
    try {
      final response = await getThinkingItemsTitle(context: context);
      if (response['status'] == 1 && response['data']?['title'] != null) {
        sectionTitle = response['data']['title'] as String;
      }
    } catch (_) {
      // fallback to default translation
    }
  }

  bool get isLoading => state == ThinkingItemsState.loading;
  bool get hasItems => items.isNotEmpty;
}
