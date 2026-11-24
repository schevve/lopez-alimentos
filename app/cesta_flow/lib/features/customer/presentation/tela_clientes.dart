import 'package:cesta_flow/core/app_data_refresh.dart';
import 'package:cesta_flow/core/constants/util/launch_phone_call.dart';
import 'package:cesta_flow/features/customer/presentation/customer_details.dart';
import 'package:flutter/material.dart';
import 'package:cesta_flow/core/data/local/model/customer_model.dart';
import 'package:cesta_flow/core/data/local/repository/customer_repository.dart';
import 'package:cesta_flow/core/data/remote/sync_on_user_refresh.dart';

import '../../shared/top_bar.dart';
import 'customer_registration.dart';

import 'package:cesta_flow/features/sale/presentation/sale_registration.dart';

import 'widgets/cliente_card.dart';

class ClientesScreen extends StatefulWidget {
  const ClientesScreen({super.key, this.repository});
  final CustomerRepository? repository;

  @override
  State<ClientesScreen> createState() => _ClientesScreenState();
}

class _ClientesScreenState extends State<ClientesScreen>
    with AppDataRefreshListener {
  static const _verde = Color(0xFF1B4D31);
  static const _menta = Color(0xFFEEFDF4);
  final _buscaController = TextEditingController();
  late final CustomerRepository _repository;
  List<Customer> _todosClientes = [];
  bool _carregando = true;
  Object? _erro;
  int _listaVersao = 0;

  @override
  void initState() {
    super.initState();
    registerAppDataRefreshListener();
    _repository = widget.repository ?? CustomerRepository();
    _recarregar();
  }

  Future<void> _recarregar({bool mostrarCarregamento = true}) async {
    if (mostrarCarregamento && mounted) {
      setState(() {
        _carregando = true;
        _erro = null;
      });
    }

    try {
      final clientes = await _repository.getAllCustomers();
      if (!mounted) return;
      setState(() {
        _todosClientes = clientes;
        _carregando = false;
        _erro = null;
        _listaVersao++;
      });
    } catch (error, stackTrace) {
      if (!mounted) return;
      setState(() {
        _carregando = false;
        _erro = stackTrace;
      });
    }
  }

  Future<void> _novoCliente() async {
    final customer = await Navigator.of(context).push<Customer>(
      MaterialPageRoute(
        builder: (_) => CustomerRegistration(repository: _repository),
      ),
    );
    if (!mounted) return;
    _recarregar();
    if (customer != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text('${customer.name} cadastrado com sucesso.')),
        );
    }
  }

  // Busca local por nome (sem acentos) ou CPF.
  String _normalizar(String texto) {
    var resultado = texto.toLowerCase();
    const grupos = {
      '[áàâãä]': 'a',
      '[éèêë]': 'e',
      '[íìîï]': 'i',
      '[óòôõö]': 'o',
      '[úùûü]': 'u',
      'ç': 'c',
    };
    grupos.forEach(
      (pattern, valor) =>
          resultado = resultado.replaceAll(RegExp(pattern), valor),
    );
    return resultado;
  }

  List<Customer> _clientesFiltrados(List<Customer> clientes) {
    final busca = _normalizar(_buscaController.text.trim());
    final cpf = busca.replaceAll(RegExp(r'[^0-9]'), '');
    return clientes
        .where(
          (cliente) =>
              _normalizar(cliente.name).contains(busca) ||
              (cpf.isNotEmpty &&
                  cliente.documentCPF
                      .replaceAll(RegExp(r'[^0-9]'), '')
                      .contains(cpf)),
        )
        .toList();
  }

  @override
  void dispose() {
    unregisterAppDataRefreshListener();
    _buscaController.dispose();
    super.dispose();
  }

  @override
  void onAppDataChanged() {
    _recarregar(mostrarCarregamento: false);
  }

  Future<void> _acao(Customer cliente, String acao) async {
    if (acao == 'Ver Perfil' && cliente.id != null) {
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => CustomerDetails(customerId: cliente.id!),
        ),
      );
      if (mounted) _recarregar();
      return;
    }

    if (acao == 'Nova Venda') {
      if (cliente.isBlockedForSales) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text('Cliente bloqueado. Não pode realizar compras.'),
            ),
          );
        return;
      }
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => SaleRegistration(initialCustomer: cliente),
        ),
      );
      return;
    }

    if (acao == 'Ligar') {
      final abriu = await launchPhoneCall(cliente.phone);
      if (!mounted) return;
      if (!abriu) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text('Não foi possível abrir o aplicativo de chamadas.'),
            ),
          );
      }
      return;
    }

    debugPrint('$acao: ${cliente.name}');
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _menta,
    appBar: const TopBar(pagTitle: 'Meus Clientes', showDrawer: true),
    floatingActionButton: MediaQuery.viewInsetsOf(context).bottom > 0
        ? null
        : FilledButton(
            onPressed: _novoCliente,
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
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.person_add_alt_1_outlined,
                    color: Colors.white,
                    size: 26,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Novo Cliente',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
    floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    body: RefreshIndicator(
      onRefresh: () => refreshWithRemoteSync(
        () => _recarregar(mostrarCarregamento: false),
        onSyncFailed: (message) {
          if (!mounted) return;
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(message)));
        },
      ),
      child: _buildCorpo(),
    ),
  );

  Widget _buildCorpo() {
    if (_carregando && _todosClientes.isEmpty) {
      return const _PaginaRolavel(
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_erro != null && _todosClientes.isEmpty) {
      return _PaginaRolavel(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Não foi possível carregar os clientes.'),
              TextButton(
                onPressed: _recarregar,
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      );
    }

    final clientes = _clientesFiltrados(_todosClientes);
    return LayoutBuilder(
            builder: (context, constraints) {
              final largura = constraints.maxWidth;
              final compacto = largura < 600;
              final margem = largura < 360
                  ? 12.0
                  : compacto
                  ? 20.0
                  : 32.0;
              final colunas = largura >= 1700
                  ? 4
                  : largura >= 1200
                  ? 3
                  : largura >= 720
                  ? 2
                  : 1;
              final linhas = (clientes.length / colunas).ceil();
              return CustomScrollView(
                key: ValueKey(_listaVersao),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Container(
                      margin: EdgeInsets.fromLTRB(margem, 16, margem, 12),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: _verde,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: TextField(
                        controller: _buscaController,
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
                  ),
                  if (clientes.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(child: Text('Nenhum cliente encontrado.')),
                    )
                  else
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(margem, 20, margem, 112),
                      sliver: SliverList.builder(
                        itemCount: linhas,
                        itemBuilder: (context, linha) => Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          // Cartões têm altura natural, inclusive com fontes ampliadas.
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (
                                var coluna = 0;
                                coluna < colunas;
                                coluna++
                              ) ...[
                                if (coluna > 0) const SizedBox(width: 20),
                                Expanded(
                                  child:
                                      linha * colunas + coluna < clientes.length
                                      ? ClienteCard(
                                          key: ValueKey(
                                            '${clientes[linha * colunas + coluna].uuid}-'
                                            '${clientes[linha * colunas + coluna].name}-'
                                            '${clientes[linha * colunas + coluna].isBlockedForSales}-'
                                            '${clientes[linha * colunas + coluna].score}',
                                          ),
                                          cliente:
                                              clientes[linha * colunas +
                                                  coluna],
                                          onAcao: (acao) => _acao(
                                            clientes[linha * colunas + coluna],
                                            acao,
                                          ),
                                        )
                                      : const SizedBox.shrink(),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          );
  }
}

class _PaginaRolavel extends StatelessWidget {
  const _PaginaRolavel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: constraints.maxHeight,
          width: constraints.maxWidth,
          child: child,
        ),
      ),
    );
  }
}
