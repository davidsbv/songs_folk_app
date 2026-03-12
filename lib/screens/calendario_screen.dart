import 'package:flutter/material.dart';

/// Pantalla placeholder del calendario de eventos.
class CalendarioScreen extends StatelessWidget {
  const CalendarioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Calendario de eventos')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text(
            'Calendario de eventos – Próximamente.\n\n'
            'El administrador podrá añadir y modificar eventos aquí.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }
}
