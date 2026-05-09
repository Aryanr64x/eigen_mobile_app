import 'package:flutter/material.dart';

class DuelsScreen extends StatelessWidget {
  const DuelsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Duels'),
        backgroundColor: const Color(0xFF36093D),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: const Center(child: Text('Duels')),
    );
  }
}