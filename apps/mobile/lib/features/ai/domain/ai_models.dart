enum ChatRole { user, assistant, system }

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.role,
    required this.text,
    required this.at,
  });

  final String id;
  final ChatRole role;
  final String text;
  final DateTime at;
}

class AiSuggestion {
  const AiSuggestion({required this.label, required this.prompt});
  final String label;
  final String prompt;
}
