import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import '../services/cross_platform_rag_service.dart';

class RAGController extends GetxController {
  var isProcessing = false.obs;
  var uploadedDocuments = <String>[].obs;
  var storageStats = <String, dynamic>{}.obs;

  @override
  void onInit() {
    super.onInit();
    initializeRAG();
  }

  /// Initialize RAG service
  Future<void> initializeRAG() async {
    try {
      await CrossPlatformRAGService.initialize();
      await loadUploadedDocuments();
      await updateStorageStats();
    } catch (e) {
      print('Error initializing RAG: $e');
      Get.snackbar('Error', 'Failed to initialize RAG service');
    }
  }

  /// Handle file upload and processing
  Future<void> uploadAndProcessDocument() async {
    try {
      if (isProcessing.value) {
        Get.snackbar('Please Wait', 'Already processing a document...');
        return;
      }

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.single.path != null) {
        isProcessing.value = true;

        String filePath = result.files.single.path!;
        String fileName = result.files.single.name;

        bool success = await CrossPlatformRAGService.processPDF(filePath, fileName);

        if (success) {
          await loadUploadedDocuments();
          await updateStorageStats();
        }
      } else {
        Get.snackbar('No File Selected', 'Please select a PDF file to upload');
      }
    } catch (e) {
      print('Error uploading document: $e');
      Get.snackbar('Upload Error', 'Failed to upload document: ${e.toString()}');
    } finally {
      isProcessing.value = false;
    }
  }

  /// Generate RAG-enhanced response for user query
  Future<String> getRAGResponse(String userQuery) async {
    try {
      if (userQuery.trim().isEmpty) {
        return "Please ask a question.";
      }

      return await CrossPlatformRAGService.generateRAGResponse(userQuery);
    } catch (e) {
      print('Error getting RAG response: $e');
      return "Sorry, I encountered an error while processing your question.";
    }
  }

  /// Load list of uploaded documents
  Future<void> loadUploadedDocuments() async {
    try {
      List<String> docs = await CrossPlatformRAGService.getUploadedDocuments();
      uploadedDocuments.value = docs;
    } catch (e) {
      print('Error loading documents: $e');
    }
  }

  /// Update storage statistics
  Future<void> updateStorageStats() async {
    try {
      Map<String, dynamic> stats = await CrossPlatformRAGService.getStorageStats();
      storageStats.value = stats;
    } catch (e) {
      print('Error updating storage stats: $e');
    }
  }

  /// Clear all RAG data
  Future<void> clearAllData() async {
    try {
      await CrossPlatformRAGService.clearAllData();
      uploadedDocuments.clear();
      storageStats.clear();
      await updateStorageStats();
    } catch (e) {
      print('Error clearing data: $e');
      Get.snackbar('Error', 'Failed to clear data');
    }
  }

  /// Check if RAG has documents available
  bool get hasDocuments => uploadedDocuments.isNotEmpty;

  /// Get formatted storage info
  String get storageInfo {
    if (storageStats.isEmpty) return 'No data';

    int docCount = storageStats['documentCount'] ?? 0;
    int chunkCount = storageStats['chunkCount'] ?? 0;

    return '$docCount documents, $chunkCount chunks';
  }
}
