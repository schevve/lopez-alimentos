import 'package:cesta_flow/core/constants/util/customer_form_validators.dart';
import 'package:cesta_flow/core/constants/util/format_cep.dart';
import 'package:cesta_flow/core/constants/util/format_cpf.dart';
import 'package:cesta_flow/core/constants/util/format_date.dart';
import 'package:cesta_flow/core/constants/util/format_phone.dart';
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

  bool _salvando = false;

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
                      validateRequired(value, 'Informe o nome completo.'),
                ),

                TextFormField(
                  initialValue: formatDateFromDateTime(customer?.dateOfBirth),
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
                  inputFormatters: [FormatDateInput()],
                  onSaved: (value) => _formData['data_nascimento'] = value,
                  validator: validateBirthDate,
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
                  validator: validateEmail,
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
                  validator: validatePhone,
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
                  validator: (value) =>
                      validateRequired(value, 'Informe a rua.'),
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
                      validateRequired(value, 'Informe o número.'),
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
                      validateRequired(value, 'Informe a cidade.'),
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
                  validator: validateState,
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
                  inputFormatters: [CepInputFormatter()],
                  onSaved: (value) => _formData['cep'] = value,
                  validator: validateCep,
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
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(11),
                    CpfInputFormatter(),
                  ],
                  onSaved: (value) => _formData['cpf'] = value,
                  validator: validateCpf,
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
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(14),
                  ],
                  onSaved: (value) => _formData['rg'] = value,
                  validator: validateRg,
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
}