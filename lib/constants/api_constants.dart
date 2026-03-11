class ApiConstants {
  static const String baseUrl = "http://192.168.102.24:5196/api";
  
  static const String refreshTokenEndpoint = "/Auth/refresh-token";
  static const String loginEndpoint = "/Auth/login";
  static const String registerEndpoint = "/Auth/register";

  static const String tryOnEndpoint = "/TryOn/try-on";
  static const String createPostEndpoint = "/Post";

  static const String feedEndpoint = "/Post/feed";

  static const String getMyPostEndpoint = "/Post/my";
  static const String getMyProfile = "/Account/{id}";

  static const String toggleLike = "/posts/{postId}/like";

  static const String getLikeCount = "/posts/{postId}/likes/count";

  static const String comments = "/posts/{postId}/comments";
  static const String createComment = "/posts/{postId}/comments";

  static const String commentById = "/comments/{commentId}";
}