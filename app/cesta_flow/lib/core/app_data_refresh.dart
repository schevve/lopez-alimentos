import 'package:flutter/widgets.dart';

/// Central de avisos: “os dados locais mudaram, recarregue se estiver na tela”.
///
/// Padrão **Observer** (publicar / escutar):
/// - Quem grava no banco chama [notifyAppDataChanged] (publica).
/// - Abas do [IndexedStack] registram um listener e chamam o próprio `_load…` (escutam).
///
/// Usamos uma instância global ([appDataRefresh]) porque rotas empilhadas
/// (`Navigator.push`) não ficam abaixo da `MainScreen` na árvore de widgets,
/// então um [InheritedWidget] só na main não alcançaria telas de cadastro.
class AppDataRefresh extends ChangeNotifier {
  void notifyDataChanged() {
    notifyListeners();
  }
}

/// Instância compartilhada do app inteiro.
final appDataRefresh = AppDataRefresh();

/// Atalho para publicar após cadastro, edição, exclusão ou sync bem-sucedido.
///
/// O aviso roda no **próximo frame** para não chamar `setState` nas abas
/// enquanto o [Navigator] ainda está fazendo `pop`/`push`.
void notifyAppDataChanged() {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    appDataRefresh.notifyDataChanged();
  });
}

/// Registra / remove o listener nas abas montadas no [IndexedStack].
mixin AppDataRefreshListener<T extends StatefulWidget> on State<T> {
  void onAppDataChanged();

  void registerAppDataRefreshListener() {
    appDataRefresh.addListener(_handleAppDataRefresh);
  }

  void unregisterAppDataRefreshListener() {
    appDataRefresh.removeListener(_handleAppDataRefresh);
  }

  void _handleAppDataRefresh() {
    if (mounted) onAppDataChanged();
  }
}