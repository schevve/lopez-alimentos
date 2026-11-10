// Widgets e formatação nativos do Flutter.
import 'package:cesta_flow/features/auth/data/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'widgets/logo_widget.dart';
import 'widgets/produce_pattern.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const _verdeMenta = Color(0xFFF1FBF3);
  static const _verdeEscuro = Color(0xFF1C5632);
  static const _verdeBotao = Color(0xFF234019);

  // Controllers e estado dos controles do formulário.
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  bool _senhaVisivel = false;
  bool _lembrarMe = true;
  bool _carregando = false;
  String? _erro;

  @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  // Validação simples de formato; quem confere se o e-mail existe é o servidor.
  String? _validarEmail(String? valor) {
    final email = (valor ?? '').trim();
    if (email.isEmpty) return 'Informe seu e-mail.';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return 'Informe um e-mail válido.';
    }
    return null;
  }

  String? _validarSenha(String? valor) {
    return valor == null || valor.isEmpty ? 'Informe sua senha.' : null;
  }

  // Autentica no Supabase. Ao dar certo, o AuthGate (main.dart) detecta a
  // sessão e troca esta tela pela tela principal, então não navegamos aqui.
  Future<void> _entrar() async {
    if (_carregando) return;
    FocusScope.of(context).unfocus();
    setState(() => _erro = null);
    if (!_formKey.currentState!.validate()) return;

    setState(() => _carregando = true);
    try {
      await AuthService.instance.entrar(
        email: _emailController.text,
        senha: _senhaController.text,
        lembrarMe: _lembrarMe,
      );
    } on LoginException catch (e) {
      if (mounted) setState(() => _erro = e.message);
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  InputDecoration _decoracaoCampo({String? placeholder, Widget? suffixIcon}) {
    return InputDecoration(
      hintText: placeholder,
      hintStyle: const TextStyle(color: Color(0xFF9EA0AD)),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(32),
        borderSide: const BorderSide(color: Color(0xFFE2E9E3)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(32),
        borderSide: const BorderSide(color: Color(0xFFE2E9E3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(32),
        borderSide: const BorderSide(color: Color(0xFFAED0AA), width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(32),
        borderSide: const BorderSide(color: Color(0xFFFFDAD6)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(32),
        borderSide: const BorderSide(color: Color(0xFFFFDAD6), width: 2),
      ),
      errorStyle: const TextStyle(color: Color(0xFFFFDAD6)),
      suffixIcon: suffixIcon,
    );
  }

  // A sombra acompanha apenas a cápsula branca, sem envolver o erro abaixo.
  Widget _campoComSombra(Widget campo) => Stack(
    children: [
      Positioned(
        top: 0,
        left: 0,
        right: 0,
        height: 56,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .10),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
        ),
      ),
      campo,
    ],
  );

  Widget _label(String texto) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      texto,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    ),
  );

  // Duas seções; rolagem mantém os campos acessíveis com o teclado aberto.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _verdeMenta,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final altura = constraints.maxHeight;
          return SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Column(
              children: [
                SizedBox(
                  height: altura * .28,
                  child: SafeArea(
                    bottom: false,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: LogoWidget(),
                        ),
                      ),
                    ),
                  ),
                ),
                Container(
                  width: double.infinity,
                  constraints: BoxConstraints(minHeight: altura * .72),
                  clipBehavior: Clip.antiAlias,
                  decoration: const BoxDecoration(
                    color: _verdeEscuro,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(32),
                    ),
                  ),
                  child: Stack(
                    children: [
                      const Positioned.fill(child: ProducePattern()),
                      SafeArea(
                        top: false,
                        minimum: EdgeInsets.fromLTRB(
                          24,
                          altura < 700 ? 40 : 64,
                          24,
                          40,
                        ),
                        child: Align(
                          alignment: Alignment.topCenter,
                          heightFactor: 1,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 480),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const Text(
                                    'Bem-Vindo de volta!!',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 28,
                                      height: 1.2,
                                      letterSpacing: -.6,
                                    ),
                                  ),
                                  const SizedBox(height: 32),
                                  _label('E-mail'),
                                  _campoComSombra(
                                    TextFormField(
                                      controller: _emailController,
                                      keyboardType: TextInputType.emailAddress,
                                      textInputAction: TextInputAction.next,
                                      autocorrect: false,
                                      enableSuggestions: false,
                                      inputFormatters: [
                                        // Impede espaços digitados sem querer.
                                        FilteringTextInputFormatter.deny(
                                          RegExp(r'\s'),
                                        ),
                                      ],
                                      validator: _validarEmail,
                                      decoration: _decoracaoCampo(
                                        placeholder: 'seu@email.com',
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  _label('Senha'),
                                  _campoComSombra(
                                    TextFormField(
                                      controller: _senhaController,
                                      obscureText: !_senhaVisivel,
                                      enableSuggestions: false,
                                      autocorrect: false,
                                      textInputAction: TextInputAction.done,
                                      onFieldSubmitted: (_) => _entrar(),
                                      validator: _validarSenha,
                                      decoration: _decoracaoCampo(
                                        suffixIcon: IconButton(
                                          tooltip: _senhaVisivel
                                              ? 'Ocultar senha'
                                              : 'Mostrar senha',
                                          onPressed: () => setState(
                                            () =>
                                                _senhaVisivel = !_senhaVisivel,
                                          ),
                                          icon: Icon(
                                            _senhaVisivel
                                                ? Icons.visibility
                                                : Icons.visibility_off,
                                            color: const Color(0xFF9EA0AD),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Checkbox(
                                        value: _lembrarMe,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            5,
                                          ),
                                        ),
                                        side: const BorderSide(
                                          color: Color(0xFFBCD5BB),
                                          width: 1.5,
                                        ),
                                        fillColor:
                                            WidgetStateProperty.resolveWith(
                                              (states) =>
                                                  states.contains(
                                                    WidgetState.selected,
                                                  )
                                                  ? const Color(0xFFDCEFD7)
                                                  : Colors.white.withValues(
                                                      alpha: .08,
                                                    ),
                                            ),
                                        checkColor: _verdeEscuro,
                                        onChanged: (valor) => setState(
                                          () => _lembrarMe = valor ?? false,
                                        ),
                                      ),
                                      const Expanded(
                                        flex: 4,
                                        child: Text(
                                          'Lembrar-me',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Flexible(
                                        flex: 6,
                                        fit: FlexFit.tight,
                                        // O alinhamento ocupa a sobra; o toque fica só no texto.
                                        child: Align(
                                          alignment: Alignment.centerRight,
                                          child: Material(
                                            color: Colors.transparent,
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                            clipBehavior: Clip.antiAlias,
                                            child: InkWell(
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                              splashColor: Colors.white
                                                  .withValues(alpha: .10),
                                              highlightColor: Colors.white
                                                  .withValues(alpha: .06),
                                              onTap: () => debugPrint(
                                                'Navegar para recuperação de senha',
                                              ),
                                              child: Padding(
                                                padding: const EdgeInsets.all(
                                                  4,
                                                ),
                                                child: Text(
                                                  'Esqueceu a senha?',
                                                  textAlign: TextAlign.end,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .labelLarge
                                                      ?.copyWith(
                                                        color: const Color(
                                                          0xFFD2DECE,
                                                        ),
                                                      ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  // Erro vindo do servidor (ex.: senha incorreta).
                                  if (_erro != null) ...[
                                    const SizedBox(height: 16),
                                    Semantics(
                                      liveRegion: true,
                                      child: Text(
                                        _erro!,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          color: Color(0xFFFFDAD6),
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 24),
                                  SizedBox(
                                    height: 56,
                                    child: ElevatedButton(
                                      onPressed: _carregando ? null : _entrar,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: _verdeBotao,
                                        foregroundColor: Colors.white,
                                        disabledBackgroundColor: _verdeBotao,
                                        disabledForegroundColor: Colors.white70,
                                        elevation: 3,
                                        shadowColor: Colors.black.withValues(
                                          alpha: .24,
                                        ),
                                        surfaceTintColor: Colors.transparent,
                                        overlayColor: Colors.white.withValues(
                                          alpha: .18,
                                        ),
                                        splashFactory: InkRipple.splashFactory,
                                        animationDuration: const Duration(
                                          milliseconds: 200,
                                        ),
                                        side: BorderSide(
                                          color: Colors.white.withValues(
                                            alpha: .08,
                                          ),
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                      ),
                                      child: _carregando
                                          ? const SizedBox(
                                              width: 24,
                                              height: 24,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 3,
                                                color: Colors.white,
                                              ),
                                            )
                                          : const Text(
                                              'Entrar',
                                              style: TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
