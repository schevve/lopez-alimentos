import 'package:cesta_flow/core/constants/colors/app_colors.dart';
import 'package:cesta_flow/core/constants/util/customer_form_validators.dart';
import 'package:cesta_flow/core/constants/util/format_cep.dart';
import 'package:cesta_flow/core/constants/util/format_cpf.dart';
import 'package:cesta_flow/core/constants/util/format_date.dart';
import 'package:cesta_flow/core/constants/util/format_phone.dart';
import 'package:cesta_flow/core/data/local/model/customer_model.dart';
import 'package:cesta_flow/features/shared/app_text_form_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomerForm extends StatefulWidget {
  final Customer? customer;

  final Future<void> Function(Map<String, dynamic> data) onSubmit;

  final Future<bool> Function()? canManageSalesOverride;

  final String buttonText;
  final String title;

  const CustomerForm({
    super.key,
    this.customer,
    this.canManageSalesOverride,
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
  bool _isSubmitting = false;
  late final Future<bool>? _canManageSalesOverride;

  @override
  void initState() {
    super.initState();
    _canManageSalesOverride = widget.customer == null
        ? null
        : widget.canManageSalesOverride?.call();
  }

  Future<void> _submitForm() async {
    if (_isSubmitting) return;

    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Corrija os campos destacados.')),
      );
      return;
    }

    _formData.remove('is_admin_unblocked');
    _formKey.currentState!.save();

    setState(() => _isSubmitting = true);
    try {
      await widget.onSubmit(_formData);
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
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
          Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              spacing: 16,
              children: [
                AppTextFormField(
                  labelText: 'Nome completo*',
                  hintText: " ",
                  initialValue: customer?.name ?? '',
                  prefixIcon: const Icon(
                    Icons.person,
                    color: Color(0xff1C5631),
                  ),
                  onSaved: (value) => _formData['nome'] = value,
                  validator: (value) =>
                      validateRequired(value, 'Informe o nome completo.'),
                ),
                AppTextFormField(
                  labelText: 'Data de Nascimento *',
                  hintText: 'dd/mm/aaaa',
                  initialValue: formatDateFromDateTime(customer?.dateOfBirth),
                  keyboardType: TextInputType.datetime,
                  inputFormatters: [FormatDateInput()],
                  onSaved: (value) => _formData['data_nascimento'] = value,
                  validator: validateBirthDate,
                ),
                AppTextFormField(
                  labelText: 'Email (opcional)',
                  initialValue: customer?.email ?? '',
                  keyboardType: TextInputType.emailAddress,
                  onSaved: (value) => _formData['email'] = value,
                  validator: validateEmail,
                ),
                AppTextFormField(
                  labelText: 'Telefone *',
                  initialValue: customer?.phone ?? '',
                  keyboardType: TextInputType.phone,
                  inputFormatters: [FormatPhoneNumber()],
                  onSaved: (value) => _formData['telefone'] = value,
                  validator: validatePhone,
                ),
                AppTextFormField(
                  labelText: 'CEP (opcional)',
                  initialValue: customer?.cep ?? '',
                  keyboardType: TextInputType.number,
                  inputFormatters: [CepInputFormatter()],
                  onSaved: (value) => _formData['cep'] = value,
                  validator: validateCep,
                ),
                AppTextFormField(
                  labelText: 'Estado *',
                  initialValue: customer?.state ?? '',
                  keyboardType: TextInputType.text,
                  onSaved: (value) => _formData['estado'] = value,
                  validator: (value) =>
                      validateRequired(value, 'Informe o estado.'),
                ),
                AppTextFormField(
                  labelText: 'Cidade *',
                  initialValue: customer?.city ?? '',
                  keyboardType: TextInputType.text,
                  onSaved: (value) => _formData['cidade'] = value,
                  validator: (value) =>
                      validateRequired(value, 'Informe a cidade.'),
                ),
                AppTextFormField(
                  labelText: 'Rua *',
                  initialValue: customer?.address ?? '',
                  keyboardType: TextInputType.text,
                  onSaved: (value) => _formData['rua'] = value,
                  validator: (value) =>
                      validateRequired(value, 'Informe a rua.'),
                ),
                AppTextFormField(
                  labelText: 'Número *',
                  initialValue: customer?.addressNumber ?? '',
                  keyboardType: TextInputType.number,
                  onSaved: (value) => _formData['numero'] = value,
                  validator: (value) =>
                      validateRequired(value, 'Informe o número.'),
                ),
                AppTextFormField(
                  labelText: 'CPF *',
                  initialValue: customer?.documentCPF ?? '',
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(11),
                    CpfInputFormatter(),
                  ],
                  onSaved: (value) => _formData['cpf'] = value,
                  validator: validateCpf,
                ),
                AppTextFormField(
                  labelText: 'RG (opcional)',
                  initialValue: customer?.documentRG ?? '',
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(14),
                  ],
                  onSaved: (value) => _formData['rg'] = value,
                  validator: validateRg,
                ),
                if (customer != null && _canManageSalesOverride != null)
                  FutureBuilder<bool>(
                    future: _canManageSalesOverride,
                    builder: (context, snapshot) {
                      if (snapshot.data != true) return const SizedBox.shrink();
                      return FormField<bool>(
                        initialValue: customer.isAdminUnblocked,
                        onSaved: (value) {
                          if (value != customer.isAdminUnblocked) {
                            _formData['is_admin_unblocked'] = value;
                          }
                        },
                        builder: (field) => SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Liberar vendas para este cliente'),
                          subtitle: const Text(
                            'Liberação do bloqueio por score',
                          ),
                          value: field.value!,
                          onChanged: _isSubmitting ? null : field.didChange,
                        ),
                      );
                    },
                  ),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _isSubmitting ? null : _submitForm,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 32,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(
                            Icons.person_add_alt_1_outlined,
                            color: AppColors.white,
                            size: 26,
                          ),
                    label: Text(
                      _isSubmitting ? 'Salvando...' : widget.buttonText,
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
