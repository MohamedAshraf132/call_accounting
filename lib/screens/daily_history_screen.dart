import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' as intl;
import 'package:call_accounting/models/cycle_model.dart';
import 'package:call_accounting/services/cycle_manager.dart';
import 'package:call_accounting/widgets/stat_card.dart';

class DailyHistoryScreen extends StatefulWidget {
  final CycleManager cycleManager;

  const DailyHistoryScreen({
    super.key,
    required this.cycleManager,
  });

  @override
  State<DailyHistoryScreen> createState() => _DailyHistoryScreenState();
}

class _DailyHistoryScreenState extends State<DailyHistoryScreen> {
  DateTime _selectedDate = DateTime.now();

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void _previousDay() {
    setState(() {
      _selectedDate = _selectedDate.subtract(const Duration(days: 1));
    });
  }

  void _nextDay() {
    setState(() {
      _selectedDate = _selectedDate.add(const Duration(days: 1));
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('ar'),
      builder: (ctx, child) {
        return Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF673AB7),
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  String _formatDateTitle(DateTime date) {
    final now = DateTime.now();
    if (_isSameDay(date, now)) return 'اليوم (${intl.DateFormat('yyyy/MM/dd').format(date)})';
    final yesterday = now.subtract(const Duration(days: 1));
    if (_isSameDay(date, yesterday)) return 'أمس (${intl.DateFormat('yyyy/MM/dd').format(date)})';
    return intl.DateFormat('EEEE، d MMMM yyyy', 'ar').format(date);
  }

  String _formatTime(DateTime? dt) {
    if (dt == null) return '--:--';
    return intl.DateFormat('hh:mm a', 'ar').format(dt);
  }

  String _formatMinutes(double minutes) {
    if (minutes == minutes.roundToDouble()) {
      return '${minutes.toInt()} د';
    }
    return '${minutes.toStringAsFixed(1)} د';
  }

  @override
  Widget build(BuildContext context) {
    final stats = widget.cycleManager.getDailyStats(_selectedDate);
    final dayCycles = widget.cycleManager.getCyclesForDate(_selectedDate);
    final isToday = _isSameDay(_selectedDate, DateTime.now());

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      body: CustomScrollView(
        slivers: [
          // Date Selector Header
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
                    tooltip: 'اليوم السابق',
                    onPressed: _previousDay,
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: _pickDate,
                      borderRadius: BorderRadius.circular(10),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.calendar_month_rounded,
                              size: 20,
                              color: Color(0xFF673AB7),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                _formatDateTitle(_selectedDate),
                                style: GoogleFonts.tajawal(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_rounded, size: 18),
                    tooltip: 'اليوم التالي',
                    onPressed: _nextDay,
                  ),
                  if (!isToday)
                    TextButton(
                      onPressed: () => setState(() => _selectedDate = DateTime.now()),
                      child: Text(
                        'اليوم',
                        style: GoogleFonts.tajawal(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF673AB7),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Financial & Calls Summary Cards
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Main Financial Balance Banner
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF283593), Color(0xFF3949AB)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF283593).withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          'إجمالي المبالغ المدخلة',
                          style: GoogleFonts.tajawal(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${stats.totalInitialAmount.toStringAsFixed(2)} ج.م',
                          style: GoogleFonts.tajawal(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Divider(color: Colors.white24, height: 1),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                children: [
                                  Text(
                                    'المبلغ المستهلك',
                                    style: GoogleFonts.tajawal(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${stats.totalConsumedAmount.toStringAsFixed(2)} ج.م',
                                    style: GoogleFonts.tajawal(
                                      color: const Color(0xFFFFCC80),
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(width: 1, height: 32, color: Colors.white24),
                            Expanded(
                              child: Column(
                                children: [
                                  Text(
                                    'الرصيد المتبقي',
                                    style: GoogleFonts.tajawal(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${stats.totalRemainingAmount.toStringAsFixed(2)} ج.م',
                                    style: GoogleFonts.tajawal(
                                      color: const Color(0xFFA7FFEB),
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // 4 Detailed Metrics
                  Row(
                    children: [
                      Expanded(
                        child: StatCard(
                          title: 'إجمالي الأشخاص / المكالمات',
                          value: '${stats.totalPeople}',
                          subtitle: 'ضمن ${stats.totalCycles} دورات',
                          icon: Icons.people_alt_rounded,
                          color: const Color(0xFF673AB7),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: StatCard(
                          title: 'الدورات المكتملة',
                          value: '${stats.completedCount}',
                          subtitle: stats.runningCount > 0 ? '${stats.runningCount} قيد التشغيل' : 'مكتملة بالكامل',
                          icon: Icons.verified_rounded,
                          color: const Color(0xFF2E7D32),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Expanded(
                        child: StatCard(
                          title: 'الدقائق المخصصة',
                          value: _formatMinutes(stats.totalAllocatedMinutes),
                          subtitle: 'إجمالي وقت المكالمات',
                          icon: Icons.access_time_filled_rounded,
                          color: const Color(0xFF00897B),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: StatCard(
                          title: 'الدقائق المستهلكة',
                          value: _formatMinutes(stats.totalConsumedMinutes),
                          subtitle: 'متبقي ${_formatMinutes(stats.totalRemainingMinutes)}',
                          icon: Icons.av_timer_rounded,
                          color: const Color(0xFFE65100),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Network Financial Breakdown Section
                  Text(
                    'تفصيل الشبكات',
                    style: GoogleFonts.tajawal(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildNetworkBreakdownGrid(stats.networkBreakdown),

                  const SizedBox(height: 22),

                  // Detailed Cycles History Title
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'سجل الدورات بالتفصيل (${dayCycles.length})',
                        style: GoogleFonts.tajawal(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),

          // Chronological Cycles List
          if (dayCycles.isEmpty)
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.all(24),
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.history_toggle_off_rounded,
                      size: 48,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'لا توجد سجلات مكالمات مسجلة في هذا اليوم',
                      style: GoogleFonts.tajawal(
                        fontSize: 14,
                        color: Colors.black54,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, index) {
                    final cycle = dayCycles[index];
                    return _buildHistoryCycleCard(cycle);
                  },
                  childCount: dayCycles.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNetworkBreakdownGrid(Map<NetworkPreset, NetworkSummary> map) {
    final activeEntries = map.entries.where((e) => e.value.cycleCount > 0).toList();

    if (activeEntries.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Center(
          child: Text(
            'لم يتم استخدام أي شبكة في هذا اليوم بعد',
            style: GoogleFonts.tajawal(color: Colors.black45, fontSize: 13),
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: activeEntries.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.8,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemBuilder: (ctx, index) {
        final entry = activeEntries[index];
        final net = entry.key;
        final summary = entry.value;

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: net.brandColor.withValues(alpha: 0.2)),
            boxShadow: [
              BoxShadow(
                color: net.brandColor.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Icon(net.icon, color: net.brandColor, size: 18),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      net.titleAr,
                      style: GoogleFonts.tajawal(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${summary.money.toStringAsFixed(1)} ج.م',
                    style: GoogleFonts.tajawal(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: net.brandColor,
                    ),
                  ),
                  Text(
                    '${summary.minutes.toStringAsFixed(0)} دقيقة',
                    style: GoogleFonts.tajawal(
                      fontSize: 11,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
              Text(
                '${summary.cycleCount} دورات • ${summary.peopleCount} أشخاص',
                style: GoogleFonts.tajawal(
                  fontSize: 10,
                  color: Colors.black45,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHistoryCycleCard(CallCycle cycle) {
    final now = DateTime.now();
    final consumedAmount = cycle.getConsumedAmount(now: now);
    final remainingAmount = cycle.getRemainingAmount(now: now);
    final consumedMins = cycle.getElapsedSeconds(now: now) / 60.0;
    final totalMins = cycle.totalDurationSeconds / 60.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: cycle.status.color.withValues(alpha: 0.25),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Name, Status Badge, Network
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: cycle.network.brandColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  cycle.network.icon,
                  color: cycle.network.brandColor,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cycle.name,
                      style: GoogleFonts.tajawal(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${cycle.network.titleAr} • ${cycle.peopleCount} شخص',
                      style: GoogleFonts.tajawal(
                        fontSize: 11,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: cycle.status.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: cycle.status.color.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(cycle.status.icon, size: 12, color: cycle.status.color),
                    const SizedBox(width: 4),
                    Text(
                      cycle.status.titleAr,
                      style: GoogleFonts.tajawal(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: cycle.status.color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 10),

          // Timestamps & Metrics
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildCompactInfo(
                'وقت البدء',
                _formatTime(cycle.startedAt ?? cycle.createdAt),
                Icons.play_circle_outline_rounded,
              ),
              _buildCompactInfo(
                'وقت الانتهاء',
                _formatTime(cycle.endedAt),
                Icons.check_circle_outline_rounded,
              ),
              _buildCompactInfo(
                'الدقائق',
                '${consumedMins.toStringAsFixed(1)} / ${totalMins.toStringAsFixed(1)} د',
                Icons.timer_outlined,
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Financial Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFC),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              spacing: 12,
              runSpacing: 4,
              children: [
                Text(
                  'المبلغ الأساسي: ${cycle.initialAmount.toStringAsFixed(2)} ج.م',
                  style: GoogleFonts.tajawal(fontSize: 11, color: Colors.black87),
                ),
                Text(
                  'المستهلك: ${consumedAmount.toStringAsFixed(2)} ج.م',
                  style: GoogleFonts.tajawal(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFE65100),
                  ),
                ),
                Text(
                  'المتبقي: ${remainingAmount.toStringAsFixed(2)} ج.م',
                  style: GoogleFonts.tajawal(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF00897B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactInfo(String label, String value, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.black45),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.tajawal(fontSize: 9, color: Colors.black45),
            ),
            Text(
              value,
              style: GoogleFonts.tajawal(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
