import 'package:flutter/material.dart';

final GlobalKey<ScaffoldState> mainScaffoldKey = GlobalKey<ScaffoldState>();

/// Troca a aba visível no [IndexedStack] da [MainScreen].
void Function(String tabKey)? selectMainShellTab;

void navigateToMainShellTab(String tabKey) {
  selectMainShellTab?.call(tabKey);
}
