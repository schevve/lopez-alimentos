// Dados de apresentação; a integração com Supabase será feita posteriormente.
enum ClienteScore { verde, amarelo, vermelho }

class Cliente {
  const Cliente({
    required this.nome,
    required this.telefone,
    required this.endereco,
    required this.score,
    this.cpf = '',
    this.pontuacao = 0,
    this.ultimaCompra = '',
    this.produto = '',
    this.pendencia = '',
    this.diasAtraso = 0,
  });

  final String nome;
  final String telefone;
  final String endereco;
  final ClienteScore score;
  final String cpf;
  final int pontuacao;
  final String ultimaCompra;
  final String produto;
  final String pendencia;
  final int diasAtraso;
}
