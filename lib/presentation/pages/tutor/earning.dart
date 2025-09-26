// --- Placeholder Page for Earnings ---
import 'package:flutter/material.dart';

class EarningsPage extends StatelessWidget {
  const EarningsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Earnings'),
        backgroundColor: const Color(0xFF231F20),
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text('Earnings Page', style: TextStyle(fontSize: 20)),
      ),
    );
  }
}
