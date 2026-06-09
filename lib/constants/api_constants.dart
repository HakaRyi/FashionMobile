class ApiConstants {
  //static const String baseUrl = "http://10.0.2.2:5196/api";
  // static const String baseUrl = "http://192.168.1.7:5196/api";
  // static const String baseUrl = "http://192.168.102.24:5196/api";
  static const String baseUrl = "https://fashionwebbe.onrender.com/api";

  static const String baseAIUrl = "https://unconceded-softly-lola.ngrok-free.dev";

  // const String baseSignalRUrl = "http://10.0.2.2:5196";
  // static const String baseSignalRUrl = "http://192.168.1.7:5196";
  // static const String baseSignalRUrl = "http://192.168.102.24:5196";
  static const String baseSignalRUrl = "https://fashionwebbe.onrender.com";

  static const String signalRHubUrl = "$baseSignalRUrl/chatHub";

  static const String refreshTokenEndpoint = "/auth/refresh";
  static const String chatEndpoint = "/Chat";
  static const String groupEndpoint = "/Group";
  static const String logoutEndpoint = "/auth/logout";

  static const String loginEndpoint = "/auth/login";
  static const String registerEndpoint = "/auth/register";
  static const String googleLoginEndpoint = "/auth/google-login";

  static const String tryOnEndpoint = "/TryOn/try-on";
  static const String tryOnInfoEndpoint = "/TryOn/info";
  static const String tryOnHistoryEndpoint = "/TryOnHistory/my-history";
  static const String tryOnHistoryDeleteEndpoint = "/TryOnHistory";

  static const String createPostEndpoint = "/Post";
  static const String feedEndpoint = "/post/feed";
  static const String getMyPostEndpoint = "/post/me";
  static const String getAllPostEndpoint = "/post";

  static const String createPost = "/post";
  static const String feed = "/post/feed";
  static const String trendingPosts = "/post/trending";
  static const String getPostDetail = "/post/{postId}";
  static const String getMyPosts = "/post/me";
  static const String getUserPosts = "/post/user/{userId}";
  static const String hidePost = "/post/{postId}/hide";
  static const String unhidePost = "/post/{postId}/unhide";
  static const String updatePost = "/post/{postId}";
  static const String deletePost = "/post/{postId}";

  static const String toggleSavePost = "/post/{postId}/save";
  static const String getSavedPosts = "/post/saved";
  static const String sharePost = "/post/{postId}/share";

  static const String getComments = "/post/{postId}/comment";
  static const String createComment = "/post/{postId}/comment";
  static const String getReplies = "/comment/{commentId}/replies";
  static const String replyComment = "/comment/{commentId}/replies";
  static const String updateComment = "/comment/{commentId}";
  static const String deleteComment = "/comment/{commentId}";

  static const String togglePostLike = "/post/{postId}/like";
  static const String toggleCommentLike = "/comment/{commentId}/like";

  static const String getPendingAdminPosts = "/admin/post/pending-admin";
  static const String getRejectedPosts = "/admin/post/rejected";
  static const String updateAdminPostStatus = "/admin/post/{postId}/status";

  static const String getMyProfile = "/Account/{id}";

  static const String uploadItemEndpoint = "/items";
  static const String AIidentityClothesEndpoint = "/analyze-fashion";
  static const String getAllMyItemEndpoint = "/items/me";
  static const String getAllMyItemsEndpoint = "/items/my-item";
  static const String updateItemEndpoint = "/items/{itemId}";
  static const String deleteItemEndpoint = "/items/{itemId}";
  static const String smartMatchEndpoint = "/items/smart-match";
  static const String getItemByIdEndpoint = "/items/{itemId}";
  static const String publicItemDetailEndpoint = "/items/public/{itemId}";

  static const String saveItemEndpoint = "/items/{itemId}/save";
  static const String getMySaveItemEndpoint = "/items/saved";

  static const String publishItemEndpoint = "/items/{itemId}/publish";
  static const String unpublishItemEndpoint = "/items/{itemId}/unpublish";
  static const String getItemVariantsEndpoint = "/items/{itemId}/variants";
  static const String createItemVariantEndpoint = "/items/{itemId}/variants";
  static const String updateItemVariantEndpoint = "/items/variants/{itemVariantId}";
  static const String deleteItemVariantEndpoint = "/items/variants/{itemVariantId}";

  static const String topUpWallet = "/payment/topup/vnpay";
  static const String topUpWalletZaloPay = "/payment/topup/zalopay";

  static const String publicWardrobes = "/public-wardrobes";
  static const String searchWardrobeByUsernameEndpoint = "/wardrobes/search-by-username";
  static const String publicProfileEndpoint = "/wardrobes/public/{accountId}/profile";
  static const String publicWardrobeItemsEndpoint = "/wardrobes/public/{accountId}/items";

  static const String publicEventsEndpoint = "/events/public/all";

  static const String followEndpoint = "/Follow";
  static const String getFollowersEndpoint = "/Post";
  static const String getShareableUsersEndpoint = "/Follow/get-shareable-users";

  static const String reportTypes = "/reports/types";
  static const String reportPost = "/reports/posts/{postId}";

  static const String getMySpendingLimitEndpoint = "/expenses/me/spending-limit";
  static const String updateMySpendingLimitEndpoint = "/expenses/me/spending-limit";

  static const String sharePostToChatEndpoint = "/Chat/share-post";

  // ====================
  // Orders
  // ====================
  static const String orderBase = "/orders";

  static String createOrder(int sellerId) => "$orderBase/$sellerId";

  static String payOrder(int orderId) => "$orderBase/$orderId/pay";

  static String getOrderById(int orderId) => "$orderBase/$orderId";

  static const String getMySales = "$orderBase/sales/me";
  static const String getMyPurchases = "$orderBase/purchases/me";

  static String updateOrderStatus(int orderId, String status) =>
      "$orderBase/$orderId/status?status=${Uri.encodeComponent(status)}";

  static String shipperUpdate(int orderId, String status) =>
      "$orderBase/$orderId/shipper?status=${Uri.encodeComponent(status)}";

  static String createRefund(int orderId) => "$orderBase/$orderId/refund";

  static const String getAllRefunds = "$orderBase/refunds";
  static const String getMyRefunds = "$orderBase/refunds/me";

  static String approveRefund(int orderId) =>
      "$orderBase/$orderId/refund/approve";

  static String rejectRefund(int orderId, String note) =>
      "$orderBase/$orderId/refund/reject?note=${Uri.encodeComponent(note)}";

  static String getMySalesFiltered({
    int page = 1,
    int pageSize = 10,
    String? status,
    DateTime? fromDate,
    DateTime? toDate,
    String? buyerName,
    String? orderCode,
  }) {
    final query = <String, String>{
      'page': page.toString(),
      'pageSize': pageSize.toString(),
    };

    if (status != null && status.trim().isNotEmpty) {
      query['status'] = status.trim();
    }

    if (fromDate != null) {
      query['fromDate'] = fromDate.toIso8601String();
    }

    if (toDate != null) {
      query['toDate'] = toDate.toIso8601String();
    }

    if (buyerName != null && buyerName.trim().isNotEmpty) {
      query['buyerName'] = buyerName.trim();
    }

    if (orderCode != null && orderCode.trim().isNotEmpty) {
      query['orderCode'] = orderCode.trim();
    }

    return Uri(path: getMySales, queryParameters: query).toString();
  }

  static String getMyPurchasesFiltered({
    int page = 1,
    int pageSize = 10,
    String? status,
    DateTime? fromDate,
    DateTime? toDate,
    String? sellerName,
    String? orderCode,
  }) {
    final query = <String, String>{
      'page': page.toString(),
      'pageSize': pageSize.toString(),
    };

    if (status != null && status.trim().isNotEmpty) {
      query['status'] = status.trim();
    }

    if (fromDate != null) {
      query['fromDate'] = fromDate.toIso8601String();
    }

    if (toDate != null) {
      query['toDate'] = toDate.toIso8601String();
    }

    if (sellerName != null && sellerName.trim().isNotEmpty) {
      query['sellerName'] = sellerName.trim();
    }

    if (orderCode != null && orderCode.trim().isNotEmpty) {
      query['orderCode'] = orderCode.trim();
    }

    return Uri(path: getMyPurchases, queryParameters: query).toString();
  }

  static const String notificationBase = "/notifications";

  static const String getMyNotifications = "$notificationBase/me";

  static String markNotificationAsRead(int notificationId) =>
      "$notificationBase/$notificationId/read";

  static const String markAllNotificationsAsRead =
      "$notificationBase/read-all";
  static const String trendingHashtags = "/post/hashtags/trending";
  static const String getPostsByHashtag = "/post/hashtags/{tagName}/posts";
  static const String hashtagSuggestions = "/post/hashtags/suggestions";
  static String confirmReturnReceived(int orderId) => "$orderBase/$orderId/return/confirm";
}