import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'frutaBase.dart';


class GamePainter extends CustomPainter {
  final List<Point<int>> snake;
  final Fruta fruta;
  final double squareSize;

  GamePainter({required this.snake, required this.fruta, required this.squareSize});

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = const Color(0xFF1E1E1E);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bg);

    final paintSnake = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.greenAccent;
    for (final s in snake) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(s.x * squareSize, s.y * squareSize, squareSize, squareSize),
          const Radius.circular(4),
        ),
        paintSnake,
      );
    }

    final paintFruit = Paint()..color = fruta.color;
    final p = fruta.posicion;
    canvas.drawOval(
      Rect.fromLTWH(p.x * squareSize, p.y * squareSize, squareSize, squareSize),
      paintFruit,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}