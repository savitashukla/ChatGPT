import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:crypto/crypto.dart';
import '../models/document_model.dart';
import '../models/vector_model.dart';
import 'embedding_service.dart';
import 'vector_database_service.dart';

class DocumentProcessingService {
  final EmbeddingService _embeddingService = EmbeddingService();

  /// Pick and process documents (PDF, TXT) - Works on all platforms including web
  Future<bool> pickAndProcessDocument() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'txt'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        PlatformFile file = result.files.first;

        // Extract content based on platform
        String content = await _extractTextFromFile(file);
        if (content.isNotEmpty) {
          await _processAndStoreDocument(file, content);
          return true;
        }
      }
      return false;
    } catch (e) {
      print('Error picking document: $e');
      return false;
    }
  }

  /// Extract text from different file types - Platform independent
  Future<String> _extractTextFromFile(PlatformFile file) async {
    try {
      if (file.extension?.toLowerCase() == 'pdf') {
        return await _extractPDFText(file);
      } else if (file.extension?.toLowerCase() == 'txt') {
        return await _extractTextFileContent(file);
      }
      return '';
    } catch (e) {
      print('Error extracting text: $e');
      return '';
    }
  }

  /// Extract text from PDF - Works on web and mobile
  Future<String> _extractPDFText(PlatformFile file) async {
    try {
      Uint8List bytes;

      // Handle different platforms
      if (kIsWeb) {
        // On web, use bytes directly
        if (file.bytes == null) {
          throw Exception('File bytes not available on web');
        }
        bytes = file.bytes!;
      } else {
        // On mobile/desktop, read from path
        if (file.path == null) {
          throw Exception('File path not available on mobile');
        }
        final File ioFile = File(file.path!);
        bytes = await ioFile.readAsBytes();
      }

      // Extract text using Syncfusion PDF
      final PdfDocument document = PdfDocument(inputBytes: bytes);
      String text = '';

      // Create text extractor
      PdfTextExtractor extractor = PdfTextExtractor(document);

      for (int i = 0; i < document.pages.count; i++) {
        // Extract text from each page
        String pageText = extractor.extractText(startPageIndex: i, endPageIndex: i);
        text += '$pageText\n';
      }

      document.dispose();

      if (text.trim().isEmpty) {
        print('Warning: No text extracted from PDF');
        return 'Document processed but no readable text found. This might be a scanned PDF or image-based document.';
      }

      return text;
    } catch (e) {
      print('Error reading PDF: $e');
      return 'Error: Unable to process PDF file. Please ensure the file is not corrupted or password-protected.';
    }
  }

  /// Extract text from TXT file - Works on web and mobile
  Future<String> _extractTextFileContent(PlatformFile file) async {
    try {
      if (kIsWeb) {
        // On web, use bytes directly
        if (file.bytes == null) {
          throw Exception('File bytes not available on web');
        }
        return utf8.decode(file.bytes!);
      } else {
        // On mobile/desktop, read from path
        if (file.path == null) {
          throw Exception('File path not available on mobile');
        }
        File ioFile = File(file.path!);
        return await ioFile.readAsString();
      }
    } catch (e) {
      print('Error reading text file: $e');
      return '';
    }
  }

  /// Process document and store in vector database
  Future<void> _processAndStoreDocument(PlatformFile file, String content) async {
    try {
      // Generate document ID
      String documentId = _generateId(file.name + DateTime.now().toString());

      // Create document model
      DocumentModel document = DocumentModel(
        id: documentId,
        title: file.name,
        content: content,
        filePath: kIsWeb ? 'web_upload' : (file.path ?? 'unknown'),
        createdAt: DateTime.now(),
        fileType: file.extension ?? 'unknown',
      );

      // Store document
      await VectorDatabaseService.insertDocument(document);

      // Split content into chunks and create embeddings
      List<String> chunks = _splitTextIntoChunks(content);

      for (int i = 0; i < chunks.length; i++) {
        String chunk = chunks[i];
        if (chunk.trim().isNotEmpty) {
          // Generate embedding for chunk
          List<double> embedding = await _embeddingService.generateEmbedding(chunk);

          // Create vector model
          VectorModel vector = VectorModel(
            id: _generateId(documentId + i.toString()),
            documentId: documentId,
            text: chunk,
            embedding: embedding,
            createdAt: DateTime.now(),
          );

          // Store vector
          await VectorDatabaseService.insertVector(vector);
        }
      }
    } catch (e) {
      print('Error processing document: $e');
    }
  }

  /// Split text into manageable chunks
  List<String> _splitTextIntoChunks(String text, {int chunkSize = 500}) {
    List<String> chunks = [];
    List<String> sentences = text.split(RegExp(r'[.!?]+'));

    String currentChunk = '';
    for (String sentence in sentences) {
      if ((currentChunk + sentence).length < chunkSize) {
        currentChunk += sentence + '. ';
      } else {
        if (currentChunk.isNotEmpty) {
          chunks.add(currentChunk.trim());
        }
        currentChunk = sentence + '. ';
      }
    }

    if (currentChunk.isNotEmpty) {
      chunks.add(currentChunk.trim());
    }

    return chunks;
  }

  /// Generate unique ID
  String _generateId(String input) {
    var bytes = utf8.encode(input);
    var digest = sha256.convert(bytes);
    return digest.toString().substring(0, 16);
  }

  /// Add text knowledge directly
  Future<bool> addTextKnowledge(String title, String content) async {
    try {
      String documentId = _generateId(title + DateTime.now().toString());

      DocumentModel document = DocumentModel(
        id: documentId,
        title: title,
        content: content,
        filePath: 'manual_input',
        createdAt: DateTime.now(),
        fileType: 'text',
      );

      await VectorDatabaseService.insertDocument(document);

      List<String> chunks = _splitTextIntoChunks(content);

      for (int i = 0; i < chunks.length; i++) {
        String chunk = chunks[i];
        if (chunk.trim().isNotEmpty) {
          List<double> embedding = await _embeddingService.generateEmbedding(chunk);

          VectorModel vector = VectorModel(
            id: _generateId(documentId + i.toString()),
            documentId: documentId,
            text: chunk,
            embedding: embedding,
            createdAt: DateTime.now(),
          );

          await VectorDatabaseService.insertVector(vector);
        }
      }
      return true;
    } catch (e) {
      print('Error adding text knowledge: $e');
      return false;
    }
  }

  /// Get all documents
  Future<List<DocumentModel>> getAllDocuments() async {
    return await VectorDatabaseService.getAllDocuments();
  }

  /// Delete document
  Future<void> deleteDocument(String documentId) async {
    await VectorDatabaseService.deleteDocument(documentId);
  }
}
