import 'package:hive/hive.dart';

part 'document_model.g.dart';

@HiveType(typeId: 1)
class DocumentModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String content;

  @HiveField(3)
  final String filePath;

  @HiveField(4)
  final DateTime createdAt;

  @HiveField(5)
  final String fileType;

  DocumentModel({
    required this.id,
    required this.title,
    required this.content,
    required this.filePath,
    required this.createdAt,
    required this.fileType,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'filePath': filePath,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'fileType': fileType,
    };
  }

  factory DocumentModel.fromMap(Map<String, dynamic> map) {
    return DocumentModel(
      id: map['id'],
      title: map['title'],
      content: map['content'],
      filePath: map['filePath'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      fileType: map['fileType'],
    );
  }
}
