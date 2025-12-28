import 'package:flutter/material.dart';

class SafetyButtonScreen extends StatelessWidget {
  const SafetyButtonScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Safety Signal")),
      body: Center(
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red.shade300,
            shape: const CircleBorder(),
            padding: const EdgeInsets.all(80),
          ),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Safety signal recorded.")),
            );
          },
          child: const Icon(Icons.warning, size: 64),
        ),
      ),
    );
  }
}
