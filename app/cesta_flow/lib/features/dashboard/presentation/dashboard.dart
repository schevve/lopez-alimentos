import 'package:cesta_flow/features/shared/top_bar.dart';
import 'package:flutter/material.dart';

import '../../auth/presentation/tela_clientes.dart';

class Dashboard extends StatelessWidget {
  const Dashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TopBar(pagTitle: "Dashboar"),
      body: Center(
        child: FilledButton.icon(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const ClientesScreen()),
          ),
          icon: const Icon(Icons.groups_outlined),
          label: const Text('Meus Clientes'),
        ),
      ),
    );
  }
}
