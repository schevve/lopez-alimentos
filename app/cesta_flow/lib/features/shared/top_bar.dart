import 'package:cesta_flow/core/constants/colors/app_colors.dart';
import 'package:cesta_flow/features/customer/presentation/customer_list.dart';
import 'package:cesta_flow/features/dashboard/presentation/dashboard.dart';
import 'package:flutter/material.dart';

class TopBar extends StatelessWidget implements PreferredSizeWidget {
  final String pagTitle;
  const TopBar({super.key, required this.pagTitle});

  @override
  Size get preferredSize => const Size.fromHeight(70.0);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.primary,
      iconTheme: const IconThemeData(color: Colors.white),
      scrolledUnderElevation: 0,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/FundoComidas.png'),
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
      // leading: IconButton.filled(
      //   icon: const Icon(Icons.arrow_back, color: Colors.white),
      //   style: IconButton.styleFrom(
      //     backgroundColor: const Color.fromARGB(48, 255, 255, 255),
      //   ),
      //   onPressed: () {
      //     Navigator.pop(context);
      //   },
      // ),
    );
  }
}
