import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:call_accounting/models/cycle_model.dart';
import 'package:call_accounting/models/pricing_config.dart';

class AddCycleDialog extends StatefulWidget {
  final PricingConfig pricingConfig;
  final int nextCycleIndex;

  const AddCycleDialog({
    super.key,
    required this.pricingConfig,
    required this.nextCycleIndex,
  });

  @override
  State<AddCycleDialog> createState() => _AddCycleDialogState();
}

class _AddCycleDialogState extends State<AddCycleDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _peopleController;
  late TextEditingController _moneyController;
  late TextEditingController _rateController;
  late TextEditingController _notesController;

  NetworkPreset _selectedNetwork = NetworkPreset.vodafone;
  bool _customRateEnabled = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: 'دورة ${_selectedNetwork.titleAr} ${widget.nextCycleIndex}',
    );
    _peopleController = TextEditingController(text: '1');
    _moneyController = TextEditingController(text: '50');
    _notesController = TextEditingController();

    final defaultRate = widget.pricingConfig.getRate(_selectedNetwork);
    _rateController = TextEditingController(text: defaultRate.toString());

    _moneyController.addListener(_recalc);
    _rateController.addListener(_recalc);
    _peopleController.addListener(_recalc);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _peopleController.dispose();
    _moneyController.dispose();
    _rateController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _recalc() {
    if (mounted) setState(() {});
  }

  void _onNetworkChanged(NetworkPreset? preset) {
    if (preset == null) return;
    setState(() {
      _selectedNetwork = preset;
      if (!_customRateEnabled) {
        final rate = widget.pricingConfig.getRate(preset);
        _rateController.text = rate.toString();
      }
      _nameController.text = 'دورة ${preset.titleAr} ${widget.nextCycleIndex}';
    });
  }

  double get _currentAmount =>
      double.tryParse(_moneyController.text.trim().replaceAll(',', '.')) ?? 0.0;

  double get _currentRate =>
      double.tryParse(_rateController.text.trim().replaceAll(',', '.')) ?? 0.5;

  int get _currentPeople => int.tryParse(_peopleController.text.trim()) ?? 1;

  double get _calculatedMinutes {
    if (_currentRate <= 0) return 0;
    return _currentAmount / _currentRate;
  }

  int get _calculatedSeconds => (_calculatedMinutes * 60).round();

  String _formatPreviewTime(int totalSecs) {
    if (totalSecs <= 0) return '00:00';
    final h = totalSecs ~/ 3600;
    final m = (totalSecs % 3600) ~/ 60;
    final s = totalSecs % 60;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 480),
          padding: const EdgeInsets.all(22),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Title Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _selectedNetwork.brandColor.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _selectedNetwork.icon,
                          color: _selectedNetwork.brandColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'إضافة دورة تتبع جديدة',
                              style: GoogleFonts.tajawal(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            Text(
                              'مؤقت مستقل مع احتساب تلقائي للمدة',
                              style: GoogleFonts.tajawal(
                                fontSize: 11,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // Network Selection Dropdown
                  Text(
                    'الشبكة / نوع الدورة',
                    style: GoogleFonts.tajawal(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F7FA),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<NetworkPreset>(
                        value: _selectedNetwork,
                        isExpanded: true,
                        items: NetworkPreset.values.map((preset) {
                          return DropdownMenuItem(
                            value: preset,
                            child: Row(
                              children: [
                                Icon(preset.icon,
                                    color: preset.brandColor, size: 20),
                                const SizedBox(width: 10),
                                Text(
                                  preset.titleAr,
                                  style: GoogleFonts.tajawal(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: _onNetworkChanged,
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Cycle Name Field
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'اسم الدورة أو الرقم',
                      hintText: 'مثال: دورة 1، دورة فودافون، شفت الصباح',
                      prefixIcon: const Icon(Icons.badge_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'أدخل اسم الدورة' : null,
                  ),

                  const SizedBox(height: 14),

                  // Row: Number of people + Amount of money
                  Row(
                    children: [
                      // People count
                      Expanded(
                        child: TextFormField(
                          controller: _peopleController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'عدد الأشخاص / المكالمات',
                            prefixIcon: const Icon(Icons.people_outline),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          validator: (v) {
                            final n = int.tryParse(v?.trim() ?? '');
                            if (n == null || n < 1) return 'عدد غير صالح';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Amount of money
                      Expanded(
                        child: TextFormField(
                          controller: _moneyController,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: InputDecoration(
                            labelText: 'المبلغ المتاح (ج.م)',
                            prefixIcon: const Icon(Icons.payments_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          validator: (v) {
                            final n = double.tryParse(
                                v?.trim().replaceAll(',', '.') ?? '');
                            if (n == null || n <= 0) return 'مبلغ غير صالح';
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Rate per minute with custom toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'سعر الدقيقة (ج.م / دقيقة)',
                        style: GoogleFonts.tajawal(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                        ),
                        onPressed: () {
                          setState(() {
                            _customRateEnabled = !_customRateEnabled;
                            if (!_customRateEnabled) {
                              _rateController.text = widget.pricingConfig
                                  .getRate(_selectedNetwork)
                                  .toString();
                            }
                          });
                        },
                        icon: Icon(
                          _customRateEnabled ? Icons.lock_open : Icons.edit_note,
                          size: 16,
                        ),
                        label: Text(
                          _customRateEnabled ? 'استعادة الافتراضي' : 'تعديل السعر',
                          style: GoogleFonts.tajawal(fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  TextFormField(
                    controller: _rateController,
                    readOnly: !_customRateEnabled,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      filled: !_customRateEnabled,
                      fillColor: _customRateEnabled
                          ? Colors.white
                          : Colors.grey.shade100,
                      prefixIcon: const Icon(Icons.price_change_outlined),
                      suffixText: 'ج.م / دقيقة',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    validator: (v) {
                      final n = double.tryParse(
                          v?.trim().replaceAll(',', '.') ?? '');
                      if (n == null || n <= 0) return 'سعر دقيقة غير صالح';
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // Real-time Calculation Card Preview
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _selectedNetwork.brandColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _selectedNetwork.brandColor.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'الدقائق المحسوبة تلقائياً:',
                              style: GoogleFonts.tajawal(
                                color: Colors.black87,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              '${_calculatedMinutes.toStringAsFixed(2)} دقيقة',
                              style: GoogleFonts.tajawal(
                                color: _selectedNetwork.brandColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'مدة المؤقت الأولي:',
                              style: GoogleFonts.tajawal(
                                color: Colors.black87,
                                fontSize: 12,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: _selectedNetwork.brandColor,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _formatPreviewTime(_calculatedSeconds),
                                style: GoogleFonts.tajawal(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'معادلة الحساب: ${_currentAmount.toStringAsFixed(2)} ج.م ÷ ${_currentRate.toStringAsFixed(2)} ج.م/دقيقة = ${_calculatedMinutes.toStringAsFixed(2)} دقيقة',
                          style: GoogleFonts.tajawal(
                            color: Colors.black54,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Actions: Add and Start vs Save Idle
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: () => _submit(startImmediately: false),
                          child: Text(
                            'حفظ فقط',
                            style: GoogleFonts.tajawal(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: _selectedNetwork.brandColor,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: () => _submit(startImmediately: true),
                          icon: const Icon(Icons.play_arrow_rounded),
                          label: Text(
                            'حفظ وبدء',
                            style: GoogleFonts.tajawal(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _submit({required bool startImmediately}) {
    if (!_formKey.currentState!.validate()) return;

    Navigator.pop(context, {
      'name': _nameController.text.trim(),
      'network': _selectedNetwork,
      'peopleCount': _currentPeople,
      'initialAmount': _currentAmount,
      'ratePerMinute': _currentRate,
      'customDurationSeconds': _calculatedSeconds,
      'notes': _notesController.text.trim(),
      'startImmediately': startImmediately,
    });
  }
}
