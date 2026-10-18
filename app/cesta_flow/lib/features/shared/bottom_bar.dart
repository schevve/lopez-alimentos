import 'package:cesta_flow/core/constants/colors/app_colors.dart';
import 'package:flutter/material.dart';

class BottomBar extends StatefulWidget {
  const BottomBar({super.key, required this.onTap, required this.buttonsIcons});

  final Map<String, (String, IconData)> buttonsIcons;
  final Function(String) onTap;

  @override
  State<BottomBar> createState() => _BottomBarState();
}

class _BottomBarState extends State<BottomBar> {
  late String _selectedKey = widget.buttonsIcons.keys.first;

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      padding: EdgeInsets.symmetric(horizontal: 40.0),
      color: AppColors.primary,
      child: Row(
        spacing: 5,
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          for (var entry in widget.buttonsIcons.entries)
            _buildTabItem(entry.key, entry.value.$1, entry.value.$2, context),
        ],
      ),
    );
  }

  Widget _buildTabItem(
    String key,
    String label,
    IconData buttonIcon,
    BuildContext context,
  ) {
    bool isSelected = key == _selectedKey;

    return Expanded(
      child: Container(
        color: isSelected ? AppColors.black.withAlpha(50) : Colors.transparent,
        child: IconButton(
          icon: Column(
            spacing: 4,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                buttonIcon,
                color: isSelected ? Colors.green : AppColors.white,
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected ? Colors.green : AppColors.white,
                ),
              ),
            ],
          ),
          onPressed: () {
            setState(() {
              _selectedKey = key;
            });
            widget.onTap(key);
          },
        ),
      ),
    );
  }
}
