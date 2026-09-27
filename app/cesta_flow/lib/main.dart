import 'package:cesta_flow/core/data/local/mock_data_seeder.dart';
import 'package:cesta_flow/features/export/presentation/data_exportation.dart';
import 'package:flutter/material.dart';

const _mockDataEnabled = bool.fromEnvironment('MOCK_DATA');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (_mockDataEnabled) {
    await MockDataSeeder().seed();
  }
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1C5632)),
      ),
      home: const DataExportation(),
    );
  }
}
