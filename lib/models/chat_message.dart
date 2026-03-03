class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });

  @override
  String toString() => 'ChatMessage(text: $text, isUser: $isUser, timestamp: $timestamp)';
}
