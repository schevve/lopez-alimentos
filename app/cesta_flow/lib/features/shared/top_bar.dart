import 'package:cesta_flow/features/customer/presentation/customer_list.dart';
import 'package:cesta_flow/features/dashboard/presentation/dashboard.dart';
import 'package:cesta_flow/features/sale/presentation/billing_page.dart';
import 'package:flutter/material.dart';

class TopBar extends StatelessWidget implements PreferredSizeWidget {
  final String pagTitle;
  const TopBar({super.key, required this.pagTitle});

  @override
  Size get preferredSize => const Size.fromHeight(70.0);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xff1C5631),

      flexibleSpace: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('web/images/FundoComidas.png'),
            fit: BoxFit.cover,
          ),
        ),
      ),

      toolbarHeight: 70,
      title: Text(
        pagTitle,
        style: TextStyle(
          fontSize: 24,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      leading: IconButton.filled(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        style: IconButton.styleFrom(
          backgroundColor: const Color.fromARGB(48, 255, 255, 255),
        ),
        onPressed: () {
          Navigator.pop(context);
        },
      ),
    );
  }
}
