import 'package:cesta_flow/core/app_data_refresh.dart';
import 'package:flutter/widgets.dart';

/// Quando uma rota empilhada fecha e a [MainScreen] volta a ser visível, recarrega as abas.
class AppShellRefreshObserver extends NavigatorObserver {
  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (previousRoute?.isFirst ?? false) {
      notifyAppDataChanged();
    }
  }
}

final appShellRefreshObserver = AppShellRefreshObserver();