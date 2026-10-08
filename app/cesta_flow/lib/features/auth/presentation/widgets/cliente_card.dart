import 'package:flutter/material.dart';

import '../models/cliente.dart';

// O card recebe callbacks: nenhuma ação simula acesso ao banco ou pagamento.
class ClienteCard extends StatelessWidget {
  const ClienteCard({super.key, required this.cliente, required this.onAcao});
  final Cliente cliente;
  final ValueChanged<String> onAcao;

  @override
  Widget build(BuildContext context) {
    final ativo = cliente.score == ClienteScore.verde;
    final bloqueado = cliente.score == ClienteScore.vermelho;
    final cor = ativo
        ? const Color(0xFF1D5335)
        : bloqueado
        ? const Color(0xFFBC171B)
        : const Color(0xFFAB4700);
    final fundo = ativo
        ? const Color(0xFFE8F6EE)
        : bloqueado
        ? const Color(0xFFFFDAD7)
        : const Color(0xFFFFEEE5);
    final status = ativo
        ? 'Ativo para Venda'
        : bloqueado
        ? 'Bloqueado p/ Crédito'
        : 'Atrasado há ${cliente.diasAtraso} dias';
    final score = ativo
        ? 'Verde'
        : bloqueado
        ? 'Vermelho'
        : 'Regular';
    final primaria = ativo
        ? 'Ver Perfil'
        : bloqueado
        ? 'Contatar'
        : 'Histórico';
    final secundaria = ativo ? 'Nova Venda' : 'Cobrar / Receber';

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF194D30).withValues(alpha: .025),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          if (bloqueado)
            const Positioned(
              top: 0,
              bottom: 0,
              left: 0,
              width: 7,
              child: ColoredBox(color: Color(0xFFBF181D)),
            ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nome e score quebram em linhas quando falta espaço.
                LayoutBuilder(
                  builder: (context, constraints) {
                    final nome = Text(
                      cliente.nome,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -.45,
                        color: Color(0xFF18251F),
                      ),
                    );
                    final badge = Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: fundo,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            ativo
                                ? Icons.verified
                                : bloqueado
                                ? Icons.cancel_outlined
                                : Icons.warning_rounded,
                            size: 18,
                            color: ativo ? const Color(0xFF18251F) : cor,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              '$score (${cliente.pontuacao})',
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.1,
                                fontWeight: FontWeight.w700,
                                color: ativo ? const Color(0xFF18251F) : cor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                    if (constraints.maxWidth < 380 ||
                        MediaQuery.textScalerOf(context).scale(14) > 18) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [nome, const SizedBox(height: 8), badge],
                      );
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: nome),
                        const SizedBox(width: 12),
                        badge,
                      ],
                    );
                  },
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: fundo,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        bloqueado ? Icons.lock_outline : Icons.circle,
                        size: bloqueado ? 13 : 7,
                        color: ativo ? const Color(0xFF9ED6AD) : cor,
                      ),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          status,
                          style: TextStyle(
                            color: cor,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            height: 1.1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 18,
                      color: Color(0xFF46524B),
                    ),
                    const SizedBox(width: 2),
                    Expanded(
                      child: Text(
                        cliente.endereco,
                        style: const TextStyle(
                          fontSize: 15,
                          height: 1.3,
                          color: Color(0xFF46524B),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Faixa de última compra e pendência, com ação de ligação nos ativos.
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  constraints: const BoxConstraints(minHeight: 44),
                  decoration: BoxDecoration(
                    color: ativo
                        ? const Color(0xFFEEF7F1)
                        : bloqueado
                        ? const Color(0xFFFFF1EF)
                        : const Color(0xFFFFF8F4),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final compra = Row(
                        children: [
                          Icon(
                            ativo
                                ? Icons.shopping_bag_outlined
                                : bloqueado
                                ? Icons.event_busy_outlined
                                : Icons.receipt_long_outlined,
                            size: 21,
                            color: cor,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Última compra: ${cliente.ultimaCompra}${ativo ? ' • ${cliente.produto}' : ''}',
                              style: TextStyle(
                                fontSize: 14,
                                color: ativo || bloqueado
                                    ? const Color(0xFF18251F)
                                    : cor,
                              ),
                            ),
                          ),
                        ],
                      );
                      final detalhe = ativo
                          ? TextButton.icon(
                              onPressed: () => onAcao('Ligar'),
                              icon: const Icon(Icons.phone_outlined, size: 17),
                              label: const Text('Ligar'),
                              style: TextButton.styleFrom(
                                foregroundColor: cor,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                minimumSize: const Size(0, 36),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            )
                          : Text(
                              cliente.pendencia,
                              style: TextStyle(
                                color: cor,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            );
                      if (constraints.maxWidth < 380 ||
                          MediaQuery.textScalerOf(context).scale(14) > 18) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            compra,
                            const SizedBox(height: 6),
                            Padding(
                              padding: const EdgeInsets.only(left: 29),
                              child: detalhe,
                            ),
                          ],
                        );
                      }
                      return Row(
                        children: [
                          Expanded(child: compra),
                          const SizedBox(width: 8),
                          detalhe,
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final empilhar =
                        constraints.maxWidth < 330 ||
                        MediaQuery.textScalerOf(context).scale(16) > 21;
                    final largura = empilhar
                        ? constraints.maxWidth
                        : (constraints.maxWidth - 10) / 2;
                    return Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        SizedBox(
                          width: largura,
                          child: _AcaoButton(
                            label: primaria,
                            icon: ativo
                                ? Icons.badge_outlined
                                : bloqueado
                                ? Icons.contact_phone_outlined
                                : Icons.history,
                            background: const Color(0xFFE3F2E9),
                            foreground: const Color(0xFF46524B),
                            onTap: () => onAcao(primaria),
                          ),
                        ),
                        SizedBox(
                          width: largura,
                          child: _AcaoButton(
                            label: secundaria,
                            icon: ativo
                                ? Icons.add_shopping_cart
                                : Icons.payments_outlined,
                            background: ativo
                                ? const Color(0xFFFF7816)
                                : bloqueado
                                ? const Color(0xFFBF181D)
                                : const Color(0xFF003BBE),
                            foreground: Colors.white,
                            onTap: () => onAcao(secundaria),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AcaoButton extends StatelessWidget {
  const _AcaoButton({
    required this.label,
    required this.icon,
    required this.background,
    required this.foreground,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final Color background;
  final Color foreground;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => FilledButton(
    onPressed: onTap,
    style: FilledButton.styleFrom(
      backgroundColor: background,
      foregroundColor: foreground,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
      minimumSize: const Size(0, 54),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 21),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );
}
