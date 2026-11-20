import 'package:cesta_flow/core/constants/util/format_cpf.dart';
import 'package:cesta_flow/core/constants/util/format_date.dart';
import 'package:cesta_flow/core/data/local/model/customer_model.dart';
import 'package:cesta_flow/core/data/local/repository/customer_repository.dart';
import 'package:cesta_flow/features/shared/top_bar.dart';
import 'package:cesta_flow/features/shared/customer_form.dart';
import 'package:flutter/material.dart';

class CustomerEdit extends StatelessWidget {
  final Customer customer;
  final CustomerRepository? repository;

  const CustomerEdit({super.key, required this.customer, this.repository});

  String? _opcional(dynamic valor) {
    final texto = (valor ?? '').toString().trim();
    return texto.isEmpty ? null : texto;
  }

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
      name: data['nome'].toString().trim(),
      dateOfBirth: cleanDate(data['data_nascimento'].toString().trim()),
      email: _opcional(data['email']),
      phone: data['telefone'].toString().trim(),
      address: data['rua'].toString().trim(),
      addressNumber: data['numero'].toString().trim(),
      city: data['cidade'].toString().trim(),
      state: data['estado'].toString().trim(),
      cep: _opcional(data['cep']),
      documentCPF: formatCpf(onlyDigits(data['cpf'].toString())),
      documentRG: _opcional(data['rg']),
      updatedAt: DateTime.now(),
    );
    await customerRepository.updateCustomer(updatedCustomer);
    if (context.mounted) {
      Navigator.of(context).pop(true);
    }
  }
}