import 'package:cesta_flow/core/data/local/model/customer_model.dart';
import 'package:cesta_flow/core/data/local/repository/customer_repository.dart';
import 'package:cesta_flow/features/shared/top_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomerRegistration extends StatefulWidget {
  const CustomerRegistration({super.key, this.customerId, this.repository});

  final int? customerId;
  final CustomerRepository? repository;

  @override
  State<CustomerRegistration> createState() => _CustomerRegistrationState();
}

class _CustomerRegistrationState extends State<CustomerRegistration> {
  final _formKey = GlobalKey<FormState>();
  final _formData = <String, dynamic>{};
  late final CustomerRepository _customerRepository;
  Customer? _cliente;
  bool _carregando = false;
  bool _salvando = false;
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

      body: SingleChildScrollView(
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
                    initialValue: _cliente?.name,
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
                    initialValue: _cliente == null
                        ? null
                        : _formatDate(_cliente!.dateOfBirth),
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
                    initialValue: _cliente?.email,
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
                    initialValue: _cliente?.phone,
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
                    initialValue: _cliente?.address,
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
                    initialValue: _cliente?.city,
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
                    initialValue: _cliente?.state,
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
                    initialValue: _cliente?.cep,
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
                    initialValue: _cliente?.documentCPF,
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
                    initialValue: _cliente?.documentRG,
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
          ],
        ),
      ),
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(canvasColor: Colors.transparent),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),

          child: FilledButton.icon(
            onPressed: _salvando ? null : _submitForm,
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
              _salvando
                  ? "Salvando..."
                  : widget.customerId == null
                  ? "Registrar Cliente"
                  : "Salvar alterações",
              style: TextStyle(
                color: Color(0xff1C5631),
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    _formKey.currentState!.save();
    setState(() => _salvando = true);
    try {
      final customerData = Customer(
        id: _cliente?.id,
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
        score: _cliente?.score,
      );

      if (_cliente == null) {
        await _customerRepository.registerCustomer(customerData);
      } else {
        await _customerRepository.updateCustomer(customerData);
      }

      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      debugPrint('Erro ao salvar cliente: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível salvar o cliente.')),
        );
      }
    } finally {
      if (mounted) setState(() => _salvando = false);
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
