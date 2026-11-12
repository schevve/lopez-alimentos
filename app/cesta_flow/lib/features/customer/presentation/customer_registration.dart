import 'package:cesta_flow/core/constants/util/format_cpf.dart';
import 'package:cesta_flow/core/data/local/model/customer_model.dart';
import 'package:cesta_flow/core/data/local/repository/customer_repository.dart';
import 'package:cesta_flow/features/shared/top_bar.dart';
import 'package:cesta_flow/features/shared/customer_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:objectbox/objectbox.dart' show UniqueViolationException;

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
        onSubmit: _registerCustomer,
        buttonText: "Registrar cliente",
        title: "Registrar cliente",
      ),
    );
  }

  String _digitos(String valor) => valor.replaceAll(RegExp(r'\D'), '');

  // Campos opcionais vazios viram null (o RG é único: "" repetido daria erro).
  String? _opcional(dynamic valor) {
    final texto = (valor ?? '').toString().trim();
    return texto.isEmpty ? null : texto;
  }

  void _avisar(String mensagem) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(mensagem)));
  }

  Future<void> _registerCustomer(Map<String, dynamic> data) async {
    final cpf = formatCpf(_digitos(data['cpf'].toString()));
    final rg = _opcional(data['rg']);

    try {
      // Confere duplicidade antes de gravar, para dar uma mensagem clara.
      final existentes = await _customerRepository.getAllCustomers();
      if (existentes.any((c) => _digitos(c.documentCPF) == _digitos(cpf))) {
        if (mounted) _avisar('Já existe um cliente cadastrado com este CPF.');
        return;
      }
      if (rg != null &&
          existentes.any(
            (c) =>
                c.documentRG != null && _digitos(c.documentRG!) == _digitos(rg),
          )) {
        if (mounted) _avisar('Já existe um cliente cadastrado com este RG.');
        return;
      }

      final customer = Customer(
        name: data['nome'].toString().trim(),
        dateOfBirth: cleanDate(data['data_nascimento'].toString().trim()),
        email: _opcional(data['email']),
        phone: data['telefone'].toString().trim(),
        address: data['rua'].toString().trim(),
        adressNumber: data['numero'].toString().trim(),
        city: data['cidade'].toString().trim(),
        state: data['estado'].toString().trim(),
        cep: _opcional(data['cep']),
        documentCPF: cpf,
        documentRG: rg,
      );

      customer.id = await _customerRepository.registerCustomer(customer);

      if (!mounted) return;
      _avisar('Cliente registrado com sucesso!');
      // Devolve o cliente criado para quem abriu a tela (ex.: seleção de venda).
      Navigator.of(context).pop(customer);
    } on UniqueViolationException {
      if (mounted) _avisar('Já existe um cliente com este CPF ou RG.');
    } catch (error) {
      debugPrint('Erro ao registrar cliente: $error');
      if (mounted) {
        _avisar('Não foi possível registrar o cliente. Tente novamente.');
      }
    }
  }
}

String _formatDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/'
    '${date.month.toString().padLeft(2, '0')}/${date.year}';

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
