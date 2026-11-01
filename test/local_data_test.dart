import 'package:call_accounting/models/cycle_model.dart';
import 'package:call_accounting/models/pricing_config.dart';
import 'package:call_accounting/services/storage_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('saved call history can be loaded with its values intact', () async {
    final cycle = CallCycle.create(
      id: 'persistence_test',
      name: 'دورة اختبار',
      network: NetworkPreset.vodafone,
      peopleCount: 3,
      initialAmount: 18.75,
      ratePerMinute: 0.75,
      notes: 'سجل محلي',
    ).copyWith(
      status: CycleStatus.completed,
      accumulatedElapsedSeconds: 1500,
      startedAt: DateTime(2026, 10, 28, 10),
      endedAt: DateTime(2026, 10, 28, 10, 25),
    );

    await StorageService.saveCycles([cycle]);
    final loaded = await StorageService.loadCycles();

    expect(loaded, hasLength(1));
    expect(loaded.single.id, cycle.id);
    expect(loaded.single.name, cycle.name);
    expect(loaded.single.peopleCount, 3);
    expect(loaded.single.initialAmount, 18.75);
    expect(loaded.single.status, CycleStatus.completed);
    expect(loaded.single.accumulatedElapsedSeconds, 1500);
    expect(loaded.single.startedAt, cycle.startedAt);
    expect(loaded.single.endedAt, cycle.endedAt);
    expect(loaded.single.notes, 'سجل محلي');
  });

  test('custom network prices can be saved and loaded', () async {
    final config = PricingConfig.defaults().copyWithRate(
      NetworkPreset.orange,
      2.75,
    );

    await config.save();
    final loaded = await PricingConfig.load();

    expect(loaded.getRate(NetworkPreset.orange), 2.75);
    expect(loaded.getRate(NetworkPreset.vodafone),
        NetworkPreset.vodafone.defaultRate);
  });
}
