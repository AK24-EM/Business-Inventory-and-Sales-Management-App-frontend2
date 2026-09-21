class ApiConfig {
  ApiConfig._();

  // Official Google Cloud Run Production API
  static const String baseUrl = "https://storeiq-api-72855384303.asia-south1.run.app";

  // Endpoints
  static const String authLogin = "/auth/login";
  static const String authRegister = "/auth/register";
  static const String authMe = "/auth/me";
  static const String users = "/auth/users";

  static const String stores = "/stores";
  static const String products = "/products";
  static const String inventory = "/inventory";
  static const String sales = "/sales";
  static const String customers = "/customers";
  static const String suppliers = "/suppliers";
  static const String analytics = "/analytics";
}
