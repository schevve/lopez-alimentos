import 'package:cesta_flow/core/constants/colors/app_colors.dart';
import 'package:cesta_flow/features/export/data/csv_export_service.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

class DataExportation extends StatefulWidget {
  const DataExportation({super.key});

  @override
  State<DataExportation> createState() => _DataExportationState();
}

class _DataExportationState extends State<DataExportation> {
  bool _isExporting = false;

  Future<void> _exportData() async {
    setState(() => _isExporting = true);

    try {
      final file = await CsvExportService().exportDatabase();
      if (!mounted) return;

      await SharePlus.instance.share(
        ShareParams(
          text: 'Exportação de dados da Cesta Flow',
          files: [XFile(file.path)],
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível exportar os dados: $error')),
      );
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Exportação de Dados',
          style: TextStyle(
            fontSize: 24,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.primary,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 10),
          Container(
            padding: EdgeInsets.all(10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Exportar para Excel',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.greenText,
                  ),
                ),
                SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _isExporting ? null : _exportData,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  ),
                  child: _isExporting
                      ? SizedBox(
                          height: 30,
                          width: 30,
                          child: CircularProgressIndicator(strokeWidth: 3),
                        )
                      : Icon(Icons.upload, size: 30),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
