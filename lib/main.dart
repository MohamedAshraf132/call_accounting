import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:call_accounting/models/cycle_model.dart';
import 'package:call_accounting/services/cycle_manager.dart';
import 'package:call_accounting/screens/dashboard_screen.dart';
import 'package:call_accounting/screens/daily_history_screen.dart';
import 'package:call_accounting/screens/pricing_settings_dialog.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  await initializeDateFormatting('ar');
  // Ensure Android status bar and orientation look great
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const MultiTimerCallApp());
}

class MultiTimerCallApp extends StatelessWidget {
  const MultiTimerCallApp({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = GoogleFonts.tajawalTextTheme(ThemeData.light().textTheme);

    return MaterialApp(
      title: 'حساب الدقائق والمكالمات',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF673AB7),
          primary: const Color(0xFF673AB7),
          secondary: const Color(0xFF00897B),
          surface: Colors.white,
        ),
        textTheme: textTheme,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: GoogleFonts.tajawal(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      builder: (context, child) {
        // Enforce RTL Arabic layout across the entire application
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        );
      },
      home: const MainNavigationShell(),
    );
  }
}

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  late final CycleManager _cycleManager;
  StreamSubscription<CallCycle>? _completionSubscription;
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _cycleManager = CycleManager();
    _cycleManager.addListener(_onManagerUpdated);

    // Subscribe to completion events across all independent cycles
    _completionSubscription = _cycleManager.onCycleCompleted.listen((cycle) {
      if (!mounted) return;
      _showCompletionNotification(cycle);
    });
  }

  void _onManagerUpdated() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _completionSubscription?.cancel();
    _cycleManager.removeListener(_onManagerUpdated);
    _cycleManager.dispose();
    super.dispose();
  }

  void _showCompletionNotification(CallCycle cycle) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF2E7D32).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.alarm_on_rounded,
                color: Color(0xFF2E7D32),
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'انتهى وقت الدورة!',
                style: GoogleFonts.tajawal(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: const Color(0xFF2E7D32),
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'اكتملت دورة "${cycle.name}" ووصل المؤقت إلى 00:00.',
              style: GoogleFonts.tajawal(fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F7FA),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('الشبكة:', style: GoogleFonts.tajawal(fontSize: 12, color: Colors.black54)),
                      Text(cycle.network.titleAr, style: GoogleFonts.tajawal(fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('المبلغ:', style: GoogleFonts.tajawal(fontSize: 12, color: Colors.black54)),
                      Text('${cycle.initialAmount.toStringAsFixed(2)} ج.م', style: GoogleFonts.tajawal(fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('الدقائق:', style: GoogleFonts.tajawal(fontSize: 12, color: Colors.black54)),
                      Text('${(cycle.totalDurationSeconds / 60).toStringAsFixed(1)} دقيقة', style: GoogleFonts.tajawal(fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: Text('حسناً', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _openPricingDialog() {
    showDialog(
      context: context,
      builder: (ctx) => PricingSettingsDialog(
        currentConfig: _cycleManager.pricingConfig,
        onSaved: (newConfig) {
          _cycleManager.updatePricingConfig(newConfig);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'تم حفظ إعدادات تسعير الشبكات',
                style: GoogleFonts.tajawal(),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_cycleManager.isInitialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final runningCount = _cycleManager.runningCycles.length;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF673AB7).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.call_rounded,
                color: Color(0xFF673AB7),
                size: 22,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'إدارة المكالمات والدورات',
                  style: GoogleFonts.tajawal(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  runningCount > 0
                      ? '$runningCount دورات نشطة بالتزامن'
                      : 'مؤقتات مستقلة وحساب فوري',
                  style: GoogleFonts.tajawal(
                    fontSize: 11,
                    color: runningCount > 0
                        ? const Color(0xFF2E7D32)
                        : Colors.black45,
                    fontWeight: runningCount > 0 ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            tooltip: 'تسعير الشبكات',
            onPressed: _openPricingDialog,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: IndexedStack(
        index: _currentTabIndex,
        children: [
          DashboardScreen(cycleManager: _cycleManager),
          DailyHistoryScreen(cycleManager: _cycleManager),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _currentTabIndex,
          onDestinationSelected: (index) {
            setState(() => _currentTabIndex = index);
          },
          backgroundColor: Colors.white,
          indicatorColor: const Color(0xFF673AB7).withValues(alpha: 0.15),
          destinations: [
            NavigationDestination(
              icon: Badge(
                isLabelVisible: runningCount > 0,
                label: Text(
                  '$runningCount',
                  style: GoogleFonts.tajawal(fontSize: 10, fontWeight: FontWeight.bold),
                ),
                backgroundColor: const Color(0xFF2E7D32),
                child: const Icon(Icons.dashboard_outlined),
              ),
              selectedIcon: Badge(
                isLabelVisible: runningCount > 0,
                label: Text(
                  '$runningCount',
                  style: GoogleFonts.tajawal(fontSize: 10, fontWeight: FontWeight.bold),
                ),
                backgroundColor: const Color(0xFF2E7D32),
                child: const Icon(Icons.dashboard_rounded, color: Color(0xFF673AB7)),
              ),
              label: 'لوحة المتابعة',
            ),
            const NavigationDestination(
              icon: Icon(Icons.analytics_outlined),
              selectedIcon: Icon(Icons.analytics_rounded, color: Color(0xFF673AB7)),
              label: 'سجل اليوم والتقرير المالي',
            ),
          ],
        ),
      ),
    );
  }
}
