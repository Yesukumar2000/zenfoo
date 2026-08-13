import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Firebase service for managing ETA (Estimated Time of Arrival) for orders
class FirebaseEtaService {
  static final FirebaseEtaService _instance = FirebaseEtaService._internal();
  factory FirebaseEtaService() => _instance;
  FirebaseEtaService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Set initial ETA for an order or update existing ETA with proper time calculation
  /// When document exists: calculates remaining time and adds new prep time
  /// Formula: new_eta = (previous_eta - elapsed) + (newPrepTime / seller_count)
  /// When document doesn't exist: creates new with just the prep time
  /// [orderId] - The order ID
  /// [etaMinutes] - Preparation time in minutes (must be 5-120)
  /// [sellerCount] - Number of sellers (default 1)
  Future<bool> setEta({
    required int orderId,
    required int etaMinutes,
    int sellerCount = 1,
  }) async {
    try {
      // Validate ETA bounds
      if (etaMinutes < 5 || etaMinutes > 120) {
        debugPrint('❌ ETA must be between 5 and 120 minutes');
        return false;
      }

      final now = DateTime.now();
      final storedAt = _formatTimeString(now);

      // Check if document exists first
      final docSnapshot = await _firestore
          .collection('order_eta')
          .doc(orderId.toString())
          .get();

      if (docSnapshot.exists) {
        // Document exists - calculate remaining time and add new prep time
        final currentEta = OrderEta.fromFirestore(docSnapshot.data()!);
        final elapsed = _calculateElapsedMinutes(currentEta.storedAt);
        final remaining = (currentEta.eta - elapsed).clamp(0, 120);

        // Add new prep time divided by seller count
        final count = sellerCount;
        final perSellerAddition = etaMinutes ~/ count;
        final finalEta = (remaining + perSellerAddition).clamp(0, 120);

        await _firestore
            .collection('order_eta')
            .doc(orderId.toString())
            .update({
          'eta': finalEta,
          'stored_at': storedAt,
          'updated_at': FieldValue.serverTimestamp(),
          'seller_count': count,
          'is_preparation': 1,
        });

        debugPrint(
            '✅ ETA updated for order $orderId: elapsed=$elapsed, remaining=$remaining, added=$etaMinutes/$count, finalEta=$finalEta at $storedAt');
      } else {
        // Document doesn't exist - create it with initial values
        await _firestore.collection('order_eta').doc(orderId.toString()).set({
          'order_id': orderId,
          'eta': etaMinutes,
          'stored_at': storedAt,
          'updated_at': FieldValue.serverTimestamp(),
          'seller_count': sellerCount,
          'delayed_time': null,
          'is_preparation': 1,
        });

        debugPrint(
            '✅ ETA set for order $orderId: $etaMinutes min at $storedAt');
      }
      return true;
    } catch (e) {
      debugPrint('❌ Error setting ETA: $e');
      return false;
    }
  }

  /// Update ETA with adjustment (add or reduce time)
  /// Calculates elapsed time from stored_at and applies adjustment divided by seller_count
  /// Example: stored_at=3:27, eta=60, now=3:37 (10 min elapsed), remaining=50
  /// If seller adds 15 min: 50 + (15/seller_count) = new eta
  /// [orderId] - The order ID
  /// [adjustmentMinutes] - Minutes to add (positive) or subtract (negative)
  /// [sellerCount] - Number of sellers (default 1)
  Future<bool> updateEta({
    required int orderId,
    required int adjustmentMinutes,
    int? sellerCount,
  }) async {
    try {
      // Get current ETA data
      final currentEta = await getOrderEta(orderId: orderId);
      if (currentEta == null) {
        debugPrint('❌ Order ETA not found for $orderId');
        return false;
      }

      // Use provided sellerCount or from Firebase
      final count = sellerCount ?? currentEta.sellerCount;

      // Validate adjustment limits
      if (adjustmentMinutes.abs() > 60) {
        debugPrint(
            '❌ Adjustment cannot exceed 60 minutes (requested: $adjustmentMinutes)');
        return false;
      }

      // Calculate current remaining time from stored_at + eta - now
      final elapsed = _calculateElapsedMinutes(currentEta.storedAt);
      final remaining = (currentEta.eta - elapsed).clamp(0, 120);

      // Apply adjustment divided by seller count
      final perSellerAdjustment = adjustmentMinutes ~/ count;
      final newEta = remaining + perSellerAdjustment;

      // Ensure ETA stays positive and within bounds
      final finalEta = newEta.clamp(0, 120);

      // Update Firebase with new values
      // stored_at is updated to CURRENT time (when this adjustment was made)
      final now = DateTime.now();
      final newStoredAt = _formatTimeString(now);

      // Track delays only when adding time (adjustment > 0)
      // If adjustment is negative (reducing), don't change delayed_time
      var newDelayedTime = currentEta.delayedTime ?? 0;
      if (adjustmentMinutes > 0) {
        newDelayedTime += adjustmentMinutes;
      }

      await _firestore.collection('order_eta').doc(orderId.toString()).update({
        'eta': finalEta,
        'stored_at': newStoredAt, // Updated to current time
        'updated_at': FieldValue.serverTimestamp(),
        'delayed_time': newDelayedTime > 0 ? newDelayedTime : null,
        'is_preparation': 1,
      });

      debugPrint(
          '✅ ETA updated for order $orderId: elapsed=$elapsed, remaining=$remaining, adjustment=$adjustmentMinutes/$count, newEta=$finalEta, storedAt=$newStoredAt');
      return true;
    } catch (e) {
      debugPrint('❌ Error updating ETA: $e');
      return false;
    }
  }

  /// Reduce ETA when seller swipes to prepared
  /// Reduces Firebase eta by the API's remaining prep time divided by seller count
  /// Step 1: Get Firebase eta and calculate elapsed since stored_at
  /// Step 2: Calculate Firebase remaining: firebase_eta - elapsed
  /// Step 3: Calculate reduction from API prep time: api_prep_time / seller_count
  /// Step 4: Final eta: firebase_remaining - reduction
  /// Also tracks delays if elapsed time > 15 minutes
  ///
  /// Example:
  ///   Firebase at 3:35: eta=50, stored_at=3:35
  ///   API at 3:35: prep_time=15
  ///   At 3:40: elapsed=5, firebase_remaining=50-5=45
  ///   Reduction from API: 15/1 = 15, but only 10 min remaining (15-5)
  ///   Final: eta = 45 - 10 = 35, stored_at = 3:40
  ///
  /// [orderId] - The order ID
  /// [apiPrepTime] - Current prep time from API (in minutes)
  /// [sellerCount] - Number of sellers (default from Firebase)
  Future<bool> reducePreparedEta({
    required int orderId,
    required int apiPrepTime,
    int? sellerCount,
  }) async {
    try {
      // Get current ETA data from Firebase
      final currentEta = await getOrderEta(orderId: orderId);
      if (currentEta == null) {
        debugPrint('❌ Order ETA not found for $orderId');
        return false;
      }

      // Use provided sellerCount or from Firebase
      final count = sellerCount ?? currentEta.sellerCount;

      // Step 1: Calculate elapsed time from stored_at to now
      final elapsed = _calculateElapsedMinutes(currentEta.storedAt);

      // Step 2: Calculate Firebase remaining time
      final firebaseRemaining = (currentEta.eta - elapsed).clamp(0, 120);

      // Step 3: Calculate remaining prep time from API (prep_time - elapsed)
      final apiRemaining = (apiPrepTime - elapsed).clamp(0, 120);

      // Step 4: Calculate reduction: api_remaining / seller_count
      final reduction = apiRemaining ~/ count;

      // Step 5: Reduce Firebase eta by the reduction amount
      final finalEta = (firebaseRemaining - reduction).clamp(0, 120);

      // Step 6: Calculate and track delays
      // If elapsed time > 15 minutes, add excess time to delayed_time
      final excessDelay = elapsed > 15 ? elapsed - 15 : 0;
      final newDelayedTime = (currentEta.delayedTime ?? 0) + excessDelay;

      // Step 7: Update Firebase with new values
      // stored_at is updated to CURRENT time
      final now = DateTime.now();
      final newStoredAt = _formatTimeString(now);

      await _firestore.collection('order_eta').doc(orderId.toString()).update({
        'eta': finalEta,
        'stored_at': newStoredAt,
        'updated_at': FieldValue.serverTimestamp(),
        'delayed_time': newDelayedTime > 0 ? newDelayedTime : null,
        'is_preparation': 1,
      });

      debugPrint(
          '✅ ETA prepared for order $orderId: firebaseEta=$currentEta.eta, elapsed=$elapsed, firebaseRemaining=$firebaseRemaining, apiPrepTime=$apiPrepTime, apiRemaining=$apiRemaining, reduction=$reduction/$count, finalEta=$finalEta, excessDelay=$excessDelay, totalDelay=$newDelayedTime, storedAt=$newStoredAt');
      return true;
    } catch (e) {
      debugPrint('❌ Error reducing ETA on prepared: $e');
      return false;
    }
  }

  /// Replace ETA with a new value directly (used when seller updates prep time via +/- buttons).
  /// Unlike setEta(), this does NOT add to remaining time — it overwrites eta with [etaMinutes]
  /// and resets stored_at to now. If the document doesn't exist, it creates one.
  /// [orderId] - The order ID
  /// [etaMinutes] - New prep time in minutes (must be 5-120)
  /// [sellerCount] - Number of sellers (default 1)
  Future<bool> replaceEta({
    required int orderId,
    required int etaMinutes,
    int sellerCount = 1,
  }) async {
    try {
      if (etaMinutes < 5 || etaMinutes > 120) {
        debugPrint('❌ ETA must be between 5 and 120 minutes');
        return false;
      }

      final now = DateTime.now();
      final storedAt = _formatTimeString(now);

      final docRef = _firestore.collection('order_eta').doc(orderId.toString());
      final docSnapshot = await docRef.get();

      if (docSnapshot.exists) {
        await docRef.update({
          'eta': etaMinutes,
          'stored_at': storedAt,
          'updated_at': FieldValue.serverTimestamp(),
          'seller_count': sellerCount,
          'is_preparation': 1,
        });
      } else {
        await docRef.set({
          'order_id': orderId,
          'eta': etaMinutes,
          'stored_at': storedAt,
          'updated_at': FieldValue.serverTimestamp(),
          'seller_count': sellerCount,
          'delayed_time': null,
          'is_preparation': 1,
        });
      }

      debugPrint(
          '✅ ETA replaced for order $orderId: newEta=$etaMinutes min at $storedAt');
      return true;
    } catch (e) {
      debugPrint('❌ Error replacing ETA: $e');
      return false;
    }
  }

  /// Listen to real-time ETA changes for an order
  Stream<OrderEta?> listenToOrderEta({required int orderId}) {
    return _firestore
        .collection('order_eta')
        .doc(orderId.toString())
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
        return null;
      }
      return OrderEta.fromFirestore(snapshot.data()!);
    }).handleError((error) {
      debugPrint('❌ Firebase ETA listener error: $error');
      return null;
    });
  }

  /// Get current ETA snapshot for an order
  Future<OrderEta?> getOrderEta({required int orderId}) async {
    try {
      final snapshot = await _firestore
          .collection('order_eta')
          .doc(orderId.toString())
          .get();

      if (!snapshot.exists || snapshot.data() == null) {
        return null;
      }

      return OrderEta.fromFirestore(snapshot.data()!);
    } catch (e) {
      debugPrint('❌ Error getting ETA snapshot: $e');
      return null;
    }
  }

  /// Calculate elapsed minutes from stored_at to now
  /// [storedAt] - Time string in "H:MM AM/PM" or "HH:MM AM/PM" format
  int _calculateElapsedMinutes(String storedAt) {
    try {
      final startTime = _parseTimeString(storedAt);
      final now = DateTime.now();
      final elapsed = now.difference(startTime);
      return elapsed.inMinutes;
    } catch (e) {
      debugPrint('❌ Error calculating elapsed time: $e');
      return 0;
    }
  }

  /// Calculate remaining minutes from stored_at and eta
  int _calculateRemainingMinutes(String storedAt, int eta) {
    final elapsed = _calculateElapsedMinutes(storedAt);
    final remaining = eta - elapsed;
    return remaining > 0 ? remaining : 0;
  }

  /// Format DateTime to "H:MM AM/PM" or "HH:MM AM/PM" format
  String _formatTimeString(DateTime time) {
    final hour =
        time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';

    return '$hour:$minute $period';
  }

  /// Parse time string in "H:MM AM/PM" or "HH:MM AM/PM" format to DateTime
  /// Returns DateTime object for today (or yesterday if time hasn't occurred yet)
  DateTime _parseTimeString(String timeString) {
    final parts = timeString.trim().split(' ');
    if (parts.length != 2) {
      throw FormatException(
          'Invalid time format. Expected "H:MM AM/PM", got "$timeString"');
    }

    final timeParts = parts[0].split(':');
    if (timeParts.length != 2) {
      throw FormatException(
          'Invalid time format. Expected "H:MM AM/PM", got "$timeString"');
    }

    int hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);
    final isPM = parts[1].toUpperCase() == 'PM';

    // Convert to 24-hour format
    if (isPM && hour != 12) {
      hour += 12;
    } else if (!isPM && hour == 12) {
      hour = 0;
    }

    final now = DateTime.now();
    var targetTime = DateTime(now.year, now.month, now.day, hour, minute);

    // If target time is significantly in the past, it was likely set earlier today
    // or yesterday (handle edge cases like 11:59 PM → 12:01 AM transitions)
    if (now.difference(targetTime).inHours > 12) {
      targetTime = targetTime.add(Duration(days: 1));
    } else if (targetTime.difference(now).inHours > 12) {
      targetTime = targetTime.subtract(Duration(days: 1));
    }

    return targetTime;
  }
}

/// Model class for Order ETA data
class OrderEta {
  final int orderId;
  final int eta; // Current ETA in minutes (seller preparation time)
  final String storedAt; // "H:MM AM/PM" when ETA was set/updated
  final DateTime updatedAt; // ISO timestamp
  final int sellerCount; // Number of sellers
  final int? delayedTime; // Tracking accumulated delays
  final int?
      isPreparation; // Flag indicating preparation status (1 = in preparation)

  OrderEta({
    required this.orderId,
    required this.eta,
    required this.storedAt,
    required this.updatedAt,
    required this.sellerCount,
    this.delayedTime,
    this.isPreparation,
  });

  /// Get remaining minutes from now
  int get remainingMinutes {
    final service = FirebaseEtaService();
    final remaining = service._calculateRemainingMinutes(storedAt, eta);
    return remaining > 0 ? remaining : 0;
  }

  /// Get remaining duration as Duration object
  Duration get remainingDuration {
    return Duration(minutes: remainingMinutes);
  }

  /// Check if ETA has expired
  bool get isExpired => remainingMinutes <= 0;

  /// Check if ETA is urgent (5 minutes or less)
  bool get isUrgent => remainingMinutes <= 5 && remainingMinutes > 0;

  /// Parse from Firestore document data
  factory OrderEta.fromFirestore(Map<String, dynamic> json) {
    // Parse updated_at - handle both Timestamp and string formats
    late DateTime updatedAt;
    if (json['updated_at'] is Timestamp) {
      updatedAt = (json['updated_at'] as Timestamp).toDate();
    } else if (json['updated_at'] is String) {
      updatedAt = DateTime.parse(json['updated_at']);
    } else {
      updatedAt = DateTime.now();
    }

    return OrderEta(
      orderId: json['order_id'] ?? 0,
      eta: json['eta'] ?? 0,
      storedAt: json['stored_at'] ?? '',
      updatedAt: updatedAt,
      sellerCount: json['seller_count'] ?? 1,
      delayedTime: json['delayed_time'],
      isPreparation: json['is_preparation'],
    );
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'order_id': orderId,
      'eta': eta,
      'stored_at': storedAt,
      'updated_at': updatedAt.toIso8601String(),
      'seller_count': sellerCount,
      'delayed_time': delayedTime,
      'is_preparation': isPreparation,
    };
  }

  @override
  String toString() {
    return 'OrderEta(orderId: $orderId, eta: $eta, storedAt: $storedAt, '
        'remaining: $remainingMinutes min, seller_count: $sellerCount)';
  }
}
