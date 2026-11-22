import 'package:cesta_flow/core/app_data_refresh.dart';
import 'package:cesta_flow/core/data/local/model/basket_model.dart';
import 'package:cesta_flow/core/data/local/repository/basket_repository.dart';
import 'package:cesta_flow/features/shared/basket_form.dart';
import 'package:cesta_flow/features/shared/top_bar.dart';
import 'package:flutter/material.dart';

class BasketEdit extends StatefulWidget {
  const BasketEdit({
    super.key,
    required this.basket,
    this.repository,
  });

  final Basket basket;
  final BasketRepository? repository;

  @override
  State<BasketEdit> createState() => _BasketEditState();
}

class _BasketEditState extends State<BasketEdit> {
  bool _isDeleting = false;

  BasketRepository get _repository => widget.repository ?? BasketRepository();

  Future<void> _update(String name, double price) async {
    final updated = widget.basket.copyWith(
      name: name,
      price: price,
    );
    final result = await _repository.updateBasket(updated);
    if (!mounted) return;
    if (result == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível salvar as alterações.'),
        ),
      );
      return;
    }
    notifyAppDataChanged();
    Navigator.of(context).pop(true);
  }

  Future<void> _confirmRemove() async {
    if (_isDeleting) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remover cesta'),
        content: Text(
          'Deseja remover "${widget.basket.name}"? '
          'Ela deixará de aparecer na lista.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFB42318)),
            child: const Text('Remover'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    setState(() => _isDeleting = true);
    try {
      final id = widget.basket.id;
      if (id == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cesta inválida.')),
        );
        return;
      }

      final result = await _repository.deleteBasket(id);
      if (!mounted) return;

      switch (result) {
        case 1:
          notifyAppDataChanged();
          Navigator.of(context).pop(true);
        case -1:
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Esta cesta está vinculada a vendas e não pode ser removida.',
              ),
            ),
          );
        default:
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Não foi possível remover a cesta.')),
          );
      }
    } finally {
      if (mounted) {
        setState(() => _isDeleting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF3FCF3),
      appBar: const TopBar(pagTitle: 'Editar cesta'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 24,
          children: [
            BasketForm(
              basket: widget.basket,
              submitLabel: 'Salvar alterações',
              onSubmit: _update,
            ),
            OutlinedButton.icon(
              onPressed: _isDeleting ? null : _confirmRemove,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFB42318),
                side: const BorderSide(color: Color(0xFFB42318)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: _isDeleting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.delete_outline),
              label: const Text(
                'Remover cesta',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}