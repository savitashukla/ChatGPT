import 'dart:async';

import 'package:chat_gpt/app/data/app_constants.dart';
import 'package:chat_gpt/app/models/answer_model.dart';
import 'package:chat_gpt/app/widgets/chat_message.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';

// RAG Service imports with correct paths
import '../../../data/rag_service.dart';
import '../../../data/document_processing_service.dart';


class HomeController extends GetxController {
  final TextEditingController textController = TextEditingController();
  final RxList<ChatMessage> messages = <ChatMessage>[].obs;

  StreamSubscription? subscription;
  RxBool isTyping = false.obs;

  // Voice search related variables
  final SpeechToText _speechToText = SpeechToText();
  RxBool isListening = false.obs;
  RxBool speechEnabled = false.obs;
  RxString lastWords = ''.obs;

  // RAG Services
  final RAGService _ragService = RAGService();
  final DocumentProcessingService _docService = DocumentProcessingService();
  RxBool isRAGEnabled = false.obs;
  RxInt documentsCount = 0.obs;

  @override
  void onInit() {
    //getGeminiModels();
    initSpeechState();
    checkKnowledgeBase();
    super.onInit();
  }

  @override
  void onClose() {
    subscription?.cancel();
    super.onClose();
  }

  void sendMessage() {
    if (textController.text.isEmpty) return;
    ChatMessage message = ChatMessage(
      text: textController.text,
      sender: "user",
    );
    messages.insert(0, message);
    isTyping.value = true;
    apiCall(msg: textController.text.trim());
    textController.clear();
  }

  void insertNewData(String response) {
    ChatMessage botMessage = ChatMessage(
      text: response,
      sender: "bot",
    );

    isTyping.value = false;
    messages.insert(0, botMessage);
  }

  /// Initialize speech recognition
  Future<void> initSpeechState() async {
    await checkMicrophonePermission();
    speechEnabled.value = await _speechToText.initialize();
  }

  /// Start/stop listening for voice input
  void toggleListening() async {
    if (!speechEnabled.value) {
      await initSpeechState();
      return;
    }

    if (!isListening.value) {
      // Start listening
      textController.clear();
      lastWords.value = '';

      await _speechToText.listen(
        onResult: (result) {
          lastWords.value = result.recognizedWords;
          textController.text = result.recognizedWords;

          // If the user stops speaking and we have final results
          if (result.finalResult && result.recognizedWords.isNotEmpty) {
            sendVoiceMessage(result.recognizedWords);
          }
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
      );
      isListening.value = true;
    } else {
      // Stop listening
      await _speechToText.stop();
      isListening.value = false;

      // Send the message if we have text
      if (lastWords.value.isNotEmpty) {
        sendVoiceMessage(lastWords.value);
      }
    }
  }

  /// Send voice message
  void sendVoiceMessage(String text) {
    if (text.isEmpty) return;

    textController.text = text;
    sendMessage();

    // Stop listening after sending
    if (isListening.value) {
      _speechToText.stop();
      isListening.value = false;
    }
  }

  /// Check microphone permission
  Future<void> checkMicrophonePermission() async {
    var status = await Permission.microphone.status;
    if (!status.isGranted) {
      status = await Permission.microphone.request();
      if (!status.isGranted) {
        Get.snackbar(
          'Permission Required',
          'Microphone permission is required for voice search',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    }
  }

  Widget buildChatTextEditor() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          // Microphone button
          Obx(() => Container(
                margin: const EdgeInsets.only(right: 8, top: 5, bottom: 5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isListening.value ? Colors.red : Colors.grey,
                ),
                child: IconButton(
                  icon: Icon(
                    isListening.value ? Icons.mic : Icons.mic_none,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    toggleListening();
                  },
                ),
              )),

          // Text field
          Expanded(
            child: Obx(() => TextField(
                  controller: textController,
                  onSubmitted: (value) => sendMessage(),
                  decoration: InputDecoration.collapsed(
                    hintText: isListening.value
                        ? "Listening..."
                        : "Ask question here or tap mic to speak...",
                  ),
                )),
          ),

          // Send button
          Container(
            margin: const EdgeInsets.only(left: 8, top: 5, bottom: 5),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.blue,
            ),
            child: isListening.value?SizedBox.shrink():IconButton(
              icon: const Icon(
                Icons.send,
                color: Colors.white,
              ),
              onPressed: () {
                sendMessage();
              },
            ),
          ),
        ],
      ),
    );
  }

  Dio dio = Dio();

  /// this method is used to get response from Gemini api

  void apiCall({required String msg}) async {
    try {
      isTyping.value = true;
      String response;

      // Check if RAG is enabled and knowledge base exists
      if (isRAGEnabled.value && await _ragService.hasKnowledgeBase()) {
        // Use RAG for enhanced responses
        response = await _ragService.ragQuery(msg);
      } else {
        // Fallback to normal Gemini API
        response = await _normalGeminiCall(msg);
      }

      insertNewData(response);

    } catch (e) {
      print('Error in API call: $e');
      isTyping.value = false;
      insertNewData("Error: Unable to get response");
    }
  }

  /// Normal Gemini API call (fallback)
  Future<String> _normalGeminiCall(String msg) async {
    dio.options.headers['content-Type'] = 'application/json';

    Map<String, dynamic> data = {
      "contents": [
        {
          "parts": [
            {"text": msg}
          ]
        }
      ]
    };

    var response = await dio.post(
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=AIzaSyD1eKN8QyDlPxduNzhlQMzsZFIKUG_1ZOw",
      data: data,
    );

    if (response.statusCode == 200) {
      final responseData = response.data;
      final candidates = responseData['candidates'] as List?;

      if (candidates != null && candidates.isNotEmpty) {
        final content = candidates[0]['content'];
        final parts = content['parts'] as List;
        return parts[0]['text'] ?? 'No response generated';
      }
    }
    throw Exception('Failed to get response from Gemini');
  }

  /// Check if knowledge base exists and update RAG status
  Future<void> checkKnowledgeBase() async {
    bool hasKB = await _ragService.hasKnowledgeBase();

    if (hasKB) {
      var stats = await _ragService.getKnowledgeBaseStats();
      documentsCount.value = stats['documents'] ?? 0;

      // Only auto-enable RAG if it was previously disabled and we now have documents
      if (!isRAGEnabled.value && documentsCount.value > 0) {
        isRAGEnabled.value = true;

        // Add welcome message
        ChatMessage welcomeMessage = ChatMessage(
          text: "🎉 RAG is now available! I can answer questions based on your ${documentsCount.value} uploaded document(s). Try asking me about the content!",
          sender: "bot",
        );
        messages.insert(0, welcomeMessage);
      }
    } else {
      documentsCount.value = 0;

      // Add helpful message if no documents and RAG is enabled
      if (isRAGEnabled.value) {
        ChatMessage helpMessage = ChatMessage(
          text: "📚 To use RAG (smart document-based responses):\n\n1️⃣ Tap the menu (⋮) in the top-right\n2️⃣ Select 'Upload Document' for PDF/TXT files\n3️⃣ OR select 'Add Knowledge' to type information manually\n4️⃣ Then ask questions about your content!\n\n💡 You can toggle RAG mode anytime from the menu.",
          sender: "bot",
        );
        messages.insert(0, helpMessage);
      }
    }
  }

  /// Upload and process document for RAG
  Future<void> uploadDocument() async {
    try {
      isTyping.value = true;

      bool success = await _docService.pickAndProcessDocument();

      if (success) {
        Get.snackbar(
          'Success',
          'Document uploaded and processed successfully!',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );

        await checkKnowledgeBase();

        // Add system message about document upload
        ChatMessage systemMessage = ChatMessage(
          text: "📄 Document has been successfully added to knowledge base. You can now ask questions about its content!",
          sender: "bot",
        );
        messages.insert(0, systemMessage);

      } else {
        Get.snackbar(
          'Error',
          'Failed to process document. Please try again.',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      print('Error uploading document: $e');
      Get.snackbar(
        'Error',
        'Error processing document: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isTyping.value = false;
    }
  }

  /// Add text knowledge directly
  Future<void> addTextKnowledge() async {
    TextEditingController titleController = TextEditingController();
    TextEditingController contentController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: const Text('Add Knowledge'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: contentController,
              decoration: const InputDecoration(
                labelText: 'Content',
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.isNotEmpty && contentController.text.isNotEmpty) {
                Get.back();

                isTyping.value = true;
                bool success = await _docService.addTextKnowledge(
                  titleController.text,
                  contentController.text,
                );

                if (success) {
                  Get.snackbar(
                    'Success',
                    'Knowledge added successfully!',
                    backgroundColor: Colors.green,
                    colorText: Colors.white,
                  );

                  await checkKnowledgeBase();

                  ChatMessage systemMessage = ChatMessage(
                    text: "✅ New knowledge has been added to the knowledge base!",
                    sender: "bot",
                  );
                  messages.insert(0, systemMessage);
                }
                isTyping.value = false;
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  /// Toggle RAG mode
  void toggleRAG() {
    isRAGEnabled.value = !isRAGEnabled.value;

    String status = isRAGEnabled.value ? "enabled" : "disabled";
    ChatMessage systemMessage = ChatMessage(
      text: "🤖 RAG mode has been $status. ${isRAGEnabled.value ? 'I can now answer based on your uploaded documents.' : 'I will use general knowledge only.'}",
      sender: "bot",
    );
    messages.insert(0, systemMessage);
  }

  /// Get knowledge base statistics
  Future<void> showKnowledgeBaseStats() async {
    var stats = await _ragService.getKnowledgeBaseStats();

    Get.dialog(
      AlertDialog(
        title: const Text('Knowledge Base Statistics'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Documents: ${stats['documents']}'),
            Text('Text Chunks: ${stats['chunks']}'),
            const SizedBox(height: 16),
            Text('RAG Status: ${isRAGEnabled.value ? "Enabled" : "Disabled"}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
