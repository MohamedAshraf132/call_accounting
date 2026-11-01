import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:call_accounting/models/cycle_model.dart';

class TimerDisplay extends StatefulWidget {
  final int remainingSeconds;
  final CycleStatus status;
  final Color accentColor;
  final bool compact;

  const TimerDisplay({
    super.key,
    required this.remainingSeconds,
    required this.status,
    required this.accentColor,
    this.compact = false,
  });

  @override
  State<TimerDisplay> createState() => _TimerDisplayState();
}

class _TimerDisplayState extends State<TimerDisplay>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (widget.status == CycleStatus.running) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant TimerDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.status == CycleStatus.running) {
      if (!_pulseController.isAnimating) {
        _pulseController.repeat(reverse: true);
      }
    } else {
      if (_pulseController.isAnimating) {
        _pulseController.stop();
        _pulseController.reset();
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  String _formatTime(int totalSeconds) {
    if (totalSeconds <= 0) return '00:00';
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    final mStr = minutes.toString().padLeft(2, '0');
    final sStr = seconds.toString().padLeft(2, '0');

    if (hours > 0) {
      final hStr = hours.toString().padLeft(2, '0');
      return '$hStr:$mStr:$sStr';
    }
    return '$mStr:$sStr';
  }

  @override
  Widget build(BuildContext context) {
    final isRunning = widget.status == CycleStatus.running;
    final isPaused = widget.status == CycleStatus.paused;
    final isCompleted = widget.status == CycleStatus.completed;
    final isStopped = widget.status == CycleStatus.stopped;

    Color bg;
    Color border;
    Color textCol;

    if (isRunning) {
      bg = widget.accentColor.withValues(alpha: 0.08);
      border = widget.accentColor.withValues(alpha: 0.35);
      textCol = widget.accentColor;
    } else if (isPaused) {
      bg = const Color(0xFFFFF3E0);
      border = const Color(0xFFFFB74D);
      textCol = const Color(0xFFE65100);
    } else if (isCompleted) {
      bg = const Color(0xFFE8F5E9);
      border = const Color(0xFF81C784);
      textCol = const Color(0xFF2E7D32);
    } else if (isStopped) {
      bg = const Color(0xFFFFEBEE);
      border = const Color(0xFFE57373);
      textCol = const Color(0xFFC62828);
    } else {
      bg = const Color(0xFFF5F5F7);
      border = const Color(0xFFE0E0E0);
      textCol = const Color(0xFF455A64);
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: widget.compact ? 12 : 16,
        vertical: widget.compact ? 8 : 10,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border, width: 1.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isRunning)
                ScaleTransition(
                  scale: _pulseAnimation,
                  child: Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(left: 6),
                    decoration: BoxDecoration(
                      color: textCol,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              Text(
                widget.status.titleAr,
                style: GoogleFonts.tajawal(
                  color: textCol,
                  fontSize: widget.compact ? 11 : 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            _formatTime(widget.remainingSeconds),
            style: GoogleFonts.tajawal(
              color: textCol,
              fontSize: widget.compact ? 22 : 28,
              fontWeight: FontWeight.w800,
              letterSpacing: 2.0,
            ),
          ),
        ],
      ),
    );
  }
}
