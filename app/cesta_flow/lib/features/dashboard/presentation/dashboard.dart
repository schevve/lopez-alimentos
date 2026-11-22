import 'package:cesta_flow/core/app_data_refresh.dart';
import 'package:cesta_flow/core/constants/colors/app_colors.dart';
import 'package:cesta_flow/core/constants/util/format_currency.dart';
import 'package:cesta_flow/core/data/remote/sync_on_user_refresh.dart';
import 'package:cesta_flow/core/data/local/model/customer_model.dart';
import 'package:cesta_flow/core/data/local/model/sale_model.dart';
import 'package:cesta_flow/core/data/local/model/installment_model.dart';
import 'package:cesta_flow/core/data/local/repository/customer_repository.dart';
import 'package:cesta_flow/core/data/local/repository/installment_repository.dart';
import 'package:cesta_flow/core/data/local/repository/sale_repository.dart';
import 'package:cesta_flow/features/dashboard/presentation/widgets/dashboard_lists_carousel.dart';
import 'package:cesta_flow/features/dashboard/presentation/widgets/metric_card.dart';
import 'package:cesta_flow/features/dashboard/presentation/widgets/metrics_row.dart';
import 'package:cesta_flow/features/sale/presentation/sale_registration.dart';
import 'package:cesta_flow/features/shared/top_bar.dart';
import 'package:flutter/material.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> with AppDataRefreshListener {
  static const int _latestSalesLimit = 5;

  final SaleRepository _saleRepository = SaleRepository();
  final CustomerRepository _customerRepository = CustomerRepository();
  final InstallmentRepository _installmentRepository = InstallmentRepository();

  bool _isLoading = true;
  String? _errorMessage;
  List<Sale> _latestSales = const [];
  List<Installment> _paymentInstallments = const [];
  Map<int, Customer> _customersById = const {};
  Map<int, int> _saleCustomerIds = const {};
  Map<int, String> _basketLabels = const {};
  double _salesAmountLast7Days = 0;
  double _estimatedReceiptsToday = 0;
  int _overduePaymentsCount = 0;

  @override
  void initState() {
    super.initState();
    registerAppDataRefreshListener();
    _loadDashboardData();
  }

  @override
  void dispose() {
    unregisterAppDataRefreshListener();
    super.dispose();
  }

  @override
  void onAppDataChanged() {
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
      final paymentInstallments = await _installmentRepository
          .getInstallmentsForDashboard();
      final salesAmount = await _saleRepository.getTotalSalesAmountSince(
        DateTime.now().subtract(const Duration(days: 7)),
      );
      final paymentMetrics = await _installmentRepository
          .getPaymentMetricsForDashboard();
      final customers = await _customerRepository.getAllCustomers();
      final basketLabels = await _saleRepository.basketLabelsFor(
        latestSales.map((sale) => sale.id).whereType<int>().toList(),
      );
      final saleCustomerIds = <int, int>{};
      for (final installment in paymentInstallments) {
        final saleId = installment.saleId;
        if (saleCustomerIds.containsKey(saleId)) continue;
        final sale = await _saleRepository.getSaleById(saleId);
        if (sale != null) {
          saleCustomerIds[saleId] = sale.customerId;
        }
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _latestSales = latestSales;
        _paymentInstallments = paymentInstallments;
        _saleCustomerIds = saleCustomerIds;
        _basketLabels = basketLabels;
        _salesAmountLast7Days = salesAmount;
        _estimatedReceiptsToday = paymentMetrics.estimatedReceiptsToday;
        _overduePaymentsCount = paymentMetrics.overdueCount;
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
        _errorMessage = 'Não foi possível carregar os dados.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0FDF4),
      appBar: const TopBar(pagTitle: 'Início', showDrawer: true),
      body: RefreshIndicator(
        onRefresh: () => refreshWithRemoteSync(
          () => _loadDashboardData(),
          onSyncFailed: (message) {
            if (!mounted) return;
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(message)));
          },
        ),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
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
                    title: 'Pagamentos',
                    value: _metricValue(
                      formatCurrency(_estimatedReceiptsToday),
                    ),
                    subtitle: 'Estimados para o dia',
                    icon: Icons.payments_outlined,
                    iconColor: AppColors.primary,
                  ),
                  MetricCard(
                    title: 'Pendências',
                    value: _metricValue(_overduePaymentsCount.toString()),
                    subtitle: 'Pagamentos atrasados',
                    icon: Icons.warning,
                    iconColor: AppColors.primary,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              DashboardListsCarousel(
                isLoading: _isLoading,
                errorMessage: _errorMessage,
                paymentInstallments: _paymentInstallments,
                latestSales: _latestSales,
                customersById: _customersById,
                saleCustomerIds: _saleCustomerIds,
                basketLabels: _basketLabels,
                onAfterReceive: () => _loadDashboardData(),
              ),
              const SizedBox(height: 100), // space for FAB
            ],
          ),
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
              Icon(Icons.add_shopping_cart, color: Colors.white, size: 26),
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
}
