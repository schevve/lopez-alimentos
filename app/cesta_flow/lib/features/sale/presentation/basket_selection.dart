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
  Future<List<Basket>> _baskets = Future.value([]);
  List<Basket> _filteredBaskets = [];

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _baskets = BasketRepository().getAllBaskets();
    _baskets.then((baskets) {
      if (!mounted) return;
      setState(() {
        _filteredBaskets = baskets;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF3FCF3),
      appBar: const TopBar(pagTitle: 'Selecionar cesta'),
      body: FutureBuilder<List<Basket>>(
        future: _baskets,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Column(
                spacing: 16,
                children: [
                  SearchBar(
                    hintText: 'Digite o nome da cesta',
                    onChanged: (searchQuery) {
                      setState(() {
                        _filteredBaskets = _filterBaskets(
                          snapshot.data!,
                          searchQuery,
                        );
                      });
                    },
                  ),
                  OutlinedButton(
                    onPressed: () async {
                      final value = await Navigator.push<Basket>(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const BasketRegistration(),
                        ),
                      );
                      if (value != null) {
                        _reload();
                        if (!context.mounted) return;
                        Navigator.pop(context, value);
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      alignment: Alignment.centerLeft,
                      fixedSize: const Size(double.infinity, 64),
                      side: const BorderSide(color: Color(0xff1C5631), width: 2),
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                    ),
                    child: const Text(
                      'Cadastrar nova cesta',
                      style: TextStyle(fontSize: 20, color: Color(0xff1C5631)),
                    ),
                  ),
                  Expanded(
                    child: _filteredBaskets.isEmpty
                        ? const Center(
                            child: Text('Nenhuma cesta cadastrada'),
                          )
                        : ListView.builder(
                            itemCount: _filteredBaskets.length,
                            itemBuilder: (context, index) {
                              final basket = _filteredBaskets[index];
                              return ListTile(
                                title: Text(basket.name),
                                subtitle: Text(formatCurrency(basket.price)),
                                onTap: () => Navigator.pop(context, basket),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          } else if (snapshot.hasError) {
            return const Center(child: Text('Erro ao carregar cestas'));
          }
          return const Center(child: CircularProgressIndicator());
        },
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
