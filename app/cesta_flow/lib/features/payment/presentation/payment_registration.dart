import 'package:cesta_flow/core/data/local/db_helper.dart';
import 'package:cesta_flow/core/data/local/model/customer_model.dart';
import 'package:cesta_flow/core/data/local/repository/installment_repository.dart';
import 'package:cesta_flow/features/payment/presentation/payment_success.dart';
import 'package:cesta_flow/features/shared/top_bar.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cesta_flow/core/constants/util/input_formatters.dart';

class PaymentRegistration extends StatefulWidget {
  final int saleId;

  const PaymentRegistration({super.key, required this.saleId});

  @override
  State<PaymentRegistration> createState() => _PaymentRegistration();
}

class _PaymentRegistration extends State<PaymentRegistration> {
  String? _selectedPaymentMethod;

  late final Customer _defaultCustomer = Customer(
    uuid: 'mock-customer',
    id: 1,
    name: 'João da Silva (Teste)',
    dateOfBirth: DateTime(1990, 5, 15),
    email: 'joao.silva@email.com',
    phone: '(11) 98765-4321',
    address: 'Rua das Flores, 123',
    addressNumber: '111',
    city: 'São Paulo',
    state: 'SP',
    cep: '01001-000',
    documentCPF: '123.456.789-00',
    documentRG: '12.345.678-9',
  );

  static const double _pendingAmount = 150.00;
  final DateTime _saleDate = DateTime.now();

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
                    'R\$${_pendingAmount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 35,
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      height: 1.0,
                    ),
                  ),
                  Text(
                    'compra realizada em ${DateFormat('dd/MM/yyyy').format(_saleDate)}',
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
                    initialValue: _pendingAmount.toStringAsFixed(2),
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
                    children:
                        [
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
                              side: const BorderSide(color: Color(0xff1C5631)),
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
                    onSaved: (value) => _formData['dueDate'] = value,
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

      final db = DatabaseHelper();
      final installmentRepository = InstallmentRepository(dbHelper: db);
      final int saleId = widget.saleId;

      final String rawValue = _formData['paymentValue'] ?? "0,00";
      final String cleanValue = rawValue
          .replaceAll('.', '')
          .replaceAll(',', '.');
      final double realValue = double.tryParse(cleanValue) ?? 0.0;

      try {
        await installmentRepository.registerPayment(
          saleId: saleId,
          amount: realValue,
          paymentMethod: _selectedPaymentMethod,
        );
      } catch (e) {
        debugPrint("erro no banco de dados: $e");
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
