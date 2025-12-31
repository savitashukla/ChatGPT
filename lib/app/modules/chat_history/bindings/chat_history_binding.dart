import 'package:get/get.dart';
import '../controllers/chat_history_controller.dart';

class ChatHistoryBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ChatHistoryController>(
      () => ChatHistoryController(),
    );
  }
}
