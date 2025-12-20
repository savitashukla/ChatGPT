import 'package:flutter/material.dart';

import 'package:get/get.dart';

import '../../../widgets/three_dots.dart';
import '../controllers/home_controller.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("ChatGPT with RAG"),
          actions: [
            // Connection Status Indicator
            Obx(() => Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: controller.connectionService.isConnected
                    ? (controller.connectionService.isOnlineMode ? Colors.green : Colors.blue)
                    : Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      controller.connectionService.isConnected
                        ? (controller.connectionService.isOnlineMode ? Icons.cloud : Icons.offline_bolt)
                        : Icons.cloud_off,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      controller.getCurrentModeStatus().split(' ')[1], // Get just the mode part
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            )),

            // RAG Status Indicator
            Obx(() => Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: controller.isRAGEnabled.value ? Colors.green : Colors.grey,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      controller.isRAGEnabled.value ? Icons.smart_toy : Icons.chat,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      controller.isRAGEnabled.value ? 'RAG ON' : 'RAG OFF',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            )),

            // Menu Button
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'upload_doc':
                    controller.uploadDocument();
                    break;
                  case 'add_knowledge':
                    controller.addTextKnowledge();
                    break;
                  case 'toggle_rag':
                    controller.toggleRAG();
                    break;
                  case 'toggle_mode':
                    controller.toggleConnectionMode();
                    break;
                  case 'model_status':
                    controller.showModelStatus();
                    break;
                  case 'download_models':
                    controller.showTFLiteModelsDialog();
                    break;
                  case 'stats':
                    controller.showKnowledgeBaseStats();
                    break;
                }
              },
              itemBuilder: (BuildContext context) => [
                const PopupMenuItem<String>(
                  value: 'upload_doc',
                  child: ListTile(
                    leading: Icon(Icons.upload_file),
                    title: Text('Upload Document'),
                    subtitle: Text('PDF or TXT files'),
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'add_knowledge',
                  child: ListTile(
                    leading: Icon(Icons.add_circle),
                    title: Text('Add Knowledge'),
                    subtitle: Text('Add text manually'),
                  ),
                ),
                const PopupMenuDivider(),
                PopupMenuItem<String>(
                  value: 'toggle_rag',
                  child: Obx(() => ListTile(
                    leading: Icon(
                      controller.isRAGEnabled.value ? Icons.toggle_on : Icons.toggle_off,
                      color: controller.isRAGEnabled.value ? Colors.green : Colors.grey,
                    ),
                    title: Text('${controller.isRAGEnabled.value ? 'Disable' : 'Enable'} RAG'),
                    subtitle: Text('Toggle smart responses'),
                  )),
                ),
                PopupMenuItem<String>(
                  value: 'toggle_mode',
                  child: Obx(() => ListTile(
                    leading: Icon(
                      controller.connectionService.isOnlineMode ? Icons.offline_bolt : Icons.cloud,
                      color: controller.connectionService.isConnected
                        ? Colors.blue
                        : Colors.grey,
                    ),
                    title: Text('Switch to ${controller.connectionService.isOnlineMode ? 'Offline' : 'Online'} Mode'),
                    subtitle: Text('Toggle connection mode'),
                  )),
                ),
                const PopupMenuItem<String>(
                  value: 'model_status',
                  child: ListTile(
                    leading: Icon(Icons.info),
                    title: Text('Model Status'),
                    subtitle: Text('View AI model info'),
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'stats',
                  child: ListTile(
                    leading: Icon(Icons.info_outline),
                    title: Text('Knowledge Stats'),
                    subtitle: Text('View database info'),
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem<String>(
                  value: 'download_models',
                  child: ListTile(
                    leading:     Icon(Icons.download),
                    title: Text('Download TFLite Models'),
                    subtitle: Text('Manage TensorFlow Lite models'),
                  ),
                ),
              ],
            ),
          ],
        ),
        body: SafeArea(
          child: Obx(() => Column(
            children: [
              // Knowledge Base Status Bar
              if (controller.documentsCount.value > 0)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  color: Colors.blue.withValues(alpha: 0.1),
                  child: Obx(() => Row(
                    children: [
                      const Icon(Icons.storage, size: 16, color: Colors.blue),
                      const SizedBox(width: 8),
                      Text(
                        '${controller.documentsCount.value} document(s) in knowledge base',
                        style: const TextStyle(
                          color: Colors.blue,
                          fontSize: 12,
                        ),
                      ),
                      const Spacer(),
                      if (controller.isRAGEnabled.value)
                        const Text(
                          '🧠 Smart mode active',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  )),
                ),

              Flexible(
                  child: ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemCount: controller.messages.length,
                    itemBuilder: (context, index) {
                      return controller.messages[index];
                    },
                  )),
              if (controller.isTyping.value) const ThreeDots(),
              const Divider(
                height: 1.0,
              ),
              Card(
                child: controller.buildChatTextEditor(),
              )
            ],
          )),
        ));
  }
}
