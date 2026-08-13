// constants.dart

class AppUrl {
  static const String baseUrl = 'https://wheat-rook-708688.hostingersite.com';
  static const String imageUrl = '';

  //  AUTH APIs
  static const String sendOtp = '$baseUrl/api/delivery-boy/send-otp';
  static const String verifyOtp = '$baseUrl/api/delivery-boy/verify-otp';
  static const String getPersonalDetails =
      '$baseUrl/api/delivery_boy/get-personal-details';
  static const String updatePersonalDetails =
      '$baseUrl/api/delivery_boy/update-personal-details';
  static const String getVehicles = '$baseUrl/api/delivery_boy/vehicles';
  static const String selectVehicle =
      '$baseUrl/api/delivery_boy/select-vehicle';
  static const String getNearbyCities =
      '$baseUrl/api/delivery_boy/nearby-cities';
  static const String updateCity = '$baseUrl/api/delivery_boy/update-city';
  static const String getStoreLocations =
      '$baseUrl/api/delivery_boy/store-locations';
  static const String selectStoreLocations =
      '$baseUrl/api/delivery_boy/select-store-locations';
  static const String updateProfileImage =
      '$baseUrl/api/delivery_boy/update-profile-image';

  // Document APIs
  static const String uploadAllDocuments =
      '$baseUrl/api/delivery_boy/upload-all-documents';
  static const String updateDocuments =
      '$baseUrl/api/delivery_boy/update-documents';
  static const String getDocuments = '$baseUrl/api/delivery_boy/get-documents';
  static const String getOrderDetails =
      '$baseUrl/api/delivery-boy/orders/seller-locations';
  static const String acceptOrder = '$baseUrl/api/delivery-boy/orders/accept';
  static const String rejectOrder = '$baseUrl/api/delivery-boy/orders/reject';
  static String generateQr(int orderId) =>
      '$baseUrl/api/delivery-boy/orders/generate-qr?order_id=$orderId';
  static const String orderCancelled = '$baseUrl/api/delivery-boy/order-cancelled';
  static const String markDelivered = '$baseUrl/api/delivery-boy/orders/mark-delivered';
  static const String getOrderSellerData =
      '$baseUrl/api/delivery-boy/orders/seller-details';
  static const String getOrderSummary =
      '$baseUrl/api/delivery-boy/orders/summary';
  static const String verifyDeliveryPin =
      '$baseUrl/api/delivery-boy/orders/verify-pin';
  static const String notifyArrival =
      '$baseUrl/api/delivery-boy/orders/notify-arrival';

  static const String requestOtp = '$baseUrl/driver/msg91';
  static const String mobileCheck = '$baseUrl/driver/mobile_check';
  static const String verifyOtpOld = '$baseUrl/driver/otp_verify';
  static const String signup = '$baseUrl/driver/signup';
  static const String login = '$baseUrl/driver/login';

  // Signup
  static const String driverSignup = '$baseUrl/driver/signup';

  // Profile & Vehicle
  static String driverProfileImage(String id) =>
      '$baseUrl/driver/profile-image/$id';
  static const String addVehicle = '$baseUrl/driver/add_driver_vehicle';

  // Uploads
  static const String uploadAadhar = '$baseUrl/api/file-upload/upload/aadhar';
  static const String uploadBank = '$baseUrl/api/file-upload/upload/bank';
  static const String uploadRc = '$baseUrl/api/file-upload/upload/licience';
  static const String uploadLicense =
      '$baseUrl/api/file-upload/upload/licience';
  static const String uploadInsurance =
      '$baseUrl/api/file-upload/upload/insurence';
  static const String uploadPollution =
      '$baseUrl/api/file-upload/upload/pollution';

  // Add details
  static const String addAadhar = '$baseUrl/driver/add_driver_aadhar';
  static const String addBank = '$baseUrl/driver/add_driver_bankaccount';
  static const String addRc = '$baseUrl/driver/add_driver_rc';
  static const String addLicense = '$baseUrl/driver/add_driver_license';
  static const String addInsurance = '$baseUrl/driver/add_driver_insurance';
  static const String addPollution = '$baseUrl/driver/add_driver_pollution';

  // Approve
  static const String approveDriver = '$baseUrl/driver/approve_driver_on_own';

  // Gig Management APIs
  static const String getAvailableGigs =
      '$baseUrl/api/delivery_boy/available-gigs';
  static const String getGigDetails = '$baseUrl/api/delivery_boy/gig-details';
  static const String bookGig = '$baseUrl/api/delivery_boy/book-gig';
  static const String getMyBookings = '$baseUrl/api/delivery_boy/my-bookings';
  static const String cancelBooking =
      '$baseUrl/api/delivery_boy/cancel-booking';
  static const String completeGig = '$baseUrl/api/delivery_boy/complete-gig';
  static const String getGigHistory = '$baseUrl/api/delivery_boy/gig-history';

  // Session Management APIs
  static const String startSession = '$baseUrl/api/delivery_boy/start-session';
  static const String endSession = '$baseUrl/api/delivery_boy/end-session';
  static const String updateLocation =
      '$baseUrl/api/delivery_boy/update-location';
  static const String getTodayStats =
      '$baseUrl/api/delivery_boy/tracking/today';
  static const String getActiveSession =
      '$baseUrl/api/delivery_boy/tracking/active';

  // Incentive Offers APIs
  static const String getActiveOffers =
      '$baseUrl/api/delivery_boy/active-offers';
  static const String getOfferDetails =
      '$baseUrl/api/delivery_boy/offer-details';
  static const String getMyOfferProgress =
      '$baseUrl/api/delivery_boy/my-offer-progress';
  static const String getAllOffers = '$baseUrl/api/delivery_boy/all-offers';

  // Order Priority APIs
  static const String getOrderPriority =
      '$baseUrl/api/delivery_boy/get-order-priority';
  static const String updateOrderPriority =
      '$baseUrl/api/delivery_boy/update-order-priority';

  // Learning APIs
  static const String getLearningTopics = '$baseUrl/api/learning/topics';
  static String getTopicDetails(int topicId) =>
      '$baseUrl/api/learning/topic/$topicId';

  // Notification APIs
  static const String getNotifications =
      '$baseUrl/api/notifications/delivery_boy_notifications';

  // Emergency Contacts APIs
  static const String emergencyContacts =
      '$baseUrl/api/delivery_boy/emergency-contacts';

  static const String emergencyContacts2 =
      '$baseUrl/api/delivery-boy/emergency-contacts';

  // Performance/Earnings APIs
  static const String performanceEarnings =
      '$baseUrl/api/delivery-boy/performance/earnings';

  // Tips APIs
  static const String weeklyTips = '$baseUrl/api/delivery-boy/tips/weekly';

  // Floating Cash APIs
  static const String floatingCash =
      '$baseUrl/api/delivery-boy/performance/floating-cash';

  // Order Earnings APIs
  static const String orderEarnings =
      '$baseUrl/api/delivery-boy/performance/order-earnings';

  // Multi-Order Earnings APIs
  static const String multiOrderEarnings =
      '$baseUrl/api/delivery-boy/performance/multi-order-earnings';
  static const String multiOrderDetail =
      '$baseUrl/api/delivery-boy/performance/multi-order-detail';

  // Weekly Summary APIs
  static const String weeklySummary =
      '$baseUrl/api/delivery-boy/performance/weekly-summary';

  // Payout History APIs
  static const String payoutHistory =
      '$baseUrl/api/delivery-boy/performance/payout-history';

  // Payout Sections (Earnings Breakdown) APIs
  static const String earningsSections =
      '$baseUrl/api/delivery-boy/performance/earnings-sections';

  // Trip History APIs
  static const String tripHistory = '$baseUrl/api/delivery-boy/trip-history';

  // App Settings APIs
  static const String appSettings = '$baseUrl/api/delivery_boy/settings';

  // Language APIs
  static const String systemLanguages = '$baseUrl/api/system_languages';

  // Chat APIs
  static const String sendChatMessage = '$baseUrl/api/order/chat/send-auth';
  static const String sendSupportChatMessage =
      '$baseUrl/api/delivery-boy/support-chat/send';
  static const String sendOrderSupportChatMessage =
      '$baseUrl/api/delivery-boy/support-chat/order/send';

  // FCM Token APIs
  static const String updateFcmToken =
      '$baseUrl/api/delivery_boy/update-fcm-token';

  // Payment Status APIs
  static const String paymentStatus =
      '$baseUrl/api/delivery-boy/payment/status';

  // Update personal details

  // change phone number
  static const String sentOtpToMobile =
      '$baseUrl/api/delivery_boy/send-mobile-update-otp?mobile';

  static const String getPhoneNumber = '$baseUrl/api/delivery_boy/get-mobile';
  static const String verifyPhoneNumber =
      '$baseUrl/api/delivery_boy/verify-mobile-update-otp';

// change pan
  static const String getPan = '$baseUrl/api/delivery_boy/get-pan';
  static const String updatePan = '$baseUrl/api/delivery_boy/update-pan';

// change driving license
  static const String getLicense =
      '$baseUrl/api/delivery_boy/get-driving-license';
  static const String updateLicense =
      '$baseUrl/api/delivery_boy/update-driving-license';

// order earning issue
  static const String getOrderEarningIssue =
      '$baseUrl/api/delivery-boy/order-history';

  static const String orderEarningIssueDetails =
      '$baseUrl/api/delivery-boy/issues/submit';

// payout issues
  static const String driverIssues = '$baseUrl/api/delivery-boy/issues';

// joining bonus
  static const String joiningBonus = '$baseUrl/api/delivery-boy/issues/submit';

// payout
  static const String payoutWeeks =
      '$baseUrl/api/delivery-boy/transactions/by-week?type=payout';
  static const String getWeekPayoutTransactions =
      '$baseUrl/api/delivery-boy/transactions/by-week';
  static const String payoutBank = '$baseUrl/api/delivery-boy/issues/submit';

// incentives
  static const String incentiveWeeks =
      '$baseUrl/api/delivery-boy/transactions/by-week?type=incentive';
  static const String getWeekIncentiveTransactions =
      '$baseUrl/api/delivery-boy/transactions/by-week';
  static const String incentiveBank = '$baseUrl/api/delivery-boy/issues/submit';

// Multi order

  static const String multiOrderWeeks =
      '$baseUrl/api/delivery-boy/transactions/by-week?type=multi_order';
  static const String getWeekMultiOrderTransactions =
      '$baseUrl/api/delivery-boy/transactions/by-week';
  static const String multiOrderBank =
      '$baseUrl/api/delivery-boy/issues/submit';

// pocketting
  static const String pockettingIssue =
      '$baseUrl/api/delivery-boy/issues/submit';

// extra floating deposited
  static const String extraFloatingDeposited =
      '$baseUrl/api/delivery-boy/issues/submit';

// duty issues
  static const String notGettingOrders =
      '$baseUrl/api/delivery-boy/help/not-getting-orders';

  static const String ordersIssue = '$baseUrl/api/delivery-boy/issues/submit';

// terms and conditions

  static const String termsAndConditions =
      '$baseUrl/delivery-boy-terms-conditions';

  // About Us
  static const String aboutUs = '$baseUrl/customer/about-us';

// deposit cash
  static const String depositCash = '$baseUrl/api/delivery-boy/hand-cash';
  static const String paytmConfig = '$baseUrl/api/delivery-boy/paytm/config';
  static const String generatePaytmToken =
      '$baseUrl/api/delivery-boy/hand-cash/generate-paytm-token';
  static const String settleHandCash =
      '$baseUrl/api/delivery-boy/hand-cash/settle';

// ratings
  static const String ratings = '$baseUrl/api/delivery-boy/ratings';

  // Delete Account
  static const String deleteAccount =
      '$baseUrl/api/delivery_boy/delete_delivery_boy_account';

  // Referral Tracking APIs
  static const String referralTracking =
      '$baseUrl/api/delivery_boy/referral-tracking';

  // Admin Payment Details API
  static const String adminPaymentDetails =
      '$baseUrl/api/delivery-boy/admin-payment-details';

  // Banner APIs
  static const String driverBanners =
      '$baseUrl/api/home_slider_images/by_type?type=driver';
  static const String driverLoginBanners =
      '$baseUrl/api/home_slider_images/by_type?type=driver_login';

  // Support Contacts API
  static const String supportContacts =
      '$baseUrl/api/support-contacts?app=driver';

  // Chatbot APIs
  static const String getChatbotQuestions =
      '$baseUrl/api/delivery-boy/chatbot/questions';
  static const String submitChatbotAnswer =
      '$baseUrl/api/delivery-boy/chatbot/answer';

  // Payment Proof APIs
  static const String submitPaymentProof =
      '$baseUrl/api/delivery-boy/submit-payment-proof';
  static const String manualPaymentHistory =
      '$baseUrl/api/delivery-boy/manual-payment-history';

  // Weather APIs
  static const String weatherRainCheck =
      '$baseUrl/api/delivery-boy/weather/rain-check';
}

// Shorter alias for easier access
class AppUrls {
  static const String sendOtp = AppUrl.sendOtp;
  static const String verifyOtp = AppUrl.verifyOtp;
  static const String getPersonalDetails = AppUrl.getPersonalDetails;
  static const String updatePersonalDetails = AppUrl.updatePersonalDetails;
  static const String getVehicles = AppUrl.getVehicles;
  static const String selectVehicle = AppUrl.selectVehicle;
  static const String getNearbyCities = AppUrl.getNearbyCities;
  static const String updateCity = AppUrl.updateCity;
  static const String getStoreLocations = AppUrl.getStoreLocations;
  static const String selectStoreLocations = AppUrl.selectStoreLocations;
  static const String updateProfileImage = AppUrl.updateProfileImage;
  static const String uploadAllDocuments = AppUrl.uploadAllDocuments;
  static const String updateDocuments = AppUrl.updateDocuments;
  static const String getDocuments = AppUrl.getDocuments;
  static const String getorderDetails = AppUrl.getOrderDetails;
  static const String acceptOrder = AppUrl.acceptOrder;
  static const String rejectOrder = AppUrl.rejectOrder;
  static const String getOrderSummary = AppUrl.getOrderSummary;
  static const String verifyDeliveryPin = AppUrl.verifyDeliveryPin;
  static const String getAvailableGigs = AppUrl.getAvailableGigs;
  static const String getGigDetails = AppUrl.getGigDetails;
  static const String bookGig = AppUrl.bookGig;
  static const String myBookings = AppUrl.getMyBookings;
  static const String cancelBooking = AppUrl.cancelBooking;
  static const String completeGig = AppUrl.completeGig;
  static const String getGigHistory = AppUrl.getGigHistory;
  static const String startSession = AppUrl.startSession;
  static const String endSession = AppUrl.endSession;
  static const String updateLocation = AppUrl.updateLocation;
  static const String getTodayStats = AppUrl.getTodayStats;
  static const String getActiveSession = AppUrl.getActiveSession;
  static const String getActiveOffers = AppUrl.getActiveOffers;
  static const String getOfferDetails = AppUrl.getOfferDetails;
  static const String getMyOfferProgress = AppUrl.getMyOfferProgress;
  static const String getAllOffers = AppUrl.getAllOffers;
  static const String getOrderPriority = AppUrl.getOrderPriority;
  static const String updateOrderPriority = AppUrl.updateOrderPriority;
  static const String getLearningTopics = AppUrl.getLearningTopics;
  static String getTopicDetails(int topicId) => AppUrl.getTopicDetails(topicId);
  static const String getNotifications = AppUrl.getNotifications;
  static const String emergencyContacts = AppUrl.emergencyContacts;
  static const String getOrderSellerData = AppUrl.getOrderSellerData;
  static const String tripHistory = AppUrl.tripHistory;
  static const String sentOtpToMobile = AppUrl.sentOtpToMobile;
  static const String getPhoneNumber = AppUrl.getPhoneNumber;
  static const String verifyPhoneNumber = AppUrl.verifyPhoneNumber;
  static const String getPan = AppUrl.getPan;
  static const String updatePan = AppUrl.updatePan;
  static const String getLicense = AppUrl.getLicense;
  static const String updateLicense = AppUrl.updateLicense;
  static const String getOrderEarningIssue = AppUrl.getOrderEarningIssue;
  static const String orderEarningIssueDetails =
      AppUrl.orderEarningIssueDetails;
  static const String joiningBonus = AppUrl.joiningBonus;
  static const String weeks = AppUrl.payoutWeeks;
  static const String getweektransactions = AppUrl.getWeekPayoutTransactions;
  static const String payoutBank = AppUrl.payoutBank;
  static const String incentiveWeeks = AppUrl.incentiveWeeks;
  static const String getWeekIncentiveTransactions =
      AppUrl.getWeekIncentiveTransactions;
  static const String incentiveBank = AppUrl.incentiveBank;
  static const String multiOrderWeeks = AppUrl.multiOrderWeeks;
  static const String getWeekMultiOrderTransactions =
      AppUrl.getWeekMultiOrderTransactions;
  static const String multiOrderBank = AppUrl.multiOrderBank;
  static const String pockettingIssue = AppUrl.pockettingIssue;
  static const String notGettingOrders = AppUrl.notGettingOrders;
  static const String ordersIssue = AppUrl.ordersIssue;
  static const String termsAndConditions = AppUrl.termsAndConditions;
  static const String depositCash = AppUrl.depositCash;
  static const String ratings = AppUrl.ratings;
}
