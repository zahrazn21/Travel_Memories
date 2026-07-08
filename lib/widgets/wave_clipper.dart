import 'package:flutter/material.dart';

class WaveClipper extends CustomClipper<Path> {
  const WaveClipper();

  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, 35);
    path.cubicTo(
      size.width * 0.18,
      35,
      size.width * 0.28,
      8,
      size.width * 0.50,
      8,
    );
    path.cubicTo(size.width * 0.72, 8, size.width * 0.82, 35, size.width, 35);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class WaveBorderPainter extends CustomPainter {
  const WaveBorderPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final path = const WaveClipper().getClip(size);
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.30)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}