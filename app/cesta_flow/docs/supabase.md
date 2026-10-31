# Documentação do Supabase

### Tabelas

As tabelas do banco de dados são as seguintes:

| Nome da Tabela   | Descrição                                                                                          | Colunas                                                                                           |
| ---------------- | -------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------- |
| tb_cliente       | Armazena informações dos clientes, como nome, email e endereço.                                    | usuário_id (usuário que registrou), nome, email, endereco, regiao_id, score, telefone             |
| tb_perfil        | Armazena informações sobre os perfis de usuário, como administrador ou usuário.                    | nome, sobrenome, cargo                                                                            |
| tb_venda         | Armazena informações sobre as vendas realizadas.                                                   | usuario_id (usuário que registrou), cliente_id, cesta_id, created_at, preco, valor_pago, parcelas |
| tb_produto       | Armazena informações sobre os produtos disponíveis para venda.                                     | nome, preco                                                                                       |
| tb_cesta         | Armazena informações sobre as cestas de produtos.                                                  | nome                                                                                              |
| tb_cesta_produto | Armazena a relação entre cestas e produtos, indicando quais produtos estão em cada cesta.          | cesta_id, produto_id, quantidade                                                                  |
| tb_venda_produto | Armazena a relação entre vendas e produtos, indicando quais produtos foram vendidos em cada venda. | venda_id, cesta_id, quantidade                                                                    |
| tb_pagamento     | Armazena informações sobre os pagamentos realizados pelos clientes.                                | venda_id, valor, data_cobranca                                                                    |
| tb_regiao        | Armazena informações sobre as regiões registradas, relacionando-se com os clientes.                | nome                                                                                              |
|                  |                                                                                                    |                                                                                                   |

### Autenticação

Para autenticar usuários, você pode usar o Supabase Auth.

#### Registro com email e senha

```dart
import 'package:supabase_flutter/supabase_flutter.dart';
final supabase = Supabase.instance.client;

Future<void> signUpWithEmailAndPassword(String email, String password) async {
  final response = await supabase.auth.signUp(
    email: email,
    password: password,
  );
}
```

> Observação: como o sistema ainda não é multi-tenant, o registro de usuários está desativado. Novos usuários devem ser criados manualmente no painel do Supabase.

#### Login com email e senha

```dart
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

Future<void> signInWithEmailAndPasssword(String email, String password) async {
  final response = await supabase.auth.signInWithPassword(
    email: email,
    password: password,
  );
}
```

Referência: [Supabase Auth](https://supabase.com/docs/guides/auth)

### Banco de Dados

Para interagir com o banco de dados, você pode usar o Supabase Client.

#### Consulta simples

```dart
import 'package:supabase_flutter/supabase_flutter.dart';
final supabase = Supabase.instance.client;

Future<void> fetchUsers() async {
  final response = await supabase.from('tb_cliente').select();
}
```

#### Consulta com filtro

```dart
Future<void> fetchUserById(int id) async {
  final response = await supabase.from('tb_cliente').select().eq('id', id);
}
```

#### Inserção de dados

```dart
Future<void> insertUser(String name, String email) async {
  final response = await supabase.from('tb_cliente').insert({
    'nome': name,
    'email': email,
    'endereco': 'Rua Central, 123',
  });
}
```

#### Atualização de dados

```dart
Future<void> updateUser(int id, String name) async {
  final response = await supabase.from('tb_cliente').update({
    'nome': name,
  }).eq('id', id);
}
```

#### Exclusão de dados

```dart
Future<void> deleteUser(int id) async {
  final response = await supabase.from('tb_cliente').delete().eq('id', id);
}
```

Referência: [Supabase Database](https://supabase.com/docs/guides/database)

### Arquitetura

#### Exemplo: Recebendo dados do Supabase e hidratando um widget

```dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserListWidget extends StatefulWidget {
  @override
  _UserListWidgetState createState() => _UserListWidgetState();
}

class _UserListWidgetState extends State<UserListWidget> {
  final supabase = Supabase.instance.client;
  // _users aqui é um Future, semelhante a uma Promise em JavaScript, que será resolvido com os dados do Supabase.
  final _users = Supabase.instance.client.from('tb_cliente').select();

  @override
  Widget build(BuildContext context) {
    // O FutureBuilder é um widget que constrói sua interface com base no estado de um Future. Ele é útil para lidar com operações assíncronas, como requisições a APIs.
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _users,
      builder: (context, snapshot) {
        // O snapshot contém o estado da requisição ao Supabase, que pode estar em andamento, ter retornado com sucesso ou ter falhado.
        // Aqui vamos tratar só os casos de sucesso e erro, mas você pode adicionar um indicador de carregamento enquanto a requisição está em andamento.
        if (snapshot.hasError) {
          return Text('Erro: ${snapshot.error}');
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Text('Nenhum usuário encontrado.');
        } else {
          // Quando os dados estiverem disponíveis, a lista de usuários será exibida.
          final users = snapshot.data!;
          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return ListTile(
                  title: Text(user['nome']),
                  subtitle: Text(user['email']),
              );
            },
          );
        }
      },
    );
  }
}
```

#### Repositories

Repositories são classes que encapsulam a lógica de acesso a dados, fornecendo uma interface para interagir com o banco de dados. Eles ajudam a manter o código organizado e facilitam a manutenção.

A responsabilidade deles é tanto interagir com o Supabase quanto atualizar bancos de dados locais, para permitir que o aplicativo funcione offline.

A lógica de sincronização entre o banco de dados local e o Supabase deve ser implementada dentro dos repositórios, nunca diretamente nos widgets. Isso garante que a lógica de negócios esteja separada da interface do usuário.
