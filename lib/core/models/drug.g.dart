// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'drug.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DrugAdapter extends TypeAdapter<Drug> {
  @override
  final int typeId = 20;

  @override
  Drug read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Drug(
      id: fields[0] as String,
      genericName: fields[1] as String,
      tradeNames: (fields[2] as List).cast<String>(),
      sideEffects: (fields[14] as List).cast<String>(),
      commonSideEffects: (fields[15] as List).cast<String>(),
      rareSideEffects: (fields[16] as List).cast<String>(),
      seriousSideEffects: (fields[17] as List).cast<String>(),
      drugClass: fields[3] as String?,
      mechanism: fields[4] as String?,
      indications: (fields[5] as List).cast<String>(),
      contraindications: (fields[6] as List).cast<String>(),
      warnings: (fields[7] as List).cast<String>(),
      blackBoxWarnings: (fields[8] as List).cast<String>(),
      interactsWith: (fields[10] as List).cast<String>(),
      standardDoseIndication: fields[18] as String?,
      standardDoseRoute: fields[19] as String?,
      standardDose: fields[20] as String?,
      standardDoseFrequency: fields[21] as String?,
      standardDoseDuration: fields[22] as String?,
      standardDoseNotes: fields[23] as String?,
      geriatricNotes: fields[24] as String?,
      maxDailyDose: fields[25] as String?,
      renalCrclGt50: fields[26] as String?,
      renalCrcl30_50: fields[27] as String?,
      renalCrcl10_30: fields[28] as String?,
      renalCrclLt10: fields[29] as String?,
      renalDialysis: fields[30] as String?,
      renalNotes: fields[31] as String?,
      hepaticChildPughA: fields[32] as String?,
      hepaticChildPughB: fields[33] as String?,
      hepaticChildPughC: fields[34] as String?,
      hepaticNotes: fields[35] as String?,
      pediatricNeonates: fields[36] as String?,
      pediatricInfants: fields[37] as String?,
      pediatricChildren: fields[38] as String?,
      pediatricAdolescents: fields[39] as String?,
      pediatricWeightBased: fields[40] as String?,
      pediatricNotes: fields[41] as String?,
      dosageInfo: fields[42] as DosageInfo?,
      cachedAt: fields[11] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, Drug obj) {
    writer
      ..writeByte(40)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.genericName)
      ..writeByte(2)
      ..write(obj.tradeNames)
      ..writeByte(14)
      ..write(obj.sideEffects)
      ..writeByte(15)
      ..write(obj.commonSideEffects)
      ..writeByte(16)
      ..write(obj.rareSideEffects)
      ..writeByte(17)
      ..write(obj.seriousSideEffects)
      ..writeByte(3)
      ..write(obj.drugClass)
      ..writeByte(4)
      ..write(obj.mechanism)
      ..writeByte(5)
      ..write(obj.indications)
      ..writeByte(6)
      ..write(obj.contraindications)
      ..writeByte(7)
      ..write(obj.warnings)
      ..writeByte(8)
      ..write(obj.blackBoxWarnings)
      ..writeByte(10)
      ..write(obj.interactsWith)
      ..writeByte(18)
      ..write(obj.standardDoseIndication)
      ..writeByte(19)
      ..write(obj.standardDoseRoute)
      ..writeByte(20)
      ..write(obj.standardDose)
      ..writeByte(21)
      ..write(obj.standardDoseFrequency)
      ..writeByte(22)
      ..write(obj.standardDoseDuration)
      ..writeByte(23)
      ..write(obj.standardDoseNotes)
      ..writeByte(24)
      ..write(obj.geriatricNotes)
      ..writeByte(25)
      ..write(obj.maxDailyDose)
      ..writeByte(26)
      ..write(obj.renalCrclGt50)
      ..writeByte(27)
      ..write(obj.renalCrcl30_50)
      ..writeByte(28)
      ..write(obj.renalCrcl10_30)
      ..writeByte(29)
      ..write(obj.renalCrclLt10)
      ..writeByte(30)
      ..write(obj.renalDialysis)
      ..writeByte(31)
      ..write(obj.renalNotes)
      ..writeByte(32)
      ..write(obj.hepaticChildPughA)
      ..writeByte(33)
      ..write(obj.hepaticChildPughB)
      ..writeByte(34)
      ..write(obj.hepaticChildPughC)
      ..writeByte(35)
      ..write(obj.hepaticNotes)
      ..writeByte(36)
      ..write(obj.pediatricNeonates)
      ..writeByte(37)
      ..write(obj.pediatricInfants)
      ..writeByte(38)
      ..write(obj.pediatricChildren)
      ..writeByte(39)
      ..write(obj.pediatricAdolescents)
      ..writeByte(40)
      ..write(obj.pediatricWeightBased)
      ..writeByte(41)
      ..write(obj.pediatricNotes)
      ..writeByte(42)
      ..write(obj.dosageInfo)
      ..writeByte(11)
      ..write(obj.cachedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DrugAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class DosageInfoAdapter extends TypeAdapter<DosageInfo> {
  @override
  final int typeId = 21;

  @override
  DosageInfo read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DosageInfo(
      standardDoses: (fields[0] as List).cast<StandardDose>(),
      renalDosing: fields[1] as RenalDosing?,
      hepaticDosing: fields[2] as HepaticDosing?,
      pediatricDosing: fields[3] as PediatricDosing?,
      geriatricNotes: fields[4] as String?,
      maxDailyDose: fields[5] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, DosageInfo obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.standardDoses)
      ..writeByte(1)
      ..write(obj.renalDosing)
      ..writeByte(2)
      ..write(obj.hepaticDosing)
      ..writeByte(3)
      ..write(obj.pediatricDosing)
      ..writeByte(4)
      ..write(obj.geriatricNotes)
      ..writeByte(5)
      ..write(obj.maxDailyDose);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DosageInfoAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class StandardDoseAdapter extends TypeAdapter<StandardDose> {
  @override
  final int typeId = 22;

  @override
  StandardDose read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return StandardDose(
      indication: fields[0] as String,
      route: fields[1] as String,
      dose: fields[2] as String,
      frequency: fields[3] as String,
      duration: fields[4] as String?,
      notes: fields[5] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, StandardDose obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.indication)
      ..writeByte(1)
      ..write(obj.route)
      ..writeByte(2)
      ..write(obj.dose)
      ..writeByte(3)
      ..write(obj.frequency)
      ..writeByte(4)
      ..write(obj.duration)
      ..writeByte(5)
      ..write(obj.notes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StandardDoseAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class RenalDosingAdapter extends TypeAdapter<RenalDosing> {
  @override
  final int typeId = 23;

  @override
  RenalDosing read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RenalDosing(
      crClGreater50: fields[0] as String,
      crCl30to50: fields[1] as String,
      crCl10to30: fields[2] as String,
      crClLess10: fields[3] as String,
      dialysis: fields[4] as String?,
      notes: fields[5] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, RenalDosing obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.crClGreater50)
      ..writeByte(1)
      ..write(obj.crCl30to50)
      ..writeByte(2)
      ..write(obj.crCl10to30)
      ..writeByte(3)
      ..write(obj.crClLess10)
      ..writeByte(4)
      ..write(obj.dialysis)
      ..writeByte(5)
      ..write(obj.notes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RenalDosingAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class HepaticDosingAdapter extends TypeAdapter<HepaticDosing> {
  @override
  final int typeId = 24;

  @override
  HepaticDosing read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HepaticDosing(
      childPughA: fields[0] as String,
      childPughB: fields[1] as String,
      childPughC: fields[2] as String,
      notes: fields[3] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, HepaticDosing obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.childPughA)
      ..writeByte(1)
      ..write(obj.childPughB)
      ..writeByte(2)
      ..write(obj.childPughC)
      ..writeByte(3)
      ..write(obj.notes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HepaticDosingAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PediatricDosingAdapter extends TypeAdapter<PediatricDosing> {
  @override
  final int typeId = 25;

  @override
  PediatricDosing read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PediatricDosing(
      neonates: fields[0] as String?,
      infants: fields[1] as String?,
      children: fields[2] as String?,
      adolescents: fields[3] as String?,
      weightBased: fields[4] as String?,
      notes: fields[5] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, PediatricDosing obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.neonates)
      ..writeByte(1)
      ..write(obj.infants)
      ..writeByte(2)
      ..write(obj.children)
      ..writeByte(3)
      ..write(obj.adolescents)
      ..writeByte(4)
      ..write(obj.weightBased)
      ..writeByte(5)
      ..write(obj.notes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PediatricDosingAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
