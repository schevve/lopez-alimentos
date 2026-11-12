import 'package:cesta_flow/core/data/local/model/customer_model.dart';
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

  bool _salvando = false;

  String _digitos(String? valor) => (valor ?? '').replaceAll(RegExp(r'\D'), '');

  String? _obrigatorio(String? valor, String mensagem) =>
      (valor ?? '').trim().isEmpty ? mensagem : null;

  String? _validarData(String? valor) {
    final texto = (valor ?? '').trim();
    final partes = texto.split('/');
    if (partes.length != 3) return 'Informe a data (dd/mm/aaaa).';
    final dia = int.tryParse(partes[0]);
    final mes = int.tryParse(partes[1]);
    final ano = int.tryParse(partes[2]);
    if (dia == null || mes == null || ano == null || partes[2].length != 4) {
      return 'Informe a data (dd/mm/aaaa).';
    }
    final data = DateTime(ano, mes, dia);
    final existe = data.day == dia && data.month == mes && data.year == ano;
    if (!existe || ano < 1900 || data.isAfter(DateTime.now())) {
      return 'Informe uma data válida.';
    }
    return null;
  }

  String? _validarEmail(String? valor) {
    final email = (valor ?? '').trim();
    if (email.isEmpty) return null; // opcional
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)
        ? null
        : 'Informe um e-mail válido.';
  }

  String? _validarTelefone(String? valor) {
    final tamanho = _digitos(valor).length;
    return tamanho == 10 || tamanho == 11
        ? null
        : 'Informe um telefone válido com DDD.';
  }

  String? _validarCep(String? valor) {
    if (_digitos(valor).isEmpty) return null; // opcional
    return _digitos(valor).length == 8 ? null : 'O CEP deve ter 8 dígitos.';
  }

  String? _validarCpf(String? valor) =>
      _digitos(valor).length == 11 ? null : 'O CPF deve ter 11 dígitos.';

  Future<void> _submitForm() async {
    if (_salvando) return;

    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Corrija os campos destacados.')),
      );
      return;
    }

    _formKey.currentState!.save();

    setState(() => _salvando = true);
    try {
      await widget.onSubmit(_formData);
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
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
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              spacing: 16,
              children: [
                TextFormField(
                  initialValue: customer?.name ?? '',
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
                  validator: (value) =>
                      _obrigatorio(value, 'Informe o nome completo.'),
                ),

                TextFormField(
                  initialValue: _formatDate(customer?.dateOfBirth),
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
                  validator: _validarData,
                ),

                TextFormField(
                  initialValue: customer?.email ?? '',
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
                  validator: _validarEmail,
                ),

                TextFormField(
                  initialValue: customer?.phone ?? '',
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
                  validator: _validarTelefone,
                ),

                TextFormField(
                  initialValue: customer?.address ?? '',
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
                  validator: (value) => _obrigatorio(value, 'Informe a rua.'),
                ),

                TextFormField(
                  initialValue: customer?.adressNumber ?? '',
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
                  validator: (value) =>
                      _obrigatorio(value, 'Informe o número.'),
                ),

                TextFormField(
                  initialValue: customer?.city ?? '',
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
                      _obrigatorio(value, 'Informe a cidade.'),
                ),

                TextFormField(
                  initialValue: customer?.state ?? '',
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
                      _obrigatorio(value, 'Informe o estado.'),
                ),

                TextFormField(
                  initialValue: customer?.cep ?? '',
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
                  validator: _validarCep,
                ),

                TextFormField(
                  initialValue: customer?.documentCPF ?? '',
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
                  validator: _validarCpf,
                ),

                TextFormField(
                  initialValue: customer?.documentRG ?? '',
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
              onPressed: _salvando ? null : _submitForm,
              style: FilledButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 158, 204, 174),
                disabledBackgroundColor: const Color.fromARGB(
                  255,
                  158,
                  204,
                  174,
                ),
                padding: EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: _salvando
                  ? const SizedBox(
                      width: 26,
                      height: 26,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: Color(0xff1C5631),
                      ),
                    )
                  : const Icon(
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
