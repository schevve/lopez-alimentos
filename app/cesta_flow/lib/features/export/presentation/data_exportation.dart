import 'package:cesta_flow/core/constants/colors/app_colors.dart';
import 'package:cesta_flow/features/export/data/excel_export_service.dart';
import 'package:cesta_flow/features/export/data/export_period_filter.dart';
import 'package:cesta_flow/features/shared/top_bar.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

class DataExportation extends StatefulWidget {
  const DataExportation({super.key});

  @override
  State<DataExportation> createState() => _DataExportationState();
}

class _DataExportationState extends State<DataExportation> {
  bool _isExporting = false;
  late DateTime _startDate;
  late DateTime _endDate;
  final _dateFormat = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    final period = ExportPeriodFilter.calendarMonth();
    _startDate = period.start;
    _endDate = period.end;
  }

  Future<void> _exportData() async {
    setState(() => _isExporting = true);

    try {
      final filter = ExportPeriodFilter(start: _startDate, end: _endDate);
      final file = await ExcelExportService().exportDatabase(filter: filter);
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

  Future<void> _pickDate({required bool isStart}) async {
    final initial = isStart ? _startDate : _endDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: isStart ? 'Data de início' : 'Data de fim',
    );
    if (picked == null || !mounted) return;

    setState(() {
      if (isStart) {
        _startDate = picked;
        if (_startDate.isAfter(_endDate)) {
          _endDate = _startDate;
        }
      } else {
        _endDate = picked;
        if (_endDate.isBefore(_startDate)) {
          _startDate = _endDate;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const TopBar(pagTitle: 'Exportação de Dados', showDrawer: true),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Exportar para Excel',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.greenText,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'O período abaixo filtra vendas, parcelas e vínculos '
                  'venda–cesta. Clientes e cestas saem completos.',
                  style: TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 12),
                Text(
                  'Período',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.greenText,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _DateSelectorField(
                        label: 'Início',
                        dateText: _dateFormat.format(_startDate),
                        onTap: _isExporting
                            ? null
                            : () => _pickDate(isStart: true),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _DateSelectorField(
                        label: 'Fim',
                        dateText: _dateFormat.format(_endDate),
                        onTap: _isExporting
                            ? null
                            : () => _pickDate(isStart: false),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _isExporting ? null : _exportData,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 10,
                    ),
                  ),
                  child: _isExporting
                      ? const SizedBox(
                          height: 30,
                          width: 30,
                          child: CircularProgressIndicator(strokeWidth: 3),
                        )
                      : const Icon(Icons.upload_rounded, size: 30),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DateSelectorField extends StatelessWidget {
  const _DateSelectorField({
    required this.label,
    required this.dateText,
    required this.onTap,
  });

  final String label;
  final String dateText;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
            suffixIcon: const Icon(Icons.calendar_today_outlined, size: 20),
            enabled: onTap != null,
          ),
          child: Text(dateText),
        ),
      ),
    );
  }
}