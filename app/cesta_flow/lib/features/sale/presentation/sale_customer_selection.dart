import 'package:cesta_flow/core/constants/colors/app_colors.dart';
import 'package:cesta_flow/core/data/local/model/customer_model.dart';
import 'package:cesta_flow/core/data/local/repository/customer_repository.dart';
import 'package:cesta_flow/features/customer/presentation/customer_registration.dart';
import 'package:cesta_flow/features/shared/top_bar.dart';
import 'package:flutter/material.dart';

class CustomerSelection extends StatefulWidget {
  const CustomerSelection({super.key, this.repository});

  final CustomerRepository? repository;

  @override
  State<CustomerSelection> createState() => _CustomerSelectionState();
}

class _CustomerSelectionState extends State<CustomerSelection> {
  late final CustomerRepository _customerRepository;
  final SearchController _searchController = SearchController();
  Future<List<Customer>> _customers = Future.value([]);
  List<Customer> _allCustomers = [];
  List<Customer> _filteredCustomers = [];

  @override
  void initState() {
    super.initState();
    _customerRepository = widget.repository ?? CustomerRepository();
    _customers = _customerRepository.getAllCustomers();
    _customers.then((customers) {
      if (!mounted) return;
      setState(() {
        _allCustomers = customers;
        _filteredCustomers = customers;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const TopBar(pagTitle: 'Selecionar cliente'),
      body: FutureBuilder<List<Customer>>(
        future: _customers,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return _buildCustomerList(snapshot.data!);
          } else if (snapshot.hasError) {
            return _statusView(
              icon: Icons.cloud_off_outlined,
              title: 'Não foi possível carregar os clientes',
              message: 'Verifique e tente novamente mais tarde.',
            );
          } else {
            return _statusView(
              loading: true,
              title: 'Carregando clientes',
              message: 'Só um instante.',
            );
          }
        },
      ),
    );
  }

  Widget _buildCustomerList(List<Customer> customers) {
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
                  'Quem é o cliente?',
                  style: TextStyle(
                    color: Color(0xFF18251F),
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Busque pelo nome ou CPF para selecionar na venda.',
                  style: TextStyle(
                    color: Color(0xFF59665E),
                    fontSize: 15,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 20),
                SearchBar(
                  controller: _searchController,
                  hintText: 'Nome ou CPF do cliente',
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
                      _filteredCustomers = filterCustomers(
                        _allCustomers,
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
                    onPressed: _openCustomerRegistration,
                    icon: const Icon(Icons.person_add_alt_1_rounded),
                    label: const Text('Cadastrar novo cliente'),
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
                        'Clientes',
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
                        '${_filteredCustomers.length}',
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
        if (_filteredCustomers.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: _emptyResults(hasCustomers: customers.isNotEmpty),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final customer = _filteredCustomers[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _CustomerSelectionCard(
                    customer: customer,
                    onTap: () => Navigator.pop(context, customer),
                  ),
                );
              }, childCount: _filteredCustomers.length),
            ),
          ),
      ],
    );
  }

  Future<void> _openCustomerRegistration() async {
    final value = await Navigator.push<Customer>(
      context,
      MaterialPageRoute(
        builder: (context) =>
            CustomerRegistration(repository: _customerRepository),
      ),
    );
    if (!mounted || value is! Customer) return;

    try {
      final customers = await _customerRepository.getAllCustomers();
      if (!mounted) return;
      setState(() {
        _allCustomers = customers;
        _customers = Future.value(customers);
        _filteredCustomers = filterCustomers(customers, _searchController.text);
      });
    } catch (error, stackTrace) {
      debugPrint(
        'Erro ao atualizar clientes após cadastro: $error\n$stackTrace',
      );
      if (!mounted) return;
      final updatedCustomers = [
        ..._allCustomers.where((customer) => customer.id != value.id),
        value,
      ];
      setState(() {
        _allCustomers = updatedCustomers;
        _customers = Future.value(updatedCustomers);
        _filteredCustomers = filterCustomers(
          updatedCustomers,
          _searchController.text,
        );
      });
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Cliente cadastrado, mas não foi possível atualizar a lista.',
            ),
          ),
        );
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('${value.name} cadastrado com sucesso.')),
      );
  }

  Widget _emptyResults({required bool hasCustomers}) {
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
                hasCustomers
                    ? Icons.person_search_rounded
                    : Icons.people_outline_rounded,
                color: AppColors.primary,
                size: 30,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              hasCustomers
                  ? 'Nenhum cliente encontrado'
                  : 'Ainda não há clientes',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF18251F),
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              hasCustomers
                  ? 'Tente buscar por outro nome ou CPF.'
                  : 'Cadastre um cliente para vinculá-lo à venda.',
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

class _CustomerSelectionCard extends StatelessWidget {
  const _CustomerSelectionCard({required this.customer, required this.onTap});

  final Customer customer;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final initials = customer.name
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
                        Icons.person_outline_rounded,
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
                      customer.name,
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
                      'CPF: ${customer.documentCPF}',
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

List<Customer> filterCustomers(List<Customer> customers, String query) {
  if (query.isEmpty) {
    return customers;
  } else {
    final cleanQueryCPF = query.replaceAll(RegExp(r'[^0-9]'), '');
    return customers
        .where(
          (customer) =>
              customer.name.toLowerCase().contains(query.toLowerCase()) ||
              (cleanQueryCPF.isNotEmpty &&
                  customer.documentCPF
                      .replaceAll(RegExp(r'[^0-9]'), '')
                      .contains(cleanQueryCPF)),
        )
        .toList();
  }
}
