import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';

class VoiceInputScreen extends ConsumerWidget {
  const VoiceInputScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Perintah Suara',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: const Center(child: Text('Perintah Suara Screen')),
    );
  }
}
