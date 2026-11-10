import 'package:cesta_flow/core/data/local/model/customer_model.dart';
import 'package:cesta_flow/core/data/local/repository/customer_repository.dart';
import 'package:cesta_flow/features/shared/top_bar.dart';
import 'package:cesta_flow/features/shared/customer_form.dart';
import 'package:flutter/material.dart';

class CustomerEdit extends StatelessWidget {
  final Customer customer;
  final CustomerRepository? repository;

  const CustomerEdit({super.key, required this.customer, this.repository});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF3FCF3),
      appBar: TopBar(pagTitle: 'Editar cliente'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: CustomerForm(
          customer: customer,
          buttonText: 'Salvar alterações',
          title: 'Editar cliente',
          onSubmit: (data) => _updateCustomer(context, data),
        ),
      ),
    );
  }

  Future<void> _updateCustomer(
    BuildContext context,
    Map<String, dynamic> data,
  ) async {
    final customerRepository = repository ?? CustomerRepository();
    final updatedCustomer = customer.copyWith(
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
    await customerRepository.updateCustomer(updatedCustomer);
    if (context.mounted) {
      Navigator.of(context).pop(true);
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
