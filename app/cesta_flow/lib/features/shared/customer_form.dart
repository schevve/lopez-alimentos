import 'package:cesta_flow/core/data/local/db_helper.dart';
import 'package:cesta_flow/core/data/local/model/customer_model.dart';
import 'package:cesta_flow/core/data/local/repository/customer_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomerForm extends StatefulWidget {
  final Customer? customer;

  final Future<void> Function(Map<String, dynamic> data) onSubmit;

  final String buttonText;
  final String title;

  const CustomerForm({
    super.key,
    this.customer,
    required this.onSubmit,
    required this.buttonText,
    required this.title,
  });

  @override
  State<CustomerForm> createState() => _CustomerFormState();
}

class _CustomerFormState extends State<CustomerForm> {
  final _formKey = GlobalKey<FormState>();
  final _formData = <String, dynamic>{};

  String _formatDate(DateTime? date) {
    if (date == null) return '';

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    _formKey.currentState!.save();

    await widget.onSubmit(_formData);
  }

  @override
  Widget build(BuildContext context) {
    final customer = widget.customer;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 4, height: 24, color: Colors.orange),

              SizedBox(width: 8),

              Icon(
                Icons.person_add_alt_1_outlined,
                color: Colors.orange,
                size: 22,
              ),

              SizedBox(width: 8),

              Text(
                "IDENTIFICAÇÃO",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Colors.redAccent,
                ),
              ),
            ],
          ),
          Padding(padding: EdgeInsetsGeometry.all(10)),
          Form(
            key: _formKey,
            child: Column(
              spacing: 16,
              children: [
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Nome completo*',
                    hintText: " ",
                    prefixIcon: const Icon(
                      Icons.person,
                      color: Color(0xff1C5631),
                    ),

                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),

                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onSaved: (value) => _formData['nome'] = value,
                ),

                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Data de Nascimento *',
                    hintText: 'dd/mm/aaaa',

                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),

                    filled: true,
                    fillColor: Colors.white,
                  ),

                  keyboardType: TextInputType.datetime,
                  inputFormatters: [FormatDate()],
                  onSaved: (value) => _formData['data_nascimento'] = value,
                ),

                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Email (opcional)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),

                    filled: true,
                    fillColor: Colors.white,
                  ),

                  keyboardType: TextInputType.emailAddress,

                  onSaved: (value) => _formData['email'] = value,
                ),

                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Telefone *',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),

                    filled: true,
                    fillColor: Colors.white,
                  ),

                  keyboardType: TextInputType.phone,
                  inputFormatters: [FormatPhoneNumber()],
                  onSaved: (value) => _formData['telefone'] = value,
                ),

                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Rua *',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),

                    filled: true,
                    fillColor: Colors.white,
                  ),

                  keyboardType: TextInputType.text,
                  onSaved: (value) => _formData['rua'] = value,
                ),

                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Número *',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),

                    filled: true,
                    fillColor: Colors.white,
                  ),

                  keyboardType: TextInputType.number,
                  onSaved: (value) => _formData['numero'] = value,
                ),

                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Cidade *',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),

                    filled: true,
                    fillColor: Colors.white,
                  ),

                  keyboardType: TextInputType.text,
                  onSaved: (value) => _formData['cidade'] = value,
                  validator: (value) =>
                      value?.isNotEmpty ?? false ? null : "erro",
                ),

                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Estado (opcional)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),

                    filled: true,
                    fillColor: Colors.white,
                  ),

                  keyboardType: TextInputType.text,
                  onSaved: (value) => _formData['estado'] = value,
                  validator: (value) =>
                      value?.isNotEmpty ?? false ? null : "erro",
                ),

                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'CEP (opcional)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),

                    filled: true,
                    fillColor: Colors.white,
                  ),

                  keyboardType: TextInputType.number,
                  onSaved: (value) => _formData['cep'] = value,
                ),

                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'CPF *',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),

                    filled: true,
                    fillColor: Colors.white,
                  ),

                  keyboardType: TextInputType.number,
                  onSaved: (value) => _formData['cpf'] = value,
                ),

                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'RG (opcional)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),

                    filled: true,
                    fillColor: Colors.white,
                  ),

                  keyboardType: TextInputType.number,
                  onSaved: (value) => _formData['rg'] = value,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),

            child: FilledButton.icon(
              onPressed: () async {
                await _submitForm();
              },
              style: FilledButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 158, 204, 174),
                padding: EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: Icon(
                Icons.person_add_alt_1_outlined,
                color: Color(0xff1C5631),
                size: 26,
              ),
              label: Text(
                widget.buttonText,
                style: TextStyle(
                  color: Color(0xff1C5631),
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  DateTime cleanDate(String dateString) {
    final parts = dateString.split('/');
    if (parts.length != 3) {
      throw FormatException('Data inválida: $dateString');
    }
    final day = int.parse(parts[0]);
    final month = int.parse(parts[1]);
    final year = int.parse(parts[2]);
    return DateTime(year, month, day);
  }
}

class FormatPhoneNumber extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    print('Old Value: ${oldValue.text}, New Value: ${newValue.text}');
    final digitsOnly = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.length == 11) {
      final match = RegExp(r'^(\d{2})(\d{5})(\d{4})$').firstMatch(digitsOnly);
      print('Digits Only: $digitsOnly, Match: $match');
      if (match != null) {
        return TextEditingValue(
          text: '(${match.group(1)}) ${match.group(2)}-${match.group(3)}',
          selection: TextSelection.collapsed(offset: 14),
        );
      }
    }
    if (digitsOnly.length > 11) {
      return oldValue;
    }
    return newValue;
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
