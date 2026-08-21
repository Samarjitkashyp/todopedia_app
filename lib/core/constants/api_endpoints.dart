class ApiEndpoints {
  // Production backend on AWS Lightsail (Nginx -> Dockerized FastAPI),
  // served over HTTPS via DuckDNS + Let's Encrypt. All traffic is encrypted.
  static const String baseUrl = "https://topedia.duckdns.org/api/";

  // Auth endpoints
  static const String register = "auth/register/";
  static const String login = "auth/login/";
  static const String profile = "auth/profile/";
  static const String refreshToken = "auth/token/refresh/";

  // CRUD endpoints
  static const String categories = "categories/";
  static const String todos = "todos/";
  static const String stats = "todos/stats/";
}
