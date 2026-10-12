import 'package:flutter/material.dart';

class SaleSuccess extends StatefulWidget {
  final double valor;
  final String clienteNome;

  const SaleSuccess({
    super.key,
    required this.valor,
    required this.clienteNome,
  });

  @override
  State<SaleSuccess> createState() => _SaleSuccessState();
}

class _SaleSuccessState extends State<SaleSuccess> {
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
              'Venda registrada!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
            Text(
              "${widget.valor}   -   ${widget.clienteNome}",
              style: TextStyle(
                color: Color.fromARGB(255, 53, 134, 83),
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
