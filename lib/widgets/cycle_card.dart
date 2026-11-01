import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:call_accounting/models/cycle_model.dart';
import 'package:call_accounting/widgets/timer_display.dart';

class CycleCard extends StatelessWidget {
  final CallCycle cycle;
  final VoidCallback? onStart;
  final VoidCallback? onPause;
  final VoidCallback? onResume;
  final VoidCallback? onStop;
  final VoidCallback? onReset;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;

  const CycleCard({
    super.key,
    required this.cycle,
    this.onStart,
    this.onPause,
    this.onResume,
    this.onStop,
    this.onReset,
    this.onDelete,
    this.onTap,
  });

  String _formatCurrency(double amount) {
    return '${amount.toStringAsFixed(2)} ج.م';
  }

  String _formatMinutes(double minutes) {
    if (minutes == minutes.roundToDouble()) {
      return '${minutes.toInt()} دقيقة';
    }
    return '${minutes.toStringAsFixed(1)} دقيقة';
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final remainingSecs = cycle.getRemainingSeconds(now: now);
    final remainingFraction = cycle.getRemainingFraction(now: now);
    final consumedAmount = cycle.getConsumedAmount(now: now);
    final remainingAmount = cycle.getRemainingAmount(now: now);

    final allocatedMins = cycle.totalDurationSeconds / 60.0;
    final remainingMins = remainingSecs / 60.0;

    final network = cycle.network;
    final status = cycle.status;

    // Distinct card border and accent based on status
    Color borderColor;
    Color headerBg;
    if (status == CycleStatus.running) {
      borderColor = const Color(0xFF2E7D32).withValues(alpha: 0.4);
      headerBg = const Color(0xFFE8F5E9).withValues(alpha: 0.5);
    } else if (status == CycleStatus.paused) {
      borderColor = const Color(0xFFFFA000).withValues(alpha: 0.4);
      headerBg = const Color(0xFFFFF8E1).withValues(alpha: 0.5);
    } else if (status == CycleStatus.completed) {
      borderColor = const Color(0xFF1565C0).withValues(alpha: 0.3);
      headerBg = const Color(0xFFE3F2FD).withValues(alpha: 0.5);
    } else if (status == CycleStatus.stopped) {
      borderColor = const Color(0xFFC62828).withValues(alpha: 0.3);
      headerBg = const Color(0xFFFFEBEE).withValues(alpha: 0.5);
    } else {
      borderColor = Colors.grey.shade300;
      headerBg = Colors.grey.shade50;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: status == CycleStatus.running ? 2 : 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: borderColor,
          width: status == CycleStatus.running ? 2.0 : 1.0,
        ),
      ),
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Header Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: headerBg,
              child: Row(
                children: [
                  // Network Icon Badge
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: network.brandColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      network.icon,
                      color: network.brandColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Cycle Name & Network Label
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cycle.name,
                          style: GoogleFonts.tajawal(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${network.titleAr} • سعر الدقيقة: ${cycle.ratePerMinute.toStringAsFixed(2)} ج.م',
                          style: GoogleFonts.tajawal(
                            color: Colors.black54,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // More menu / Delete
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: Colors.black54),
                    onSelected: (val) {
                      if (val == 'reset') onReset?.call();
                      if (val == 'delete') onDelete?.call();
                    },
                    itemBuilder: (ctx) => [
                      PopupMenuItem(
                        value: 'reset',
                        child: Row(
                          children: [
                            const Icon(Icons.refresh_rounded, size: 18),
                            const SizedBox(width: 8),
                            Text('إعادة تعيين', style: GoogleFonts.tajawal()),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            const Icon(Icons.delete_outline,
                                color: Colors.red, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'حذف الدورة',
                              style: GoogleFonts.tajawal(color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Timer Row + People & Status
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Countdown timer display
                      TimerDisplay(
                        remainingSeconds: remainingSecs,
                        status: status,
                        accentColor: network.brandColor,
                      ),
                      const SizedBox(width: 14),
                      // Meta stats: People & Allocated minutes
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _miniMetric(
                              icon: Icons.people_alt_outlined,
                              label: 'عدد الأشخاص:',
                              value: '${cycle.peopleCount} شخص / مكالمة',
                              color: const Color(0xFF6E3B82),
                            ),
                            const SizedBox(height: 6),
                            _miniMetric(
                              icon: Icons.timelapse_rounded,
                              label: 'إجمالي الدقائق:',
                              value: _formatMinutes(allocatedMins),
                              color: const Color(0xFF1976D2),
                            ),
                            const SizedBox(height: 6),
                            _miniMetric(
                              icon: Icons.hourglass_bottom_rounded,
                              label: 'المتبقي:',
                              value: _formatMinutes(remainingMins),
                              color: const Color(0xFF00897B),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: remainingFraction.clamp(0.0, 1.0),
                      minHeight: 7,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        status == CycleStatus.completed
                            ? const Color(0xFF1565C0)
                            : status == CycleStatus.paused
                                ? const Color(0xFFFFA000)
                                : status == CycleStatus.stopped
                                    ? const Color(0xFFC62828)
                                    : network.brandColor,
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Financial Breakdown: Initial, Consumed, Remaining
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9F9FB),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _financeBox(
                            title: 'المبلغ الأصلي',
                            amount: _formatCurrency(cycle.initialAmount),
                            color: Colors.black87,
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 32,
                          color: Colors.grey.shade300,
                        ),
                        Expanded(
                          child: _financeBox(
                            title: 'المستهلك',
                            amount: _formatCurrency(consumedAmount),
                            color: const Color(0xFFC62828),
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 32,
                          color: Colors.grey.shade300,
                        ),
                        Expanded(
                          child: _financeBox(
                            title: 'المتبقي',
                            amount: _formatCurrency(remainingAmount),
                            color: const Color(0xFF2E7D32),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Action Buttons Row (Start, Pause, Resume, Stop)
                  Row(
                    children: [
                      // Start button (when Idle)
                      if (status == CycleStatus.idle)
                        Expanded(
                          child: _actionButton(
                            label: 'بدء الدورة',
                            icon: Icons.play_arrow_rounded,
                            color: const Color(0xFF2E7D32),
                            onTap: onStart,
                          ),
                        ),

                      // Pause button (when Running)
                      if (status == CycleStatus.running) ...[
                        Expanded(
                          child: _actionButton(
                            label: 'إيقاف مؤقت',
                            icon: Icons.pause_rounded,
                            color: const Color(0xFFE65100),
                            onTap: onPause,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _actionButton(
                            label: 'إنهاء',
                            icon: Icons.stop_rounded,
                            color: const Color(0xFFC62828),
                            isOutlined: true,
                            onTap: onStop,
                          ),
                        ),
                      ],

                      // Resume & Stop buttons (when Paused)
                      if (status == CycleStatus.paused) ...[
                        Expanded(
                          child: _actionButton(
                            label: 'استئناف',
                            icon: Icons.play_arrow_rounded,
                            color: const Color(0xFF2E7D32),
                            onTap: onResume,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _actionButton(
                            label: 'إنهاء',
                            icon: Icons.stop_rounded,
                            color: const Color(0xFFC62828),
                            isOutlined: true,
                            onTap: onStop,
                          ),
                        ),
                      ],

                      // Restart button (when Completed or Stopped)
                      if (status == CycleStatus.completed ||
                          status == CycleStatus.stopped) ...[
                        Expanded(
                          child: _actionButton(
                            label: 'إعادة تشغيل الدورة',
                            icon: Icons.replay_rounded,
                            color: const Color(0xFF6E3B82),
                            onTap: onReset,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniMetric({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.tajawal(
            color: Colors.black54,
            fontSize: 11,
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.tajawal(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _financeBox({
    required String title,
    required String amount,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          title,
          style: GoogleFonts.tajawal(
            color: Colors.black54,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          amount,
          style: GoogleFonts.tajawal(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
    bool isOutlined = false,
  }) {
    if (isOutlined) {
      return OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color.withValues(alpha: 0.6)),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(
          label,
          style: GoogleFonts.tajawal(
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      );
    }

    return FilledButton.icon(
      style: FilledButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(
        label,
        style: GoogleFonts.tajawal(
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }
}
