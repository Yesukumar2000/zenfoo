import 'package:project/helper/utils/generalImports.dart';

/// Validates a friend's referral code so the UI can give immediate feedback.
/// Non-blocking by design — a failure just resolves to "not valid" rather than
/// throwing, so signup is never held up by this check.
Future<Map<String, dynamic>> validateReferralCodeApi({
  required BuildContext context,
  required String referralCode,
}) async {
  try {
    var response = await sendApiRequest(
      apiName: ApiAndParams.apiValidateReferralCode,
      params: {
        ApiAndParams.referralCode: referralCode,
      },
      isPost: true,
      context: context,
    );
    return json.decode(response);
  } catch (e) {
    return {"status": 0, "valid": false, "message": e.toString()};
  }
}

/// Fetches the logged-in user's referral earnings summary.
Future<Map<String, dynamic>> getReferralStatsApi({
  required BuildContext context,
}) async {
  try {
    var response = await sendApiRequest(
      apiName: ApiAndParams.apiReferralStats,
      params: {},
      isPost: false,
      context: context,
    );
    return json.decode(response);
  } catch (e) {
    throw e.toString();
  }
}
