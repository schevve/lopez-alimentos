import 'package:cesta_flow/core/data/local/model/customer_model.dart';
import 'package:cesta_flow/features/customer/presentation/customer_list.dart';
import 'package:cesta_flow/features/dashboard/presentation/dashboard.dart';
import 'package:cesta_flow/features/sale/presentation/customer_selection.dart';
import 'package:cesta_flow/features/sale/presentation/payment_registration.dart';
import 'package:cesta_flow/features/sale/presentation/sale_registration.dart';
import 'package:cesta_flow/core/data/local/db_helper.dart';
import 'package:cesta_flow/core/data/local/model/payment_model.dart';
import 'package:cesta_flow/core/data/local/repository/payment_repository.dart';
import 'package:flutter/material.dart';

class BillingPage extends StatefulWidget {
  final int customerId;
  const BillingPage({super.key, this.customerId = 1});

  @override
  State<BillingPage> createState() => _BillingPage();
}

class _BillingPage extends State<BillingPage> {
  final _formKey = GlobalKey<FormState>();
  final _formData = <String, dynamic>{};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xffF3FCF3),

      appBar: AppBar(
        backgroundColor: const Color(0xff1C5631),

        flexibleSpace: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage('web/images/FundoComidas.png'),
              fit: BoxFit.cover,
            ),
          ),
        ),

        toolbarHeight: 70,
        title: Text(
          'Registrar Cliente',
          style: TextStyle(
            fontSize: 24,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton.filled(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          style: IconButton.styleFrom(
            backgroundColor: const Color.fromARGB(48, 255, 255, 255),
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
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
      bottomNavigationBar: BottomAppBar(
        padding: EdgeInsets.symmetric(horizontal: 40.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => Dashboard()),
                );
              },
              icon: Icon(Icons.home),
            ),
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CustomerList()),
                );
              },
              icon: Icon(Icons.person),
            ),
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CustomerSelection()),
                );
              },
              icon: Icon(Icons.settings),
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
          builder: (context) => PaymentRegistration(
            paymentValue: _formData['paymentValue'],
            paymentTerm: _formData['paymentTerm'],
            nextVisit: _formData['nextVisit'],
          ),
        ),
      );
    }
  }
}
