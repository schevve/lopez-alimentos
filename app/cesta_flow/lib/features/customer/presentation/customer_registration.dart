import 'package:cesta_flow/core/data/local/db_helper.dart';
import 'package:cesta_flow/core/data/local/model/customer_model.dart';
import 'package:cesta_flow/core/data/local/repository/customer_repository.dart';
import 'package:cesta_flow/features/shared/Top_bar.dart';
import 'package:cesta_flow/features/shared/customer_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomerRegistration extends StatefulWidget {

  const CustomerRegistration({super.key});

  @override
  State<CustomerRegistration> createState() => _CustomerRegistrationState();
}

class _CustomerRegistrationState extends State<CustomerRegistration> {
  final data = <String, dynamic>{};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xffF3FCF3),

      appBar: TopBar(pagTitle: "Registrar cliente"),

      body: CustomerForm(onSubmit: _registerCustomer, buttonText: "Registrar cliente", title: "Registrar cliente")
    );
  }

  Future<void> _registerCustomer(
    Map<String, dynamic> data,
    ) async {
      final repository = CustomerRepository(
        dbHelper: DatabaseHelper(),
      );
      final customer = Customer(
        name: data['nome'],
        dateOfBirth: cleanDate(data['data_nascimento']),
        email: data['email'],
        phone: data['telefone'],
        address: data['rua'],
        adress_number: data['numero'],
        city: data['cidade'],
        state: data['estado'],
        cep: data['cep'],
        documentCPF: data['cpf'],
        documentRG: data['rg'],
      );
    await repository.registerCustomer(customer);
    print('Cliente registrado com sucesso: ${customer.name}');
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