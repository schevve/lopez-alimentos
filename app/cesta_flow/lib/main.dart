import 'package:cesta_flow/core/constants/colors/app_colors.dart';
import 'package:cesta_flow/features/customer/presentation/customer_list.dart';
import 'package:cesta_flow/features/dashboard/presentation/dashboard.dart';
import 'package:cesta_flow/features/export/presentation/data_exportation.dart';
import 'package:cesta_flow/features/sale/presentation/sale_list.dart';
import 'package:cesta_flow/features/shared/app_navigation.dart';
import 'package:cesta_flow/features/shared/bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:wakelock_plus/wakelock_plus.dart';

Future<void> main() async {
  await Supabase.initialize(
    url: 'https://vzpomvpwbqaesfezxehf.supabase.co',
    publishableKey: 'sb_publishable_Y5sHcuLfegaSCvK_c5RUFg_-ecEu179',
  );
  runApp(MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    WakelockPlus.enable();
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  String _selectedKey = 'home';

  final Map<String, Widget> _pages = {
    'home': const Dashboard(),
    'sales': const SalesList(),
    'customers': const CustomerList(),
    'export': const DataExportation(),
  };

  @override
  Widget build(BuildContext context) {
    int selectedIndex = _pages.keys.toList().indexOf(_selectedKey);
    return Scaffold(
      key: mainScaffoldKey,
      body: IndexedStack(
        index: selectedIndex,
        children: _pages.values.toList(),
      ),
      bottomNavigationBar: BottomBar(
        selectedKey: _selectedKey,
        onTap: (key) {
          setState(() {
            _selectedKey = key;
          });
        },
        buttonsIcons: <String, (String, IconData)>{
          'home': ('Início', Icons.home_rounded),
          'sales': ('Vendas', Icons.shopping_cart_rounded),
          'customers': ('Clientes', Icons.people_rounded),
        },
      ),
      drawer: NavigationDrawer(
        backgroundColor: AppColors.primary,
        indicatorColor: AppColors.black.withAlpha(50),
        onDestinationSelected: (index) {
          setState(() {
            _selectedKey = _pages.keys.toList()[index];
          });
          Navigator.pop(context);
        },
        selectedIndex: selectedIndex,
        children: [
          NavigationDrawerDestination(
            backgroundColor: AppColors.primary,
            icon: const Icon(Icons.home_rounded, color: AppColors.white),
            label: const Text(
              'Início',
              style: TextStyle(color: AppColors.white),
            ),
          ),
          NavigationDrawerDestination(
            icon: const Icon(
              Icons.shopping_cart_rounded,
              color: AppColors.white,
            ),
            label: const Text(
              'Vendas',
              style: TextStyle(color: AppColors.white),
            ),
          ),
          NavigationDrawerDestination(
            icon: const Icon(Icons.people_rounded, color: AppColors.white),
            label: const Text(
              'Clientes',
              style: TextStyle(color: AppColors.white),
            ),
          ),
          NavigationDrawerDestination(
            icon: const Icon(Icons.upload_rounded, color: AppColors.white),
            label: const Text(
              'Exportar Dados',
              style: TextStyle(color: AppColors.white),
            ),
          ),
        ],
      ),
    );
  }
}
