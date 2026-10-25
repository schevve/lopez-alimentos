import 'package:cesta_flow/features/shared/top_bar.dart';
import 'package:flutter/material.dart';

class CustomerList extends StatelessWidget {
  const CustomerList({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const TopBar(pagTitle: "Lista de Clientes", showDrawer: true),
      body: Center(child: Text('Clientes')),
    );
  }
}
