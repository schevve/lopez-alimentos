import 'models/cliente.dart';

// Exemplos locais do protótipo, sem consultas ou gravações em banco.
const List<Cliente> clientesMockados = [
  Cliente(
    nome: 'Rosângela Batista',
    telefone: '(45) 9 9136-6948',
    endereco: 'São Paulo • Cerqueira César (Docas 02 e 03)',
    cpf: '123.456.789-01',
    score: ClienteScore.verde,
    pontuacao: 940,
    ultimaCompra: '12/Out',
    produto: 'Cesta Especial',
  ),
  Cliente(
    nome: 'Ângelo Pereira de Souza',
    telefone: '(45) 9 9145-7098',
    endereco: 'São Paulo • Centro Histórico',
    cpf: '234.567.890-12',
    score: ClienteScore.amarelo,
    pontuacao: 680,
    ultimaCompra: '28/Set',
    pendencia: 'R\$ 184,00 pendente',
    diasAtraso: 3,
  ),
  Cliente(
    nome: 'José Aparecido dos Santos',
    telefone: '(45) 9 9965-7891',
    endereco: 'São Paulo • Jd. América',
    cpf: '345.678.901-23',
    score: ClienteScore.vermelho,
    pontuacao: 310,
    ultimaCompra: '15/Ago',
    pendencia: '3 parcelas em aberto',
  ),
  Cliente(
    nome: 'Janaína Gonçalves',
    telefone: '(45) 9 9822-8412',
    endereco: 'São Paulo • Vila Nova',
    cpf: '456.789.012-34',
    score: ClienteScore.verde,
    pontuacao: 880,
    ultimaCompra: '18/Out',
    produto: 'Cesta Família',
  ),
];
