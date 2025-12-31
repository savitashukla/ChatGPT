import 'package:get/get.dart';

import '../modules/home/bindings/home_binding.dart';
import '../modules/home/views/home_view.dart';
import '../modules/chat_history/views/chat_history_view.dart';
import '../modules/chat_history/controllers/chat_history_controller.dart';

part 'app_routes.dart';

class AppPages {
  AppPages._();

  static const INITIAL = Routes.HOME;

  static final routes = [
    GetPage(
      name: _Paths.HOME,
      page: () => const HomeView(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: _Paths.CHAT_HISTORY,
      page: () => const ChatHistoryScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut<ChatHistoryController>(() => ChatHistoryController());
      }),
    ),
  ];
}
