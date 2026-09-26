import 'package:flutter/material.dart';

import 'features/sale/presentation/customer_selection.dart';
import 'features/customer/presentation/customer_registration.dart';
import 'features/sale/presentation/sale_registration.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: CustomerRegistration());
  }
}
