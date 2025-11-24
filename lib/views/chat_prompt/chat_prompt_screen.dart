import 'package:flutter/material.dart';

class ChatPromptScreen extends StatelessWidget {
  const ChatPromptScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chat Prompt')),
      body: const Center(child: Text('Layar Chat Prompt')),
    );
  }
}
