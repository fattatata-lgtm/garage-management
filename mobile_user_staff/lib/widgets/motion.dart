import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../core/theme.dart';

/// Penghitung jeda berurutan: widget yang muncul pada frame yang sama
/// diberi jeda bertingkat sehingga tampil seperti gelombang (stagger).
class _Stagger {
  static int _n = 0;
  static bool _scheduled = false;

  static Duration next() {
    final d = Duration(milliseconds: _n.clamp(0, 8) * 45);
    _n++;
    if (!_scheduled) {
      _scheduled = true;
      SchedulerBinding.instance.addPostFrameCallback((_) {
        _n = 0;
        _scheduled = false;
      });
    }
    return d;
  }
}

bool _reduceMotion() => SchedulerBinding.instance.platformDispatcher.accessibilityFeatures.disableAnimations;

/// Muncul dengan memudar + naik halus. Jeda otomatis bertingkat bila banyak widget muncul bersamaan.
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({
    super.key,
    required this.child,
    this.delay,
    this.offset = 14,
    this.duration = const Duration(milliseconds: 420),
  });

  final Widget child;
  final Duration? delay;
  final double offset;
  final Duration duration;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: widget.duration);
  late final Animation<double> _curve = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (_reduceMotion()) {
      _c.value = 1;
      return;
    }
    final d = widget.delay ?? _Stagger.next();
    if (d == Duration.zero) {
      _c.forward();
    } else {
      _timer = Timer(d, () {
        if (mounted) _c.forward();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _curve,
      child: widget.child,
      builder: (context, child) => Opacity(
        opacity: _curve.value,
        child: Transform.translate(offset: Offset(0, (1 - _curve.value) * widget.offset), child: child),
      ),
    );
  }
}

/// Efek tekan: mengecil sedikit saat disentuh. Tidak mengganggu gestur anak.
class Pressable extends StatefulWidget {
  const Pressable({super.key, required this.child, this.enabled = true, this.scale = 0.97});
  final Widget child;
  final bool enabled;
  final double scale;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  void _set(bool v) {
    if (!widget.enabled || _down == v) return;
    setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _set(true),
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: AnimatedScale(
        scale: _down ? widget.scale : 1,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// Titik berdenyut (untuk status yang sedang berjalan).
class PulseDot extends StatefulWidget {
  const PulseDot({super.key, required this.color, this.size = 6});
  final Color color;
  final double size;

  @override
  State<PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<PulseDot> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));

  @override
  void initState() {
    super.initState();
    if (!_reduceMotion()) _c.repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    return SizedBox(
      width: s * 2.4,
      height: s * 2.4,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final t = Curves.easeOut.transform(_c.value);
          return Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: s + s * 1.4 * t,
                height: s + s * 1.4 * t,
                decoration: BoxDecoration(shape: BoxShape.circle, color: widget.color.withAlpha(((1 - t) * 90).round())),
              ),
              Container(width: s, height: s, decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle)),
            ],
          );
        },
      ),
    );
  }
}

/// Kerangka (skeleton) saat memuat data: kartu-kartu berdenyut lembut.
class SkeletonList extends StatefulWidget {
  const SkeletonList({super.key, this.count = 5});
  final int count;

  @override
  State<SkeletonList> createState() => _SkeletonListState();
}

class _SkeletonListState extends State<SkeletonList> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));

  @override
  void initState() {
    super.initState();
    if (!_reduceMotion()) _c.repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = C.isDark(context);
    final base = dark ? D.surface2 : const Color(0xFFE6EBF4);
    final card = C.cardOf(context);
    final line = C.lineOf(context);
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final o = 0.45 + 0.55 * Curves.easeInOut.transform(_c.value);
        Widget bar(double w, double h) => Container(
              width: w,
              height: h,
              decoration: BoxDecoration(color: base, borderRadius: BorderRadius.circular(6)),
            );
        return Opacity(
          opacity: o,
          child: ListView.builder(
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            itemCount: widget.count,
            itemBuilder: (context, i) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: card,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: line),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(color: base, borderRadius: BorderRadius.circular(14)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [bar(150, 12), const SizedBox(height: 8), bar(100, 10), const SizedBox(height: 6), bar(70, 9)],
                    ),
                  ),
                  bar(54, 18),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Membesar-mengecil pelan (efek "bernapas"), mis. untuk logo di layar splash.
class Breathing extends StatefulWidget {
  const Breathing({super.key, required this.child, this.amount = 0.1});
  final Widget child;
  final double amount;

  @override
  State<Breathing> createState() => _BreathingState();
}

class _BreathingState extends State<Breathing> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));

  @override
  void initState() {
    super.initState();
    if (!_reduceMotion()) _c.repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween<double>(begin: 1, end: 1 + widget.amount).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut)),
      child: widget.child,
    );
  }
}
