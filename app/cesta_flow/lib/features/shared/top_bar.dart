import 'package:cesta_flow/core/constants/colors/app_colors.dart';
import 'package:cesta_flow/features/shared/app_navigation.dart';
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
      leading: Builder(builder: (context) => LeadingOpenDrawerButton(context)),
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
    );
  }
}

class LeadingOpenDrawerButton extends StatelessWidget {
  final BuildContext context;
  const LeadingOpenDrawerButton(this.context, {super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.menu, color: Colors.white),
      onPressed: () {
        mainScaffoldKey.currentState?.openDrawer();
      },
    );
  }
}
