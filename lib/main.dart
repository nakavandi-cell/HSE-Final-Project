import 'package:flutter/material.dart';

void main() {
  runApp(const HSEApp());
}

class HSEApp extends StatelessWidget {
  const HSEApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'HSE Final Project',
      home: Scaffold(
        appBar: AppBar(
          title: const Text('HSE Final Project'),
        ),
        body: const Center(
          child: Text('HSE App is running'),
        ),
      ),
    );
  }
}
