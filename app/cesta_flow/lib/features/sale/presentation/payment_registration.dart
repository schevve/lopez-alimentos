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
import 'package:intl/intl.dart';

class PaymentRegistration extends StatefulWidget {
  final Customer? customer;
  final Payment? payment;

  const PaymentRegistration({super.key, this.customer, this.payment});

  @override
  State<PaymentRegistration> createState() => _PaymentRegistration();
}

class _PaymentRegistration extends State<PaymentRegistration> {
  String? _selectedPaymentMethod;

  late final Customer _defaultCustomer = Customer(
    id: 1,
    name: 'João da Silva (Teste)',
    dateOfBirth: DateTime(1990, 5, 15),
    email: 'joao.silva@email.com',
    phone: '(11) 98765-4321',
    address: 'Rua das Flores, 123',
    city: 'São Paulo',
    state: 'SP',
    cep: '01001-000',
    documentCPF: '123.456.789-00',
    documentRG: '12.345.678-9',
  );

  // Dados de teste (mock) caso nenhum pagamento seja passado externamente
  late final Payment _defaultPayment = Payment(
    id: 1,
    customerId: 1,
    method: 'Cartão de Crédito',
    amount: 150.00,
    date: DateTime.now(),
  );

  final _formKey = GlobalKey<FormState>();
  final _formData = <String, dynamic>{};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xffF3FCF3),

      appBar: TopBar(pagTitle: 'Registrar pagamento'),

      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 32),

        child: Column(
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
                  _defaultCustomer.name,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Colors.redAccent,
                  ),
                ),
              ],
            ),

            SizedBox(height: 8),

            Container(
              padding: EdgeInsets.fromLTRB(8.00, 4.00, 8.00, 4.00),
              width: 650,
              height: 100,
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 179, 189, 167),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.warning_outlined,
                        color: Colors.orange,
                        size: 20,
                      ),

                      SizedBox(width: 4),

                      Text(
                        "Parcela pendente",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    "R\$${_defaultPayment?.amount.toString() ?? ''}",
                    style: TextStyle(
                      fontSize: 35,
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      height: 1.0,
                    ),
                  ),
                  Text(
                    "compra realizada em ${_defaultPayment?.date != null ? DateFormat('dd/MM/yyyy').format(_defaultPayment!.date) : ''}",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "VALOR RECEBIDO (R\$)",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Color(0xff1C5631),
                ),
              ),
            ),
            SizedBox(height: 8),
            Form(
              key: _formKey,

              child: Column(
                spacing: 10,
                children: [
                  TextFormField(
                    initialValue: _defaultPayment?.amount.toString() ?? '',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                    ),

                    decoration: InputDecoration(
                      prefixText: 'R\$ ',
                      prefixStyle: TextStyle(
                        color: Color(0xff1C5631),
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),

                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),

                      filled: true,
                      fillColor: Colors.white,

                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 10,
                      ),
                    ),

                    keyboardType: TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [FormatMoney()],
                    onSaved: (value) => _formData['paymentValue'] = value,
                  ),

                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Forma de pagamento",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color.fromARGB(255, 77, 82, 79),
                      ),
                    ),
                  ),
                  GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 3.5,
                    children: [
                      'Pix',
                      'Cartão',
                      'Dinheiro',
                      'Vale de alimentação',
                    ].map((method) {
                      final isSelected = _selectedPaymentMethod == method;

                      return OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _selectedPaymentMethod = method;
                          });
                        },
                        style: OutlinedButton.styleFrom(
                          backgroundColor: isSelected
                              ? const Color(0xff1C5631)
                              : Colors.white,
                          foregroundColor: isSelected
                              ? Colors.white
                              : const Color(0xff1C5631),
                          side: const BorderSide(
                            color: Color(0xff1C5631),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(method),
                      );
                    }).toList(),
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
                    style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xff1C5631),
                    foregroundColor: Colors.white,
                  ),

                    onPressed: () async {
                      if (_selectedPaymentMethod == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Selecione um método de pagamento'),
                          ),
                        );
                        return;
                      }

                      if (!_formKey.currentState!.validate()) {
                        return;
                      }

                      _formKey.currentState!.save();

                      _formData['paymentTerm'] = _selectedPaymentMethod;
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

      // var db = DatabaseHelper();
      // var paymentRepository = PaymentRepository(dbHelper: db);
      // final int? customerId = widget.customer?.id;
      // if (customerId == null) {
      //   throw Exception('o cliente não possui ID válido');
      // }

      // final String rawValue = _formData['paymentValue'] ?? "0,00";
      // final String cleanValue = rawValue
      //     .replaceAll('.', '')
      //     .replaceAll(',', '.');
      // final double realValue = double.tryParse(cleanValue) ?? 0.0;

      // try {
      //   final List<Payment> allPayments = await paymentRepository
      //       .getPaymentsByCustumerId(customerId);

      //   double amount = await paymentRepository.getPaymentsByCustumerIdAmount(
      //     customerId,
      //   );

      //   if (allPayments.isNotEmpty) {
      //     amount = amount - realValue;
      //   }
      //   var paymentData = Payment(
      //     customerId: customerId,
      //     method: _formData['paymentTerm'],
      //     amount: amount,
      //     date: DateTime.now(),
      //   );
      //   await paymentRepository.registerPayment(paymentData);
      //   print('Pagamento registrado com sucesso: ${paymentData.amount}');
      // } catch (e) {
      //   print("erro no banco de dados: $e");
      // }

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
