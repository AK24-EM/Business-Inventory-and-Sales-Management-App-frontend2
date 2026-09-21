/// Legacy Cloud Run HTTP helper.
///
/// The app no longer uses this for data. All screens persist through
/// Firestore. Methods return null and never throw so a stale caller cannot
/// crash the web client with `Exception: unauthenticated`.
class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  Future<dynamic> get(String path, {Map<String, dynamic>? queryParams}) async =>
      null;

  Future<dynamic> post(String path, {dynamic body}) async => null;

  Future<dynamic> patch(String path, {dynamic body}) async => null;

  Future<dynamic> delete(String path) async => null;
}
