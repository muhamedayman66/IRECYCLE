class SharedKeys {
  static const String isLoggedIn = 'isLoggedIn';
  static const String userId = 'userId';
  static const String userEmail = 'user_email';
  static const String userPassword = 'user_password';
  static const String userType = 'user_type';
  static const String onboardingSeen = 'onboardingSeen';
  static const String recycleBagItems = 'recycleBagItems';
  static const String userPoints = 'userPoints';
  static const String orderStatus = 'orderStatus';
  static const String rewardShown = 'rewardShown';
  static const String lastEarnedPoints = 'lastEarnedPoints';
  static const String activityHistory = 'activityHistory';
  static const String showRecycleBagDot = 'showRecycleBagDot';
  static const String userAddress = 'user_address';
  static const String lastTransactionShown = 'last_transaction_shown';
  static const String userGovernorate = 'user_governorate';
  static const String lastAssignmentId = 'last_assignment_id';
  static String lastEarnedShown(String email) => '${email}_lastEarnedShown';

  // User-specific keys
  static String balanceKey(String email) => 'balance_$email';
  static String pointsKey(String email) => 'points_$email';
  static String voucherKey(String email) => 'voucher_$email';
  static String lastTransactionKey(String email) => 'last_transaction_$email';
  static const userFirstName = 'user_first_name';
  static const userLastName = 'user_last_name';
  static String itemsRecycledKey(String email) => 'items_recycled_$email';
  static String co2SavedKey(String email) => 'co2_saved_$email';
  static const String wasOnOrderStatusScreen =
      'wasOnOrderStatusScreen'; // Will be removed later
  static const String orderStatusResumeEmail = 'orderStatusResumeEmail';
}
