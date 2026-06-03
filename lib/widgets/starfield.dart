import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Premium cosmic backdrop: a slowly drifting nebula behind three parallax
/// layers of twinkling stars, with the occasional shooting star.
///
/// Everything loops seamlessly over [period] because each periodic effect uses
/// an INTEGER number of cycles, so value 1.0 lands exactly on value 0.0.
/// Cheap to run: nebula is GPU-composited gradients, stars are one CustomPaint,
/// the whole thing sits under a RepaintBoundary.
class Starfield extends StatefulWidget {
  const Starfield({super.key});

  @override
  State<Starfield> createState() => _StarfieldState();
}

class _StarfieldState extends State<Starfield>
    with SingleTickerProviderStateMixin {
  static const _period = Duration(seconds: 120);

  late final AnimationController _c;
  late final List<_Star> _stars;
  late final List<_Shoot> _shoots;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: _period)..repeat();
    final rng = math.Random(7);

    // Three depth layers: far (dim/tiny/slow) -> near (bright/bigger/faster).
    _stars = [
      ..._layer(rng, count: 90, minR: 0.4, maxR: 0.9, alphaLo: 0.15, alphaHi: 0.5, drift: 1),
      ..._layer(rng, count: 55, minR: 0.7, maxR: 1.4, alphaLo: 0.3, alphaHi: 0.8, drift: 2),
      ..._layer(rng, count: 22, minR: 1.2, maxR: 2.1, alphaLo: 0.5, alphaHi: 1.0, drift: 3),
    ];

    // A few shooting stars, spaced through the loop, each finishing before wrap.
    _shoots = List.generate(4, (i) {
      return _Shoot(
        startT: 0.12 + i * 0.22 + rng.nextDouble() * 0.04,
        durT: 0.018 + rng.nextDouble() * 0.01,
        x0: 0.1 + rng.nextDouble() * 0.7,
        y0: 0.05 + rng.nextDouble() * 0.35,
        angle: math.pi * (0.18 + rng.nextDouble() * 0.12), // gentle downward
        len: 120 + rng.nextDouble() * 90,
      );
    });
  }

  List<_Star> _layer(math.Random rng,
      {required int count,
      required double minR,
      required double maxR,
      required double alphaLo,
      required double alphaHi,
      required int drift}) {
    return List.generate(count, (_) {
      final roll = rng.nextDouble();
      final color = roll < 0.10
          ? AppTheme.gold
          : roll < 0.18
              ? AppTheme.purpleBright
              : roll < 0.24
                  ? AppTheme.sky
                  : Colors.white;
      return _Star(
        x: rng.nextDouble(),
        y: rng.nextDouble(),
        r: minR + rng.nextDouble() * (maxR - minR),
        baseAlpha: alphaLo + rng.nextDouble() * (alphaHi - alphaLo),
        twinkle: 3 + rng.nextInt(10), // integer cycles -> seamless
        drift: drift,
        phase: rng.nextDouble(),
        color: color,
      );
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // LayoutBuilder gives the size so nebulas can be DIRECT Positioned children
    // of the Stack. (Wrapping a Positioned in another widget breaks the
    // Stack/StackParentData contract and throws every frame.)
    return RepaintBoundary(
      child: LayoutBuilder(
        builder: (context, c) {
          final w = c.maxWidth, h = c.maxHeight;
          return AnimatedBuilder(
            animation: _c,
            builder: (context, _) {
              final t = _c.value;
              return Stack(
                fit: StackFit.expand,
                children: [
                  _nebula(w, h, t, AppTheme.purple,
                      cx: 0.18, cy: 0.92, rad: 640, baseA: 0.09, drift: 1, phase: 0.0),
                  _nebula(w, h, t, AppTheme.sky,
                      cx: 0.86, cy: 0.96, rad: 560, baseA: 0.06, drift: 1, phase: 0.45),
                  CustomPaint(painter: _SkyPainter(_stars, _shoots, t)),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Positioned _nebula(double w, double h, double t, Color color,
      {required double cx,
      required double cy,
      required double rad,
      required double baseA,
      required int drift,
      required double phase}) {
    final wobble = 2 * math.pi * (t * drift + phase);
    final dx = math.cos(wobble) * 26;
    final dy = math.sin(wobble) * 20;
    final pulse = 0.78 + 0.22 * (0.5 + 0.5 * math.sin(wobble));
    return Positioned(
      left: cx * w - rad / 2 + dx,
      top: cy * h - rad / 2 + dy,
      width: rad,
      height: rad,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: baseA * pulse),
              color.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }
}

class _Star {
  final double x, y, r, baseAlpha, phase;
  final int twinkle, drift;
  final Color color;
  const _Star({
    required this.x,
    required this.y,
    required this.r,
    required this.baseAlpha,
    required this.twinkle,
    required this.drift,
    required this.phase,
    required this.color,
  });
}

class _Shoot {
  final double startT, durT, x0, y0, angle, len;
  const _Shoot({
    required this.startT,
    required this.durT,
    required this.x0,
    required this.y0,
    required this.angle,
    required this.len,
  });
}

class _SkyPainter extends CustomPainter {
  final List<_Star> stars;
  final List<_Shoot> shoots;
  final double t;
  _SkyPainter(this.stars, this.shoots, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint();
    for (final s in stars) {
      final tw = 0.5 + 0.5 * math.sin(2 * math.pi * (t * s.twinkle + s.phase));
      final a = (s.baseAlpha * (0.4 + 0.6 * tw)).clamp(0.0, 1.0);
      final y = ((s.y + t * s.drift) % 1.0) * size.height;
      final x = s.x * size.width;
      final c = s.color;
      // Soft halo via a radial gradient (NOT MaskFilter.blur — that renders as
      // opaque grey boxes when CanvasKit falls back to software rendering).
      if (s.r > 1.2) {
        final glowR = s.r * 3.2;
        p.shader = RadialGradient(
          colors: [c.withValues(alpha: a * 0.45), c.withValues(alpha: 0)],
        ).createShader(Rect.fromCircle(center: Offset(x, y), radius: glowR));
        canvas.drawCircle(Offset(x, y), glowR, p);
        p.shader = null;
      }
      p.color = c.withValues(alpha: a);
      canvas.drawCircle(Offset(x, y), s.r, p);
    }
    _paintShoots(canvas, size);
  }

  void _paintShoots(Canvas canvas, Size size) {
    for (final s in shoots) {
      if (t < s.startT || t > s.startT + s.durT) continue;
      final p = ((t - s.startT) / s.durT).clamp(0.0, 1.0);
      final hx = s.x0 * size.width + math.cos(s.angle) * s.len * p * 2.4;
      final hy = s.y0 * size.height + math.sin(s.angle) * s.len * p * 2.4;
      final tx = hx - math.cos(s.angle) * s.len;
      final ty = hy - math.sin(s.angle) * s.len;
      // fade in then out
      final alpha = (math.sin(math.pi * p)).clamp(0.0, 1.0);
      final paint = Paint()
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round
        ..shader = ui_gradient(Offset(tx, ty), Offset(hx, hy), alpha);
      canvas.drawLine(Offset(tx, ty), Offset(hx, hy), paint);
      // bright head
      canvas.drawCircle(
        Offset(hx, hy),
        1.8,
        Paint()..color = Colors.white.withValues(alpha: alpha),
      );
    }
  }

  Shader ui_gradient(Offset from, Offset to, double alpha) {
    return LinearGradient(
      colors: [
        Colors.white.withValues(alpha: 0),
        AppTheme.sky.withValues(alpha: alpha * 0.6),
        Colors.white.withValues(alpha: alpha),
      ],
      stops: const [0, 0.6, 1],
    ).createShader(Rect.fromPoints(from, to));
  }

  @override
  bool shouldRepaint(_SkyPainter old) => old.t != t;
}
