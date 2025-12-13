import 'dart:math';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/document_model.dart';
import '../models/vector_model.dart';

class VectorDatabaseService {
  static const String _documentsBoxName = 'vector_documents';
  static const String _vectorsBoxName = 'vectors';

  static Box<DocumentModel>? _documentsBox;
  static Box<VectorModel>? _vectorsBox;
  static bool _isInitialized = false;

  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize Hive
      await Hive.initFlutter();

      // Register adapters if not already registered
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(DocumentModelAdapter());
      }
      if (!Hive.isAdapterRegistered(2)) {
        Hive.registerAdapter(VectorModelAdapter());
      }

      // Open boxes
      _documentsBox = await Hive.openBox<DocumentModel>(_documentsBoxName);
      _vectorsBox = await Hive.openBox<VectorModel>(_vectorsBoxName);

      _isInitialized = true;
      print('VectorDatabaseService initialized successfully');
    } catch (e) {
      print('Error initializing VectorDatabaseService: $e');
      throw Exception('Failed to initialize vector database: $e');
    }
  }

  static Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }

  // Document operations
  static Future<void> insertDocument(DocumentModel document) async {
    await _ensureInitialized();
    await _documentsBox!.put(document.id, document);
  }

  static Future<List<DocumentModel>> getAllDocuments() async {
    await _ensureInitialized();
    return _documentsBox!.values.toList();
  }

  static Future<DocumentModel?> getDocument(String documentId) async {
    await _ensureInitialized();
    return _documentsBox!.get(documentId);
  }

  static Future<void> deleteDocument(String documentId) async {
    await _ensureInitialized();
    // Delete document
    await _documentsBox!.delete(documentId);

    // Delete associated vectors
    final vectorsToDelete = _vectorsBox!.values
        .where((vector) => vector.documentId == documentId)
        .toList();

    for (var vector in vectorsToDelete) {
      await _vectorsBox!.delete(vector.key);
    }
  }

  // Vector operations
  static Future<void> insertVector(VectorModel vector) async {
    await _ensureInitialized();
    await _vectorsBox!.put(vector.id, vector);
  }

  static Future<List<VectorModel>> getAllVectors() async {
    await _ensureInitialized();
    return _vectorsBox!.values.toList();
  }

  static Future<List<VectorModel>> getVectorsByDocumentId(String documentId) async {
    await _ensureInitialized();
    return _vectorsBox!.values
        .where((vector) => vector.documentId == documentId)
        .toList();
  }

  // Similarity search using cosine similarity
  static Future<List<VectorModel>> findSimilarVectors(List<double> queryEmbedding, {int limit = 5}) async {
    await _ensureInitialized();
    final vectors = await getAllVectors();

    List<MapEntry<VectorModel, double>> similarities = [];

    for (var vector in vectors) {
      double similarity = _cosineSimilarity(queryEmbedding, vector.embedding);
      similarities.add(MapEntry(vector, similarity));
    }

    // Sort by similarity (highest first)
    similarities.sort((a, b) => b.value.compareTo(a.value));

    return similarities
        .take(limit)
        .map((entry) => entry.key)
        .toList();
  }

  // Calculate cosine similarity between two vectors
  static double _cosineSimilarity(List<double> a, List<double> b) {
    if (a.length != b.length) return 0.0;

    double dotProduct = 0.0;
    double normA = 0.0;
    double normB = 0.0;

    for (int i = 0; i < a.length; i++) {
      dotProduct += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }

    if (normA == 0.0 || normB == 0.0) return 0.0;

    return dotProduct / (sqrt(normA) * sqrt(normB));
  }

  static Future<void> clearAllData() async {
    await _ensureInitialized();
    await _vectorsBox!.clear();
    await _documentsBox!.clear();
  }

  // Get statistics
  static Future<Map<String, int>> getStats() async {
    await _ensureInitialized();
    return {
      'documents': _documentsBox!.length,
      'vectors': _vectorsBox!.length,
    };
  }

  // Close boxes (call this when app is closing)
  static Future<void> close() async {
    if (_documentsBox?.isOpen == true) {
      await _documentsBox!.close();
    }
    if (_vectorsBox?.isOpen == true) {
      await _vectorsBox!.close();
    }
    _isInitialized = false;
  }
}
