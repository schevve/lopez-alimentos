import 'package:cesta_flow/core/constants/colors/app_colors.dart';
import 'package:cesta_flow/core/constants/util/format_cpf.dart';
import 'package:cesta_flow/core/constants/util/format_currency.dart';
import 'package:cesta_flow/core/data/local/model/customer_model.dart';
import 'package:cesta_flow/core/data/local/model/sale_model.dart';
import 'package:cesta_flow/core/data/local/repository/customer_repository.dart';
import 'package:cesta_flow/core/data/local/repository/sale_repository.dart';
import 'package:cesta_flow/features/dashboard/presentation/widgets/sale_card.dart';
import 'package:cesta_flow/features/sale/presentation/sale_registration.dart';
import 'package:cesta_flow/features/shared/top_bar.dart';
import 'package:flutter/material.dart';

class SalesList extends StatefulWidget {
  const SalesList({super.key});

  @override
  State<SalesList> createState() => _SalesListState();
}

class _SalesListState extends State<SalesList> {
  static const _verde = Color(0xFF1B4D31);

  final SaleRepository _saleRepository = SaleRepository();
  final CustomerRepository _customerRepository = CustomerRepository();
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  String? _errorMessage;
  List<Sale> _sales = const [];
  Map<int, Customer> _customersById = const {};

  @override
  void initState() {
    super.initState();
    _loadSalesList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSalesList({bool showLoadingIndicator = false}) async {
    if (showLoadingIndicator) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final sales = await _saleRepository.getAllSales();
      final customers = await _customerRepository.getAllCustomers();

      if (!mounted) {
        return;
      }

      sales.sort((a, b) => b.date.compareTo(a.date));

      setState(() {
        _sales = sales;
        _customersById = {
          for (final customer in customers)
            if (customer.id != null) customer.id!: customer,
        };
        _isLoading = false;
      });
    } catch (error) {
      debugPrint('Erro ao carregar lista de vendas: $error');
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
        _errorMessage = 'Não foi possível carregar as vendas.';
      });
    }
  }

  // Busca local por nome (sem acentos) ou CPF, igual à tela de clientes.
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

  List<Sale> get _filteredSales {
    final query = _normalize(_searchController.text.trim());
    if (query.isEmpty) {
      return _sales;
    }

    final cpfQuery = query.replaceAll(RegExp(r'[^0-9]'), '');

    return _sales.where((sale) {
      final customer = _customersById[sale.customerId];
      if (customer == null) {
        return false;
      }

      final matchesName = _normalize(customer.name).contains(query);
      final matchesCpf =
          cpfQuery.isNotEmpty &&
          customer.documentCPF
              .replaceAll(RegExp(r'[^0-9]'), '')
              .contains(cpfQuery);

      return matchesName || matchesCpf;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredSales = _filteredSales;

    return Scaffold(
      backgroundColor: const Color(0xFFF0FDF4),
      appBar: const TopBar(pagTitle: 'Vendas', showDrawer: true),
      body: RefreshIndicator(
        onRefresh: _loadSalesList,
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 14),
              Text(
                'Lista de vendas',
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
                    hintText: 'Buscar por nome, CPF...',
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
              ..._buildSalesSection(filteredSales),
              const SizedBox(height: 100), // space for FAB
            ],
          ),
        ),
      ),
      floatingActionButton: FilledButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SaleRegistration()),
          );
          if (!mounted) {
            return;
          }
          await _loadSalesList(showLoadingIndicator: true);
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
              Icon(Icons.add_rounded, color: Colors.white, size: 30),
              SizedBox(width: 8),
              Text(
                'Registrar Venda',
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

  List<Widget> _buildSalesSection(List<Sale> sales) {
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

    if (sales.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: Text(
            _searchController.text.trim().isEmpty
                ? 'Nenhuma venda registrada ainda.'
                : 'Nenhuma venda encontrada para a busca.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: Color(0xFF707070)),
          ),
        ),
      ];
    }

    return [
      for (var index = 0; index < sales.length; index++) ...[
        if (index > 0) const SizedBox(height: 14),
        _buildSaleCard(sales[index]),
      ],
    ];
  }

  Widget _buildSaleCard(Sale sale) {
    final customer = _customersById[sale.customerId];
    final address = customer == null
        ? 'Endereço não informado'
        : '${customer.address} (${customer.city})';
    final status = customer == null
        ? 'Registrada em ${_formatDate(sale.date)}'
        : 'CPF ${formatCpf(customer.documentCPF)} • '
              'Registrada em ${_formatDate(sale.date)}';

    return SaleCard(
      saleId: sale.id,
      name: customer?.name ?? 'Cliente #${sale.customerId}',
      status: status,
      statusColor: AppColors.greenText,
      address: address,
      product: sale.quantity > 1
          ? '${sale.quantity}x ${sale.productName}'
          : sale.productName,
      productColor: AppColors.greenText,
      amount: formatCurrency(sale.price * sale.quantity),
      amountColor: AppColors.primary,
    );
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }
}
