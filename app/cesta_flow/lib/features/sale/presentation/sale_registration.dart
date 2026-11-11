import 'package:cesta_flow/core/constants/colors/app_colors.dart';
import 'package:cesta_flow/core/constants/util/format_cpf.dart';
import 'package:cesta_flow/core/data/local/db_helper.dart';
import 'package:cesta_flow/core/data/local/model/customer_model.dart';
import 'package:cesta_flow/core/data/local/model/sale_model.dart';
import 'package:cesta_flow/core/data/local/repository/sale_repository.dart';
import 'package:cesta_flow/features/sale/presentation/sale_customer_selection.dart';
import 'package:cesta_flow/features/shared/top_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cesta_flow/features/sale/presentation/sale_success.dart';

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
      backgroundColor: Color(0xffF3FCF3),
      appBar: TopBar(pagTitle: "Registrar venda"),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 16,
            children: [
              FormField(
                builder: (contextt) {
                  return Column(
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
                              color: Color(0xff1C5631),
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
                              color: Color(0xff1C5631),
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
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Informe o produto.';
                  }
                  return null;
                },
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
                validator: (value) {
                  final date = _parseDate(value);
                  if (date == null) return 'Informe uma data válida.';
                  return null;
                },
                onSaved: (value) => _formData['data_venda'] = value,
              ),
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Valor Total da Venda *',
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FormatMoney()],
                validator: (value) {
                  final amount = double.tryParse(
                    (value ?? '').replaceAll(',', '.'),
                  );
                  if (amount == null || amount <= 0) {
                    return 'Informe um valor maior que zero.';
                  }
                  return null;
                },
                onSaved: (value) => _formData['valor_total'] = value,
              ),
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Quantidade de parcelas *',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  final count = int.tryParse(value ?? '');
                  if (count == null || count < 1) {
                    return 'Informe pelo menos uma parcela.';
                  }
                  return null;
                },
                onSaved: (value) => _formData['quantidade_parcelas'] = value,
              ),
              FilledButton(
                onPressed: () {
                  _submitForm();
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.greenButton,
                  padding: EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'Registrar Venda',
                  style: TextStyle(color: Color(0xff1C5631), fontSize: 24),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCustomer?.id == null) {
      _showError('Selecione um cliente.');
      return;
    }

    _formKey.currentState!.save();
    final price = double.parse(
      (_formData['valor_total'] as String).replaceAll(',', '.'),
    );
    final installmentCount = int.parse(
      _formData['quantidade_parcelas'] as String,
    );
    if (installmentCount > (price * 100).round()) {
      _showError('A quantidade de parcelas excede o valor em centavos.');
      return;
    }

    final saleData = Sale(
      customerId: _selectedCustomer!.id!,
      productName: (_formData['produto'] as String).trim(),
      price: price,
      quantity: 1,
      date: _parseDate(_formData['data_venda'] as String)!,
      description: _formData['observacoes'] ?? '',
    );
    try {
      await SaleRepository(dbHelper: DatabaseHelper())
          .registerSaleWithInstallments(
            saleData,
            installmentCount: installmentCount,
          );
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => SaleSuccess(
            valor: saleData.price,
            clienteNome: _selectedCustomer!.name,
          ),
        ),
      );
    } catch (error) {
      if (mounted) {
        _showError('Não foi possível registrar a venda: $error');
      }
    }
  }

  DateTime? _parseDate(String? value) {
    final parts = (value ?? '').split('/');
    if (parts.length != 3) return null;
    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) return null;
    final date = DateTime(year, month, day);
    if (date.year != year || date.month != month || date.day != day) {
      return null;
    }
    return date;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
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
