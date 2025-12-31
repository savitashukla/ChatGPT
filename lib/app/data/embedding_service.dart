import 'dart:convert';
import 'package:dio/dio.dart';

class EmbeddingService {
  final Dio _dio = Dio();
  final String _apiKey = 'AIzaSyBFbWsr1AK4TAelWGSAqCKsXFctJqN2lpA'; // Your Gemini API key

  /// Generate text embedding using Gemini's text-embedding-004 model
  Future<List<double>> generateEmbedding(String text) async {
    try {
      // Clean and validate input text
      if (text.trim().isEmpty) {
        return List.generate(768, (index) => 0.0);
      }

      final response = await _dio.post(
        'https://generativelanguage.googleapis.com/v1beta/models/text-embedding-004:embedContent?key=$_apiKey',
        data: {
          'content': {
            'parts': [
              {'text': text.trim()}
            ]
          }
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
          receiveTimeout: const Duration(seconds: 30),
          sendTimeout: const Duration(seconds: 30),
        ),
      );

      if (response.statusCode == 200) {
        final embedding = response.data['embedding']['values'] as List?;
        if (embedding != null) {
          return embedding.map<double>((e) => e.toDouble()).toList();
        } else {
          throw Exception('No embedding values in response');
        }
      } else {
        throw Exception('API returned status ${response.statusCode}: ${response.data}');
      }
    } catch (e) {
      print('Error generating embedding for text: ${text.substring(0, text.length > 50 ? 50 : text.length)}... Error: $e');
      // Return a simple hash-based embedding as fallback
      return _generateSimpleEmbedding(text);
    }
  }

  /// Generate embeddings for multiple texts
  Future<List<List<double>>> generateMultipleEmbeddings(List<String> texts) async {
    List<List<double>> embeddings = [];

    for (String text in texts) {
      final embedding = await generateEmbedding(text);
      embeddings.add(embedding);

      // Add small delay to avoid rate limiting
      await Future.delayed(const Duration(milliseconds: 100));
    }

    return embeddings;
  }

  /// Generate a simple hash-based embedding as fallback
  List<double> _generateSimpleEmbedding(String text) {
    List<double> embedding = List.filled(768, 0.0);
    final bytes = text.codeUnits;

    for (int i = 0; i < bytes.length && i < 768; i++) {
      embedding[i] = (bytes[i] % 256) / 256.0;
    }

    return embedding;
  }
}
