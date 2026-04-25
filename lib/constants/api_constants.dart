class ApiConstants {
   static const String baseUrl = "http://10.0.2.2:5196/api";
  // static const String baseUrl = "http://192.168.1.7:5196/api";
  //static const String baseUrl = "http://192.168.102.24:5196/api";

  static const String baseAIUrl = "https://retiform-illa-refinedly.ngrok-free.dev";
  static const String signalRHubUrl = "$baseSignalRUrl/chatHub";

  static const String baseSignalRUrl = "http://10.0.2.2:5196";
  // static const String baseSignalRUrl = "http://192.168.1.7:5196";
  //static const String baseSignalRUrl = "http://192.168.102.24:5196";

  static const String refreshTokenEndpoint = "/auth/refresh-token";
  static const String chatEndpoint = "/Chat";
  static const String groupEndpoint = "/Group";

  static const String loginEndpoint = "/auth/login";
  static const String registerEndpoint = "/auth/register";

  static const String tryOnEndpoint = "/TryOn/try-on";
  static const String tryOnInfoEndpoint = "/TryOn/info";
  static const String tryOnHistoryEndpoint = "/TryOnHistory/my-history";
  static const String tryOnHistoryDeleteEndpoint = "/TryOnHistory";

  static const String createPostEndpoint = "/Post";

  static const String feedEndpoint = "/post/feed";
  static const String getMyPostEndpoint = "/post/me";
  static const String getAllPostEndpoint = "/post";


  static const String getMyProfile = "/Account/{id}";

  static const String uploadItemEndpoint = "/items";
  static const String AIidentityClothesEndpoint = "/analyze-fashion";
  static const String getAllMyItemEndpoint = "/items/me";
  static const String getAllMyItemsEndpoint = "/items/my-item";
  static const String updateItemEndpoint = "/items/{itemId}";
  static const String deleteItemEndpoint = "/items/{itemId}";
  static const String smartMatchEndpoint = "/items/smart-match";

  static const String SaveItemEnpoint = "/items/{itemId}/saved";
  static const String DeleteItemEnpoint = "/items/{itemId}/saved";
  static const String getMySaveItemEnpoint = "/items/saved";

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

  static const String topUpWallet = "/payment/topup/vnpay";
  static const String topUpWalletZaloPay = "/payment/topup/zalopay";

  static const String publicWardrobes = "/public-wardrobes";
  static const String searchWardrobeByUsernameEndpoint = "/wardrobes/search-by-username"; // Tên theo controller ní vừa sửa
  static const String publicProfileEndpoint = "/wardrobes/public/{accountId}/profile";
  static const String publicWardrobeItemsEndpoint = "/wardrobes/public/{accountId}/items";
  static const String publicItemDetailEndpoint = "/items/public/{itemId}";

  static const String publicEventsEndpoint = "/events/public/all";

  static const String googleLoginEndpoint = "/auth/google-login";

  static const String followEndpoint = "/Follow";
  static const String getFollowersEndpoint = "/Post";

  static const String reportTypes = "/reports/types";
  static const String reportPost = "/reports/posts/{postId}";

  static const String getMySpendingLimitEndpoint = "/expenses/me/spending-limit";
  static const String updateMySpendingLimitEndpoint = "/expenses/me/spending-limit";
  static const String sharePostToChatEndpoint = "/Chat/share-post";
  static const String getShareableUsersEndpoint = "/Follow/get-shareable-users";
}