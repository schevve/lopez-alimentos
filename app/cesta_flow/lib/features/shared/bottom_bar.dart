import 'package:cesta_flow/features/customer/presentation/customer_list.dart';
import 'package:cesta_flow/features/dashboard/presentation/dashboard.dart';
import 'package:cesta_flow/features/sale/presentation/payment_registration.dart';
import 'package:flutter/material.dart';

class BottomBar extends StatefulWidget {
  BottomBar({super.key, this.onTap, this.pagesIcons});

  final List<Widget>? pagesIcons;
  final Function(int)? onTap;

  @override
  State<BottomBar> createState() => _BottomBarState();
}

class _BottomBarState extends State<BottomBar> {
  late int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      padding: EdgeInsets.symmetric(horizontal: 40.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (var icon in widget.pagesIcons ?? [])
            _buildTabItem(icon, context),
        ],
      ),
    );
  }

  Widget _buildTabItem(Widget pageIcon, BuildContext context) {
    int index = widget.pagesIcons?.indexOf(pageIcon) ?? 0;
    bool isSelected = index == _selectedIndex;

    return IconButton(
      icon: Icon(
        (pageIcon as Icon).icon,
        color: isSelected ? Colors.green : Colors.grey,
      ),
      onPressed: () {
        if (widget.onTap != null) {
          setState(() {
            _selectedIndex = index;
          });
          widget.onTap!(index);
        }
      },
    );
  }
}
