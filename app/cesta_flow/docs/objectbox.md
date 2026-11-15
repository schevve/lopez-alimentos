# Banco local ObjectBox

O aplicativo nativo usa ObjectBox para clientes, vendas e pagamentos.
`DatabaseHelper` abre um único store na pasta de suporte do app antes de liberar
as telas. Os cadastros e consultas usam diretamente esse armazenamento.

## Executar

Use um dispositivo/emulador Android ou simulador/dispositivo iOS configurado:

```sh
flutter pub get
flutter devices
flutter run -d <id-do-dispositivo>
```

ObjectBox não suporta Flutter Web. O Supabase continua configurado como serviço
remoto PostgreSQL; sua integração com o armazenamento local será feita depois.

## Repositórios e regras

As telas usam `CustomerRepository`, `SaleRepository` e `PaymentRepository`.
As APIs, totais, ordenação, CPF/RG únicos, score opcional e exclusões em cascata
continuam com a mesma lógica. Os repositórios verificam a existência do cliente
antes de gravar uma venda e da venda antes de gravar um pagamento.

O critério de clientes pendentes continua sendo a existência de alguma venda
sem pagamento. A exportação CSV existente lê os registros atuais do ObjectBox.

## Manutenção

Após alterar uma entidade:

```sh
dart run build_runner build
```

Versione **lib/objectbox-model.json** e **lib/objectbox.g.dart** junto com as
entidades. Não apague/recrie o JSON: seus UIDs identificam o esquema persistido.
Ao excluir entidades, o gerador registra seus UIDs como aposentados para manter
a identidade das demais entidades.

ObjectBox, seu plugin nativo e seu gerador estão fixados em 5.3.2. O limite do
build_runner mantém compatibilidade com o gerador estável.

## Testes

Testes nativos precisam da biblioteca ObjectBox correspondente ao SDK. Para
macOS/Linux, obtenha o instalador oficial, confira-o e execute em modo local:

```sh
curl -fsSL https://raw.githubusercontent.com/objectbox/objectbox-dart/v5.3.2/install.sh -o /tmp/objectbox-install.sh
bash /tmp/objectbox-install.sh --quiet
flutter test test/objectbox_storage_test.dart test/customer_model_test.dart test/sale_details_test.dart
```

O modo `--quiet` copia a biblioteca para `lib/`, sem instalá-la no sistema.
Bibliotecas baixadas e a pasta `download/` ficam fora do Git. Os testes criam
bases temporárias e cobrem CRUD, unicidade, RGs nulos, score nulo, vínculos,
agregações, ordenação, cascatas e persistência ao fechar e reabrir o store.

Consulte [o relatório de validação](objectbox-validacao.md) para os resultados
executados e os limites da verificação.
