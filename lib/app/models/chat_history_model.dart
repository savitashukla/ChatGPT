import 'package:uuid/uuid.dart';

class ChatHistoryMessage {
  final String id;
  final String text;
  final String sender;
  final DateTime timestamp;
  final String? sessionId;

  ChatHistoryMessage({
    String? id,
    required this.text,
    required this.sender,
    required this.timestamp,
    this.sessionId,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'sender': sender,
    'timestamp': timestamp.toIso8601String(),
    'sessionId': sessionId,
  };

  factory ChatHistoryMessage.fromJson(Map<String, dynamic> json) => ChatHistoryMessage(
    id: json['id'],
    text: json['text'],
    sender: json['sender'],
    timestamp: DateTime.parse(json['timestamp']),
    sessionId: json['sessionId'],
  );

  bool get isUser => sender == "user";
}
