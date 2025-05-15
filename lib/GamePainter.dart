import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'frutaBase.dart';


class GamePainter extends CustomPainter {
  /// Información a dibujar
  final List<Point<int>> snake;
  final Fruta fruta;
  final double squareSize;

  /// Estilos de los objetos
  late final Paint snakeStyle;
  late final Paint fruitStyle;
  late final Paint backgroundStyle;

  GamePainter({required this.snake, required this.fruta, required this.squareSize})
  {
    snakeStyle = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.greenAccent;

    fruitStyle = Paint()
      ..style = PaintingStyle.fill
      ..color = fruta.color; // Color definido en la clase Fruta

    backgroundStyle = Paint()..color = const Color(0xFF1E1E1E);
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), backgroundStyle);

    // Dibujar los pedazos de la serpiente
    for (final bodyPiece in snake) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(bodyPiece.x * squareSize, bodyPiece.y * squareSize, squareSize, squareSize),
          const Radius.circular(4),
        ),
        snakeStyle,
      );
    }

    // Dibujar la fruta
    canvas.drawOval(
      Rect.fromLTWH(fruta.posicion.x * squareSize, fruta.posicion.y * squareSize, squareSize, squareSize),
      fruitStyle,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}