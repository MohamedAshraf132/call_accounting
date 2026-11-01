import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:call_accounting/models/cycle_model.dart';
import 'package:call_accounting/models/pricing_config.dart';
import 'package:call_accounting/services/storage_service.dart';

class DailyStats {
  final DateTime date;
  final int totalCycles;
  final int totalPeople;
  final double totalInitialAmount;
  final double totalConsumedAmount;
  final double totalRemainingAmount;
  final double totalAllocatedMinutes;
  final double totalConsumedMinutes;
  final double totalRemainingMinutes;
  final int completedCount;
  final int runningCount;
  final int pausedCount;
  final int stoppedCount;
  final Map<NetworkPreset, NetworkSummary> networkBreakdown;

  DailyStats({
    required this.date,
    required this.totalCycles,
    required this.totalPeople,
    required this.totalInitialAmount,
    required this.totalConsumedAmount,
    required this.totalRemainingAmount,
    required this.totalAllocatedMinutes,
    required this.totalConsumedMinutes,
    required this.totalRemainingMinutes,
    required this.completedCount,
    required this.runningCount,
    required this.pausedCount,
    required this.stoppedCount,
    required this.networkBreakdown,
  });
}

class NetworkSummary {
  final int cycleCount;
  final int peopleCount;
  final double money;
  final double minutes;

  NetworkSummary({
    required this.cycleCount,
    required this.peopleCount,
    required this.money,
    required this.minutes,
  });
}

class CycleManager extends ChangeNotifier with WidgetsBindingObserver {
  List<CallCycle> _cycles = [];
  PricingConfig _pricingConfig = PricingConfig.defaults();
  Timer? _ticker;
  bool _initialized = false;

  final StreamController<CallCycle> _completedEvents =
      StreamController<CallCycle>.broadcast();

  CycleManager() {
    WidgetsBinding.instance.addObserver(this);
    _init();
  }

  bool get isInitialized => _initialized;
  List<CallCycle> get cycles => List.unmodifiable(_cycles);
  PricingConfig get pricingConfig => _pricingConfig;
  Stream<CallCycle> get onCycleCompleted => _completedEvents.stream;

  List<CallCycle> get activeCycles => _cycles
      .where((c) =>
          c.status == CycleStatus.running ||
          c.status == CycleStatus.paused ||
          c.status == CycleStatus.idle)
      .toList();

  List<CallCycle> get runningCycles =>
      _cycles.where((c) => c.status == CycleStatus.running).toList();

  List<CallCycle> get finishedCycles => _cycles
      .where((c) =>
          c.status == CycleStatus.completed || c.status == CycleStatus.stopped)
      .toList();

  Future<void> _init() async {
    _pricingConfig = await PricingConfig.load();
    _cycles = await StorageService.loadCycles();
    _recheckAllTimersOnResume();
    _startTickerIfNeeded();
    _initialized = true;
    notifyListeners();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Re-evaluate wall-clock time across all running timers immediately
      _recheckAllTimersOnResume();
      _startTickerIfNeeded();
      notifyListeners();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    _completedEvents.close();
    super.dispose();
  }

  /// Start 1-second ticker if at least one cycle is running
  void _startTickerIfNeeded() {
    final hasRunning = _cycles.any((c) => c.status == CycleStatus.running);
    if (hasRunning) {
      if (_ticker == null || !_ticker!.isActive) {
        _ticker = Timer.periodic(const Duration(seconds: 1), _onTick);
      }
    } else {
      _ticker?.cancel();
      _ticker = null;
    }
  }

  /// Periodic tick: checks if running timers expired and updates UI
  void _onTick(Timer timer) {
    final now = DateTime.now();
    bool stateChanged = false;
    final List<CallCycle> newlyCompleted = [];

    final updatedList = <CallCycle>[];
    for (final cycle in _cycles) {
      if (cycle.status == CycleStatus.running) {
        if (cycle.isExpired(now: now)) {
          // Timer finished!
          final completed = cycle.copyWith(
            status: CycleStatus.completed,
            accumulatedElapsedSeconds: cycle.totalDurationSeconds,
            clearLastResumed: true,
            endedAt: now,
          );
          updatedList.add(completed);
          newlyCompleted.add(completed);
          stateChanged = true;
        } else {
          updatedList.add(cycle);
        }
      } else {
        updatedList.add(cycle);
      }
    }

    if (stateChanged) {
      _cycles = updatedList;
      _persist();
      for (final comp in newlyCompleted) {
        _triggerCompletionAlert(comp);
      }
    }

    _startTickerIfNeeded();
    notifyListeners();
  }

  /// Evaluates all cycles on resume / cold start
  void _recheckAllTimersOnResume() {
    final now = DateTime.now();
    bool anyChanged = false;
    final List<CallCycle> newlyCompleted = [];

    final updated = <CallCycle>[];
    for (final cycle in _cycles) {
      if (cycle.status == CycleStatus.running) {
        if (cycle.isExpired(now: now)) {
          final completed = cycle.copyWith(
            status: CycleStatus.completed,
            accumulatedElapsedSeconds: cycle.totalDurationSeconds,
            clearLastResumed: true,
            endedAt: cycle.lastResumedAt != null
                ? cycle.lastResumedAt!.add(
                    Duration(
                      seconds: (cycle.totalDurationSeconds -
                              cycle.accumulatedElapsedSeconds)
                          .clamp(0, cycle.totalDurationSeconds),
                    ),
                  )
                : now,
          );
          updated.add(completed);
          newlyCompleted.add(completed);
          anyChanged = true;
        } else {
          updated.add(cycle);
        }
      } else {
        updated.add(cycle);
      }
    }

    if (anyChanged) {
      _cycles = updated;
      _persist();
      for (final comp in newlyCompleted) {
        _triggerCompletionAlert(comp);
      }
    }
  }

  void _triggerCompletionAlert(CallCycle cycle) {
    // Play subtle alert chime & heavy haptic feedback
    try {
      HapticFeedback.heavyImpact();
      SystemSound.play(SystemSoundType.alert);
    } catch (_) {}
    _completedEvents.add(cycle);
  }

  // ── Cycle Actions ───────────────────────────────────────────────────────────

  /// Add a new independent cycle
  Future<CallCycle> addCycle({
    required String name,
    required NetworkPreset network,
    required int peopleCount,
    required double initialAmount,
    double? customRatePerMinute,
    int? customDurationSeconds,
    String notes = '',
  }) async {
    final rate = customRatePerMinute ?? _pricingConfig.getRate(network);
    final id = 'cycle_${DateTime.now().millisecondsSinceEpoch}_${_cycles.length + 1}';

    final newCycle = CallCycle.create(
      id: id,
      name: name.trim().isEmpty ? 'دورة ${network.titleAr} ${_cycles.length + 1}' : name.trim(),
      network: network,
      peopleCount: peopleCount,
      initialAmount: initialAmount,
      ratePerMinute: rate,
      customDurationSeconds: customDurationSeconds,
      notes: notes,
    );

    _cycles.insert(0, newCycle);
    await _persist();
    notifyListeners();
    return newCycle;
  }

  /// Start an idle or newly added cycle
  Future<void> startCycle(String id) async {
    final index = _cycles.indexWhere((c) => c.id == id);
    if (index == -1) return;

    final cycle = _cycles[index];
    if (cycle.status == CycleStatus.running) return;

    final now = DateTime.now();
    _cycles[index] = cycle.copyWith(
      status: CycleStatus.running,
      lastResumedAt: now,
      startedAt: cycle.startedAt ?? now,
    );

    await _persist();
    _startTickerIfNeeded();
    notifyListeners();
  }

  /// Pause an active cycle
  Future<void> pauseCycle(String id) async {
    final index = _cycles.indexWhere((c) => c.id == id);
    if (index == -1) return;

    final cycle = _cycles[index];
    if (cycle.status != CycleStatus.running) return;

    final now = DateTime.now();
    final elapsedNow = cycle.getElapsedSeconds(now: now);

    _cycles[index] = cycle.copyWith(
      status: CycleStatus.paused,
      accumulatedElapsedSeconds: elapsedNow,
      clearLastResumed: true,
    );

    await _persist();
    _startTickerIfNeeded();
    notifyListeners();
  }

  /// Resume a paused cycle
  Future<void> resumeCycle(String id) async {
    final index = _cycles.indexWhere((c) => c.id == id);
    if (index == -1) return;

    final cycle = _cycles[index];
    if (cycle.status != CycleStatus.paused) return;

    final now = DateTime.now();
    _cycles[index] = cycle.copyWith(
      status: CycleStatus.running,
      lastResumedAt: now,
    );

    await _persist();
    _startTickerIfNeeded();
    notifyListeners();
  }

  /// Manually stop a cycle before it finishes
  Future<void> stopCycle(String id) async {
    final index = _cycles.indexWhere((c) => c.id == id);
    if (index == -1) return;

    final cycle = _cycles[index];
    final now = DateTime.now();
    final elapsedNow = cycle.getElapsedSeconds(now: now);

    _cycles[index] = cycle.copyWith(
      status: CycleStatus.stopped,
      accumulatedElapsedSeconds: elapsedNow,
      clearLastResumed: true,
      endedAt: now,
    );

    await _persist();
    _startTickerIfNeeded();
    notifyListeners();
  }

  /// Reset / restart a cycle back to initial state
  Future<void> resetCycle(String id) async {
    final index = _cycles.indexWhere((c) => c.id == id);
    if (index == -1) return;

    final cycle = _cycles[index];
    _cycles[index] = cycle.copyWith(
      status: CycleStatus.idle,
      accumulatedElapsedSeconds: 0,
      clearLastResumed: true,
      clearEndedAt: true,
      startedAt: null,
    );

    await _persist();
    _startTickerIfNeeded();
    notifyListeners();
  }

  /// Update an existing cycle
  Future<void> updateCycle(CallCycle updated) async {
    final index = _cycles.indexWhere((c) => c.id == updated.id);
    if (index == -1) return;

    _cycles[index] = updated;
    await _persist();
    _startTickerIfNeeded();
    notifyListeners();
  }

  /// Delete a cycle permanently
  Future<void> deleteCycle(String id) async {
    _cycles.removeWhere((c) => c.id == id);
    await _persist();
    _startTickerIfNeeded();
    notifyListeners();
  }

  /// Clear all data
  Future<void> clearAll() async {
    _ticker?.cancel();
    _ticker = null;
    _cycles.clear();
    await StorageService.clearAll();
    notifyListeners();
  }

  /// Update pricing rules
  Future<void> updatePricingConfig(PricingConfig newConfig) async {
    _pricingConfig = newConfig;
    await _pricingConfig.save();
    notifyListeners();
  }

  Future<void> _persist() async {
    await StorageService.saveCycles(_cycles);
  }

  // ── Daily Statistics Engine ─────────────────────────────────────────────────

  /// Filter cycles for a specific date (based on createdAt or startedAt)
  List<CallCycle> getCyclesForDate(DateTime date) {
    return _cycles.where((c) {
      final refDate = c.startedAt ?? c.createdAt;
      return refDate.year == date.year &&
          refDate.month == date.month &&
          refDate.day == date.day;
    }).toList();
  }

  /// Compute full daily stats for a specific date
  DailyStats getDailyStats(DateTime date) {
    final dayCycles = getCyclesForDate(date);
    final now = DateTime.now();

    int totalPeople = 0;
    double totalInitialAmount = 0.0;
    double totalConsumedAmount = 0.0;
    double totalRemainingAmount = 0.0;
    double totalAllocatedMinutes = 0.0;
    double totalConsumedMinutes = 0.0;
    double totalRemainingMinutes = 0.0;
    int completedCount = 0;
    int runningCount = 0;
    int pausedCount = 0;
    int stoppedCount = 0;

    final networkMap = <NetworkPreset, NetworkSummary>{};
    for (final p in NetworkPreset.values) {
      networkMap[p] = NetworkSummary(
        cycleCount: 0,
        peopleCount: 0,
        money: 0.0,
        minutes: 0.0,
      );
    }

    for (final c in dayCycles) {
      totalPeople += c.peopleCount;
      totalInitialAmount += c.initialAmount;
      final consumed = c.getConsumedAmount(now: now);
      final remaining = c.getRemainingAmount(now: now);
      totalConsumedAmount += consumed;
      totalRemainingAmount += remaining;

      final allocatedMins = c.totalDurationSeconds / 60.0;
      final consumedMins = c.getElapsedSeconds(now: now) / 60.0;
      final remainingMins = c.getRemainingSeconds(now: now) / 60.0;

      totalAllocatedMinutes += allocatedMins;
      totalConsumedMinutes += consumedMins;
      totalRemainingMinutes += remainingMins;

      switch (c.status) {
        case CycleStatus.completed:
          completedCount++;
          break;
        case CycleStatus.running:
          runningCount++;
          break;
        case CycleStatus.paused:
          pausedCount++;
          break;
        case CycleStatus.stopped:
          stoppedCount++;
          break;
        case CycleStatus.idle:
          break;
      }

      final prevNet = networkMap[c.network]!;
      networkMap[c.network] = NetworkSummary(
        cycleCount: prevNet.cycleCount + 1,
        peopleCount: prevNet.peopleCount + c.peopleCount,
        money: prevNet.money + c.initialAmount,
        minutes: prevNet.minutes + allocatedMins,
      );
    }

    return DailyStats(
      date: date,
      totalCycles: dayCycles.length,
      totalPeople: totalPeople,
      totalInitialAmount: totalInitialAmount,
      totalConsumedAmount: totalConsumedAmount,
      totalRemainingAmount: totalRemainingAmount,
      totalAllocatedMinutes: totalAllocatedMinutes,
      totalConsumedMinutes: totalConsumedMinutes,
      totalRemainingMinutes: totalRemainingMinutes,
      completedCount: completedCount,
      runningCount: runningCount,
      pausedCount: pausedCount,
      stoppedCount: stoppedCount,
      networkBreakdown: networkMap,
    );
  }
}
