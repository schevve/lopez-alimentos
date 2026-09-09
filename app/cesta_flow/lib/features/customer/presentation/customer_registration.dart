import 'package:cesta_flow/core/data/local/db_helper.dart';
import 'package:cesta_flow/core/data/local/model/customer_model.dart';
import 'package:cesta_flow/core/data/local/repository/customer_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomerRegistration extends StatefulWidget {
  const CustomerRegistration({super.key});

  @override
  State<CustomerRegistration> createState() => _CustomerRegistrationState();
}

class _CustomerRegistrationState extends State<CustomerRegistration> {
  final _formKey = GlobalKey<FormState>();
  final _formData = <String, dynamic>{};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Registrar Cliente',
          style: TextStyle(
            fontSize: 24,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Form(
          key: _formKey,
          child: Column(
            spacing: 16,
            children: [
              TextFormField(
                decoration: InputDecoration(labelText: 'Nome *'),
                onSaved: (value) => _formData['nome'] = value,
              ),
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Data de Nascimento *',
                  hintText: 'dd/mm/aaaa',
                ),
                keyboardType: TextInputType.datetime,
                inputFormatters: [FormatDate()],
                onSaved: (value) => _formData['data_nascimento'] = value,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Email (opcional)'),
                keyboardType: TextInputType.emailAddress,
                onSaved: (value) => _formData['email'] = value,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Telefone *'),
                keyboardType: TextInputType.phone,
                inputFormatters: [FormatPhoneNumber()],
                onSaved: (value) => _formData['telefone'] = value,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Rua *'),
                keyboardType: TextInputType.text,
                onSaved: (value) => _formData['rua'] = value,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Número *'),
                keyboardType: TextInputType.number,
                onSaved: (value) => _formData['numero'] = value,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Cidade *'),
                keyboardType: TextInputType.text,
                onSaved: (value) => _formData['cidade'] = value,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Estado (opcional)'),
                keyboardType: TextInputType.text,
                onSaved: (value) => _formData['estado'] = value,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'CEP (opcional)'),
                keyboardType: TextInputType.number,
                onSaved: (value) => _formData['cep'] = value,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'CPF *'),
                keyboardType: TextInputType.number,
                onSaved: (value) => _formData['cpf'] = value,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'RG (opcional)'),
                keyboardType: TextInputType.number,
                onSaved: (value) => _formData['rg'] = value,
              ),
              FilledButton(
                onPressed: () async {
                  await _submitForm();
                },
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.all(Colors.green),
                  padding: WidgetStateProperty.all(
                    EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                  ),
                ),
                child: Text(
                  "Registrar Cliente",
                  style: TextStyle(color: Colors.white, fontSize: 24),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      print('Registrando cliente: ${_formData['nome']}');
      var db = DatabaseHelper();
      var customerRepository = CustomerRepository(dbHelper: db);
      var customers = await customerRepository.getAllCustomers();
      print('Clientes existentes: ${customers.length}');
      for (var customer in customers) {
        print('Cliente existente: ${customer.name}');
      }
      var customerData = Customer(
        name: _formData['nome'],
        dateOfBirth: cleanDate(_formData['data_nascimento']),
        email: _formData['email'],
        phone: _formData['telefone'],
        address: _formData['rua'],
        city: _formData['cidade'],
        state: _formData['estado'],
        cep: _formData['cep'],
        documentCPF: _formData['cpf'],
        documentRG: _formData['rg'],
      );
      await customerRepository.registerCustomer(customerData);
      print('Cliente registrado com sucesso: ${customerData.name}');
    }
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
