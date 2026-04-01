// lib/constants/api_constants.dart
class ApiConstants {
  // static const String baseUrl = "http://10.0.2.2:5196/api";
  static const String baseUrl = "http://192.168.102.24:5196/api";

  static const String baseAIUrl = "http://10.0.2.2:8000";
  static const String baseSignalRUrl = "http://10.0.2.2:5196";
  static const String refreshTokenEndpoint = "/Auth/refresh-token";

  static const String loginEndpoint = "/Auth/login";
  static const String registerEndpoint = "/Auth/register";

  static const String tryOnEndpoint = "/TryOn/try-on";
  static const String createPostEndpoint = "/Post";

  static const String getMyPostEndpoint = "/Post/my";
  static const String getAllPostEndpoint = "/Post";

  static const String getMyProfile = "/Account/{id}";

  static const String uploadItemEndpoint = "/item/upload";
  static const String AIidentityClothesEndpoint = "/analyze-fashion";
  static const String getAllMyItemEndpoint = "/my-items";

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
  static const String sharePost = '/api/post/{postId}/share';

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
  static const String topUpWallet = "/payment/create-order-vnpay";

  static const String publicWardrobes = "/public-wardrobes";
  static const String publicProfileEndpoint = "/wardrobes/public/{accountId}/profile";
  static const String publicWardrobeItemsEndpoint = "/wardrobes/public/{accountId}/items";
  static const String publicItemDetailEndpoint = "/items/public/{itemId}";
}