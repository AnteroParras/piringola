import 'dart:math';
import 'package:flutter/material.dart';
import 'frutaBase.dart';
import 'GameScreen.dart';

class FrutaRoja extends Fruta {
  FrutaRoja(Point<int> posicion) : super(posicion, Colors.redAccent);
}

class FrutaAzul extends Fruta {
  FrutaAzul(Point<int> posicion) : super(posicion, Colors.blueAccent);
  @override
  void aplicarEfecto(GameScreenState state) {
    state.score++;
    // Invierte controles
    state.invertDirections();
    state.growQueue += 1;
  }
}

class FrutaAmarilla extends Fruta {
  FrutaAmarilla(Point<int> posicion) : super(posicion, Colors.yellowAccent);
  @override
  void aplicarEfecto(GameScreenState state) {
    state.score++;
    // Crecer aleatorio 1-3 bloques adicionales
    final extra = Random().nextInt(3) + 1;
    state.growQueue += extra;
  }
}