import 'package:cesta_flow/core/constants/util/format_cpf.dart';
import 'package:cesta_flow/core/constants/util/format_date.dart';
import 'package:cesta_flow/core/data/local/model/customer_model.dart';
import 'package:cesta_flow/core/data/local/repository/customer_repository.dart';
import 'package:cesta_flow/features/shared/top_bar.dart';
import 'package:cesta_flow/features/shared/customer_form.dart';
import 'package:flutter/material.dart';
import 'package:objectbox/objectbox.dart' show UniqueViolationException;
import 'package:uuid/uuid.dart';

class CustomerRegistration extends StatefulWidget {
  const CustomerRegistration({
    super.key,
    this.customerId,
    this.repository,
  });

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
    final isEditing = widget.customerId != null;

    if (_carregando || _erroCarregamento != null) {
      return Scaffold(
        backgroundColor: const Color(0xffF3FCF3),
        appBar: TopBar(
          pagTitle: isEditing ? 'Editar cliente' : 'Registrar cliente',
        ),
        body: Center(
          child: _carregando
              ? const CircularProgressIndicator()
              : Text(_erroCarregamento!),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xffF3FCF3),
      appBar: TopBar(
        pagTitle: isEditing ? 'Editar cliente' : 'Registrar cliente',
      ),
      body: CustomerForm(
        customer: _cliente,
        onSubmit: isEditing ? _updateCustomer : _registerCustomer,
        buttonText: isEditing ? 'Salvar alterações' : 'Registrar cliente',
        title: isEditing ? 'Editar cliente' : 'Registrar cliente',
      ),
    );
  }

  String _digitos(String valor) => onlyDigits(valor);

  String? _opcional(dynamic valor) {
    final texto = (valor ?? '').toString().trim();
    return texto.isEmpty ? null : texto;
  }

  void _avisar(String mensagem) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(mensagem)));
  }

  Future<bool> _cpfOuRgDuplicado({
    required String cpf,
    String? rg,
    int? ignorarId,
  }) async {
    final existentes = await _customerRepository.getAllCustomers();
    final cpfDigitos = _digitos(cpf);

    if (existentes.any(
      (c) =>
          c.id != ignorarId && _digitos(c.documentCPF) == cpfDigitos,
    )) {
      if (mounted) _avisar('Já existe um cliente cadastrado com este CPF.');
      return true;
    }

    if (rg != null &&
        existentes.any(
          (c) =>
              c.id != ignorarId &&
              c.documentRG != null &&
              _digitos(c.documentRG!) == _digitos(rg),
        )) {
      if (mounted) _avisar('Já existe um cliente cadastrado com este RG.');
      return true;
    }

    return false;
  }

  Customer _customerFromForm(Map<String, dynamic> data, {String? uuid}) {
    return Customer(
      uuid: uuid ?? _cliente?.uuid ?? const Uuid().v4(),
      name: data['nome'].toString().trim(),
      dateOfBirth: cleanDate(data['data_nascimento'].toString().trim()),
      email: _opcional(data['email']),
      phone: data['telefone'].toString().trim(),
      address: data['rua'].toString().trim(),
      addressNumber: data['numero'].toString().trim(),
      city: data['cidade'].toString().trim(),
      state: data['estado'].toString().trim(),
      cep: _opcional(data['cep']),
      documentCPF: formatCpf(_digitos(data['cpf'].toString())),
      documentRG: _opcional(data['rg']),
    );
  }

  Future<void> _registerCustomer(Map<String, dynamic> data) async {
    final rg = _opcional(data['rg']);
    final cpf = formatCpf(_digitos(data['cpf'].toString()));

    try {
      if (await _cpfOuRgDuplicado(cpf: cpf, rg: rg)) return;

      final customer = _customerFromForm(data);
      customer.id = await _customerRepository.registerCustomer(customer);

      if (!mounted) return;
      _avisar('Cliente registrado com sucesso!');
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

  Future<void> _updateCustomer(Map<String, dynamic> data) async {
    final current = _cliente;
    if (current == null) return;

    final rg = _opcional(data['rg']);
    final cpf = formatCpf(_digitos(data['cpf'].toString()));

    try {
      if (await _cpfOuRgDuplicado(
        cpf: cpf,
        rg: rg,
        ignorarId: current.id,
      )) {
        return;
      }

      final updated = current.copyWith(
        name: data['nome'].toString().trim(),
        dateOfBirth: cleanDate(data['data_nascimento'].toString().trim()),
        email: _opcional(data['email']),
        phone: data['telefone'].toString().trim(),
        address: data['rua'].toString().trim(),
        addressNumber: data['numero'].toString().trim(),
        city: data['cidade'].toString().trim(),
        state: data['estado'].toString().trim(),
        cep: _opcional(data['cep']),
        documentCPF: cpf,
        documentRG: rg,
        updatedAt: DateTime.now(),
      );

      await _customerRepository.updateCustomer(updated);

      if (!mounted) return;
      _avisar('Cliente atualizado com sucesso!');
      Navigator.of(context).pop(true);
    } on UniqueViolationException {
      if (mounted) _avisar('Já existe um cliente com este CPF ou RG.');
    } catch (error) {
      debugPrint('Erro ao atualizar cliente: $error');
      if (mounted) {
        _avisar('Não foi possível salvar as alterações. Tente novamente.');
      }
    }
  }
}