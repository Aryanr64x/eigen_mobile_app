import 'package:flutter/material.dart';

class ContestsScreen extends StatelessWidget {
  const ContestsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contests'),
        backgroundColor: const Color(0xFF36093D),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: const Center(child: Text('Contests')),
    );
  }
}