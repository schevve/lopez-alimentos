import 'package:cesta_flow/core/data/local/model/customer_model.dart';
import 'package:cesta_flow/core/data/local/repository/customer_repository.dart';
import 'package:cesta_flow/features/shared/top_bar.dart';
import 'package:cesta_flow/features/shared/customer_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:objectbox/objectbox.dart';

class CustomerRegistration extends StatefulWidget {
  const CustomerRegistration({super.key, this.customerId, this.repository});

  final int? customerId;
  final CustomerRepository? repository;

  @override
  State<CustomerRegistration> createState() => _CustomerRegistrationState();
}

class _CustomerRegistrationState extends State<CustomerRegistration> {
  late final CustomerRepository _customerRepository;
  Customer? _cliente;
  bool _carregando = false;
  String? _erroCarregamento;

  @override
  void initState() {
    super.initState();
    _customerRepository = widget.repository ?? CustomerRepository();
    if (widget.customerId != null) {
      _carregando = true;
      _carregarCliente();
    }
  }

  Future<void> _carregarCliente() async {
    try {
      final cliente = await _customerRepository.getCustomerById(
        widget.customerId!,
      );
      if (!mounted) return;
      setState(() {
        _cliente = cliente;
        _carregando = false;
        if (cliente == null) {
          _erroCarregamento = 'Cliente não encontrado.';
        }
      });
    } catch (error) {
      debugPrint('Erro ao carregar cliente para edição: $error');
      if (!mounted) return;
      setState(() {
        _carregando = false;
        _erroCarregamento = 'Não foi possível carregar os dados do cliente.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_carregando || _erroCarregamento != null) {
      return Scaffold(
        backgroundColor: const Color(0xffF3FCF3),
        appBar: TopBar(
          pagTitle: widget.customerId == null
              ? 'Registrar cliente'
              : 'Editar cliente',
        ),
        body: Center(
          child: _carregando
              ? const CircularProgressIndicator()
              : Text(_erroCarregamento!),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Color(0xffF3FCF3),

      appBar: TopBar(
        pagTitle: widget.customerId == null
            ? "Registrar cliente"
            : "Editar cliente",
      ),

      body: CustomerForm(
        customer: _cliente,
        onSubmit: _registerCustomer,
        buttonText: widget.customerId == null
            ? 'Registrar cliente'
            : 'Salvar alterações',
        title: widget.customerId == null
            ? 'Registrar cliente'
            : 'Editar cliente',
      ),
    );
  }

  Future<void> _registerCustomer(Map<String, dynamic> data) async {
    try {
      final customer = Customer(
        id: _cliente?.id,
        name: data['nome'],
        dateOfBirth: cleanDate(data['data_nascimento']),
        email: data['email'],
        phone: data['telefone'],
        address: data['rua'],
        adressNumber: data['numero'],
        city: data['cidade'],
        state: data['estado'],
        cep: data['cep'],
        documentCPF: data['cpf'],
        documentRG: data['rg'],
        score: _cliente?.score,
      );

      if (widget.customerId == null) {
        final id = await _customerRepository.registerCustomer(customer);
        final savedCustomer = await _customerRepository.getCustomerById(id);
        if (savedCustomer == null) {
          throw StateError('Cliente salvo não foi encontrado.');
        }
        if (mounted) {
          Navigator.of(context).pop(savedCustomer);
        }
        return;
      }

      final updated = await _customerRepository.updateCustomer(customer);
      if (updated == 0) {
        throw StateError('Cliente não encontrado para atualização.');
      }
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } on UniqueViolationException {
      _showSaveError('Já existe um cliente cadastrado com este CPF ou RG.');
    } catch (error, stackTrace) {
      debugPrint('Erro ao salvar cliente: $error\n$stackTrace');
      _showSaveError('Não foi possível salvar o cliente. Tente novamente.');
    }
  }

  void _showSaveError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
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

class FormatPhoneNumber extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digitsOnly = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.length == 11) {
      final match = RegExp(r'^(\d{2})(\d{5})(\d{4})$').firstMatch(digitsOnly);
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
