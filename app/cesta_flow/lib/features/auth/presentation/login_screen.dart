// Widgets e formatação nativos do Flutter.
import 'package:cesta_flow/features/dashboard/presentation/dashboard.dart';
import 'package:flutter/foundation.dart';
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
  final _cpfController = TextEditingController();
  final _senhaController = TextEditingController();
  bool _senhaVisivel = false;
  bool _lembrarMe = true;

  @override
  void dispose() {
    _cpfController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  // Valida somente o preenchimento; autenticação será integrada depois.
  String? _validarCpf(String? valor) {
    return valor == null || valor.trim().isEmpty ? 'Informe seu CPF.' : null;
  }

  String? _validarSenha(String? valor) {
    return valor == null || valor.trim().isEmpty ? 'Informe sua senha.' : null;
  }

  void _entrar() {
    if (!_formKey.currentState!.validate()) return;
    // Saída solicitada para desenvolvimento, desativada em release.
    if (kDebugMode) {
      debugPrint('CPF: ${_cpfController.text}');
      debugPrint('Senha: ${_senhaController.text}');
      debugPrint('Lembrar-me: $_lembrarMe');
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const Dashboard()),
    );
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
                                  _label('CPF'),
                                  _campoComSombra(
                                    TextFormField(
                                      controller: _cpfController,
                                      keyboardType: TextInputType.number,
                                      textInputAction: TextInputAction.next,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                        LengthLimitingTextInputFormatter(11),
                                        _CpfInputFormatter(),
                                      ],
                                      validator: _validarCpf,
                                      decoration: _decoracaoCampo(
                                        placeholder: '123.456.456-78',
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
                                  const SizedBox(height: 24),
                                  SizedBox(
                                    height: 56,
                                    child: ElevatedButton(
                                      onPressed: _entrar,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: _verdeBotao,
                                        foregroundColor: Colors.white,
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
                                      child: const Text(
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

// Máscara incremental preservando a posição do cursor ao editar o CPF.
class _CpfInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text;
    final buffer = StringBuffer();
    var cursor = 0;
    for (var i = 0; i < digits.length; i++) {
      if (i == 3 || i == 6) buffer.write('.');
      if (i == 9) buffer.write('-');
      buffer.write(digits[i]);
      if (i < newValue.selection.extentOffset) cursor = buffer.length;
    }
    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: cursor),
    );
  }
}
