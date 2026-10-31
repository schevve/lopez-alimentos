import 'package:cesta_flow/core/constants/colors/app_colors.dart';
import 'package:flutter/material.dart';

class BottomBar extends StatefulWidget {
  const BottomBar({
    super.key,
    required this.onTap,
    required this.buttonsIcons,
    required this.selectedKey,
  });

  final Map<String, (String, IconData)> buttonsIcons;
  final Function(String) onTap;
  final String selectedKey;

  @override
  State<BottomBar> createState() => _BottomBarState();
}

class _BottomBarState extends State<BottomBar> {
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
    bool isSelected = key == widget.selectedKey;

    return Expanded(
      child: Container(
        color: isSelected ? AppColors.black.withAlpha(50) : Colors.transparent,
        child: IconButton(
          hoverColor: Colors.transparent,
          style: IconButton.styleFrom(
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.zero,
            ),
          ),
          icon: Column(
            spacing: 4,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(buttonIcon, color: AppColors.white),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          onPressed: () {
            setState(() {
              widget.onTap(key);
            });
          },
        ),
      ),
    );
  }
}
