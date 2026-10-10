import 'package:cesta_flow/features/customer/presentation/customer_list.dart';
import 'package:cesta_flow/features/dashboard/presentation/dashboard.dart';
import 'package:cesta_flow/features/export/presentation/data_exportation.dart';
import 'package:cesta_flow/features/sale/presentation/payment_success.dart';
import 'package:cesta_flow/features/shared/bottom_bar.dart';
import 'package:flutter/material.dart';

import 'features/sale/presentation/customer_selection.dart';
import 'features/customer/presentation/customer_registration.dart';
import 'features/sale/presentation/sale_registration.dart';
import 'features/sale/presentation/payment_registration.dart';
import 'features/sale/presentation/payment_registration.dart';

import 'package:wakelock_plus/wakelock_plus.dart';

void main() {
  runApp(const MainApp());
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
  String _selectedKey = 'Início';

  final Map<String, Widget> _pages = {
    'home': const Dashboard(),
    'customers': const CustomerList(),
    'settings': const DataExportation(),
  };

  @override
  Widget build(BuildContext context) {
    int selectedIndex = _pages.keys.toList().indexOf(_selectedKey);
    return Scaffold(
      body: IndexedStack(
        index: selectedIndex,
        children: _pages.values.toList(),
      ),
      bottomNavigationBar: BottomBar(
        onTap: (index) {
          setState(() {
            _selectedKey = index;
          });
        },
        buttonsIcons: <String, (String, IconData)>{
          'home': ('Início', Icons.home_rounded),
          'customers': ('Clientes', Icons.people_rounded),
          'settings': ('Configurações', Icons.settings_rounded),
        },
      ),
    );
  }
}
