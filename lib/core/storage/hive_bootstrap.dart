import 'package:hive_flutter/hive_flutter.dart';
import '../models/drug.dart';
import '../models/drug_interaction.dart';

class HiveBootstrap {
  static const labRangesBoxName = 'lab_ranges_v1';

  static Future<void> init() async {
    await Hive.initFlutter();

    // Register Drug model adapters
    if (!Hive.isAdapterRegistered(20)) {
      Hive.registerAdapter(DrugAdapter());
    }
    if (!Hive.isAdapterRegistered(21)) {
      Hive.registerAdapter(DosageInfoAdapter());
    }
    if (!Hive.isAdapterRegistered(22)) {
      Hive.registerAdapter(StandardDoseAdapter());
    }
    if (!Hive.isAdapterRegistered(23)) {
      Hive.registerAdapter(RenalDosingAdapter());
    }
    if (!Hive.isAdapterRegistered(24)) {
      Hive.registerAdapter(HepaticDosingAdapter());
    }
    if (!Hive.isAdapterRegistered(25)) {
      Hive.registerAdapter(PediatricDosingAdapter());
    }
    if (!Hive.isAdapterRegistered(26)) {
      Hive.registerAdapter(DrugInteractionAdapter());
    }
    if (!Hive.isAdapterRegistered(27)) {
      Hive.registerAdapter(InteractionSeverityAdapter());
    }

    await Hive.openBox(labRangesBoxName);
  }
}
