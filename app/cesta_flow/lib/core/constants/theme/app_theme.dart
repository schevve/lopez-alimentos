import 'package:cesta_flow/core/constants/colors/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

ThemeData buildAppTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
  );
  final fontFamily = GoogleFonts.lexend().fontFamily;
  final textTheme = base.textTheme.apply(fontFamily: fontFamily);
  return base.copyWith(
    textTheme: textTheme,
    primaryTextTheme: base.primaryTextTheme.apply(fontFamily: fontFamily),
  );
}