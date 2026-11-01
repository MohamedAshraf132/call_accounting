import 'package:flutter_test/flutter_test.dart';
import 'package:call_accounting/models/cycle_model.dart';

void main() {
  test('CallCycle creates and calculates minutes accurately', () {
    final cycle = CallCycle.create(
      id: 'test_1',
      name: 'دورة تجريبية',
      network: NetworkPreset.vodafone,
      peopleCount: 2,
      initialAmount: 50.0,
      ratePerMinute: 10.0,
    );

    // 50 EGP / 10 EGP per min = 5 minutes = 300 seconds
    expect(cycle.totalDurationSeconds, 300);
    expect(cycle.getRemainingSeconds(), 300);
    expect(cycle.status, CycleStatus.idle);
  });
}
