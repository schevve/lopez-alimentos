import 'package:cesta_flow/core/data/local/model/customer_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final registroAntigo = <String, dynamic>{
    'id': 1,
    'name': 'Cliente existente',
    'date_of_birth': '1990-01-01',
    'phone': '45999990000',
    'address': 'Rua Um',
    'city': 'Cascavel',
    'state': 'PR',
    'document_cpf': '12345678901',
    'email': null,
    'cep': null,
    'document_rg': null,
  };

  test('Lê registro antigo e opcionais NULL sem exigir score', () {
    final cliente = Customer.fromMap(registroAntigo);
    expect(cliente.score, isNull);
    expect(cliente.scoreCategory, CustomerScoreCategory.yellow);
    expect(cliente.authorized, isFalse);
    expect(cliente.manualBlockOverride, isNull);
    expect(cliente.email, isNull);
    expect(cliente.cep, isNull);
    expect(Customer.fromMap(cliente.toMap()).score, isNull);
    expect(cliente.toMap()['id'], 1);
  });

  test('Preserva score NULL, zero e numérico ao serializar', () {
    for (final score in [null, 0, 940]) {
      final cliente = Customer.fromMap({...registroAntigo, 'score': score});
      expect(cliente.toMap()['score'], score);
      expect(cliente.copyWith(name: 'Outro nome').score, score);
      expect(Customer.fromMap(cliente.toMap()).score, score);
    }
  });

  test('Permite atualizar o score e limpar para NULL', () {
    final cliente = Customer.fromMap(registroAntigo).copyWith(score: 940);
    expect(cliente.score, 940);
    expect(cliente.copyWith(score: 0).score, 0);
    expect(cliente.copyWith(clearScore: true).toMap()['score'], isNull);
  });

  test('Serializa classificação e preferências de bloqueio', () {
    final cliente = Customer.fromMap({
      ...registroAntigo,
      'score_category': 'green',
      'authorized': 1,
      'manual_block_override': 0,
    });

    expect(cliente.scoreCategory, CustomerScoreCategory.green);
    expect(cliente.authorized, isTrue);
    expect(cliente.manualBlockOverride, isFalse);

    final atualizado = cliente.copyWith(
      scoreCategory: CustomerScoreCategory.red,
      authorized: false,
      manualBlockOverride: true,
    );
    expect(atualizado.toMap()['score_category'], 'red');
    expect(atualizado.toMap()['authorized'], 0);
    expect(atualizado.toMap()['manual_block_override'], 1);
    expect(
      atualizado.copyWith(clearManualBlockOverride: true).manualBlockOverride,
      isNull,
    );
  });
}
