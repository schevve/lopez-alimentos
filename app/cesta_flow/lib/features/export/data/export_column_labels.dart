/// Rótulos das colunas na exportação Excel (cabeçalhos em português).
abstract final class ExportColumnLabels {
  static const _common = <String, String>{
    'id': 'ID',
    'uuid': 'UUID',
    'user_id': 'ID do usuário',
    'created_at': 'Criado em',
    'updated_at': 'Atualizado em',
    'is_deleted': 'Excluído',
    'is_synced': 'Sincronizado',
    'name': 'Nome',
    'price': 'Preço',
    'sale_id': 'ID da venda',
    'sale_uuid': 'UUID da venda',
    'basket_id': 'ID da cesta',
    'basket_uuid': 'UUID da cesta',
    'customer_id': 'ID do cliente',
    'customer_uuid': 'UUID do cliente',
    'quantity': 'Quantidade',
  };

  static const _clientes = <String, String>{
    'date_of_birth': 'Data de nascimento',
    'email': 'E-mail',
    'phone': 'Telefone',
    'address': 'Endereço',
    'address_number': 'Número',
    'city': 'Cidade',
    'state': 'Estado',
    'cep': 'CEP',
    'cpf': 'CPF',
    'rg': 'RG',
    'score': 'Pontuação',
    'is_blocked': 'Bloqueado',
  };

  static const _vendas = <String, String>{
    'amount_paid': 'Valor pago',
    'installments': 'Número de parcelas',
  };

  static const _parcelas = <String, String>{
    'expected_amount': 'Valor previsto',
    'paid_amount': 'Valor pago',
    'due_date': 'Vencimento',
    'payment_date': 'Data de pagamento',
    'indicated_payment_date': 'Data de pagamento indicado',
    'payment_method': 'Forma de pagamento',
  };

  static String label(String sheetName, String fieldKey) {
    final sheetMap = switch (sheetName) {
      'clientes' => _clientes,
      'vendas' => _vendas,
      'parcelas' => _parcelas,
      _ => const <String, String>{},
    };
    return sheetMap[fieldKey] ??
        _common[fieldKey] ??
        _titleFromSnakeCase(fieldKey);
  }

  static String _titleFromSnakeCase(String key) {
    final words = key.split('_').where((part) => part.isNotEmpty);
    return words
      .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
      .join(' ');
  }
}