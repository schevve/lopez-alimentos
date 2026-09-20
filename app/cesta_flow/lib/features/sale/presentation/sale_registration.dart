import 'package:cesta_flow/core/constants/colors/app_colors.dart';
import 'package:cesta_flow/core/constants/util/format_cpf.dart';
import 'package:cesta_flow/core/data/local/db_helper.dart';
import 'package:cesta_flow/core/data/local/model/customer_model.dart';
import 'package:cesta_flow/core/data/local/model/sale_model.dart';
import 'package:cesta_flow/core/data/local/repository/sale_repository.dart';
import 'package:cesta_flow/features/sale/presentation/customer_selection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SaleRegistration extends StatefulWidget {
  const SaleRegistration({super.key});

  @override
  State<SaleRegistration> createState() => _SaleRegistrationState();
}

class _SaleRegistrationState extends State<SaleRegistration> {
  final _formKey = GlobalKey<FormState>();
  final _formData = <String, dynamic>{};
  Customer? _selectedCustomer;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Nova Venda',
          style: TextStyle(
            fontSize: 24,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.primary,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 32),
            child: Form(
              key: _formKey,
              child: Column(
                spacing: 16,
                children: [
                  FormField(
                    builder: (contextt) {
                      return Column(
                        spacing: 16,
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CustomerSelection(),
                                  ),
                                ).then((value) {
                                  if (value != null) {
                                    if (value is Customer) {
                                      setState(() {
                                        _selectedCustomer = value;
                                        _formData['clienteId'] = value.id;
                                      });
                                    }
                                  }
                                });
                              },
                              style: OutlinedButton.styleFrom(
                                alignment: Alignment.centerLeft,
                                fixedSize: Size(double.infinity, 64),
                                side: BorderSide(
                                  color: AppColors.primary,
                                  width: 2,
                                ),
                                padding: EdgeInsets.symmetric(
                                  vertical: 12,
                                  horizontal: 16,
                                ),
                              ),
                              child: Text(
                                'Selecionar Cliente',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                          InputDecorator(
                            decoration: InputDecoration(labelText: 'Cliente *'),
                            child: Text(
                              _selectedCustomer == null
                                  ? 'Nenhum cliente selecionado'
                                  : '${_selectedCustomer!.name}, CPF: ${formatCpf(_selectedCustomer!.documentCPF)}',
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ],
                      );
                    },
                    // onSaved: (value) => _formData['clienteId'] = value,
                  ),
                  TextFormField(
                    decoration: InputDecoration(labelText: 'Produto *'),
                    onSaved: (value) => _formData['produto'] = value,
                  ),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Observações (opcional)',
                    ),
                    onSaved: (value) => _formData['observacoes'] = value,
                  ),
                  TextFormField(
                    initialValue: getCurrentFormattedDate(),
                    decoration: InputDecoration(labelText: 'Data da Venda *'),
                    keyboardType: TextInputType.datetime,
                    inputFormatters: [FormatDate()],
                    onSaved: (value) => _formData['data_venda'] = value,
                  ),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Valor Total da Venda *',
                    ),
                    keyboardType: TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [FormatMoney()],
                    onSaved: (value) => _formData['valor_total'] = value,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            width: MediaQuery.of(context).size.width,
            child: Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                spacing: 16,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Total da venda: ',
                        style: TextStyle(fontSize: 20, color: AppColors.text),
                      ),
                      Text(
                        _formData['valor_total'] ?? '0,00',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.black,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        _submitForm();
                      },
                      style: ButtonStyle(
                        shape: WidgetStateProperty.all(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        backgroundColor: WidgetStateProperty.all(
                          AppColors.secondary,
                        ),
                        padding: WidgetStateProperty.all(
                          EdgeInsets.symmetric(vertical: 24, horizontal: 32),
                        ),
                      ),
                      child: Text(
                        'Registrar Venda',
                        style: TextStyle(color: Colors.white, fontSize: 20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitForm() async {
    print(_formKey.currentState!.validate());
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      var db = DatabaseHelper();
      var salesRepository = SaleRepository(dbHelper: db);
      final saleData = Sale(
        customerId: _formData['clienteId'],
        productName: _formData['produto'],
        price: double.parse(
          (_formData['valor_total'] as String).replaceAll(',', '.'),
        ),
        quantity: 1,
        date: DateTime.parse(
          _formData['data_venda'].split('/').reversed.join('-'),
        ),
        description: _formData['observacoes'] ?? '',
      );
      print(saleData);
      int saleId = await salesRepository.registerSale(saleData);
      print('Venda registrada com sucesso! ID da venda: $saleId');
      salesRepository.getAllSales().then((sales) {
        print('Vendas registradas: ${sales.length}');
      });
    }
  }
}

class FormatDate extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digitsOnly = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.length > 8) {
      return oldValue;
    }
    String formatted = '';
    for (int i = 0; i < digitsOnly.length; i++) {
      if (i == 2 || i == 4) {
        formatted += '/';
      }
      formatted += digitsOnly[i];
    }
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

String getCurrentFormattedDate() {
  final now = DateTime.now();
  final day = now.day.toString().padLeft(2, '0');
  final month = now.month.toString().padLeft(2, '0');
  final year = now.year.toString();
  return '$day/$month/$year';
}

class FormatMoney extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digitsOnly = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.isEmpty) {
      return newValue.copyWith(text: '');
    }
    final value = double.parse(digitsOnly) / 100;
    final formatted = value.toStringAsFixed(2).replaceAll('.', ',');
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
