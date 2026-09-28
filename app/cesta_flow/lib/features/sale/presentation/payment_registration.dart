import 'package:cesta_flow/core/data/local/model/customer_model.dart';
import 'package:cesta_flow/features/customer/presentation/customer_list.dart';
import 'package:cesta_flow/features/dashboard/presentation/dashboard.dart';
import 'package:cesta_flow/features/sale/presentation/customer_selection.dart';
import 'package:cesta_flow/features/sale/presentation/payment_success.dart';
import 'package:cesta_flow/features/sale/presentation/sale_registration.dart';
import 'package:cesta_flow/core/data/local/db_helper.dart';
import 'package:cesta_flow/core/data/local/model/payment_model.dart';
import 'package:cesta_flow/core/data/local/repository/payment_repository.dart';
import 'package:cesta_flow/features/shared/bottom_bar.dart';
import 'package:cesta_flow/features/shared/top_bar.dart';
import 'package:flutter/material.dart';

class PaymentRegistration extends StatefulWidget {
  final int customerId;

  const PaymentRegistration({super.key, this.customerId = 1});

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
                      labelText: "Metodo de pagamento",
                      prefixText: '',

                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),

                      filled: true,
                      fillColor: Colors.white,
                    ),

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
      bottomNavigationBar: BottomBar(),
    );
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      var db = DatabaseHelper();
      var paymentRepository = PaymentRepository(dbHelper: db);
      final int customerId = widget.customerId;

      final String rawValue = _formData['paymentValue'] ?? "0,00";
      final String cleanValue = rawValue
          .replaceAll('.', '')
          .replaceAll(',', '.');
      final double realValue = double.tryParse(cleanValue) ?? 0.0;

      try {
        final List<Payment> allPayments = await paymentRepository
            .getPaymentsByCustumerId(customerId);

        double amount = await paymentRepository.getPaymentsByCustumerIdAmount(
          customerId,
        );

        if (allPayments.isNotEmpty) {
          amount = amount - realValue;
        }
        var paymentData = Payment(
          customerId: customerId,
          method: _formData['paymentTerm'],
          amount: amount,
          date: DateTime.now(),
        );
        await paymentRepository.registerPayment(paymentData);
        print('Pagamento registrado com sucesso: ${paymentData.amount}');
      } catch (e) {
        print("erro no banco de dados: $e");
      }

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => PaymentSuccess(
            paymentValue: _formData['paymentValue'],
            paymentTerm: _formData['paymentTerm'],
            nextVisit: _formData['nextVisit'],
          ),
        ),
      );
    }
  }
}
