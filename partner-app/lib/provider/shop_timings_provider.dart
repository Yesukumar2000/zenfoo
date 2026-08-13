import 'package:flutter/material.dart';
import 'package:project/helper/utils/generalImports.dart';

class ShopTimingsProvider extends ChangeNotifier {
  bool isLoading = false;
  bool isUpdating = false;
  String? errorMessage;

  // Raw time strings from API ("HH:mm:ss")
  String? openingTime;
  String? closingTime;

  // Parsed TimeOfDay for pickers
  TimeOfDay? openingTimeOfDay;
  TimeOfDay? closingTimeOfDay;

  /// Parse "HH:mm:ss" → TimeOfDay
  TimeOfDay _parseTime(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return const TimeOfDay(hour: 9, minute: 0);
    final parts = timeStr.split(':');
    if (parts.length >= 2) {
      return TimeOfDay(
        hour: int.tryParse(parts[0]) ?? 9,
        minute: int.tryParse(parts[1]) ?? 0,
      );
    }
    return const TimeOfDay(hour: 9, minute: 0);
  }

  /// Format TimeOfDay → "HH:mm:ss"
  String formatTimeOfDay(TimeOfDay t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m:00';
  }

  /// Display format for UI (e.g. "09:00 AM")
  String displayTime(TimeOfDay? t) {
    if (t == null) return '--:--';
    final hour = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final minute = t.minute.toString().padLeft(2, '0');
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  Future<void> fetchShopTimings() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final response = await sendApiRequest(
        apiName: 'shop-timings',
        params: {},
        isPost: false,
      );

      if (response != null) {
        final data = json.decode(response) as Map<String, dynamic>;
        if (data['status'] == 1 && data['data'] != null) {
          openingTime = data['data']['shop_opening_time']?.toString();
          closingTime = data['data']['shop_closing_time']?.toString();
          openingTimeOfDay = _parseTime(openingTime);
          closingTimeOfDay = _parseTime(closingTime);
        } else {
          errorMessage = data['message']?.toString() ?? 'Failed to fetch shop timings';
        }
      } else {
        errorMessage = 'No response from server';
      }
    } catch (e) {
      errorMessage = 'Error: ${e.toString()}';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateShopTimings(BuildContext context) async {
    if (openingTimeOfDay == null || closingTimeOfDay == null) return false;

    isUpdating = true;
    errorMessage = null;
    notifyListeners();

    final opening = formatTimeOfDay(openingTimeOfDay!);
    final closing = formatTimeOfDay(closingTimeOfDay!);

    try {
      final response = await sendApiRequest(
        apiName: 'update-shop-timings',
        params: {
          'shop_opening_time': opening,
          'shop_closing_time': closing,
        },
        isPost: true,
      );

      if (response != null) {
        final data = json.decode(response) as Map<String, dynamic>;
        if (data['status'] == 1) {
          openingTime = opening;
          closingTime = closing;
          notifyListeners();
          return true;
        } else {
          errorMessage = data['message']?.toString() ?? 'Failed to update shop timings';
          notifyListeners();
          return false;
        }
      } else {
        errorMessage = 'No response from server';
        notifyListeners();
        return false;
      }
    } catch (e) {
      errorMessage = 'Error: ${e.toString()}';
      notifyListeners();
      return false;
    } finally {
      isUpdating = false;
      notifyListeners();
    }
  }

  void setOpeningTime(TimeOfDay t) {
    openingTimeOfDay = t;
    notifyListeners();
  }

  void setClosingTime(TimeOfDay t) {
    closingTimeOfDay = t;
    notifyListeners();
  }
}
