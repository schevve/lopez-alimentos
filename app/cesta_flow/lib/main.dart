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
    return const MaterialApp(home: MainScreen());
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const Dashboard(),
    const CustomerList(),
    const DataExportation(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: BottomBar(
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        pagesIcons: const [
          Icon(Icons.home_rounded),
          Icon(Icons.people_rounded),
          Icon(Icons.settings_rounded),
        ],
      ),
    );
  }
}
