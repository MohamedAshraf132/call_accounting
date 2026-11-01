import 'package:flutter/material.dart';

/// Status of an individual cycle
enum CycleStatus {
  idle,       // Created, ready to start
  running,    // Active countdown in progress
  paused,     // Temporarily paused
  completed,  // Reached 00:00 automatically
  stopped,    // Manually terminated before 00:00
}

extension CycleStatusX on CycleStatus {
  String get titleAr => switch (this) {
        CycleStatus.idle => 'جاهزة للبدء',
        CycleStatus.running => 'تعمل الآن',
        CycleStatus.paused => 'متوقفة مؤقتاً',
        CycleStatus.completed => 'مكتملة',
        CycleStatus.stopped => 'تم إيقافها',
      };

  Color get color => switch (this) {
        CycleStatus.idle => const Color(0xFF6E7A8A),
        CycleStatus.running => const Color(0xFF2E7D32),
        CycleStatus.paused => const Color(0xFFE65100),
        CycleStatus.completed => const Color(0xFF1565C0),
        CycleStatus.stopped => const Color(0xFFC62828),
      };

  IconData get icon => switch (this) {
        CycleStatus.idle => Icons.schedule,
        CycleStatus.running => Icons.play_arrow_rounded,
        CycleStatus.paused => Icons.pause_rounded,
        CycleStatus.completed => Icons.check_circle_outline_rounded,
        CycleStatus.stopped => Icons.stop_circle_outlined,
      };
}

/// Supported Egyptian networks and generic presets
enum NetworkPreset {
  vodafone,
  orange,
  etisalat,
  we,
  other,
  custom,
}

extension NetworkPresetX on NetworkPreset {
  String get titleAr => switch (this) {
        NetworkPreset.vodafone => 'فودافون',
        NetworkPreset.orange => 'أورنج',
        NetworkPreset.etisalat => 'اتصالات',
        NetworkPreset.we => 'وي (المصرية للاتصالات)',
        NetworkPreset.other => 'الشبكات الأخرى',
        NetworkPreset.custom => 'مخصص / أخرى',
      };

  double get defaultRate => switch (this) {
        NetworkPreset.vodafone => 0.50, // 0.50 EGP per minute
        NetworkPreset.orange => 0.50,
        NetworkPreset.etisalat => 0.50,
        NetworkPreset.we => 0.50,
        NetworkPreset.other => 2.50,
        NetworkPreset.custom => 1.00,
      };

  Color get brandColor => switch (this) {
        NetworkPreset.vodafone => const Color(0xFFE53935),
        NetworkPreset.orange => const Color(0xFFF58220),
        NetworkPreset.etisalat => const Color(0xFF2E7D32),
        NetworkPreset.we => const Color(0xFF6A1B9A),
        NetworkPreset.other => const Color(0xFF1976D2),
        NetworkPreset.custom => const Color(0xFF00897B),
      };

  IconData get icon => switch (this) {
        NetworkPreset.vodafone => Icons.sim_card_outlined,
        NetworkPreset.orange => Icons.phone_android_rounded,
        NetworkPreset.etisalat => Icons.cell_tower_rounded,
        NetworkPreset.we => Icons.router_outlined,
        NetworkPreset.other => Icons.call_outlined,
        NetworkPreset.custom => Icons.tune_rounded,
      };
}

/// Represents a single independent call cycle with its own countdown timer and finances.
class CallCycle {
  final String id;
  final String name;
  final NetworkPreset network;
  final int peopleCount;
  final double initialAmount;
  final double ratePerMinute;
  final int totalDurationSeconds;
  final int accumulatedElapsedSeconds;
  final DateTime? lastResumedAt;
  final CycleStatus status;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final String notes;

  CallCycle({
    required this.id,
    required this.name,
    required this.network,
    required this.peopleCount,
    required this.initialAmount,
    required this.ratePerMinute,
    required this.totalDurationSeconds,
    this.accumulatedElapsedSeconds = 0,
    this.lastResumedAt,
    this.status = CycleStatus.idle,
    required this.createdAt,
    this.startedAt,
    this.endedAt,
    this.notes = '',
  });

  /// Factory helper that computes totalDurationSeconds from money / rate
  factory CallCycle.create({
    required String id,
    required String name,
    required NetworkPreset network,
    required int peopleCount,
    required double initialAmount,
    required double ratePerMinute,
    int? customDurationSeconds,
    String notes = '',
  }) {
    final computedSeconds = customDurationSeconds ??
        (ratePerMinute > 0
            ? ((initialAmount / ratePerMinute) * 60).round()
            : 0);

    return CallCycle(
      id: id,
      name: name,
      network: network,
      peopleCount: peopleCount,
      initialAmount: initialAmount,
      ratePerMinute: ratePerMinute,
      totalDurationSeconds: computedSeconds,
      createdAt: DateTime.now(),
      notes: notes,
    );
  }

  /// Calculates total elapsed seconds strictly using wall-clock timestamps.
  int getElapsedSeconds({DateTime? now}) {
    if (status == CycleStatus.completed) {
      return totalDurationSeconds;
    }
    int elapsed = accumulatedElapsedSeconds;
    if (status == CycleStatus.running && lastResumedAt != null) {
      final current = now ?? DateTime.now();
      final diff = current.difference(lastResumedAt!).inSeconds;
      if (diff > 0) {
        elapsed += diff;
      }
    }
    return elapsed.clamp(0, totalDurationSeconds);
  }

  /// Accurate remaining seconds.
  int getRemainingSeconds({DateTime? now}) {
    if (status == CycleStatus.completed) return 0;
    final elapsed = getElapsedSeconds(now: now);
    return (totalDurationSeconds - elapsed).clamp(0, totalDurationSeconds);
  }

  /// Progress fraction from 0.0 (finished) to 1.0 (full).
  double getRemainingFraction({DateTime? now}) {
    if (totalDurationSeconds <= 0) return 0.0;
    return getRemainingSeconds(now: now) / totalDurationSeconds;
  }

  /// Progress fraction from 0.0 (start) to 1.0 (finished).
  double getConsumedFraction({DateTime? now}) {
    if (totalDurationSeconds <= 0) return 0.0;
    return getElapsedSeconds(now: now) / totalDurationSeconds;
  }

  /// Financial calculation: amount consumed based on elapsed time.
  double getConsumedAmount({DateTime? now}) {
    if (totalDurationSeconds <= 0) return initialAmount;
    final fraction = getConsumedFraction(now: now);
    return (initialAmount * fraction).clamp(0.0, initialAmount);
  }

  /// Financial calculation: remaining balance.
  double getRemainingAmount({DateTime? now}) {
    if (totalDurationSeconds <= 0) return 0.0;
    final consumed = getConsumedAmount(now: now);
    return (initialAmount - consumed).clamp(0.0, initialAmount);
  }

  /// Check whether countdown reached 0 or past expiration
  bool isExpired({DateTime? now}) {
    if (totalDurationSeconds <= 0) return true;
    return getRemainingSeconds(now: now) <= 0;
  }

  CallCycle copyWith({
    String? id,
    String? name,
    NetworkPreset? network,
    int? peopleCount,
    double? initialAmount,
    double? ratePerMinute,
    int? totalDurationSeconds,
    int? accumulatedElapsedSeconds,
    DateTime? lastResumedAt,
    CycleStatus? status,
    DateTime? createdAt,
    DateTime? startedAt,
    DateTime? endedAt,
    String? notes,
    bool clearLastResumed = false,
    bool clearEndedAt = false,
  }) {
    return CallCycle(
      id: id ?? this.id,
      name: name ?? this.name,
      network: network ?? this.network,
      peopleCount: peopleCount ?? this.peopleCount,
      initialAmount: initialAmount ?? this.initialAmount,
      ratePerMinute: ratePerMinute ?? this.ratePerMinute,
      totalDurationSeconds: totalDurationSeconds ?? this.totalDurationSeconds,
      accumulatedElapsedSeconds:
          accumulatedElapsedSeconds ?? this.accumulatedElapsedSeconds,
      lastResumedAt:
          clearLastResumed ? null : (lastResumedAt ?? this.lastResumedAt),
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      startedAt: startedAt ?? this.startedAt,
      endedAt: clearEndedAt ? null : (endedAt ?? this.endedAt),
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'network': network.name,
      'peopleCount': peopleCount,
      'initialAmount': initialAmount,
      'ratePerMinute': ratePerMinute,
      'totalDurationSeconds': totalDurationSeconds,
      'accumulatedElapsedSeconds': accumulatedElapsedSeconds,
      'lastResumedAt': lastResumedAt?.toIso8601String(),
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'startedAt': startedAt?.toIso8601String(),
      'endedAt': endedAt?.toIso8601String(),
      'notes': notes,
    };
  }

  factory CallCycle.fromJson(Map<String, dynamic> json) {
    return CallCycle(
      id: json['id'] as String? ?? 'cycle_${DateTime.now().millisecondsSinceEpoch}',
      name: json['name'] as String? ?? 'دورة اتصال',
      network: NetworkPreset.values.firstWhere(
        (e) => e.name == json['network'],
        orElse: () => NetworkPreset.vodafone,
      ),
      peopleCount: (json['peopleCount'] as num?)?.toInt() ?? 0,
      initialAmount: (json['initialAmount'] as num?)?.toDouble() ?? 0.0,
      ratePerMinute: (json['ratePerMinute'] as num?)?.toDouble() ?? 0.5,
      totalDurationSeconds:
          (json['totalDurationSeconds'] as num?)?.toInt() ?? 0,
      accumulatedElapsedSeconds:
          (json['accumulatedElapsedSeconds'] as num?)?.toInt() ?? 0,
      lastResumedAt: json['lastResumedAt'] != null
          ? DateTime.tryParse(json['lastResumedAt'] as String)
          : null,
      status: CycleStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => CycleStatus.idle,
      ),
      createdAt: json['createdAt'] != null
          ? (DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now())
          : DateTime.now(),
      startedAt: json['startedAt'] != null
          ? DateTime.tryParse(json['startedAt'] as String)
          : null,
      endedAt: json['endedAt'] != null
          ? DateTime.tryParse(json['endedAt'] as String)
          : null,
      notes: json['notes'] as String? ?? '',
    );
  }
}
