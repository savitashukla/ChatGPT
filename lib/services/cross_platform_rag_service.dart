import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:crypto/crypto.dart';
import 'package:get/get.dart';
import '../models/document_chunk.dart';

class CrossPlatformRAGService {
  static const String _chunksBoxName = 'document_chunks';
  static const String _documentsKey = 'uploaded_documents';

  static late Box<DocumentChunk> _chunksBox;
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
    webOptions: WebOptions(
      dbName: 'rag_secure_storage',
      publicKey: 'rag_public_key',
    ),
  );

  static bool _isInitialized = false;

  /// Initialize the RAG service - works on all platforms
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize Hive for cross-platform storage
      await Hive.initFlutter();

      // Register adapters
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(DocumentChunkAdapter());
      }

      // Open the chunks box
      _chunksBox = await Hive.openBox<DocumentChunk>(_chunksBoxName);

      _isInitialized = true;
      print('RAG Service initialized successfully');
    } catch (e) {
      print('Error initializing RAG service: $e');
      throw Exception('Failed to initialize RAG service: $e');
    }
  }

  /// Process and store PDF document
  static Future<bool> processPDF(String filePath, String fileName) async {
    try {
      await _ensureInitialized();

      // Read PDF file
      File file = File(filePath);
      if (!await file.exists()) {
        throw Exception('File not found: $filePath');
      }

      Uint8List bytes = await file.readAsBytes();

      // Extract text from PDF
      final PdfDocument document = PdfDocument(inputBytes: bytes);
      String fullText = '';

      for (int i = 0; i < document.pages.count; i++) {
        String pageText = PdfTextExtractor(document).extractText(
          startPageIndex: i,
          endPageIndex: i
        );
        fullText += pageText + '\n';
      }

      document.dispose();

      if (fullText.trim().isEmpty) {
        throw Exception('No text content found in PDF');
      }

      // Split into chunks
      List<String> chunks = _splitTextIntoChunks(fullText, 500);

      // Store chunks
      await _storeChunks(chunks, fileName);

      // Update document list in secure storage
      await _updateDocumentList(fileName);

      Get.snackbar(
        'Success',
        'Document "$fileName" processed successfully!\n${chunks.length} chunks created.',
        duration: Duration(seconds: 3),
      );

      return true;
    } catch (e) {
      print('Error processing PDF: $e');
      Get.snackbar(
        'Error',
        'Failed to process document: ${e.toString()}',
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
      return false;
    }
  }

  /// Split text into manageable chunks
  static List<String> _splitTextIntoChunks(String text, int maxWords) {
    List<String> sentences = text.split(RegExp(r'[.!?]+'));
    List<String> chunks = [];
    String currentChunk = '';

    for (String sentence in sentences) {
      sentence = sentence.trim();
      if (sentence.isEmpty) continue;

      List<String> words = sentence.split(' ');

      if ((currentChunk.split(' ').length + words.length) <= maxWords) {
        currentChunk += (currentChunk.isEmpty ? '' : '. ') + sentence;
      } else {
        if (currentChunk.isNotEmpty) {
          chunks.add(currentChunk.trim());
        }
        currentChunk = sentence;
      }
    }

    if (currentChunk.isNotEmpty) {
      chunks.add(currentChunk.trim());
    }

    return chunks.where((chunk) => chunk.trim().isNotEmpty).toList();
  }

  /// Store text chunks in Hive
  static Future<void> _storeChunks(List<String> chunks, String documentId) async {
    for (int i = 0; i < chunks.length; i++) {
      String chunkText = chunks[i];
      String hash = sha256.convert(utf8.encode(chunkText)).toString();

      DocumentChunk chunk = DocumentChunk(
        documentId: documentId,
        chunkText: chunkText,
        chunkHash: hash,
        metadata: jsonEncode({
          'chunkIndex': i,
          'totalChunks': chunks.length,
          'wordCount': chunkText.split(' ').length,
        }),
        createdAt: DateTime.now(),
      );

      await _chunksBox.add(chunk);
    }
  }

  /// Update document list in secure storage
  static Future<void> _updateDocumentList(String documentName) async {
    try {
      String? existingDocs = await _secureStorage.read(key: _documentsKey);
      List<String> documentList = [];

      if (existingDocs != null) {
        documentList = List<String>.from(jsonDecode(existingDocs));
      }

      if (!documentList.contains(documentName)) {
        documentList.add(documentName);
        await _secureStorage.write(
          key: _documentsKey,
          value: jsonEncode(documentList)
        );
      }
    } catch (e) {
      print('Error updating document list: $e');
    }
  }

  /// Retrieve relevant chunks for a query
  static Future<List<DocumentChunk>> retrieveRelevantChunks(String query, {int maxResults = 3}) async {
    await _ensureInitialized();

    if (query.trim().isEmpty) return [];

    List<String> queryWords = query.toLowerCase().split(' ')
        .where((word) => word.length > 2)
        .toList();

    if (queryWords.isEmpty) return [];

    List<MapEntry<DocumentChunk, double>> scoredChunks = [];

    for (DocumentChunk chunk in _chunksBox.values) {
      double score = _calculateRelevanceScore(chunk.chunkText, queryWords);
      if (score > 0) {
        scoredChunks.add(MapEntry(chunk, score));
      }
    }

    // Sort by relevance score (descending)
    scoredChunks.sort((a, b) => b.value.compareTo(a.value));

    // Return top results
    return scoredChunks
        .take(maxResults)
        .map((entry) => entry.key)
        .toList();
  }

  /// Calculate relevance score for text chunks
  static double _calculateRelevanceScore(String chunkText, List<String> queryWords) {
    String lowerChunk = chunkText.toLowerCase();
    double score = 0.0;

    for (String word in queryWords) {
      // Exact word match
      int exactMatches = word.allMatches(lowerChunk).length;
      score += exactMatches * 2.0;

      // Partial matches (contains)
      if (lowerChunk.contains(word)) {
        score += 1.0;
      }
    }

    // Boost score for shorter chunks (more focused content)
    int wordCount = chunkText.split(' ').length;
    if (wordCount < 200) {
      score *= 1.2;
    }

    return score;
  }

  /// Generate RAG-enhanced response
  static Future<String> generateRAGResponse(String userQuery) async {
    try {
      await _ensureInitialized();

      // Check if we have any documents
      if (_chunksBox.isEmpty) {
        return "I don't have any documents to reference. Please upload some documents first to use RAG functionality.";
      }

      // Retrieve relevant chunks
      List<DocumentChunk> relevantChunks = await retrieveRelevantChunks(userQuery);

      if (relevantChunks.isEmpty) {
        return "I couldn't find relevant information in the uploaded documents to answer your question.";
      }

      // Build context from chunks
      String context = relevantChunks
          .map((chunk) => chunk.chunkText)
          .join('\n\n');

      // Create enhanced prompt
      String enhancedPrompt = '''
Context from uploaded documents:
$context

Based on the above context, please answer this question:
$userQuery

If the context doesn't fully answer the question, please mention what information might be missing.
''';

      return enhancedPrompt;
    } catch (e) {
      print('Error generating RAG response: $e');
      return "Error processing your question with document context: ${e.toString()}";
    }
  }

  /// Get list of uploaded documents
  static Future<List<String>> getUploadedDocuments() async {
    try {
      String? docs = await _secureStorage.read(key: _documentsKey);
      if (docs != null) {
        return List<String>.from(jsonDecode(docs));
      }
      return [];
    } catch (e) {
      print('Error getting document list: $e');
      return [];
    }
  }

  /// Clear all RAG data
  static Future<void> clearAllData() async {
    try {
      await _ensureInitialized();
      await _chunksBox.clear();
      await _secureStorage.delete(key: _documentsKey);

      Get.snackbar('Success', 'All RAG data cleared successfully');
    } catch (e) {
      print('Error clearing data: $e');
      Get.snackbar('Error', 'Failed to clear data: ${e.toString()}');
    }
  }

  /// Get storage statistics
  static Future<Map<String, dynamic>> getStorageStats() async {
    await _ensureInitialized();

    List<String> documents = await getUploadedDocuments();
    int totalChunks = _chunksBox.length;

    // Calculate total text size
    int totalTextSize = 0;
    for (DocumentChunk chunk in _chunksBox.values) {
      totalTextSize += chunk.chunkText.length;
    }

    return {
      'documentCount': documents.length,
      'chunkCount': totalChunks,
      'totalTextSize': totalTextSize,
      'averageChunkSize': totalChunks > 0 ? (totalTextSize / totalChunks).round() : 0,
      'documents': documents,
    };
  }

  static Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }
}
