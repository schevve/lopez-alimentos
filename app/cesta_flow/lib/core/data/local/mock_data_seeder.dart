import 'package:cesta_flow/core/data/local/db_helper.dart';

class MockDataSeeder {
  MockDataSeeder({DatabaseHelper? dbHelper})
    : _dbHelper = dbHelper ?? DatabaseHelper();

  final DatabaseHelper _dbHelper;

  Future<void> seed() async {
    final db = await _dbHelper.database;
    final sales = await db.query('sales', limit: 1);
    if (sales.isNotEmpty) return;

    await db.transaction((transaction) async {
      final firstCustomerId = await transaction.insert('customers', {
        'name': 'Maria de Souza',
        'date_of_birth': '1985-04-12',
        'email': 'maria.souza@example.com',
        'phone': '(11) 99999-1001',
        'address': 'Rua das Flores, 100',
        'city': 'Sao Paulo',
        'state': 'SP',
        'cep': '01001-000',
        'document_cpf': '11111111111',
        'document_rg': '11.111.111-1',
      });
      final secondCustomerId = await transaction.insert('customers', {
        'name': 'Joao Oliveira',
        'date_of_birth': '1978-09-23',
        'email': 'joao.oliveira@example.com',
        'phone': '(21) 98888-2002',
        'address': 'Avenida Central, 250',
        'city': 'Rio de Janeiro',
        'state': 'RJ',
        'cep': '20040-000',
        'document_cpf': '22222222222',
        'document_rg': '22.222.222-2',
      });

      final firstSaleId = await transaction.insert('sales', {
        'customer_id': firstCustomerId,
        'product_name': 'Cesta Basica Completa',
        'price': 120.50,
        'quantity': 2,
        'date': '2026-09-20T10:00:00.000',
        'description': 'Venda parcelada em seis pagamentos',
      });
      final secondSaleId = await transaction.insert('sales', {
        'customer_id': secondCustomerId,
        'product_name': 'Cesta Basica Economica',
        'price': 85.00,
        'quantity': 1,
        'date': '2026-09-21T14:30:00.000',
        'description': 'Venda com pagamento unico',
      });

      for (var index = 0; index < 6; index++) {
        await transaction.insert('payments', {
          'sale_id': firstSaleId,
          'method': index.isEven ? 'pix' : 'cartao',
          'amount': 40.17,
          'date': '2026-09-${20 + index}T10:00:00.000',
        });
      }
      await transaction.insert('payments', {
        'sale_id': secondSaleId,
        'method': 'dinheiro',
        'amount': 85.00,
        'date': '2026-09-21T14:30:00.000',
      });
    });
  }
}
