import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Animated cosmic starfield, matching the live weirdbrains.com canvas.
/// Twinkling + slowly drifting stars, plus a few floating doodles.
///
/// The loop is seamless: per-star twinkle and drift use INTEGER cycle counts
/// over the controller period, so value 1.0 lands exactly where 0.0 began.
class Starfield extends StatefulWidget {
  final int starCount;
  const Starfield({super.key, this.starCount = 150});

  @override
  State<Starfield> createState() => _StarfieldState();
}

class _StarfieldState extends State<Starfield>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_Star> _stars;
  late final List<_Doodle> _doodles;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    )..repeat();

    final rng = math.Random(42); // fixed seed → stable layout across rebuilds
    _stars = List.generate(widget.starCount, (_) {
      final roll = rng.nextDouble();
      final color = roll < 0.12
          ? AppTheme.gold
          : roll < 0.20
              ? AppTheme.purple
              : Colors.white;
      return _Star(
        x: rng.nextDouble(),
        y: rng.nextDouble(),
        radius: 0.4 + rng.nextDouble() * 1.5,
        baseOpacity: 0.2 + rng.nextDouble() * 0.7,
        twinkleCycles: 5 + rng.nextInt(14), // integer → seamless
        driftCycles: rng.nextInt(2), // 0 or 1 → subtle, seamless
        phase: rng.nextDouble(),
        color: color,
      );
    });

    const glyphs = ['🧠', '✨', '🚀', '🪐', '💫'];
    _doodles = List.generate(5, (i) {
      return _Doodle(
        glyph: glyphs[i % glyphs.length],
        x: 0.08 + rng.nextDouble() * 0.84,
        y: 0.12 + rng.nextDouble() * 0.7,
        size: 16 + rng.nextDouble() * 14,
        bobCycles: 1 + rng.nextInt(2),
        phase: rng.nextDouble(),
        opacity: 0.12 + rng.nextDouble() * 0.18,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        return Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(painter: _StarPainter(_stars, t)),
            for (final d in _doodles) _positionDoodle(context, d, t),
          ],
        );
      },
    );
  }

  Widget _positionDoodle(BuildContext context, _Doodle d, double t) {
    final size = MediaQuery.of(context).size;
    final bob = math.sin(2 * math.pi * (t * d.bobCycles + d.phase)) * 10;
    return Positioned(
      left: d.x * size.width,
      top: d.y * size.height + bob,
      child: Opacity(
        opacity: d.opacity,
        child: Text(d.glyph, style: TextStyle(fontSize: d.size)),
      ),
    );
  }
}

class _Star {
  final double x, y, radius, baseOpacity, phase;
  final int twinkleCycles, driftCycles;
  final Color color;
  const _Star({
    required this.x,
    required this.y,
    required this.radius,
    required this.baseOpacity,
    required this.twinkleCycles,
    required this.driftCycles,
    required this.phase,
    required this.color,
  });
}

class _Doodle {
  final String glyph;
  final double x, y, size, phase, opacity;
  final int bobCycles;
  const _Doodle({
    required this.glyph,
    required this.x,
    required this.y,
    required this.size,
    required this.bobCycles,
    required this.phase,
    required this.opacity,
  });
}

class _StarPainter extends CustomPainter {
  final List<_Star> stars;
  final double t; // 0..1
  _StarPainter(this.stars, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (final s in stars) {
      // Twinkle: integer cycles → identical at t=0 and t=1 (seamless).
      final tw = 0.5 + 0.5 * math.sin(2 * math.pi * (t * s.twinkleCycles + s.phase));
      final opacity = (s.baseOpacity * (0.35 + 0.65 * tw)).clamp(0.0, 1.0);

      // Slow vertical drift, wraps seamlessly.
      final y = ((s.y + t * s.driftCycles) % 1.0) * size.height;
      final x = s.x * size.width;

      paint.color = s.color.withValues(alpha: opacity);
      // Faint glow for the larger stars.
      if (s.radius > 1.1) {
        paint
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0)
          ..color = s.color.withValues(alpha: opacity * 0.5);
        canvas.drawCircle(Offset(x, y), s.radius * 2.2, paint);
        paint.maskFilter = null;
      }
      paint.color = s.color.withValues(alpha: opacity);
      canvas.drawCircle(Offset(x, y), s.radius, paint);
    }
  }

  @override
  bool shouldRepaint(_StarPainter old) => old.t != t;
}
