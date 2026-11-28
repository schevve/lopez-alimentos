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
  bool _suppressOpen = false;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _syncDisplayText();
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
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
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

  void _startEditing() {
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
  }

  void _closeWithoutSelection() {
    if (!_editing) return;
    setState(() {
      _editing = false;
      _query = '';
      _syncDisplayText();
    });
    _focusNode.unfocus();
  }

  bool _tapIsInsideAnchor(Offset globalPosition) {
    final box = _anchorKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return false;
    final local = box.globalToLocal(globalPosition);
    return box.size.contains(local);
  }

  void _select(FormFieldState<T> field, T value) {
    // setValue atualiza o campo sem marcar interação. didChange faria o
    // Form em onUserInteraction validar todos os campos na hora.
    field.setValue(value);
    widget.onChanged?.call(value);
    _textController.text = _labelFor(value) ?? '';
    setState(() {
      _editing = false;
      _query = '';
    });
    _focusNode.unfocus();
  }

  TextStyle _fieldTextStyle(BuildContext context) {
    return (Theme.of(context).textTheme.bodyLarge ?? const TextStyle()).copyWith(
      fontSize: 16,
    );
  }

  InputDecoration _decoration(
    BuildContext context, {
    required FormFieldState<T> field,
    String? errorText,
  }) {
    final errorColor = Theme.of(context).colorScheme.error;
    return AppTextFormField.baseDecoration.copyWith(
      labelText: widget.labelText,
      hintText: widget.hintText,
      errorText: errorText,
      suffixIcon: IconButton(
        tooltip: _editing ? 'Fechar' : 'Abrir',
        onPressed: !widget.enabled
            ? null
            : _editing
            ? () {
                _suppressOpen = true;
                _closeWithoutSelection();
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _suppressOpen = false;
                });
              }
            : _startEditing,
        icon: Icon(
          _editing ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
          color: const Color(0xff1C5631),
        ),
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
        if (field.value != widget.value) {
          field.setValue(widget.value);
        }
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
              style: _fieldTextStyle(context),
              decoration: _decoration(
                context,
                field: field,
                errorText: showError ? field.errorText : null,
              ),
              onTap: () {
                if (_suppressOpen || _editing) return;
                _startEditing();
              },
              onTapOutside: (event) {
                if (!_editing) return;
                if (_tapIsInsideAnchor(event.position)) return;
                _closeWithoutSelection();
              },
              onChanged: _editing
                  ? (value) => setState(() => _query = value)
                  : null,
              textInputAction: TextInputAction.search,
            ),
            if (_editing) ...[
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 280),
                child: _filteredOptions.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 18,
                        ),
                        child: Text(
                          _query.trim().isEmpty
                              ? 'Digite para pesquisar.'
                              : 'Nenhum resultado para "$_query".',
                          style: _fieldTextStyle(context),
                        ),
                      )
                    : Material(
                        color: const Color(0xFFE4F1E8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: ListView.separated(
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          itemCount: _filteredOptions.length,
                          separatorBuilder: (_, _) => const Divider(
                            height: 1,
                            thickness: 1,
                            color: Color(0xFF9EBBA8),
                          ),
                          itemBuilder: (context, index) {
                            final option = _filteredOptions[index];
                            return InkWell(
                              onTap: () => _select(field, option.value),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 18,
                                ),
                                child: Text(
                                  option.label,
                                  style: _fieldTextStyle(context),
                                ),
                              ),
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