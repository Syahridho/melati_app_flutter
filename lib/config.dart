import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static String get baseUrl =>
      dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:8000/api';
  static String get apiKey => dotenv.env['API_KEY'] ?? '';
  static const apiKeyHeader = 'X-API-KEY';
  static int get channelId =>
      int.tryParse(dotenv.env['CHANNEL_ID'] ?? '') ?? 1;
}