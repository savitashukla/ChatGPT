import 'dart:async';

import 'package:chat_gpt/app/widgets/chat_message.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';

// RAG Service imports with correct paths
import '../../../data/rag_service.dart';
import '../../../data/document_processing_service.dart';
import '../../../data/app_constants.dart'; // Import for secure API keys

import '../../../../services/offline_ml_service.dart';
import '../../../../services/connection_service.dart';
import '../../../../services/tflite_model_manager.dart';
import '../../../models/chat_history_model.dart';
import '../../../services/chat_history_service.dart';

// Chat History imports



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

  // Offline ML Service
  final OfflineMLService _offlineMLService = OfflineMLService();
  RxBool isOfflineMLModelLoaded = false.obs;

  // Connection Service
  late final ConnectionService connectionService;

  // TensorFlow Lite Model Manager
  final TFLiteModelManager _tfliteModelManager = TFLiteModelManager();

  @override
  void onInit() {
    super.onInit();
    // Initialize connection service properly from GetX DI
    connectionService = Get.find<ConnectionService>();

    // Force check connection immediately on init
    Future.delayed(const Duration(milliseconds: 100), () async {
      print('🚀 Starting connection check...');
      await connectionService.forceCheckConnection();
      print('🚀 Forced connection check completed on app start');
    });

    //getGeminiModels();
    initSpeechState();
    checkKnowledgeBase();
    _loadOfflineMLModel();
    _showNewYearGreeting();

    // Add debug logging for connection status
    _debugConnectionStatus();
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
      timestamp: DateTime.now(),
    );
    messages.insert(0, message);

    // Save user message to history
    _saveMessageToHistory(textController.text.trim(), "user");

    isTyping.value = true;
    apiCall(msg: textController.text.trim());
    textController.clear();
  }

  void insertNewData(String response) {
    ChatMessage botMessage = ChatMessage(
      text: response,
      sender: "bot",
      timestamp: DateTime.now(),
    );

    isTyping.value = false;
    messages.insert(0, botMessage);

    // Save bot response to history
    _saveMessageToHistory(response, "bot");
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

  /// this method is used to get response from Gemini api or offline ML
  void apiCall({required String msg}) async {
    try {
      isTyping.value = true;
      String response;

      // Add debug logging
      print('🔍 API Call Debug:');
      print('   - Network Connected: ${connectionService.isConnected}');
      print('   - Online Mode: ${connectionService.isOnlineMode}');
      print('   - Message: $msg');

      // Check connection status and mode preference
      bool isOnline = connectionService.isOnlineMode && connectionService.isConnected;

      print('   - Should use online: $isOnline');

      if (isOnline) {
        print('🌐 Using online mode - calling Gemini API');
        // Online mode - use existing online functionality
        if (isRAGEnabled.value && await _ragService.hasKnowledgeBase()) {
          // Use RAG for enhanced responses
          print('📚 Using RAG for enhanced response');
          response = await _ragService.ragQuery(msg);
        } else {
          // Fallback to normal Gemini API
          print('🤖 Using normal Gemini API call');
          response = await _normalGeminiCall(msg);
        }
      } else {
        print('📱 Using offline mode - local ML');
        // Offline mode - use on-device ML
        response = await _offlineMLService.generateResponse(msg);

        // Add offline indicator to response
        response = "📱 **Offline Mode**\n\n$response\n\n_Generated using on-device AI without internet connection._";
      }

      insertNewData(response);

    } catch (e) {
      print('❌ Error in API call: $e');
      isTyping.value = false;

      // If online call failed, try offline as fallback
      if (connectionService.isConnected) {
        print('🔄 Attempting offline fallback');
        try {
          String fallbackResponse = await _offlineMLService.generateResponse(msg);
          insertNewData("🔄 **Fallback to Offline Mode**\n\n$fallbackResponse\n\n_Online service unavailable, using on-device AI._");
        } catch (offlineError) {
          print('❌ Offline fallback also failed: $offlineError');
          insertNewData("❌ Error: Unable to get response from both online and offline services.");
        }
      } else {
        insertNewData("❌ Error: No internet connection and offline service unavailable.");
      }
    }
  }

  /// Normal Gemini API call (fallback)
  Future<String> _normalGeminiCall(String msg) async {
    print('🔑 Validating Gemini API key...');
    print('🔑 API Key length: ${AppConstants.geminiApiKey.length}');
    print('🔑 API Key (first 10 chars): ${AppConstants.geminiApiKey.length > 10 ? AppConstants.geminiApiKey.substring(0, 10) : "TOO_SHORT"}...');

    // Validate API key first
    if (!AppConstants.isGeminiKeyValid) {
      print('❌ API key validation failed - key is empty or invalid');
      throw Exception('Gemini API key is missing. Please provide GEMINI_API_KEY via --dart-define');
    }

    print('✅ API key valid, making request to Gemini...');

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

    final url = "${AppConstants.geminiBaseUrl}/models/${AppConstants.geminiModel}:generateContent?key=${AppConstants.geminiApiKey}";

    print('🌐 Making request to: ${AppConstants.geminiBaseUrl}/models/${AppConstants.geminiModel}:generateContent');

    var response = await dio.post(
      url,
      data: data,
      options: Options(
        sendTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 30),
        // Allow reading response bodies for 4xx errors
        validateStatus: (status) => status != null && status < 500,
      ),
    );

    print('📨 Response status: ${response.statusCode}');

    // Handle common permission errors explicitly
    if (response.statusCode == 403) {
      final err = response.data is Map ? (response.data['error'] ?? {}) : {};
      final status = err['status'] ?? 'PERMISSION_DENIED';
      final message = err['message'] ?? 'Forbidden';

      // Check if it's a leaked API key
      if (message.toLowerCase().contains('leaked')) {
        print('🚨 API KEY LEAKED! The key has been disabled by Google.');
        throw Exception(
          '🚨 API KEY LEAKED!\n\n'
          'Your Gemini API key has been reported as leaked and disabled by Google.\n\n'
          'SOLUTION:\n'
          '1. Get a new API key: https://aistudio.google.com/app/apikey\n'
          '2. Update .env.local file with the new key\n'
          '3. Restart app using: ./run_web.sh\n\n'
          'See QUICK_FIX.md for details.'
        );
      }

      throw Exception(
        '403 $status: $message. Check API key validity, billing, API enablement, key restrictions, and model access.'
      );
    }

    if (response.statusCode == 401) {
      throw Exception('401 UNAUTHENTICATED: Invalid API key.');
    }

    if (response.statusCode != 200) {
      final err = response.data is Map ? (response.data['error'] ?? {}) : {};
      final status = err['status'] ?? response.statusCode.toString();
      final message = err['message'] ?? 'Unexpected error';
      throw Exception('$status: $message');
    }

    final responseData = response.data;
    print("✅ Gemini API response received: ${responseData}");
    final candidates = responseData['candidates'] as List?;

    if (candidates != null && candidates.isNotEmpty) {
      final content = candidates[0]['content'];
      final parts = content['parts'] as List;
      return parts[0]['text'] ?? 'No response generated';
    }

    throw Exception('No response generated from Gemini');
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
            onPressed: () {
              titleController.dispose();
              contentController.dispose();
              Get.back(closeOverlays: false);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.isNotEmpty && contentController.text.isNotEmpty) {
                Get.back(closeOverlays: false);
                titleController.dispose();
                contentController.dispose();

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
                } else {
                  Get.snackbar(
                    'Error',
                    'Failed to add knowledge. Please try again.',
                    backgroundColor: Colors.red,
                    colorText: Colors.white,
                  );
                }
                isTyping.value = false;
              } else {
                Get.snackbar(
                  'Validation Error',
                  'Please fill in both title and content fields.',
                  backgroundColor: Colors.orange,
                  colorText: Colors.white,
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
      barrierDismissible: true,
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
            onPressed: () => Get.back(closeOverlays: false),
            child: const Text('Close'),
          ),
        ],
      ),
      barrierDismissible: true,
    );
  }

  /// Load offline ML model
  Future<void> _loadOfflineMLModel() async {
    try {
      bool success = await _offlineMLService.initializeModel();
      isOfflineMLModelLoaded.value = success;

      if (success) {
        // Add welcome message about offline capability
        ChatMessage welcomeMessage = ChatMessage(
          text: "🤖 **Offline AI Ready!**\n\nI can now work both online and offline:\n\n"
               "🌐 **Online Mode**: Full HelpAI capabilities with RAG\n"
               "📱 **Offline Mode**: On-device AI for basic assistance\n\n"
               "I'll automatically switch modes based on your internet connection!",
          sender: "bot",
        );
        messages.insert(0, welcomeMessage);
      }
    } catch (e) {
      print('Error loading offline ML model: $e');
      isOfflineMLModelLoaded.value = false;
    }
  }

  /// Toggle between online and offline modes manually
  void toggleConnectionMode() {
    connectionService.toggleMode();

    String mode = connectionService.isOnlineMode ? "Online" : "Offline";
    String emoji = connectionService.isOnlineMode ? "🌐" : "📱";

    ChatMessage modeMessage = ChatMessage(
      text: "$emoji **Switched to $mode Mode**\n\n"
           "${connectionService.isOnlineMode
             ? 'Using cloud-based AI with full capabilities.'
             : 'Using on-device AI for privacy and offline access.'}",
      sender: "bot",
    );
    messages.insert(0, modeMessage);
  }

  /// Get current mode status
  String getCurrentModeStatus() {
    if (!connectionService.isConnected) {
      return "📴 Offline (No Internet)";
    } else if (connectionService.isOnlineMode) {
      return "🌐 Online Mode";
    } else {
      return "📱 Offline Mode (By Choice)";
    }
  }

  /// Get offline ML model status
  Map<String, dynamic> getOfflineModelStatus() {
    return _offlineMLService.getModelStatus();
  }

  /// Show model status dialog
  void showModelStatus() {
    final modelStatus = getOfflineModelStatus();
    final connectionInfo = connectionService.getConnectionInfo();

    Get.dialog(
      AlertDialog(
        title: const Text('AI Model Status'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Connection Status
              Text('📡 Connection Status',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              Text('• Internet: ${connectionInfo['isConnected'] ? '✅ Connected' : '❌ Disconnected'}'),
              Text('• Connection Type: ${connectionInfo['connectionType']}'),
              Text('• Current Mode: ${connectionInfo['isOnlineMode'] ? '🌐 Online' : '📱 Offline'}'),

              const SizedBox(height: 16),

              // API Key Status
              Text('🔑 API Configuration',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              Text('• Gemini Key: ${AppConstants.isGeminiKeyValid ? '✅ Configured (${AppConstants.geminiApiKey.substring(0, 10)}...)' : '❌ Missing'}'),
              Text('• OpenAI Key: ${AppConstants.isOpenAiKeyValid ? '✅ Configured' : '❌ Missing'}'),
              if (!AppConstants.isGeminiKeyValid)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text('⚠️ No valid API key! Please restart app with:\n./run_web.sh',
                    style: TextStyle(color: Colors.red, fontSize: 12)),
                ),

              const SizedBox(height: 16),

              // Offline ML Model Status
              Text('🤖 Offline AI Model',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              Text('• Model Loaded: ${modelStatus['isLoaded'] ? '✅ Yes' : '❌ No'}'),
              Text('• Mode: ${modelStatus['mode']}'),

              const SizedBox(height: 16),

              // RAG Status
              Text('🧠 RAG System',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              Text('• RAG Enabled: ${isRAGEnabled.value ? '✅ Yes' : '❌ No'}'),
              Text('• Documents: ${documentsCount.value}'),

              const SizedBox(height: 16),

              // Capabilities
              Text('💡 Current Capabilities',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              if (connectionInfo['isOnlineMode'] && connectionInfo['isConnected'])
                Text('• 🌐 Full online AI with HelpAI/Gemini')
              else
                Text('• 📱 On-device AI for basic assistance'),
              if (isRAGEnabled.value && documentsCount.value > 0)
                Text('• 🧠 Document-based question answering'),
              Text('• 🎤 Voice input and speech recognition'),
              Text('• 💾 Local knowledge base storage'),
              Text('• 🔢 Mathematical calculations'),
              Text('• 📅 Date and time information'),
            ],
          ),
        ),
        actions: [
          if (!connectionInfo['isConnected'])
            TextButton(
              onPressed: () {
                Get.back(closeOverlays: false);
                toggleConnectionMode();
              },
              child: const Text('Retry Connection'),
            ),
          TextButton(
            onPressed: () => Get.back(closeOverlays: false),
            child: const Text('Close'),
          ),
        ],
      ),
      barrierDismissible: true,
    );
  }

  /// Show TensorFlow Lite Models management dialog
  Future<void> showTFLiteModelsDialog() async {
    // Get downloaded models list
    List<String> downloadedModels = await TFLiteModelManager.getDownloadedModels();

    Get.dialog(
      AlertDialog(
        title: const Text('TensorFlow Lite Models'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Manage offline AI models for enhanced performance',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: TFLiteModelManager.availableModels.length,
                  itemBuilder: (context, index) {
                    final modelKey = TFLiteModelManager.availableModels.keys.elementAt(index);
                    final modelInfo = TFLiteModelManager.availableModels[modelKey]!;
                    final isDownloaded = downloadedModels.contains(modelKey);

                    return Card(
                      child: ListTile(
                        leading: Icon(
                          isDownloaded ? Icons.check_circle : Icons.download,
                          color: isDownloaded ? Colors.green : Colors.blue,
                        ),
                        title: Text(modelInfo.name),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(modelInfo.description),
                            const SizedBox(height: 4),
                            Text(
                              'Size: ${modelInfo.size}',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                        trailing: isDownloaded
                            ? IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () async {
                                  // Show confirmation dialog before deletion
                                  Get.dialog(
                                    AlertDialog(
                                      title: const Text('Delete Model'),
                                      content: Text('Are you sure you want to delete ${modelInfo.name}?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Get.back(),
                                          child: const Text('Cancel'),
                                        ),
                                        ElevatedButton(
                                          onPressed: () async {
                                            Get.back(); // Close confirmation dialog
                                            Get.back(); // Close models dialog

                                            bool success = await TFLiteModelManager.deleteModel(modelKey);
                                            if (success) {
                                              Get.snackbar(
                                                'Success',
                                                'Model deleted successfully',
                                                backgroundColor: Colors.orange,
                                                colorText: Colors.white,
                                              );
                                              // Refresh the models dialog
                                              showTFLiteModelsDialog();
                                            } else {
                                              Get.snackbar(
                                                'Error',
                                                'Failed to delete model',
                                                backgroundColor: Colors.red,
                                                colorText: Colors.white,
                                              );
                                            }
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red,
                                            foregroundColor: Colors.white,
                                          ),
                                          child: const Text('Delete'),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              )
                            : IconButton(
                                icon: const Icon(Icons.download, color: Colors.blue),
                                onPressed: () async {
                                  Get.back(); // Close current dialog

                                  // Show download progress dialog
                                  RxDouble downloadProgress = 0.0.obs;

                                  Get.dialog(
                                    AlertDialog(
                                      title: Text('Downloading ${modelInfo.name}'),
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Text('Please wait while the model is being downloaded...'),
                                          const SizedBox(height: 16),
                                          Obx(() => LinearProgressIndicator(
                                            value: downloadProgress.value,
                                          )),
                                          const SizedBox(height: 8),
                                          Obx(() => Text(
                                            '${(downloadProgress.value * 100).toStringAsFixed(1)}%',
                                          )),
                                        ],
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            Get.back(); // Close progress dialog
                                            showTFLiteModelsDialog(); // Reopen models dialog
                                          },
                                          child: const Text('Cancel'),
                                        ),
                                      ],
                                    ),
                                    barrierDismissible: false,
                                  );

                                  try {
                                    // Download the model
                                    bool success = await TFLiteModelManager.downloadModel(
                                      modelKey,
                                      onProgress: (progress) {
                                        downloadProgress.value = progress;
                                      },
                                    );

                                    Get.back(); // Close progress dialog

                                    if (success) {
                                      Get.snackbar(
                                        'Success',
                                        'Model downloaded successfully!',
                                        backgroundColor: Colors.green,
                                        colorText: Colors.white,
                                      );
                                      // Refresh the models dialog
                                      showTFLiteModelsDialog();
                                    } else {
                                      Get.snackbar(
                                        'Error',
                                        'Failed to download model',
                                        backgroundColor: Colors.red,
                                        colorText: Colors.white,
                                      );
                                      // Reopen models dialog on error
                                      showTFLiteModelsDialog();
                                    }
                                  } catch (e) {
                                    Get.back(); // Close progress dialog on exception
                                    Get.snackbar(
                                      'Error',
                                      'Download failed: $e',
                                      backgroundColor: Colors.red,
                                      colorText: Colors.white,
                                    );
                                    // Reopen models dialog on error
                                    showTFLiteModelsDialog();
                                  }
                                },
                              ),
                        isThreeLine: true,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Close'),
          ),
        ],
      ),
      barrierDismissible: true,
    );
  }

  /// Save message to chat history
  Future<void> _saveMessageToHistory(String text, String sender) async {
    try {
      final sessionId = await ChatHistoryService.getCurrentSessionId();
      final historyMessage = ChatHistoryMessage(
        text: text,
        sender: sender,
        timestamp: DateTime.now(),
        sessionId: sessionId,
      );
      await ChatHistoryService.saveChatMessage(historyMessage);
    } catch (e) {
      print('Error saving message to history: $e');
    }
  }

  /// Clear current chat and start new session
  Future<void> clearCurrentChat() async {
    messages.clear();
    await ChatHistoryService.startNewSession();
    Get.showSnackbar(
      GetSnackBar(
        title: "New Chat",
        message: "Started a new conversation",
        backgroundColor: Colors.blue,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(16),
        borderRadius: 8,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Show Happy New Year greeting when app opens
  void _showNewYearGreeting() {
    // Add a beautiful New Year message
    ChatMessage newYearMessage = ChatMessage(
      text: "🎉🎊 **HAPPY NEW YEAR 2026!** 🎊🎉\n\n"
           "✨ Wishing you a year filled with:\n"
           "💫 Success and prosperity\n"
           "🌟 Health and wellness\n"
           "🚀 Amazing achievements\n\n"
           "🎆 May this year bring you joy, peace, and countless blessings!\n\n"
           "🎁 Thank you for using HelpAI. Let's make 2026 extraordinary together!\n\n"
           "🥳 Cheers to new beginnings! 🥂",
      sender: "bot",
      timestamp: DateTime.now(),
    );
    messages.insert(0, newYearMessage);
  }

  /// Debug connection status for troubleshooting
  void _debugConnectionStatus() {
    // Print initial API key status
    print('═══════════════════════════════════════════════════');
    print('🔍 API CONFIGURATION DIAGNOSTICS');
    print('═══════════════════════════════════════════════════');
    print('🔑 Gemini API Key Status:');
    print('   - Configured: ${AppConstants.isGeminiKeyValid ? 'YES ✅' : 'NO ❌'}');
    print('   - Length: ${AppConstants.geminiApiKey.length} characters');
    if (AppConstants.isGeminiKeyValid) {
      print('   - Preview: ${AppConstants.geminiApiKey.substring(0, 10)}...');
    } else {
      print('   - ⚠️  API key is EMPTY! Please restart with: ./run_web.sh');
    }
    print('');
    print('🔑 OpenAI API Key Status:');
    print('   - Configured: ${AppConstants.isOpenAiKeyValid ? 'YES ✅' : 'NO ❌'}');
    print('   - Length: ${AppConstants.openAiApiKey.length} characters');
    print('');
    print('🌐 Connection Status:');
    print('   - Internet: ${connectionService.isConnected ? 'CONNECTED ✅' : 'DISCONNECTED ❌'}');
    print('   - Mode: ${connectionService.isOnlineMode ? 'ONLINE 🌐' : 'OFFLINE 📱'}');
    print('═══════════════════════════════════════════════════');

    // Use simple polling instead of observables for release compatibility
    Timer.periodic(const Duration(seconds: 10), (timer) {
      print('🔄 Status Update:');
      print('   🌐 Connection: ${connectionService.isConnected}');
      print('   📱 Mode: ${connectionService.isOnlineMode ? 'Online' : 'Offline'}');
      print('   🔑 Gemini Key: ${AppConstants.isGeminiKeyValid ? 'Valid' : 'Missing'}');
    });
  }
}
