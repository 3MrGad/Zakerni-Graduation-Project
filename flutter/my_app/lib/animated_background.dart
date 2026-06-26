import 'package:flutter/material.dart';
import 'package:simple_animations/simple_animations.dart';

class AnimatedBackground extends StatelessWidget {
  const AnimatedBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(color: Colors.blue[50]),
        Positioned(
          top: 100,
          left: 50,
          child: _AnimatedCircle(
            size: 80,
            color: Colors.blue[100]!,
            delay: 0,
          ),
        ),
        Positioned(
          bottom: 150,
          right: 80,
          child: _AnimatedCircle(
            size: 120,
            color: Colors.lightBlue[100]!,
            delay: 1,
          ),
        ),
        Positioned.fill(child: _AnimatedWaves()),
        Positioned(
          top: 200,
          right: 40,
          child: _AnimatedStar(),
        ),
        Positioned(
          bottom: 80,
          left: 30,
          child: _AnimatedStar(),
        ),
      ],
    );
  }
}

class _AnimatedCircle extends StatelessWidget {
  final double size;
  final Color color;
  final double delay;
  const _AnimatedCircle({
    required this.size,
    required this.color,
    required this.delay,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return PlayAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(seconds: 4),
      delay: Duration(seconds: delay.toInt()),
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.8 + 0.4 * value,
          child: Opacity(
            opacity: 0.3 + 0.2 * value,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AnimatedWaves extends StatelessWidget {
  const _AnimatedWaves({super.key});

  @override
  Widget build(BuildContext context) {
    return PlayAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(seconds: 6),
      builder: (context, value, child) {
        return CustomPaint(painter: _WavePainter(value));
      },
    );
  }
}

class _WavePainter extends CustomPainter {
  final double animationValue;
  _WavePainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue[100]!.withOpacity(0.2)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height * 0.7);
    for (double i = 0; i <= size.width; i += 10) {
      path.quadraticBezierTo(
        i + 5,
        size.height * 0.7 + 30 * animationValue,
        i + 10,
        size.height * 0.7,
      );
    }
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _AnimatedStar extends StatelessWidget {
  const _AnimatedStar({super.key});

  @override
  Widget build(BuildContext context) {
    return PlayAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(seconds: 3),
      builder: (context, value, child) {
        return Opacity(
          opacity: 0.5 + 0.5 * value,
          child: Icon(Icons.star, color: const Color.fromARGB(255, 130, 176, 255), size: 24),
        );
      },
    );
  }
}
