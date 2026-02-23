class ApiConstants {
  static const String baseUrl = "http://10.0.2.2:5196/api";
  //cac endpoint
  static const String refreshTokenEndpoint = "/Auth/refresh-token";

  static const String loginEndpoint = "/Auth/login";
  static const String registerEndpoint = "/Auth/register";

  static const String tryOnEndpoint = "/TryOn/try-on";
  static const String createPostEndpoint = "/Post";

  static const String getMyPostEndpoint = "/Post/getMyPost";
  static const String getAllPostEndpoint = "/Post"; //cho admin nma dang test cho trang home 22/2
}