class ApiConstants {
  //static const String baseUrl = 'http://10.0.2.2:8000';
  static const String baseUrl = 'https://cf81-156-209-67-30.ngrok-free.app';

  // User-related endpoints
  static const String registers = '$baseUrl/api/registers/';
  static const String registerCreate = '$baseUrl/api/registers/create/';
  static String registerUpdate(int id) => '$baseUrl/api/registers/$id/update/';
  static const String updatePassword = '$baseUrl/api/update_password/';
  static const String getUserProfile = '$baseUrl/api/get_user_profile/';
  static const String updateProfile = '$baseUrl/api/update_profile/';
  static const String generateQr = '$baseUrl/api/generate_qr_code_for_user/';

  // Delivery boy endpoints
  static const String deliveryBoys = '$baseUrl/api/delivery_boys/';
  static String deliveryBoyUpdate(int id) =>
      '$baseUrl/api/delivery_boys/$id/update/';

  // تحديث مسارات التوصيل
  static String availableOrders(String email) {
    final url = '$baseUrl/api/delivery/available_orders/$email/';
    print('Available orders URL: $url');
    return url;
  }

  static String acceptOrder(int assignmentId) =>
      '$baseUrl/api/assignments/$assignmentId/accept/';

  static String rejectOrder(int assignmentId) =>
      '$baseUrl/api/delivery/reject_order/$assignmentId/';

  static String verifyOrder(int assignmentId) =>
      '$baseUrl/api/assignments/$assignmentId/verify/';

  static String completeOrder(int assignmentId) =>
      '$baseUrl/api/assignments/$assignmentId/complete/';

  static String startDelivery(int assignmentId) => // New endpoint
      '$baseUrl/api/assignments/$assignmentId/start_delivery/';

  static String deliveryHistory(String email) {
    final url = '$baseUrl/api/delivery/history/$email/';
    print('Delivery history URL: $url');
    return url;
  }

  static String rateOrder(int assignmentId) =>
      '$baseUrl/api/delivery/rate_order/$assignmentId/';

  static String deliveryDashboard(String email) =>
      '$baseUrl/api/delivery/dashboard/$email/';

  static String getDeliveryBalance(String email) =>
      '$baseUrl/api/delivery-boy/balance/$email/';

  static String deliveryNotifications(String email) =>
      '$baseUrl/api/delivery/notifications/$email';

  static String markDeliveryNotificationAsRead(int notificationId) =>
      '$baseUrl/delivery/notifications/$notificationId/mark_as_read/';

  // Order and recycle bag endpoints
  static String userOrders(String email) => '$baseUrl/api/user_orders/$email/';
  static const String placeOrder = '$baseUrl/api/place_order/';
  static String recycleBagsPending(String email) =>
      '$baseUrl/api/get_pending_bags/$email/';
  static String confirmOrder(int bagId) => '$baseUrl/api/confirm_order/$bagId/';
  static String userRateOrder(int assignmentId) =>
      '$baseUrl/api/orders/rate/$assignmentId/';
  static String cancelOrder(int assignmentId) =>
      '$baseUrl/api/delivery/cancel_order/$assignmentId/';

  static String getAllBags(String email) => '$baseUrl/api/get_all_bags/$email/';
  static String updateOrderStatus(int bagId) =>
      '$baseUrl/api/update_order_status/$bagId/';

  // Store-related endpoints
  static const String stores = '$baseUrl/api/stores/';
  static String getStoreById(int id) => '$baseUrl/api/stores/$id/';
  static String getStoresByArea(String area) =>
      '$baseUrl/api/stores/area/$area/';
  static String getNearbyStores(double lat, double lng) =>
      '$baseUrl/api/stores/nearby/$lat/$lng/';

  // Notification endpoints
  static String notifications(String email) =>
      '$baseUrl/api/notifications/$email/';
  static String markNotificationAsRead(int notificationId) =>
      '$baseUrl/api/notifications/$notificationId/mark_as_read/';
  static String clearNotifications(String email) =>
      '$baseUrl/api/notifications/$email/clear/';

  // Activity endpoints
  static String activities(String email) => '$baseUrl/api/activities/$email/';
  static String addActivities(String email) =>
      '$baseUrl/api/activities/$email/add/';
  static String getActivityById(int id) => '$baseUrl/api/activities/$id/';
  static String getUserActivities(String email) =>
      '$baseUrl/api/user_activities/$email/';

  // Balance and rewards endpoints
  static String userBalance(String email) =>
      '$baseUrl/api/user_balance/$email/';
  static const String generateQrCode =
      '$baseUrl/api/generate_qr_code_for_user/';
  static String checkVoucherStatus(String email) =>
      '$baseUrl/api/check_voucher_status/$email/';
  static const String useQrCode = '$baseUrl/api/use_qr_code/';
  static String qrUsageHistory(String email) =>
      '$baseUrl/api/qr_usage_history/$email/';
  static String getRewards(String email) => '$baseUrl/api/rewards/$email/';
  static const String updatePointsAndRewards =
      '$baseUrl/api/update_points_and_rewards/';

  // Statistics endpoints
  static String totalRecycledItems(String email) =>
      '$baseUrl/api/total_recycled_items/$email/';
  static String getUserStats(String email) => '$baseUrl/api/user_stats/$email/';
  static String getMonthlyStats(String email) =>
      '$baseUrl/api/monthly_stats/$email/';
  static String getYearlyStats(String email) =>
      '$baseUrl/api/yearly_stats/$email/';

  // تحديث المسار للحصول على تفاصيل الطلب
  static String getOrder(int orderId) => '$baseUrl/api/orders/$orderId/';

  // Voucher and QR Code endpoints
  static String checkDeliveryVoucherStatus(String email) =>
      '$baseUrl/api/delivery-boy/voucher/status/$email/';

  static String getDeliveryVoucherHistory(String email) =>
      '$baseUrl/api/delivery-boy/voucher/list/$email/';

  static String generateDeliveryVoucher(String email) =>
      '$baseUrl/api/delivery-boy/voucher/generate/$email/';

  static String validateDeliveryVoucher(String voucherCode) =>
      '$baseUrl/api/delivery-boy/voucher/use/$voucherCode/';

  static String generateDeliveryQrCode(int assignmentId) =>
      '$baseUrl/api/delivery/generate_qr/$assignmentId/';

  static String validateDeliveryQrCode(String qrCode) =>
      '$baseUrl/api/delivery/validate_qr/$qrCode/';

  static String getDeliveryQrDetails(String qrCode) =>
      '$baseUrl/api/delivery/qr_details/$qrCode/';

  static String getDeliveryQrHistory(String email) =>
      '$baseUrl/api/delivery/qr_history/$email/';

  // Assignment endpoints
  static String getOrderAssignment(int orderId) =>
      '$baseUrl/api/orders/$orderId/assignment/';
  static String createAssignment() => '$baseUrl/api/assignments/create/';

  // Order status endpoint
  static String getUserOrderStatus(String email) {
    final url = '$baseUrl/api/orders/status/$email/';
    print('Order status URL: $url');
    return url;
  }

  // ===== الدردشة =====
  // الحصول على رسائل الدردشة للمهمة المحددة
  static String getChatMessages(int assignmentId, String requesterEmail) =>
      '$baseUrl/api/chat/get_messages/$assignmentId/?email=$requesterEmail';

  // إرسال رسالة جديدة في الدردشة
  static String sendChatMessage(int assignmentId) =>
      '$baseUrl/api/chat/send_message/$assignmentId/';

  // Order status endpoints
  static String getLatestOrder(String email) =>
      '$baseUrl/api/orders/latest/$email';

  static String generateDeliveryBoyVoucher(String email) =>
      '$baseUrl/api/delivery-boy/voucher/generate/$email/';
}
