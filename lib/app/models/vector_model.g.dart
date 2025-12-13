// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vector_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class VectorModelAdapter extends TypeAdapter<VectorModel> {
  @override
  final int typeId = 2;

  @override
  VectorModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return VectorModel(
      id: fields[0] as String,
      documentId: fields[1] as String,
      text: fields[2] as String,
      embedding: (fields[3] as List).cast<double>(),
      createdAt: fields[4] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, VectorModel obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.documentId)
      ..writeByte(2)
      ..write(obj.text)
      ..writeByte(3)
      ..write(obj.embedding)
      ..writeByte(4)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VectorModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
