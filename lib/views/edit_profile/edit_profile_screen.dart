import 'package:flutter/material.dart';

class EditProfileScreen extends StatelessWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ubah Profil'),
      ),
      body: const Center(
        child: Text('Layar Ubah Profil - Segera Hadir!'),
      ),
    );
  }
}
