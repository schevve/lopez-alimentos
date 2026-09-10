import 'package:flutter/material.dart';

// Destino provisório após a validação do login.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Início')),
      body: const Center(child: Text('Bem-vindo à HomeScreen!')),
    );
  }
}
