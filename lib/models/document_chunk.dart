import 'package:hive/hive.dart';

part 'document_chunk.g.dart';

@HiveType(typeId: 0)
class DocumentChunk extends HiveObject {
  @HiveField(0)
  String documentId;

  @HiveField(1)
  String chunkText;

  @HiveField(2)
  String chunkHash;

  @HiveField(3)
  String metadata;

  @HiveField(4)
  DateTime createdAt;

  DocumentChunk({
    required this.documentId,
    required this.chunkText,
    required this.chunkHash,
    required this.metadata,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'documentId': documentId,
      'chunkText': chunkText,
      'chunkHash': chunkHash,
      'metadata': metadata,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory DocumentChunk.fromJson(Map<String, dynamic> json) {
    return DocumentChunk(
      documentId: json['documentId'],
      chunkText: json['chunkText'],
      chunkHash: json['chunkHash'],
      metadata: json['metadata'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
