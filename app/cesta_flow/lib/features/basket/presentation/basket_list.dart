import 'package:cesta_flow/core/constants/colors/app_colors.dart';
import 'package:cesta_flow/core/data/local/model/basket_model.dart';
import 'package:cesta_flow/core/data/local/repository/basket_repository.dart';
import 'package:cesta_flow/core/data/remote/sync_on_user_refresh.dart';
import 'package:cesta_flow/features/basket/presentation/widgets/basket_card.dart';
import 'package:cesta_flow/features/sale/presentation/basket_registration.dart';
import 'package:cesta_flow/features/shared/top_bar.dart';
import 'package:flutter/material.dart';

class BasketList extends StatefulWidget {
  const BasketList({super.key});

  @override
  State<BasketList> createState() => _BasketListState();
}

class _BasketListState extends State<BasketList> {
  static const _verde = Color(0xFF1B4D31);

  final BasketRepository _basketRepository = BasketRepository();
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  String? _errorMessage;
  List<Basket> _baskets = const [];

  @override
  void initState() {
    super.initState();
    _loadBaskets();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadBaskets({bool showLoadingIndicator = false}) async {
    if (showLoadingIndicator) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final baskets = await _basketRepository.getAllBaskets();
      if (!mounted) {
        return;
      }

      setState(() {
        _baskets = baskets;
        _isLoading = false;
      });
    } catch (error) {
      debugPrint('Erro ao carregar lista de cestas: $error');
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
        _errorMessage = 'Não foi possível carregar as cestas.';
      });
    }
  }

  String _normalize(String text) {
    var result = text.toLowerCase();
    const groups = {
      '[áàâãä]': 'a',
      '[éèêë]': 'e',
      '[íìîï]': 'i',
      '[óòôõö]': 'o',
      '[úùûü]': 'u',
      'ç': 'c',
    };
    groups.forEach(
      (pattern, value) => result = result.replaceAll(RegExp(pattern), value),
    );
    return result;
  }

  List<Basket> get _filteredBaskets {
    final query = _normalize(_searchController.text.trim());
    if (query.isEmpty) {
      return _baskets;
    }

    return _baskets
        .where((basket) => _normalize(basket.name).contains(query))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredBaskets = _filteredBaskets;

    return Scaffold(
      backgroundColor: const Color(0xFFF0FDF4),
      appBar: const TopBar(pagTitle: 'Cestas', showDrawer: true),
      body: RefreshIndicator(
        onRefresh: () => refreshWithRemoteSync(
          _loadBaskets,
          onSyncFailed: (message) {
            if (!mounted) return;
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(message)));
          },
        ),
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 14),
              Text(
                'Lista de cestas',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.black,
                ),
              ),
              Container(
                margin: const EdgeInsets.fromLTRB(0, 16, 0, 12),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: _verde,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Buscar por nome...',
                    hintStyle: const TextStyle(
                      color: Color(0xFF808A84),
                      fontSize: 18,
                    ),
                    fillColor: Colors.white,
                    filled: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 20,
                    ),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: _verde,
                      size: 26,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              ..._buildBasketsSection(filteredBaskets),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
      floatingActionButton: FilledButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const BasketRegistration(),
            ),
          );
          if (!mounted) {
            return;
          }
          await _loadBaskets(showLoadingIndicator: true);
        },
        style: FilledButton.styleFrom(
          padding: EdgeInsets.zero,
          backgroundColor: Colors.transparent,
          shadowColor: Colors.black,
          elevation: 6,
        ),
        child: Container(
          height: 58,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFFF7A16),
            borderRadius: BorderRadius.circular(999),
            boxShadow: const [
              BoxShadow(
                color: Color.fromRGBO(255, 122, 22, 0.28),
                spreadRadius: 0,
                blurRadius: 24,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.add_shopping_cart, color: Colors.white, size: 26),
              SizedBox(width: 8),
              Text(
                'Cadastrar Cesta',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  List<Widget> _buildBasketsSection(List<Basket> baskets) {
    if (_isLoading) {
      return const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 32),
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }

    if (_errorMessage != null) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: Color(0xFFC62828)),
          ),
        ),
      ];
    }

    if (baskets.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: Text(
            _searchController.text.trim().isEmpty
                ? 'Nenhuma cesta cadastrada ainda.'
                : 'Nenhuma cesta encontrada para a busca.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: Color(0xFF707070)),
          ),
        ),
      ];
    }

    return [
      for (var index = 0; index < baskets.length; index++) ...[
        if (index > 0) const SizedBox(height: 14),
        BasketCard(
          basket: baskets[index],
          onEdit: () {
            // Edição de cestas: implementar na página de edição.
          },
        ),
      ],
    ];
  }
}