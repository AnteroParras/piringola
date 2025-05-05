import 'dart:convert';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'GameScreen.dart';

class MainMenu extends StatelessWidget {
  const MainMenu({super.key});
  void _start(BuildContext c, String mode) => Navigator.push(
      c,
      MaterialPageRoute(
        builder: (_) => GameScreen(mode: mode),
      ));

  Future<List<Map<String, dynamic>>> _getScores() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList('highScores') ?? [])
        .map((e) => jsonDecode(e) as Map<String, dynamic>)
        .toList();
  }

  void _showScores(BuildContext c) async {
    final list = await _getScores();
    list.sort((a, b) => b['score'].compareTo(a['score']));
    showDialog(
      context: c,
      builder: (_) => AlertDialog(
        title: const Text('Top 10 Puntuaciones'),
        content: SizedBox(
          width: 300,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: min(10, list.length),
            itemBuilder: (ctx, i) {
              final e = list[i];
              return ListTile(
                leading: Text('${i + 1}'),
                title: Text(e['initials']),
                trailing: Text('${e['score']}'),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('Cerrar'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'SNAKE GAME',
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.bold,
              color: Colors.greenAccent,
            ),
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: () => _start(context, 'rojo'),
            child: const Text('Frutas Rojas'),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () => _start(context, 'azul'),
            child: const Text('Frutas Azules'),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () => _start(context, 'amarillo'),
            child: const Text('Frutas Amarillas'),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () => _start(context, 'random'),
            child: const Text('Modo Aleatorio'),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => _showScores(context),
            child: const Text('Top Puntuaciones'),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => Navigator.of(context).maybePop(),
            child: const Text('Salir'),
          ),
        ],
      ),
    ),
  );
}
