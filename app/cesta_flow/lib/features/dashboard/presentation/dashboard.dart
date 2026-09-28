import 'package:cesta_flow/features/shared/top_bar.dart';
import 'package:flutter/material.dart';

class Dashboard extends StatelessWidget {
  const Dashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TopBar(pagTitle: "Dashboar"),
      body: Center(child: Text('Dashboard')),
    );
  }
}
