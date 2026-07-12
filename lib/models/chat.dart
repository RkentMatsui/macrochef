class ChatMessage {
  final String role; // 'system' | 'user' | 'assistant'
  final String content;
  const ChatMessage(this.role, this.content);
}

class ChatOpts {
  final String? model;
  final int? maxTokens;
  final double? temperature;
  const ChatOpts({this.model, this.maxTokens, this.temperature});
}
