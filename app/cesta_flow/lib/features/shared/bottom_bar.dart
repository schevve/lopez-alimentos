import 'package:cesta_flow/features/customer/presentation/customer_list.dart';
import 'package:cesta_flow/features/dashboard/presentation/dashboard.dart';
import 'package:cesta_flow/features/sale/presentation/payment_registration.dart';
import 'package:flutter/material.dart';

class BottomBar extends StatelessWidget {
  const BottomBar({super.key});

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
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
                MaterialPageRoute(builder: (context) => PaymentRegistration()),
              );
            },
            icon: Icon(Icons.settings),
          ),
        ],
      ),
    );
  }
}
