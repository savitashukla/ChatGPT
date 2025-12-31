import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat_history_model.dart';

class ChatHistoryService {
  static const String _chatHistoryKey = 'chat_history';
  static const String _currentSessionKey = 'current_session';

  static Future<void> saveChatMessage(ChatHistoryMessage message) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final history = await getChatHistory();

      // Add new message to beginning of list (latest first)
      history.insert(0, message);

      // Keep only last 1000 messages to avoid storage issues
      if (history.length > 1000) {
        history.removeRange(1000, history.length);
      }

      final jsonList = history.map((msg) => msg.toJson()).toList();
      await prefs.setString(_chatHistoryKey, json.encode(jsonList));
    } catch (e) {
      print('Error saving chat message: $e');
    }
  }

  static Future<List<ChatHistoryMessage>> getChatHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString(_chatHistoryKey);

      if (historyJson == null || historyJson.isEmpty) return [];

      final List<dynamic> jsonList = json.decode(historyJson);
      return jsonList.map((json) => ChatHistoryMessage.fromJson(json)).toList();
    } catch (e) {
      print('Error loading chat history: $e');
      return [];
    }
  }

  static Future<void> clearChatHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_chatHistoryKey);
      await prefs.remove(_currentSessionKey);
    } catch (e) {
      print('Error clearing chat history: $e');
    }
  }

  static Future<String> getCurrentSessionId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? sessionId = prefs.getString(_currentSessionKey);

      if (sessionId == null) {
        sessionId = DateTime.now().millisecondsSinceEpoch.toString();
        await prefs.setString(_currentSessionKey, sessionId);
      }

      return sessionId;
    } catch (e) {
      return DateTime.now().millisecondsSinceEpoch.toString();
    }
  }

  static Future<void> startNewSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final newSessionId = DateTime.now().millisecondsSinceEpoch.toString();
      await prefs.setString(_currentSessionKey, newSessionId);
    } catch (e) {
      print('Error starting new session: $e');
    }
  }

  static Future<List<ChatHistoryMessage>> getMessagesByDate(DateTime date) async {
    try {
      final allMessages = await getChatHistory();
      return allMessages.where((msg) {
        return msg.timestamp.year == date.year &&
               msg.timestamp.month == date.month &&
               msg.timestamp.day == date.day;
      }).toList();
    } catch (e) {
      print('Error getting messages by date: $e');
      return [];
    }
  }

  static Future<int> getMessageCount() async {
    try {
      final history = await getChatHistory();
      return history.length;
    } catch (e) {
      return 0;
    }
  }
}
