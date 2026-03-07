/// Configuration Template - EXAMPLE FILE
/// 
/// Copy this file to app_config.dart and fill in your actual values.
/// The app_config.dart file should be added to .gitignore to keep secrets safe.
/// 
/// DO NOT commit app_config.dart with real API keys to version control!

class AppConfig {
  /// AI Agent Service Configuration
  /// Replace with your actual AI Agent base URL
  static const String aiAgentBaseUrl = 'https://your-ai-agent-url.ngrok-free.dev';
  
  /// AI Agent API timeout (in seconds)
  static const int aiAgentTimeoutSeconds = 30;
  
  /// AI Agent endpoint path
  static const String aiAgentAskPath = '/ask-ai';
  
  /// Full URL to the AI Agent ask endpoint
  static String get aiAgentAskUrl => '$aiAgentBaseUrl$aiAgentAskPath';
  
  // Firebase Configuration (if using Firebase)
  // static const String firebaseProjectId = 'your-project-id';
  // static const String firebaseApiKey = 'your-api-key';
  
  // Add more configurations as needed
  // Example: Other API keys, remote service URLs, feature flags, etc.
}
