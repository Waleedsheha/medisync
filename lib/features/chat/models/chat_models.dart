class ChatMessage {
  final String id;
  final String conversationId;
  final String senderId;
  final String body;
  final DateTime createdAt;
  final String? senderName; // Joined from profiles

  ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.body,
    required this.createdAt,
    this.senderName,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      conversationId: json['conversation_id'],
      senderId: json['sender_id'],
      body: json['body'],
      createdAt: DateTime.parse(json['created_at']),
      senderName: json['profiles']?['full_name'],
    );
  }

  bool get isMine => false; // Helper to be set by UI
}

class ChatConversation {
  final String id;
  final String? name;
  final bool isGroup;
  final DateTime createdAt;
  final String? lastMessage; // Computed/Joined
  final DateTime? lastMessageAt;

  ChatConversation({
    required this.id,
    this.name,
    required this.isGroup,
    required this.createdAt,
    this.lastMessage,
    this.lastMessageAt,
  });

  factory ChatConversation.fromJson(Map<String, dynamic> json) {
    return ChatConversation(
      id: json['id'],
      name: json['name'],
      isGroup: json['is_group'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      // Note: Real last message fetching might need a more complex query or view
    );
  }
}
