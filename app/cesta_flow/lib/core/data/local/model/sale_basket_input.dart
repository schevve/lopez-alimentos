/// Linha de cesta ao registrar uma venda.
class SaleBasketInput {
  const SaleBasketInput.catalog({
    required this.basketUuid,
    required this.quantity,
    this.unitPrice,
  }) : name = null;

  /// Temporário até a tela usar o catálogo; cria uma cesta só para esta venda.
  const SaleBasketInput.unregistered({
    required this.name,
    required this.unitPrice,
    required this.quantity,
  }) : basketUuid = '';

  final String basketUuid;
  final String? name;
  final double? unitPrice;
  final int quantity;

  bool get isCatalog => basketUuid.isNotEmpty;

  double unitPriceFor(double catalogPrice) => unitPrice ?? catalogPrice;

  static void ensureValid(Iterable<SaleBasketInput> lines) {
    final list = lines.toList();
    if (list.isEmpty) {
      throw ArgumentError('A venda precisa incluir ao menos uma cesta.');
    }
    for (final line in list) {
      if (line.quantity <= 0) {
        throw ArgumentError('A quantidade de cada cesta deve ser maior que zero.');
      }
      if (line.isCatalog) {
        if (line.basketUuid.isEmpty) {
          throw ArgumentError('Cesta do catálogo sem identificador.');
        }
        continue;
      }
      final name = line.name?.trim() ?? '';
      if (name.isEmpty) {
        throw ArgumentError('Informe o nome da cesta ou selecione do catálogo.');
      }
      if (line.unitPrice == null || line.unitPrice! < 0) {
        throw ArgumentError('Informe o preço unitário da cesta.');
      }
    }
  }
}
