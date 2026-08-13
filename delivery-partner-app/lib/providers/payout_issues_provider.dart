import 'dart:io';

import 'package:flutter/material.dart';
import '../repository/help_center/payout_issues/payout_issues_repository.dart';
import '../services/status.dart';

class PayoutIssuesProvider extends ChangeNotifier {
  final PayoutIssuesRepository _repo = PayoutIssuesRepository();

  ApiResponse joiningBonusState = ApiResponse.nothing();

  Future<void> joiningBonus({
    required String description,
  }) async {
    joiningBonusState = ApiResponse.loading();
    notifyListeners();

    joiningBonusState = await _repo.joiningBonus(description: description);

    notifyListeners();
  }

  ApiResponse getPayoutWeeksState = ApiResponse.nothing();

  Future<void> getPayoutWeeks() async {
    getPayoutWeeksState = ApiResponse.loading();
    notifyListeners();

    getPayoutWeeksState = await _repo.payoutWeeks();

    notifyListeners();
  }

  ApiResponse getWeekTransactionsState = ApiResponse.nothing();

  Future<void> getWeekTransactions({
    required String week,
  }) async {
    getWeekTransactionsState = ApiResponse.loading();
    notifyListeners();

    getWeekTransactionsState = await _repo.getweektransactions(week: week);

    notifyListeners();
  }

  // ============= payout bank details =============
  ApiResponse payoutBankState = ApiResponse.nothing();

  Future<void> payoutBank({
    required String description,
    required String issueType,
    required List<int> issueIds,
    List<File>? attachments,
  }) async {
    payoutBankState = ApiResponse.loading();
    notifyListeners();

    payoutBankState = await _repo.payoutBank(
      description: description,
      issueType: issueType,
      issueIds: issueIds,
      attachments: attachments,
    );

    notifyListeners();
  }

  //=========== incentive =============

  ApiResponse getIncentiveWeeksState = ApiResponse.nothing();

  Future<void> getIncentiveWeeks() async {
    getIncentiveWeeksState = ApiResponse.loading();
    notifyListeners();

    getIncentiveWeeksState = await _repo.incentiveWeeks();

    notifyListeners();
  }

  ApiResponse getWeekIncentiveTransactionsState = ApiResponse.nothing();

  Future<void> getWeekIncentiveTransactions({
    required String week,
  }) async {
    getWeekIncentiveTransactionsState = ApiResponse.loading();
    notifyListeners();

    getWeekIncentiveTransactionsState =
        await _repo.getWeekIncentiveTransactions(week: week);

    notifyListeners();
  }

  ApiResponse incentiveBankState = ApiResponse.nothing();

  Future<void> incentiveBank({
    required String description,
    required String issueType,
    required List<int> issueIds,
    List<File>? attachments,
  }) async {
    incentiveBankState = ApiResponse.loading();
    notifyListeners();

    incentiveBankState = await _repo.incentiveBank(
      description: description,
      issueType: issueType,
      issueIds: issueIds,
      attachments: attachments,
    );

    notifyListeners();
  }

  //============== Multi order ===============

  ApiResponse multiOrderWeeksState = ApiResponse.nothing();

  Future<void> multiOrderWeeks() async {
    multiOrderWeeksState = ApiResponse.loading();
    notifyListeners();

    multiOrderWeeksState = await _repo.multiOrderWeeks();

    notifyListeners();
  }

  ApiResponse getWeekMultiOrderTransactionsState = ApiResponse.nothing();

  Future<void> getWeekMultiOrderTransactions({
    required String week,
  }) async {
    getWeekMultiOrderTransactionsState = ApiResponse.loading();
    notifyListeners();

    getWeekMultiOrderTransactionsState =
        await _repo.getWeekMultiOrderTransactions(week: week);

    notifyListeners();
  }

  ApiResponse multiOrderBankState = ApiResponse.nothing();

  Future<void> multiOrderBank({
    required String description,
    required String issueType,
    required List<int> issueIds,
    List<File>? attachments,
  }) async {
    multiOrderBankState = ApiResponse.loading();
    notifyListeners();

    multiOrderBankState = await _repo.multiOrderBank(
      description: description,
      issueType: issueType,
      issueIds: issueIds,
      attachments: attachments,
    );

    notifyListeners();
  }
}
