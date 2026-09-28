import 'package:cesta_flow/features/shared/Top_bar.dart';
import 'package:flutter/material.dart';

class CustomerList extends StatelessWidget {
  const CustomerList({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TopBar(pagTitle: "Lista de Clientes"),
      body: Center(child: Text('Clientes')),
    );
  }
}
