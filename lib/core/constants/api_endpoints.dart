import 'dart:io';

class ApiEndpoints {
  // Dynamically resolve base URL depending on the running platform (Android emulator vs iOS simulator)
  static String get baseUrl {
    // Modify this IP if you are testing on a physical device (use your PC's local IP e.g. 192.168.X.X)
    // const String physicalDeviceIp = "192.168.1.100";
    
    try {
      if (Platform.isAndroid) {
        // Updated to PC local IP for physical Xiaomi device debugging
        return "http://192.168.0.237:8000/api/";
      } else if (Platform.isIOS) {
        return "http://127.0.0.1:8000/api/";
      }
    } catch (_) {
      // Fallback for web or desktop environments
      return "http://localhost:8000/api/";
    }
    return "http://192.168.0.237:8000/api/";
  }

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
