import 'package:hive/hive.dart';

part 'vector_model.g.dart';

@HiveType(typeId: 2)
class VectorModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String documentId;

  @HiveField(2)
  final String text;

  @HiveField(3)
  final List<double> embedding;

  @HiveField(4)
  final DateTime createdAt;

  VectorModel({
    required this.id,
    required this.documentId,
    required this.text,
    required this.embedding,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'documentId': documentId,
      'text': text,
      'embedding': embedding.join(','),
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory VectorModel.fromMap(Map<String, dynamic> map) {
    return VectorModel(
      id: map['id'],
      documentId: map['documentId'],
      text: map['text'],
      embedding: map['embedding'].split(',').map<double>((e) => double.parse(e)).toList(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
    );
  }
}
