import 'package:cesta_flow/core/constants/colors/app_colors.dart';
import 'package:cesta_flow/core/constants/util/format_currency.dart';
import 'package:cesta_flow/core/data/local/model/customer_model.dart';
import 'package:cesta_flow/core/data/local/model/sale_model.dart';
import 'package:cesta_flow/core/data/local/repository/customer_repository.dart';
import 'package:cesta_flow/core/data/local/repository/sale_repository.dart';
import 'package:cesta_flow/features/dashboard/presentation/widgets/metric_card.dart';
import 'package:cesta_flow/features/dashboard/presentation/widgets/metrics_row.dart';
import 'package:cesta_flow/features/dashboard/presentation/widgets/sale_card.dart';
import 'package:cesta_flow/features/sale/presentation/sale_registration.dart';
import 'package:cesta_flow/features/shared/top_bar.dart';
import 'package:flutter/material.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  static const int _latestSalesLimit = 5;

  final SaleRepository _saleRepository = SaleRepository();
  final CustomerRepository _customerRepository = CustomerRepository();

  bool _isLoading = true;
  String? _errorMessage;
  List<Sale> _latestSales = const [];
  Map<int, Customer> _customersById = const {};
  double _salesAmountLast7Days = 0;
  int _customersCount = 0;
  int _pendingCustomersCount = 0;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData({bool showLoadingIndicator = false}) async {
    if (showLoadingIndicator) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final latestSales = await _saleRepository.getLatestSales(
        limit: _latestSalesLimit,
      );
      final salesAmount = await _saleRepository.getTotalSalesAmountSince(
        DateTime.now().subtract(const Duration(days: 7)),
      );
      final pendingCustomers = await _saleRepository.getPendingCustomersCount();
      final customers = await _customerRepository.getAllCustomers();

      if (!mounted) {
        return;
      }

      setState(() {
        _latestSales = latestSales;
        _salesAmountLast7Days = salesAmount;
        _pendingCustomersCount = pendingCustomers;
        _customersCount = customers.length;
        _customersById = {
          for (final customer in customers)
            if (customer.id != null) customer.id!: customer,
        };
        _isLoading = false;
      });
    } catch (error) {
      debugPrint('Erro ao carregar dados da dashboard: $error');
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
        _errorMessage = 'Não foi possível carregar as vendas.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0FDF4),
      appBar: const TopBar(pagTitle: 'Início', showDrawer: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 14),
            MetricsRow(
              cards: [
                MetricCard(
                  title: 'Vendas',
                  value: _metricValue(formatCurrency(_salesAmountLast7Days)),
                  subtitle: 'Últimos 7 dias',
                  icon: Icons.shopping_cart,
                  iconColor: AppColors.primary,
                ),
                MetricCard(
                  title: 'Clientes',
                  value: _metricValue(_customersCount.toString()),
                  subtitle: 'Cadastrados',
                  icon: Icons.people,
                  iconColor: AppColors.primary,
                ),
                MetricCard(
                  title: 'Pendências',
                  value: _metricValue(_pendingCustomersCount.toString()),
                  subtitle: 'Sem pagamento',
                  icon: Icons.warning,
                  iconColor: const Color(0xFFC62828),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              'Últimas vendas',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.black,
              ),
            ),
            const SizedBox(height: 14),
            ..._buildSalesSection(),
            const SizedBox(height: 100), // space for FAB
          ],
        ),
      ),
      // Floating Action Button
      floatingActionButton: FilledButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SaleRegistration()),
          );
          if (!mounted) {
            return;
          }
          await _loadDashboardData(showLoadingIndicator: true);
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

  String _metricValue(String value) {
    if (_isLoading || _errorMessage != null) {
      return '—';
    }
    return value;
  }

  List<Widget> _buildSalesSection() {
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

    if (_latestSales.isEmpty) {
      return const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 32),
          child: Text(
            'Nenhuma venda registrada ainda.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Color(0xFF707070)),
          ),
        ),
      ];
    }

    return [
      for (var index = 0; index < _latestSales.length; index++) ...[
        if (index > 0) const SizedBox(height: 14),
        _buildSaleCard(_latestSales[index]),
      ],
    ];
  }

  Widget _buildSaleCard(Sale sale) {
    final customer = _customersById[sale.customerId];
    final address = customer == null
        ? 'Endereço não informado'
        : '${customer.address} (${customer.city})';

    return SaleCard(
      saleId: sale.id,
      name: customer?.name ?? 'Cliente #${sale.customerId}',
      status: 'Registrada em ${_formatDate(sale.date)}',
      address: address,
      product: sale.quantity > 1
          ? '${sale.quantity}x ${sale.productName}'
          : sale.productName,
      amount: formatCurrency(sale.price * sale.quantity),
    );
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }
}
