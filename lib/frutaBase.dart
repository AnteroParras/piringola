import 'dart:math';
import 'dart:ui';
import 'GameScreen.dart';
/// Clase abstracta fruta para crear una fruta con

abstract class Fruta {
  Point<int> posicion;
  Color color;
  Fruta(this.posicion, this.color);
  void aplicarEfecto(GameScreenState state){
    state.score++;
    state.growQueue += 1;
  }
}