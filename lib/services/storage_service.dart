import 'dart:convert';
import 'package:call_accounting/models/cycle_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _cyclesKey = 'call_cycles_v2';
  static const String _migratedKey = 'has_migrated_old_summary';

  /// Load all cycles stored locally
  static Future<List<CallCycle>> loadCycles() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Check if we need to migrate from legacy single-slot format
    final hasMigrated = prefs.getBool(_migratedKey) ?? false;
    if (!hasMigrated) {
      await _checkAndMigrateLegacy(prefs);
    }

    final raw = prefs.getString(_cyclesKey);
    if (raw == null || raw.isEmpty) {
      return [];
    }

    try {
      final List decoded = jsonDecode(raw) as List;
      final Map<String, CallCycle> uniqueCycles = {};
      
      for (final item in decoded) {
        if (item is Map<String, dynamic>) {
          final cycle = CallCycle.fromJson(item);
          // Prevent duplicates by retaining unique IDs
          uniqueCycles[cycle.id] = cycle;
        }
      }
      return uniqueCycles.values.toList();
    } catch (e) {
      // In case of corrupt JSON, return empty or safe fallback
      return [];
    }
  }

  /// Atomically save the complete list of cycles, preventing duplicates
  static Future<void> saveCycles(List<CallCycle> cycles) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Ensure uniqueness by ID
    final Map<String, CallCycle> map = {};
    for (final c in cycles) {
      map[c.id] = c;
    }
    
    final encoded = jsonEncode(map.values.map((c) => c.toJson()).toList());
    await prefs.setString(_cyclesKey, encoded);
  }

  /// Migrates data from previous single-record network_summary_v2 if it exists
  static Future<void> _checkAndMigrateLegacy(SharedPreferences prefs) async {
    try {
      final oldRaw = prefs.getString('network_summary_v2');
      if (oldRaw != null) {
        final decoded = jsonDecode(oldRaw) as Map<String, dynamic>;
        final List<CallCycle> migratedList = [];

        final now = DateTime.now();
        for (final entry in decoded.entries) {
          final key = entry.key; // vodafone, orange, other
          final data = entry.value as Map<String, dynamic>;
          final people = (data['people'] as num?)?.toInt() ?? 0;
          final money = (data['money'] as num?)?.toDouble() ?? 0.0;

          if (people > 0 || money > 0) {
            final network = switch (key) {
              'vodafone' => NetworkPreset.vodafone,
              'orange' => NetworkPreset.orange,
              _ => NetworkPreset.other,
            };
            migratedList.add(CallCycle.create(
              id: 'migrated_${network.name}_${now.millisecondsSinceEpoch}',
              name: 'دورة ${network.titleAr} (سجل سابق)',
              network: network,
              peopleCount: people,
              initialAmount: money,
              ratePerMinute: network.defaultRate,
            ));
          }
        }

        if (migratedList.isNotEmpty) {
          final existing = prefs.getString(_cyclesKey);
          if (existing == null) {
            final encoded = jsonEncode(migratedList.map((c) => c.toJson()).toList());
            await prefs.setString(_cyclesKey, encoded);
          }
        }
      }
    } catch (_) {
      // Ignore migration errors
    } finally {
      await prefs.setBool(_migratedKey, true);
    }
  }

  /// Clear all stored cycle data
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cyclesKey);
  }
}
