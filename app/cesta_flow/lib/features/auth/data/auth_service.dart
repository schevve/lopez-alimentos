import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Erro de login com mensagem pronta para ser exibida ao usuário.
class LoginException implements Exception {
  const LoginException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Concentra a autenticação com o Supabase Auth.
///
/// O Supabase Auth autentica por e-mail + senha, mas o app usa CPF + senha.
/// Por isso o CPF (somente dígitos) é convertido em um e-mail interno, por
/// exemplo `12345678901@cestaflow.example.com`. Os usuários precisam estar
/// cadastrados no Supabase (Authentication → Users) com esse e-mail.
///
/// Se o grupo preferir outro formato (ex.: buscar o e-mail numa tabela),
/// basta alterar [cpfParaEmail].
class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  static const String _dominioEmail = 'cestaflow.example.com';
  static const String _chaveLembrarMe = 'auth_lembrar_me';

  SupabaseClient get _client => Supabase.instance.client;

  /// Há uma sessão ativa (usuário logado)?
  bool get estaLogado => _client.auth.currentSession != null;

  /// Converte um CPF (com ou sem máscara) no e-mail usado no Supabase Auth.
  static String cpfParaEmail(String cpf) {
    final digitos = cpf.replaceAll(RegExp(r'\D'), '');
    return '$digitos@$_dominioEmail';
  }

  /// Faz login com CPF e senha. Lança [LoginException] em caso de falha.
  Future<void> entrar({
    required String cpf,
    required String senha,
    required bool lembrarMe,
  }) async {
    try {
      await _client.auth.signInWithPassword(
        email: cpfParaEmail(cpf),
        password: senha,
      );
    } on AuthRetryableFetchException {
      throw const LoginException(
        'Sem conexão com o servidor. Verifique sua internet e tente de novo.',
      );
    } on AuthException catch (e) {
      throw LoginException(_traduzirErro(e));
    } catch (_) {
      throw const LoginException(
        'Não foi possível entrar agora. Tente novamente.',
      );
    }

    // Só guarda a preferência depois que o login deu certo.
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_chaveLembrarMe, lembrarMe);
    } catch (_) {
      // Falhar ao salvar a preferência não deve impedir o login.
    }
  }

  /// Encerra a sessão do usuário.
  Future<void> sair() => _client.auth.signOut();

  /// Chamar uma vez ao abrir o app: se o usuário desmarcou "Lembrar-me" no
  /// último login, a sessão salva é encerrada e ele volta para a tela de login.
  Future<void> aplicarPreferenciaLembrarMe() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lembrar = prefs.getBool(_chaveLembrarMe) ?? true;
      if (!lembrar && estaLogado) {
        await _client.auth.signOut();
      }
    } catch (_) {
      // Na dúvida, mantém a sessão como está.
    }
  }

  String _traduzirErro(AuthException e) {
    switch (e.code) {
      case 'invalid_credentials':
        return 'CPF ou senha incorretos.';
      case 'email_not_confirmed':
        return 'Esta conta ainda não foi ativada. Procure o administrador.';
      case 'over_request_rate_limit':
      case 'over_email_send_rate_limit':
        return 'Muitas tentativas. Aguarde um momento e tente de novo.';
      case 'user_banned':
        return 'Esta conta está bloqueada. Procure o administrador.';
    }
    // Versões antigas do servidor não enviam `code`, só a mensagem.
    if (e.message.toLowerCase().contains('invalid login credentials')) {
      return 'CPF ou senha incorretos.';
    }
    return 'Não foi possível entrar. Tente novamente.';
  }
}
