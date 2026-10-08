import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'clientes_mock.dart';
import 'models/cliente.dart';
import 'widgets/cliente_card.dart';

class ClientesScreen extends StatefulWidget {
  const ClientesScreen({super.key, this.clientes = clientesMockados});
  final List<Cliente> clientes;

  @override
  State<ClientesScreen> createState() => _ClientesScreenState();
}

class _ClientesScreenState extends State<ClientesScreen> {
  static const _verde = Color(0xFF1B4D31);
  static const _menta = Color(0xFFEEFDF4);
  static const _abas = ['Início', 'Clientes', 'Vendas', 'Perfil'];
  final _buscaController = TextEditingController();
  int _indiceSelecionado = 1;
  ClienteScore? _filtro;

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

  List<Cliente> get _clientesFiltrados {
    final busca = _normalizar(_buscaController.text.trim());
    final cpf = busca.replaceAll(RegExp(r'[^0-9]'), '');
    return widget.clientes
        .where(
          (cliente) =>
              (_filtro == null || cliente.score == _filtro) &&
              (_normalizar(cliente.nome).contains(busca) ||
                  (cpf.isNotEmpty &&
                      cliente.cpf
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

  void _acao(Cliente cliente, String acao) =>
      debugPrint('$acao: ${cliente.nome}');

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
              for (final (valor, label) in <(ClienteScore?, String)>[
                (null, 'Todos'),
                (ClienteScore.verde, 'Score Verde'),
                (ClienteScore.amarelo, 'Atenção'),
                (ClienteScore.vermelho, 'Bloqueados'),
              ])
                ListTile(
                  title: Text(label),
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

  Widget _filtros(double margem) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    padding: EdgeInsets.symmetric(horizontal: margem),
    child: Row(
      children: [
        for (final (valor, label, cor) in <(ClienteScore?, String, Color?)>[
          (null, 'Todos', null),
          (ClienteScore.verde, 'Score Verde', const Color(0xFF9FD7AF)),
          (ClienteScore.amarelo, 'Atenção', const Color(0xFFFF7816)),
          (ClienteScore.vermelho, 'Bloqueados', const Color(0xFFBF181D)),
        ])
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
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (cor != null) ...[
                    Icon(Icons.circle, size: 12, color: cor),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    label,
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
                    '(${valor == null ? widget.clientes.length : widget.clientes.where((c) => c.score == valor).length})',
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
  Widget build(BuildContext context) {
    final clientes = _clientesFiltrados;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      // A largura vem da janela, sem limitar a tela a um formato de celular.
      child: LayoutBuilder(
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
          return Scaffold(
            backgroundColor: _menta,
            body: CustomScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              slivers: [
                SliverToBoxAdapter(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: _verde,
                      borderRadius: BorderRadius.vertical(
                        bottom: Radius.circular(34),
                      ),
                    ),
                    child: SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          margem,
                          compacto ? 20 : 32,
                          margem,
                          24,
                        ),
                        child: Row(
                          children: [
                            const CircleAvatar(
                              radius: 20,
                              backgroundColor: Color(0xFF003C22),
                              child: Icon(
                                Icons.groups_outlined,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'Meus Clientes',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 26,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: -.4,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10462A),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                '7ª BASE',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
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
                SliverToBoxAdapter(child: _filtros(margem)),
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
            ),
            floatingActionButton: MediaQuery.viewInsetsOf(context).bottom > 0
                ? null
                : SizedBox(
                    height: compacto ? 56 : 64,
                    child: FloatingActionButton.extended(
                      extendedPadding: const EdgeInsets.symmetric(
                        horizontal: 24,
                      ),
                      onPressed: () =>
                          debugPrint('Navegar para tela de cadastro'),
                      backgroundColor: const Color(0xFFFF7816),
                      foregroundColor: Colors.white,
                      elevation: 6,
                      shape: const StadiumBorder(),
                      icon: const Icon(
                        Icons.person_add_alt_1_outlined,
                        size: 28,
                      ),
                      label: const Text(
                        'Novo Cliente',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
            bottomNavigationBar: BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              currentIndex: _indiceSelecionado,
              onTap: (index) {
                setState(() => _indiceSelecionado = index);
                debugPrint('Aba selecionada: ${_abas[index]}');
              },
              backgroundColor: Colors.white,
              selectedItemColor: _verde,
              unselectedItemColor: const Color(0xFF46524B),
              elevation: 0,
              selectedFontSize: 14,
              unselectedFontSize: 14,
              iconSize: 28,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home_outlined),
                  label: 'Início',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.people_outline),
                  label: 'Clientes',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.shopping_basket_outlined),
                  label: 'Vendas',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.account_circle_outlined),
                  label: 'Perfil',
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
