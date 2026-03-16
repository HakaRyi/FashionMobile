class ApiConstants {
  static const String baseSignalRUrl = "http://10.0.2.2:5196";
  static const String baseUrl = "http://10.0.2.2:5196/api";
  static const String baseAIUrl = "http://10.0.2.2:8000";
  //cac endpoint
  static const String refreshTokenEndpoint = "/Auth/refresh-token";

  static const String loginEndpoint = "/Auth/login";
  static const String registerEndpoint = "/Auth/register";

  static const String tryOnEndpoint = "/TryOn/try-on";
  static const String createPostEndpoint = "/Post";

  static const String getMyPostEndpoint = "/Post/my";
  static const String getAllPostEndpoint = "/Post"; //cho admin nma dang test cho trang home 22/2

  static const String getMyProfile = "/Account/{id}";

  static const String uploadItemEndpoint = "/item/upload";
  static const String AIidentityClothesEndpoint = "/analyze-fashion";
  static const String getAllMyItemEndpoint = "/my-items";

}