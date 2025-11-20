import 'package:flutter/material.dart';

class ScanStrukScreen extends StatelessWidget {
  const ScanStrukScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Struk'),
      ),
      body: const Center(
        child: Text('Scan Struk Screen (Image)'),
      ),
    );
  }
}
