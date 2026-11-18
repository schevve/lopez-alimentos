import 'package:cesta_flow/core/constants/colors/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Campo de texto padrão do app.
///
/// Todo formulário deve usar este widget no lugar de [TextFormField] para que
/// a aparência dos campos (borda, preenchimento, rótulo, cores, estado
/// somente leitura...) possa ser alterada em um único lugar:
/// [AppTextFormField.baseDecoration].
///
/// Exemplo de campo editável:
/// ```dart
/// AppTextFormField(
///   labelText: 'Próxima visita',
///   controller: _nextVisitController,
///   inputFormatters: [FormatDate()],
/// )
/// ```
///
/// Exemplo de campo somente leitura (exibição de dados):
/// ```dart
/// AppTextFormField(
///   labelText: 'Cliente',
///   initialValue: customerLabel,
///   readOnly: true,
/// )
/// ```
class AppTextFormField extends StatelessWidget {
  /// Raio das bordas dos campos do app.
  static const BorderRadius _borderRadius = BorderRadius.all(
    Radius.circular(20),
  );

  /// Decoração compartilhada por todos os campos do app.
  ///
  /// Alterar aqui reflete em todos os formulários que usam
  /// [AppTextFormField]. As bordas de erro são montadas em tempo de execução
  /// com a cor de erro do tema (`Theme.of(context).colorScheme.error`).
  static const InputDecoration baseDecoration = InputDecoration(
    filled: true,
    fillColor: Color(0xFFE4F1E8),
    floatingLabelBehavior: FloatingLabelBehavior.never,
    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 18),
    border: OutlineInputBorder(borderRadius: _borderRadius),
    enabledBorder: OutlineInputBorder(
      borderRadius: _borderRadius,
      borderSide: BorderSide(color: Color(0xFFE4F1E8)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: _borderRadius,
      borderSide: BorderSide(color: AppColors.primary, width: 2),
    ),
    disabledBorder: OutlineInputBorder(
      borderRadius: _borderRadius,
      borderSide: BorderSide(color: Color(0xFF9EBBA8)),
    ),
  );

  final String labelText;
  final String? hintText;

  /// Valor inicial do campo. Não pode ser usado junto com [controller].
  final String? initialValue;

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final FormFieldValidator<String>? validator;
  final FormFieldSetter<String>? onSaved;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;

  /// Quando `true`, o texto é exibido mas não pode ser editado.
  final bool readOnly;
  final bool enabled;
  final bool obscureText;
  final bool autofocus;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final TextCapitalization textCapitalization;
  final TextInputAction? textInputAction;
  final TextAlign textAlign;
  final AutovalidateMode? autovalidateMode;

  /// Decoração personalizada apenas para este campo.
  ///
  /// Quando informada, substitui [baseDecoration] (estilo global do app).
  /// [labelText], [hintText], [prefixIcon] e [suffixIcon] continuam sendo
  /// aplicados por cima, e as bordas de erro seguem a cor de erro do tema.
  final InputDecoration? decoration;

  const AppTextFormField({
    super.key,
    required this.labelText,
    this.hintText,
    this.initialValue,
    this.controller,
    this.focusNode,
    this.keyboardType,
    this.inputFormatters,
    this.validator,
    this.onSaved,
    this.onChanged,
    this.onFieldSubmitted,
    this.readOnly = false,
    this.enabled = true,
    this.obscureText = false,
    this.autofocus = false,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.prefixIcon,
    this.suffixIcon,
    this.textCapitalization = TextCapitalization.none,
    this.textInputAction,
    this.textAlign = TextAlign.start,
    this.autovalidateMode,
    this.decoration,
  }) : assert(
         initialValue == null || controller == null,
         'Informe apenas um: initialValue ou controller.',
       );

  @override
  Widget build(BuildContext context) {
    final errorColor = Theme.of(context).colorScheme.error;
    // `decoration` substitui [baseDecoration] apenas neste campo; rótulo,
    // hint e ícones são sempre aplicados por cima.
    final resolvedDecoration = (decoration ?? baseDecoration).copyWith(
      labelText: labelText,
      hintText: hintText,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      errorBorder: OutlineInputBorder(
        borderRadius: _borderRadius,
        borderSide: BorderSide(color: errorColor),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: _borderRadius,
        borderSide: BorderSide(color: errorColor, width: 2),
      ),
    );

    return TextFormField(
      controller: controller,
      initialValue: initialValue,
      focusNode: focusNode,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      onSaved: onSaved,
      onChanged: onChanged,
      onFieldSubmitted: onFieldSubmitted,
      readOnly: readOnly,
      enabled: enabled,
      obscureText: obscureText,
      autofocus: autofocus,
      maxLines: obscureText ? 1 : maxLines,
      minLines: minLines,
      maxLength: maxLength,
      textCapitalization: textCapitalization,
      textInputAction: textInputAction,
      textAlign: textAlign,
      autovalidateMode: autovalidateMode,
      decoration: resolvedDecoration,
    );
  }
}
