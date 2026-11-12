import 'package:cesta_flow/features/payment/presentation/payment_success.dart';
import 'package:cesta_flow/features/sale/presentation/sale_registration.dart';
import 'package:cesta_flow/core/data/local/db_helper.dart';
import 'package:cesta_flow/core/data/local/model/installment_model.dart';
import 'package:cesta_flow/core/data/local/repository/installment_repository.dart';
import 'package:cesta_flow/features/shared/top_bar.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class PaymentRegistration extends StatefulWidget {
  final int saleId;

  const PaymentRegistration({super.key, required this.saleId});

  @override
  State<PaymentRegistration> createState() => _PaymentRegistration();
}

class _PaymentRegistration extends State<PaymentRegistration> {
  final _formKey = GlobalKey<FormState>();
  final _formData = <String, dynamic>{};

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
                    onSaved: (value) => _formData['paymentValue'] = value,
                  ),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Vencimento',
                      hintText: 'dd/mm/aaaa',

                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),

                      filled: true,
                      fillColor: Colors.white,
                    ),

                    keyboardType: TextInputType.datetime,
                    inputFormatters: [FormatDate()],
                    onSaved: (value) => _formData['dueDate'] = value,
                  ),
                  FilledButton(
                    onPressed: () async {
                      await _submitForm();
                    },
                    child: Text("Realizar cobrança"),
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
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      var db = DatabaseHelper();
      var installmentRepository = InstallmentRepository(dbHelper: db);
      final int saleId = widget.saleId;

      final String rawValue = _formData['paymentValue'] ?? "0,00";
      final String cleanValue = rawValue
          .replaceAll('.', '')
          .replaceAll(',', '.');
      final double realValue = double.tryParse(cleanValue) ?? 0.0;
      final dueDate = _parseDate(_formData['dueDate'] as String?);

      try {
        final installment = Installment(
          uuid: const Uuid().v4(),
          saleId: saleId,
          amount: realValue,
          dueDate: dueDate,
          paymentDate: DateTime.now(),
        );
        await installmentRepository.registerInstallment(installment);
      } catch (e) {
        print("erro no banco de dados: $e");
      }

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => PaymentSuccess(
            paymentValue: _formData['paymentValue'] as String? ?? '',
            dueDate: _formData['dueDate'] as String? ?? '',
          ),
        ),
      );
    }
  }
}

DateTime? _parseDate(String? value) {
  if (value == null || value.trim().isEmpty) return null;
  final parts = value.split('/');
  if (parts.length != 3) return null;
  final day = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  final year = int.tryParse(parts[2]);
  if (day == null || month == null || year == null) return null;
  return DateTime(year, month, day);
}
