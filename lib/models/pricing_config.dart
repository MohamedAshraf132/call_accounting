import 'dart:convert';
import 'package:call_accounting/models/cycle_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PricingConfig {
  static const String _prefsKey = 'custom_pricing_rules_v1';

  final Map<NetworkPreset, double> rates;

  PricingConfig({required this.rates});

  factory PricingConfig.defaults() {
    return PricingConfig(
      rates: {
        for (final p in NetworkPreset.values) p: p.defaultRate,
      },
    );
  }

  double getRate(NetworkPreset preset) {
    return rates[preset] ?? preset.defaultRate;
  }

  double calculateMinutes(double amount, NetworkPreset preset) {
    final rate = getRate(preset);
    if (rate <= 0) return 0;
    return amount / rate;
  }

  int calculateTotalSeconds(double amount, NetworkPreset preset) {
    final mins = calculateMinutes(amount, preset);
    return (mins * 60).round();
  }

  PricingConfig copyWithRate(NetworkPreset preset, double newRate) {
    final updated = Map<NetworkPreset, double>.from(rates);
    updated[preset] = newRate;
    return PricingConfig(rates: updated);
  }

  Map<String, dynamic> toJson() {
    return {
      for (final entry in rates.entries) entry.key.name: entry.value,
    };
  }

  factory PricingConfig.fromJson(Map<String, dynamic> json) {
    final defaults = PricingConfig.defaults().rates;
    final map = <NetworkPreset, double>{};
    for (final p in NetworkPreset.values) {
      if (json.containsKey(p.name)) {
        map[p] = (json[p.name] as num).toDouble();
      } else {
        map[p] = defaults[p]!;
      }
    }
    return PricingConfig(rates: map);
  }

  static Future<PricingConfig> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw != null) {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        return PricingConfig.fromJson(decoded);
      }
    } catch (_) {}
    return PricingConfig.defaults();
  }

  Future<void> save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, jsonEncode(toJson()));
    } catch (_) {}
  }
}
