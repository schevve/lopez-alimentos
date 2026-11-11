import 'package:cesta_flow/features/payment/presentation/payment_success.dart';
import 'package:cesta_flow/features/sale/presentation/sale_registration.dart';
import 'package:cesta_flow/core/data/local/repository/payment_repository.dart';
import 'package:cesta_flow/core/domain/payment_allocation.dart';
import 'package:cesta_flow/features/shared/top_bar.dart';
import 'package:flutter/material.dart';

class PaymentRegistration extends StatefulWidget {
  final int saleId;

  const PaymentRegistration({super.key, required this.saleId});

  @override
  State<PaymentRegistration> createState() => _PaymentRegistration();
}

class _PaymentRegistration extends State<PaymentRegistration> {
  final _formKey = GlobalKey<FormState>();
  final _formData = <String, dynamic>{};
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xffF3FCF3),

      appBar: TopBar(pagTitle: "Cobrança"),

      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 32),

        child: Column(
          children: [
            Form(
              key: _formKey,

              child: Column(
                spacing: 16,
                children: [
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: "valor cobrado",
                      prefixText: 'R\$',

                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),

                      filled: true,
                      fillColor: Colors.white,
                    ),

                    keyboardType: TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [FormatMoney()],
                    validator: (value) {
                      final raw = (value ?? '')
                          .replaceAll('.', '')
                          .replaceAll(',', '.');
                      final amount = double.tryParse(raw);
                      if (amount == null || amount <= 0) {
                        return 'Informe um valor maior que zero.';
                      }
                      return null;
                    },
                    onSaved: (value) => _formData['paymentValue'] = value,
                  ),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: "Metodo de pagamento",
                      prefixText: '',

                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),

                      filled: true,
                      fillColor: Colors.white,
                    ),

                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Informe a forma de pagamento.';
                      }
                      return null;
                    },
                    onSaved: (value) => _formData['paymentTerm'] = value,
                  ),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Proxima visita *',
                      hintText: 'dd/mm/aaaa',

                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),

                      filled: true,
                      fillColor: Colors.white,
                    ),

                    keyboardType: TextInputType.datetime,
                    inputFormatters: [FormatDate()],
                    onSaved: (value) => _formData['nextVisit'] = value,
                  ),
                  FilledButton(
                    onPressed: _isSubmitting ? null : _submitForm,
                    child: Text(
                      _isSubmitting ? "Registrando..." : "Realizar cobrança",
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    setState(() {
      _isSubmitting = true;
    });

    final rawValue = _formData['paymentValue'] as String;
    final cleanValue = rawValue.replaceAll('.', '').replaceAll(',', '.');
    final amountCents = (double.parse(cleanValue) * 100).round();
    final paymentValue = _formData['paymentValue'] as String;
    final paymentTerm = (_formData['paymentTerm'] as String).trim();
    final nextVisit = _formData['nextVisit'] as String? ?? '';

    try {
      final result = await PaymentRepository().registerSalePayment(
        saleId: widget.saleId,
        amountCents: amountCents,
        method: paymentTerm,
        date: DateTime.now(),
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => PaymentSuccess(
            paymentValue: paymentValue,
            paymentTerm: paymentTerm,
            nextVisit: nextVisit,
            saleSettled: result.saleIsSettled,
          ),
        ),
      );
    } on PaymentExceedsBalanceException catch (error) {
      if (mounted) _showError(error.toString());
    } catch (error) {
      if (mounted) _showError('Não foi possível registrar o pagamento: $error');
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}
