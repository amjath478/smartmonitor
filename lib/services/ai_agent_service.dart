import 'package:http/http.dart' as http;
import 'dart:convert';

class AIAgentService {
  static const String _baseUrl = 'https://skirtless-irremeably-eldridge.ngrok-free.dev';
  static const Duration _timeout = Duration(seconds: 30);

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
            Uri.parse('$_baseUrl/ask-ai'),
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
