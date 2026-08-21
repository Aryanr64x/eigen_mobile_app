class ApiConstants {
  ApiConstants._();
  static const String baseUrl = 'https://eigen-backend.vercel.app';
  // static const String baseUrl = 'http://127.0.0.1:8000';

  // static const String baseUrl = 'http://192.168.1.7:8000'; 
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);
}