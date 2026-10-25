import 'package:flutter/material.dart';
import 'package:cesta_flow/core/data/local/model/customer_model.dart';
import 'package:cesta_flow/core/data/local/repository/customer_repository.dart';

import '../../shared/top_bar.dart';
import '../../shared/bottom_bar.dart';
import 'customer_registration.dart';

import 'widgets/cliente_card.dart';

class ClientesScreen extends StatefulWidget {
  const ClientesScreen({super.key, this.repository});
  final CustomerRepository? repository;

  @override
  State<ClientesScreen> createState() => _ClientesScreenState();
}

enum _FiltroScore {
  todos('Todos'),
  comScore('Com score'),
  semScore('Sem score');

  const _FiltroScore(this.label);
  final String label;

  bool inclui(Customer cliente) => switch (this) {
    _FiltroScore.todos => true,
    _FiltroScore.comScore => cliente.score != null,
    _FiltroScore.semScore => cliente.score == null,
  };
}

class _ClientesScreenState extends State<ClientesScreen> {
  static const _verde = Color(0xFF1B4D31);
  static const _menta = Color(0xFFEEFDF4);
  final _buscaController = TextEditingController();
  _FiltroScore _filtro = _FiltroScore.todos;
  late final CustomerRepository _repository;
  late Future<List<Customer>> _clientes;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? CustomerRepository();
    _clientes = _repository.getAllCustomers();
  }

  void _recarregar() {
    setState(() {
      _clientes = _repository.getAllCustomers();
    });
  }

  Future<void> _novoCliente() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => const CustomerRegistration()),
    );
    if (mounted) _recarregar();
  }

  // Busca local por nome (sem acentos) ou CPF, combinada com o filtro de score.
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
              _filtro.inclui(cliente) &&
              (_normalizar(cliente.name).contains(busca) ||
                  (cpf.isNotEmpty &&
                      cliente.documentCPF
                          .replaceAll(RegExp(r'[^0-9]'), '')
                          .contains(cpf))),
        )
        .toList();
  }

  @override
  void dispose() {
    _buscaController.dispose();
    super.dispose();
  }

  void _acao(Customer cliente, String acao) =>
      debugPrint('$acao: ${cliente.name}');

  Future<void> _abrirFiltros() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Filtrar clientes',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              for (final valor in _FiltroScore.values)
                ListTile(
                  title: Text(valor.label),
                  trailing: _filtro == valor
                      ? const Icon(Icons.check, color: _verde)
                      : null,
                  onTap: () {
                    setState(() => _filtro = valor);
                    Navigator.pop(sheetContext);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _filtros(double margem, List<Customer> clientes) =>
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: margem),
        child: Row(
          children: [
            for (final valor in _FiltroScore.values)
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: ChoiceChip(
                  selected: _filtro == valor,
                  onSelected: (_) => setState(() => _filtro = valor),
                  showCheckmark: false,
                  selectedColor: _verde,
                  backgroundColor: Colors.white,
                  side: BorderSide.none,
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 10,
                  ),
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        valor.label,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: _filtro == valor
                              ? Colors.white
                              : const Color(0xFF18251F),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '(${clientes.where(valor.inclui).length})',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _filtro == valor ? Colors.white : _verde,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _menta,
    appBar: const TopBar(pagTitle: 'Meus Clientes'),
    bottomNavigationBar: const BottomBar(),
    floatingActionButton: MediaQuery.viewInsetsOf(context).bottom > 0
        ? null
        : FloatingActionButton.extended(
            onPressed: _novoCliente,
            backgroundColor: const Color(0xFFFF7816),
            foregroundColor: Colors.white,
            shape: const StadiumBorder(),
            icon: const Icon(Icons.person_add_alt_1_outlined),
            label: const Text('Novo Cliente'),
          ),
    body: FutureBuilder<List<Customer>>(
      future: _clientes,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
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
          );
        }
        final todos = snapshot.data ?? [];
        final clientes = _clientesFiltrados(todos);
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
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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
                        suffixIcon: IconButton(
                          tooltip: 'Filtrar clientes',
                          onPressed: _abrirFiltros,
                          icon: const Icon(
                            Icons.tune,
                            color: Color(0xFF46524B),
                          ),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(child: _filtros(margem, todos)),
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
                                        cliente:
                                            clientes[linha * colunas + coluna],
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
      },
    ),
  );
}
