import 'package:flutter/material.dart';

class PaymentRegistration extends StatefulWidget {
  final String paymentValue;
  final String paymentTerm;
  final String nextVisit;

  const PaymentRegistration({
    super.key,
    required this.paymentValue,
    required this.paymentTerm,
    required this.nextVisit
  });

  @override
  State<PaymentRegistration> createState() => _PaymentRegistrationState();
}

class _PaymentRegistrationState extends State<PaymentRegistration> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xffF3FCF3),

      body: Center(
        child: Column(
          spacing: 16,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 60,
              height: 60,

              alignment: Alignment.center,

              decoration: BoxDecoration(
                color: Color.fromARGB(255, 204, 250, 204),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.check_circle_outline,
                size: 30,
                color: Color.fromARGB(255, 53, 134, 83),
              ),
            ),

            SizedBox(height: 10),
            Text(
              'Pagamento registrado!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
            Text(
              "${widget.paymentValue}   -   ${widget.paymentTerm}",
              style: TextStyle(
                color: Color.fromARGB(255, 53, 134, 83),
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
            Text("Próxima visita: ${widget.nextVisit}"),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("voltar ao cliente"),
            ),
            
          ],
        ),
      ),
    );
  }
}
