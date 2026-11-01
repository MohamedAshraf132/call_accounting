import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:call_accounting/models/cycle_model.dart';
import 'package:call_accounting/services/cycle_manager.dart';
import 'package:call_accounting/widgets/cycle_card.dart';
import 'package:call_accounting/widgets/stat_card.dart';
import 'package:call_accounting/screens/add_cycle_dialog.dart';

enum DashboardFilter { all, active, completed, stopped }

class DashboardScreen extends StatefulWidget {
  final CycleManager cycleManager;

  const DashboardScreen({
    super.key,
    required this.cycleManager,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DashboardFilter _filter = DashboardFilter.all;

  List<CallCycle> _getFilteredCycles(List<CallCycle> cycles) {
    return switch (_filter) {
      DashboardFilter.all => cycles,
      DashboardFilter.active => cycles
          .where((c) =>
              c.status == CycleStatus.running ||
              c.status == CycleStatus.paused ||
              c.status == CycleStatus.idle)
          .toList(),
      DashboardFilter.completed =>
        cycles.where((c) => c.status == CycleStatus.completed).toList(),
      DashboardFilter.stopped =>
        cycles.where((c) => c.status == CycleStatus.stopped).toList(),
    };
  }

  Future<void> _openAddCycleDialog() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddCycleDialog(
        pricingConfig: widget.cycleManager.pricingConfig,
        nextCycleIndex: widget.cycleManager.cycles.length + 1,
      ),
    );

    if (result != null && mounted) {
      final newCycle = await widget.cycleManager.addCycle(
        name: result['name'] as String,
        network: result['network'] as NetworkPreset,
        peopleCount: result['peopleCount'] as int,
        initialAmount: result['initialAmount'] as double,
        customRatePerMinute: result['customRate'] as double?,
        notes: result['notes'] as String? ?? '',
      );

      final autoStart = result['autoStart'] as bool? ?? false;
      if (autoStart) {
        await widget.cycleManager.startCycle(newCycle.id);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF2E7D32),
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  'تمت إضافة "${newCycle.name}" بنجاح',
                  style: GoogleFonts.tajawal(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        );
      }
    }
  }

  void _confirmDeleteCycle(CallCycle cycle) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'حذف الدورة',
          style: GoogleFonts.tajawal(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'هل أنت متأكد من حذف دورة "${cycle.name}"؟ سيتم حذفها نهائياً من سجل اليوم.',
          style: GoogleFonts.tajawal(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('إلغاء', style: GoogleFonts.tajawal()),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC62828),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              widget.cycleManager.deleteCycle(cycle.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'تم حذف "${cycle.name}"',
                    style: GoogleFonts.tajawal(),
                  ),
                ),
              );
            },
            child: Text('حذف', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cycles = widget.cycleManager.cycles;
    final filtered = _getFilteredCycles(cycles);
    final stats = widget.cycleManager.getDailyStats(DateTime.now());

    final runningCount = widget.cycleManager.runningCycles.length;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      body: CustomScrollView(
        slivers: [
          // Quick Stats Banner
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Active Status Bar
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: runningCount > 0
                            ? [const Color(0xFF1B5E20), const Color(0xFF2E7D32)]
                            : [const Color(0xFF4527A0), const Color(0xFF673AB7)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: (runningCount > 0
                                  ? const Color(0xFF2E7D32)
                                  : const Color(0xFF673AB7))
                              .withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            runningCount > 0
                                ? Icons.timer_rounded
                                : Icons.phonelink_ring_rounded,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                runningCount > 0
                                    ? '$runningCount دورات تعمل الآن بالتزامن'
                                    : 'لا توجد دورات نشطة حالياً',
                                style: GoogleFonts.tajawal(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'إجمالي اليوم: ${stats.totalPeople} شخص • ${stats.totalInitialAmount.toStringAsFixed(1)} ج.م • ${stats.totalAllocatedMinutes.toStringAsFixed(0)} دقيقة',
                                style: GoogleFonts.tajawal(
                                  color: Colors.white.withValues(alpha: 0.85),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // 3 Quick Stat Cards
                  Row(
                    children: [
                      Expanded(
                        child: StatCard(
                          title: 'المتبقي',
                          value: '${stats.totalRemainingMinutes.toStringAsFixed(1)} د',
                          subtitle: '${stats.totalRemainingAmount.toStringAsFixed(1)} ج.م',
                          icon: Icons.hourglass_top_rounded,
                          color: const Color(0xFF00897B),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: StatCard(
                          title: 'المستهلك',
                          value: '${stats.totalConsumedMinutes.toStringAsFixed(1)} د',
                          subtitle: '${stats.totalConsumedAmount.toStringAsFixed(1)} ج.م',
                          icon: Icons.history_toggle_off_rounded,
                          color: const Color(0xFFE65100),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: StatCard(
                          title: 'المكتملة',
                          value: '${stats.completedCount}',
                          subtitle: 'من أصل ${stats.totalCycles}',
                          icon: Icons.task_alt_rounded,
                          color: const Color(0xFF1565C0),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip(
                          filter: DashboardFilter.all,
                          label: 'الكل (${cycles.length})',
                          icon: Icons.apps_rounded,
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          filter: DashboardFilter.active,
                          label: 'النشطة (${widget.cycleManager.activeCycles.length})',
                          icon: Icons.play_circle_fill_rounded,
                          activeColor: const Color(0xFF2E7D32),
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          filter: DashboardFilter.completed,
                          label: 'المكتملة (${stats.completedCount})',
                          icon: Icons.check_circle_rounded,
                          activeColor: const Color(0xFF1565C0),
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          filter: DashboardFilter.stopped,
                          label: 'المتوقفة (${stats.stoppedCount})',
                          icon: Icons.cancel_rounded,
                          activeColor: const Color(0xFFC62828),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Cycles List or Empty State
          if (filtered.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: const BoxDecoration(
                          color: Color(0xFFEDE7F6),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.phone_in_talk_rounded,
                          size: 56,
                          color: Color(0xFF673AB7),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        _filter == DashboardFilter.all
                            ? 'لا توجد دورات مسجلة بعد'
                            : 'لا توجد دورات مطابقة لهذا التصنيف',
                        style: GoogleFonts.tajawal(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'ابدأ بإضافة دورة اتصال جديدة وحدد عدد الأشخاص والمبلغ لبدء العد التنازلي التلقائي.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.tajawal(
                          fontSize: 13,
                          color: Colors.black54,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _openAddCycleDialog,
                        icon: const Icon(Icons.add_rounded),
                        label: Text(
                          'إضافة أول دورة اتصال',
                          style: GoogleFonts.tajawal(fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF673AB7),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, index) {
                    final cycle = filtered[index];
                    return CycleCard(
                      key: ValueKey(cycle.id),
                      cycle: cycle,
                      onStart: () => widget.cycleManager.startCycle(cycle.id),
                      onPause: () => widget.cycleManager.pauseCycle(cycle.id),
                      onResume: () => widget.cycleManager.resumeCycle(cycle.id),
                      onStop: () => widget.cycleManager.stopCycle(cycle.id),
                      onReset: () => widget.cycleManager.resetCycle(cycle.id),
                      onDelete: () => _confirmDeleteCycle(cycle),
                    );
                  },
                  childCount: filtered.length,
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddCycleDialog,
        backgroundColor: const Color(0xFF673AB7),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text(
          'دورة جديدة',
          style: GoogleFonts.tajawal(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required DashboardFilter filter,
    required String label,
    required IconData icon,
    Color activeColor = const Color(0xFF673AB7),
  }) {
    final isSelected = _filter == filter;
    return InkWell(
      onTap: () => setState(() => _filter = filter),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? activeColor : Colors.grey.shade300,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: activeColor.withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : Colors.black54,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.tajawal(
                color: isSelected ? Colors.white : Colors.black87,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
