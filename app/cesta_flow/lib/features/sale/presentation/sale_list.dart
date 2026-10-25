import 'package:cesta_flow/core/constants/colors/app_colors.dart';
import 'package:cesta_flow/features/shared/top_bar.dart';
import 'package:flutter/material.dart';

class SalesList extends StatefulWidget {
  const SalesList({super.key});

  @override
  State<SalesList> createState() => _SalesListState();
}

class _SalesListState extends State<SalesList> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const TopBar(pagTitle: "Vendas", showDrawer: true),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          spacing: 16,
          children: [
            Text(
              'Lista de vendas',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.black,
              ),
            ),
            const SizedBox(height: 14),
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: 10, // Replace with your actual item count
              itemBuilder: (context, index) {
                return Card(
                  child: ListTile(
                    title: Text('Venda ${index + 1}'),
                    subtitle: Text('Detalhes da venda ${index + 1}'),
                    trailing: Icon(Icons.arrow_forward),
                    onTap: () {
                      // Handle item tap
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
