import 'package:cesta_flow/core/constants/colors/app_colors.dart';
import 'package:cesta_flow/features/shared/app_navigation.dart';
import 'package:flutter/material.dart';

class TopBar extends StatelessWidget implements PreferredSizeWidget {
  final String pagTitle;

  /// Quando `true`, exibe o botão que abre o drawer da tela principal.
  /// Nas demais telas (rotas empilhadas) o leading é uma seta de voltar.
  final bool showDrawer;

  const TopBar({
    super.key,
    required this.pagTitle,
    this.showDrawer = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(70.0);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.primary,
      iconTheme: const IconThemeData(color: Colors.white),
      scrolledUnderElevation: 0,
      leading: showDrawer
          ? const LeadingOpenDrawerButton()
          : const LeadingBackButton(),
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
  const LeadingOpenDrawerButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.menu, color: Colors.white),
      tooltip: 'Abrir menu',
      onPressed: () {
        mainScaffoldKey.currentState?.openDrawer();
      },
    );
  }
}

class LeadingBackButton extends StatelessWidget {
  const LeadingBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back, color: Colors.white),
      tooltip: 'Voltar',
      onPressed: () {
        Navigator.maybePop(context);
      },
    );
  }
}
