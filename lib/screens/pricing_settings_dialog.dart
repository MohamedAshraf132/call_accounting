import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:call_accounting/models/cycle_model.dart';
import 'package:call_accounting/models/pricing_config.dart';

class PricingSettingsDialog extends StatefulWidget {
  final PricingConfig currentConfig;
  final ValueChanged<PricingConfig> onSaved;

  const PricingSettingsDialog({
    super.key,
    required this.currentConfig,
    required this.onSaved,
  });

  @override
  State<PricingSettingsDialog> createState() => _PricingSettingsDialogState();
}

class _PricingSettingsDialogState extends State<PricingSettingsDialog> {
  late Map<NetworkPreset, TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = {
      for (final p in NetworkPreset.values)
        p: TextEditingController(
          text: widget.currentConfig.getRate(p).toString(),
        ),
    };
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    var updated = widget.currentConfig;
    for (final entry in _controllers.entries) {
      final val = double.tryParse(entry.value.text.trim().replaceAll(',', '.')) ??
          entry.key.defaultRate;
      updated = updated.copyWithRate(entry.key, val);
    }
    widget.onSaved(updated);
    Navigator.pop(context);
  }

  void _resetToDefaults() {
    setState(() {
      for (final p in NetworkPreset.values) {
        _controllers[p]!.text = p.defaultRate.toString();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF673AB7).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.tune_rounded, color: Color(0xFF673AB7)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'تسعير الشبكات',
                          style: GoogleFonts.tajawal(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'تحديد سعر الدقيقة بالجنيه لكل شبكة',
                          style: GoogleFonts.tajawal(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const Divider(height: 1),
              const SizedBox(height: 12),

              ...NetworkPreset.values.map((preset) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: preset.brandColor.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(preset.icon, color: preset.brandColor, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          preset.titleAr,
                          style: GoogleFonts.tajawal(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 90,
                        child: TextField(
                          controller: _controllers[preset],
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          textAlign: TextAlign.center,
                          style: GoogleFonts.tajawal(fontWeight: FontWeight.bold),
                          decoration: InputDecoration(
                            isDense: true,
                            suffixText: 'ج.م',
                            suffixStyle: GoogleFonts.tajawal(fontSize: 10),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 10,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),

              const SizedBox(height: 12),
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  TextButton.icon(
                    onPressed: _resetToDefaults,
                    icon: const Icon(Icons.restore_rounded, size: 16),
                    label: Text(
                      'استعادة الافتراضي',
                      style: GoogleFonts.tajawal(fontSize: 12),
                    ),
                  ),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('إلغاء', style: GoogleFonts.tajawal()),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF673AB7),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: _save,
                        child: Text(
                          'حفظ',
                          style: GoogleFonts.tajawal(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
