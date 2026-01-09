// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'drug_interaction.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DrugInteractionAdapter extends TypeAdapter<DrugInteraction> {
  @override
  final int typeId = 26;

  @override
  DrugInteraction read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DrugInteraction(
      id: fields[0] as String,
      drug1Id: fields[1] as String,
      drug1Name: fields[2] as String,
      drug2Id: fields[3] as String,
      drug2Name: fields[4] as String,
      severity: fields[5] as InteractionSeverity,
      description: fields[6] as String,
      mechanism: fields[7] as String?,
      management: fields[8] as String?,
      source: fields[9] as String,
      cachedAt: fields[10] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, DrugInteraction obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.drug1Id)
      ..writeByte(2)
      ..write(obj.drug1Name)
      ..writeByte(3)
      ..write(obj.drug2Id)
      ..writeByte(4)
      ..write(obj.drug2Name)
      ..writeByte(5)
      ..write(obj.severity)
      ..writeByte(6)
      ..write(obj.description)
      ..writeByte(7)
      ..write(obj.mechanism)
      ..writeByte(8)
      ..write(obj.management)
      ..writeByte(9)
      ..write(obj.source)
      ..writeByte(10)
      ..write(obj.cachedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DrugInteractionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class InteractionSeverityAdapter extends TypeAdapter<InteractionSeverity> {
  @override
  final int typeId = 27;

  @override
  InteractionSeverity read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return InteractionSeverity.major;
      case 1:
        return InteractionSeverity.moderate;
      case 2:
        return InteractionSeverity.minor;
      default:
        return InteractionSeverity.major;
    }
  }

  @override
  void write(BinaryWriter writer, InteractionSeverity obj) {
    switch (obj) {
      case InteractionSeverity.major:
        writer.writeByte(0);
        break;
      case InteractionSeverity.moderate:
        writer.writeByte(1);
        break;
      case InteractionSeverity.minor:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InteractionSeverityAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
