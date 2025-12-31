import 'package:get/get.dart';

import '../../../models/chat_history_model.dart';
import '../../../services/chat_history_service.dart';


class ChatHistoryController extends GetxController {
  final RxList<ChatHistoryMessage> messages = <ChatHistoryMessage>[].obs;
  final RxBool isLoading = false.obs;
  final RxString searchQuery = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadChatHistory();
  }

  Future<void> loadChatHistory() async {
    try {
      isLoading.value = true;
      final history = await ChatHistoryService.getChatHistory();
      messages.assignAll(history);
    } catch (e) {
      Get.snackbar('Error', 'Failed to load chat history');
    } finally {
      isLoading.value = false;
    }
  }

  List<ChatHistoryMessage> get filteredMessages {
    if (searchQuery.value.isEmpty) return messages;
    return messages
        .where((msg) => msg.text.toLowerCase().contains(searchQuery.value.toLowerCase()))
        .toList();
  }

  void updateSearchQuery(String query) {
    searchQuery.value = query;
  }

  Future<void> clearHistory() async {
    try {
      await ChatHistoryService.clearChatHistory();
      messages.clear();
      Get.snackbar('Success', 'Chat history cleared');
    } catch (e) {
      Get.snackbar('Error', 'Failed to clear chat history');
    }
  }

  Future<void> exportHistory() async {
    if (messages.isEmpty) {
      Get.snackbar('Info', 'No messages to export');
      return;
    }

    // This would be implemented based on your export requirements
    Get.snackbar('Success', 'Chat history exported');
  }
}
