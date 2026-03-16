class ApiConstants {
  // static const String baseUrl = "http://10.0.2.2:5196/api";
  static const String baseUrl = "http://192.168.102.24:5196/api";

  static const String baseAIUrl = "http://10.0.2.2:8000";

  static const String refreshTokenEndpoint = "/Auth/refresh-token";
  static const String loginEndpoint = "/Auth/login";
  static const String registerEndpoint = "/Auth/register";

  static const String tryOnEndpoint = "/TryOn/try-on";

  static const String getMyProfile = "/Account/{id}";

  static const String uploadItemEndpoint = "/item/upload";
  static const String AIidentityClothesEndpoint = "/analyze-fashion";
  static const String getAllMyItemEndpoint = "/my-items";

  static const String createPost = "/posts";
  static const String feed = "/posts/feed";
  static const String trendingPosts = "/posts/trending";
  static const String getPostDetail = "/posts/{postId}";
  static const String getMyPosts = "/posts/me";
  static const String getUserPosts = "/posts/user/{userId}";

  static const String toggleSavePost = "/posts/{postId}/save";
  static const String getSavedPosts = "/posts/saved";

  static const String getComments = "/posts/{postId}/comments";
  static const String createComment = "/posts/{postId}/comments";
  static const String getReplies = "/comments/{commentId}/replies";
  static const String replyComment = "/comments/{commentId}/replies";
  static const String updateComment = "/comments/{commentId}";
  static const String deleteComment = "/comments/{commentId}";

  static const String togglePostLike = "/posts/{postId}/like";
  static const String toggleCommentLike = "/comments/{commentId}/like";
}