import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: const Color(0xFF36093D),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: const Center(child: Text('Profile')),
    );
  }
}