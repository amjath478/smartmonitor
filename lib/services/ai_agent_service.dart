import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/app_config.dart';

/// Configuration for AI Agent service
class AIAgentConfig {
  /// Base URL for AI Agent API (can be changed at runtime)
  /// Defaults to value from AppConfig, but can be overridden
  static String baseUrl = AppConfig.aiAgentBaseUrl;
  
  /// Set a new base URL (e.g., from environment or user config)
  static void setBaseUrl(String url) {
    baseUrl = url;
  }
  
  /// Reset to default URL from AppConfig
  static void resetBaseUrl() {
    baseUrl = AppConfig.aiAgentBaseUrl;
  }
}

class AIAgentService {
  static Duration _timeout = Duration(seconds: AppConfig.aiAgentTimeoutSeconds);
  
  /// Note: Base URL is loaded from AppConfig and can be overridden at runtime
  /// Change it at runtime with: AIAgentConfig.setBaseUrl('your-new-url')

  /// Send a message to the AI Agent
  /// 
  /// Returns the AI's reply text on success
  /// Throws an exception on network error or timeout
  Future<String> sendMessage({
    required String message,
    required String userId,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('${AIAgentConfig.baseUrl}${AppConfig.aiAgentAskPath}'),
            headers: {
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'message': message,
              'userId': userId,
            }),
          )
          .timeout(
            _timeout,
            onTimeout: () => throw TimeoutException('AI Agent request timed out after ${_timeout.inSeconds}s'),
          );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final reply = data['reply'] as String?;
        
        if (reply == null) {
          throw FormatException('Invalid response format: missing "reply" field');
        }
        
        return reply;
      } else {
        throw HttpException(
          'AI Agent returned status ${response.statusCode}: ${response.body}',
        );
      }
    } on TimeoutException {
      rethrow;
    } on HttpException {
      rethrow;
    } catch (e) {
      throw Exception('Error communicating with AI Agent: $e');
    }
  }
}

/// Custom exception for timeout
class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);

  @override
  String toString() => message;
}

/// Custom exception for HTTP errors
class HttpException implements Exception {
  final String message;
  HttpException(this.message);

  @override
  String toString() => message;
}
