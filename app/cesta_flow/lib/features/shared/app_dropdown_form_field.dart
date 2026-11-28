import 'package:cesta_flow/features/shared/app_text_form_field.dart';
import 'package:flutter/material.dart';

class AppDropdownOption<T> {
  const AppDropdownOption({required this.value, required this.label});

  final T value;
  final String label;
}

/// Campo de seleção com pesquisa no próprio input (combobox).
///
/// Ao tocar, o texto fica editável, o teclado abre, o formulário rola para o
/// topo e a lista filtrada aparece abaixo do mesmo campo.
class AppDropdownFormField<T> extends StatefulWidget {
  final String labelText;
  final String? hintText;
  final T? value;
  final List<AppDropdownOption<T>> options;
  final FormFieldValidator<T>? validator;
  final FormFieldSetter<T>? onSaved;
  final ValueChanged<T?>? onChanged;
  final bool enabled;
  final AutovalidateMode? autovalidateMode;
  final Key? fieldKey;

  const AppDropdownFormField({
    super.key,
    this.fieldKey,
    required this.labelText,
    this.hintText,
    required this.value,
    required this.options,
    this.validator,
    this.onSaved,
    this.onChanged,
    this.enabled = true,
    this.autovalidateMode,
  });

  @override
  State<AppDropdownFormField<T>> createState() => _AppDropdownFormFieldState<T>();
}

class _AppDropdownFormFieldState<T> extends State<AppDropdownFormField<T>> {
  final _anchorKey = GlobalKey();
  final _textController = TextEditingController();
  final _focusNode = FocusNode();
  bool _editing = false;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _syncDisplayText();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(covariant AppDropdownFormField<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_editing && widget.value != oldWidget.value) {
      _syncDisplayText();
    }
    if (!_editing && widget.options != oldWidget.options) {
      _syncDisplayText();
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus && _editing) {
      _stopEditing(restoreLabel: true);
    }
  }

  void _syncDisplayText() {
    final label = _labelFor(widget.value);
    _textController.text = label ?? '';
    _query = '';
  }

  String _normalize(String text) {
    const from = 'áàâãäéèêëíìîïóòôõöúùûüçñ';
    const to = 'aaaaaeeeeiiiiooooouuuucn';
    final buffer = StringBuffer();
    for (final rune in text.toLowerCase().runes) {
      final char = String.fromCharCode(rune);
      final index = from.indexOf(char);
      buffer.write(index >= 0 ? to[index] : char);
    }
    return buffer.toString();
  }

  List<AppDropdownOption<T>> get _filteredOptions {
    if (_query.trim().isEmpty) return widget.options;
    final query = _normalize(_query.trim());
    return widget.options
        .where((option) => _normalize(option.label).contains(query))
        .toList();
  }

  String? _labelFor(T? value) {
    if (value == null) return null;
    for (final option in widget.options) {
      if (option.value == value) return option.label;
    }
    return null;
  }

  void _startEditing(FormFieldState<T> field) {
    if (!widget.enabled || _editing) return;
    setState(() {
      _editing = true;
      _query = '';
      _textController.clear();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final context = _anchorKey.currentContext;
      if (context != null) {
        Scrollable.ensureVisible(
          context,
          alignment: 0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
      _focusNode.requestFocus();
    });
    field.validate();
  }

  void _stopEditing({required bool restoreLabel}) {
    if (!_editing) return;
    setState(() {
      _editing = false;
      _query = '';
      if (restoreLabel) {
        _syncDisplayText();
      }
    });
  }

  void _select(FormFieldState<T> field, T value) {
    field.didChange(value);
    widget.onChanged?.call(value);
    _textController.text = _labelFor(value) ?? '';
    setState(() {
      _editing = false;
      _query = '';
    });
    _focusNode.unfocus();
  }

  InputDecoration _decoration(
    BuildContext context, {
    String? errorText,
  }) {
    final errorColor = Theme.of(context).colorScheme.error;
    return AppTextFormField.baseDecoration.copyWith(
      labelText: widget.labelText,
      hintText: widget.hintText,
      errorText: errorText,
      suffixIcon: Icon(
        _editing ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
        color: const Color(0xff1C5631),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(color: errorColor),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(color: errorColor, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FormField<T>(
      initialValue: widget.value,
      validator: widget.validator,
      onSaved: widget.onSaved,
      autovalidateMode: widget.autovalidateMode,
      builder: (field) {
        final showError = field.hasError;

        return Column(
          key: _anchorKey,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              key: widget.fieldKey,
              controller: _textController,
              focusNode: _focusNode,
              enabled: widget.enabled,
              readOnly: !_editing,
              showCursor: _editing,
              decoration: _decoration(
                context,
                errorText: showError ? field.errorText : null,
              ),
              onTap: () {
                if (!_editing) _startEditing(field);
              },
              onChanged: _editing
                  ? (value) => setState(() => _query = value)
                  : null,
              textInputAction: TextInputAction.search,
            ),
            if (_editing) ...[
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 220),
                child: _filteredOptions.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          _query.trim().isEmpty
                              ? 'Digite para pesquisar.'
                              : 'Nenhum resultado para "$_query".',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      )
                    : Material(
                        elevation: 2,
                        borderRadius: BorderRadius.circular(12),
                        color: const Color(0xFFE4F1E8),
                        child: ListView.separated(
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          itemCount: _filteredOptions.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final option = _filteredOptions[index];
                            final isSelected =
                                (widget.value ?? field.value) == option.value;
                            return ListTile(
                              dense: true,
                              title: Text(option.label),
                              selected: isSelected,
                              onTap: () => _select(field, option.value),
                            );
                          },
                        ),
                      ),
              ),
            ],
          ],
        );
      },
    );
  }
}