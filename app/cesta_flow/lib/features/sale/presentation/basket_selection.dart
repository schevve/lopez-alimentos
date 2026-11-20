import 'package:cesta_flow/core/constants/colors/app_colors.dart';
import 'package:cesta_flow/core/constants/util/format_currency.dart';
import 'package:cesta_flow/core/data/local/model/basket_model.dart';
import 'package:cesta_flow/core/data/local/repository/basket_repository.dart';
import 'package:cesta_flow/features/sale/presentation/basket_registration.dart';
import 'package:cesta_flow/features/shared/top_bar.dart';
import 'package:flutter/material.dart';

class BasketSelection extends StatefulWidget {
  const BasketSelection({super.key});

  @override
  State<BasketSelection> createState() => _BasketSelectionState();
}

class _BasketSelectionState extends State<BasketSelection> {
  final SearchController _searchController = SearchController();
  Future<List<Basket>> _baskets = Future.value([]);
  List<Basket> _allBaskets = [];
  List<Basket> _filteredBaskets = [];

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _reload() {
    _baskets = BasketRepository().getAllBaskets();
    _baskets.then((baskets) {
      if (!mounted) return;
      setState(() {
        _allBaskets = baskets;
        _filteredBaskets = _filterBaskets(baskets, _searchController.text);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const TopBar(pagTitle: 'Selecionar cesta'),
      body: FutureBuilder<List<Basket>>(
        future: _baskets,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return _buildBasketList(snapshot.data!);
          } else if (snapshot.hasError) {
            return _statusView(
              icon: Icons.cloud_off_outlined,
              title: 'Não foi possível carregar as cestas',
              message: 'Verifique e tente novamente mais tarde.',
            );
          } else {
            return _statusView(
              loading: true,
              title: 'Carregando cestas',
              message: 'Só um instante.',
            );
          }
        },
      ),
    );
  }

  Widget _buildBasketList(List<Basket> baskets) {
    return CustomScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Qual é a cesta?',
                  style: TextStyle(
                    color: Color(0xFF18251F),
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Busque pelo nome para selecionar na venda.',
                  style: TextStyle(
                    color: Color(0xFF59665E),
                    fontSize: 15,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 20),
                SearchBar(
                  controller: _searchController,
                  hintText: 'Nome da cesta',
                  leading: const Icon(
                    Icons.search_rounded,
                    color: AppColors.primary,
                  ),
                  elevation: const WidgetStatePropertyAll(0),
                  backgroundColor: const WidgetStatePropertyAll(Colors.white),
                  padding: const WidgetStatePropertyAll(
                    EdgeInsets.symmetric(horizontal: 16),
                  ),
                  constraints: const BoxConstraints(minHeight: 58),
                  shape: WidgetStatePropertyAll(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                      side: const BorderSide(color: Color(0xFFE1E9E3)),
                    ),
                  ),
                  onChanged: (searchQuery) {
                    setState(() {
                      _filteredBaskets = _filterBaskets(
                        _allBaskets,
                        searchQuery,
                      );
                    });
                  },
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: FilledButton.icon(
                    onPressed: _openBasketRegistration,
                    icon: const Icon(Icons.add_shopping_cart),
                    label: const Text('Cadastrar nova cesta'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Cestas',
                        style: TextStyle(
                          color: Color(0xFF18251F),
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE7F1E9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_filteredBaskets.length}',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
        if (_filteredBaskets.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: _emptyResults(hasBaskets: baskets.isNotEmpty),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final basket = _filteredBaskets[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _BasketSelectionCard(
                    basket: basket,
                    onTap: () => Navigator.pop(context, basket),
                  ),
                );
              }, childCount: _filteredBaskets.length),
            ),
          ),
      ],
    );
  }

  Future<void> _openBasketRegistration() async {
    final value = await Navigator.push<Basket>(
      context,
      MaterialPageRoute(builder: (context) => const BasketRegistration()),
    );
    if (value != null) {
      _reload();
      if (!mounted) return;
      Navigator.pop(context, value);
    }
  }

  Widget _emptyResults({required bool hasBaskets}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: Color(0xFFE7F1E9),
                shape: BoxShape.circle,
              ),
              child: Icon(
                hasBaskets
                    ? Icons.search_off_rounded
                    : Icons.shopping_basket_outlined,
                color: AppColors.primary,
                size: 30,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              hasBaskets ? 'Nenhuma cesta encontrada' : 'Ainda não há cestas',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF18251F),
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              hasBaskets
                  ? 'Tente buscar por outro nome.'
                  : 'Cadastre uma cesta para adicioná-la à venda.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF59665E),
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusView({
    required String title,
    required String message,
    IconData? icon,
    bool loading = false,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (loading)
              const CircularProgressIndicator(color: AppColors.primary)
            else
              Icon(icon, color: AppColors.primary, size: 42),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF18251F),
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF59665E),
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BasketSelectionCard extends StatelessWidget {
  const _BasketSelectionCard({required this.basket, required this.onTap});

  final Basket basket;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final initials = basket.name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();

    return Material(
      color: Colors.white,
      elevation: 1,
      shadowColor: const Color(0xFF194D30).withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFFE7F1E9),
                child: initials.isEmpty
                    ? const Icon(
                        Icons.shopping_basket_outlined,
                        color: AppColors.primary,
                      )
                    : Text(
                        initials,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      basket.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF18251F),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      formatCurrency(basket.price),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF59665E),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFF718078)),
            ],
          ),
        ),
      ),
    );
  }
}

List<Basket> _filterBaskets(List<Basket> baskets, String query) {
  if (query.isEmpty) return baskets;
  final lowered = query.toLowerCase();
  return baskets
      .where((basket) => basket.name.toLowerCase().contains(lowered))
      .toList();
}
