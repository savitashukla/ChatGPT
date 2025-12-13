import 'package:dio/dio.dart';
import '../models/vector_model.dart';
import 'embedding_service.dart';
import 'vector_database_service.dart';

class RAGService {
  final EmbeddingService _embeddingService = EmbeddingService();
  final Dio _dio = Dio();
  final String _apiKey = 'AIzaSyD1eKN8QyDlPxduNzhlQMzsZFIKUG_1ZOw';

  /// Perform RAG: Retrieve relevant context and generate response
  Future<String> ragQuery(String userQuery) async {
    try {
      // Validate input
      if (userQuery.trim().isEmpty) {
        return 'Please provide a valid question.';
      }

      // Check if knowledge base has content
      if (!await hasKnowledgeBase()) {
        return 'No documents available in knowledge base. Please upload documents first.';
      }

      // Step 1: Generate embedding for user query
      List<double> queryEmbedding = await _embeddingService.generateEmbedding(userQuery);

      // Step 2: Find similar documents/chunks
      List<VectorModel> relevantChunks = await VectorDatabaseService.findSimilarVectors(
        queryEmbedding,
        limit: 3  // Get top 3 most relevant chunks
      );

      // Step 3: Build context from relevant chunks
      String context = _buildContext(relevantChunks);

      // Step 4: Generate response using Gemini with context
      String response = await _generateResponseWithContext(userQuery, context);

      return response;

    } catch (e) {
      print('Error in RAG query: $e');
      return 'Sorry, I encountered an error while processing your request. Error: ${e.toString()}';
    }
  }

  /// Build context string from relevant chunks
  String _buildContext(List<VectorModel> chunks) {
    if (chunks.isEmpty) {
      return 'No relevant information found in knowledge base.';
    }

    StringBuffer contextBuffer = StringBuffer();
    contextBuffer.writeln('Based on the following information from your documents:');
    contextBuffer.writeln();

    for (int i = 0; i < chunks.length; i++) {
      contextBuffer.writeln('Reference ${i + 1}:');
      contextBuffer.writeln(chunks[i].text);
      contextBuffer.writeln();
    }

    return contextBuffer.toString();
  }

  /// Generate response using Gemini with retrieved context
  Future<String> _generateResponseWithContext(String query, String context) async {
    try {
      String prompt = '''
You are an AI assistant with access to a knowledge base. Use the provided context to answer the user's question accurately.

Context:
$context

User Question: $query

Instructions:
1. Answer based on the provided context
2. If the context doesn't contain relevant information, say so
3. Be precise and cite the information from the context
4. If you're unsure, acknowledge the limitation

Answer:''';

      Map<String, dynamic> data = {
        "contents": [
          {
            "parts": [
              {"text": prompt}
            ]
          }
        ]
      };

      var response = await _dio.post(
        "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$_apiKey",
        data: data,
        options: Options(
          headers: {'Content-Type': 'application/json'},
          receiveTimeout: const Duration(seconds: 60),
          sendTimeout: const Duration(seconds: 30),
        ),
      );

      if (response.statusCode == 200) {
        final responseData = response.data;
        final candidates = responseData['candidates'] as List?;

        if (candidates != null && candidates.isNotEmpty) {
          final content = candidates[0]['content'];
          final parts = content['parts'] as List;
          final text = parts[0]['text'] ?? '';
          return text.trim();
        }
      }

      return 'Sorry, I could not generate a response at this time.';

    } catch (e) {
      print('Error generating response: $e');
      return 'Error generating response with context. Please try again.';
    }
  }

  /// Check if knowledge base has any documents
  Future<bool> hasKnowledgeBase() async {
    final documents = await VectorDatabaseService.getAllDocuments();
    return documents.isNotEmpty;
  }

  /// Get knowledge base statistics
  Future<Map<String, int>> getKnowledgeBaseStats() async {
    final documents = await VectorDatabaseService.getAllDocuments();
    final vectors = await VectorDatabaseService.getAllVectors();

    return {
      'documents': documents.length,
      'chunks': vectors.length,
    };
  }
}
