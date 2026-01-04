class ChatModel {
  final String id;
  final List<String> participants;
  final String lastMessage;
  final int lastMessageTimestamp;
  final Map<String, int> unreadCounts;

  ChatModel({
    required this.id,
    required this.participants,
    this.lastMessage = '',
    this.lastMessageTimestamp = 0,
    this.unreadCounts = const {},
  });

  factory ChatModel.fromMap(String id, Map<String, dynamic> map) {
    return ChatModel(
      id: id,
      participants: List<String>.from(map['participants'] ?? []),
      lastMessage: map['lastMessage'] ?? '',
      lastMessageTimestamp: map['lastMessageTimestamp'] ?? 0,
      unreadCounts: Map<String, int>.from(map['unreadCounts'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'participants': participants,
      'lastMessage': lastMessage,
      'lastMessageTimestamp': lastMessageTimestamp,
      'unreadCounts': unreadCounts,
    };
  }
}

class MessageModel {
  final String id;
  final String senderId;
  final String text;
  final int timestamp;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.text,
    required this.timestamp,
  });

  factory MessageModel.fromMap(String id, Map<String, dynamic> map) {
    return MessageModel(
      id: id,
      senderId: map['senderId'] ?? '',
      text: map['text'] ?? '',
      timestamp: map['timestamp'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {'senderId': senderId, 'text': text, 'timestamp': timestamp};
  }
}
