# Banco local ObjectBox

O aplicativo nativo usa ObjectBox para clientes, vendas e pagamentos. O Supabase
continua configurado como serviço remoto PostgreSQL. Esta mudança não importa
registros do Supabase nem implementa sincronização com ele.

## Executar

Use um dispositivo/emulador Android ou simulador/dispositivo iOS configurado:

```sh
flutter pub get
flutter devices
flutter run -d <id-do-dispositivo>
```

ObjectBox não suporta Flutter Web. Os registros SQLite que ficaram no navegador
não são acessíveis pelo aplicativo nativo; precisam de uma exportação/importação
separada. A migração automática abaixo lê somente o arquivo SQLite da mesma
instalação nativa. Não desinstale o app nem limpe seus dados antes de migrar.

## Migração de dados existentes

- Na inicialização, `DatabaseHelper` abre ObjectBox na pasta de suporte do app.
- `SqliteMigration` procura `app_database.db` no diretório padrão do sqflite.
- A base antiga é aberta somente para leitura, sem executar os antigos upgrades.
- Clientes, vendas e pagamentos são copiados em uma única transação, preservando
  IDs, vínculos, CPF/RG únicos, score nulo e o número do endereço (aceita tanto
  `adress_number` quanto `addres_number`).
- Um registro interno marca a conclusão dentro da mesma transação. A importação
  não se repete em futuras aberturas, mesmo se registros forem excluídos no app.
- O SQLite original não é removido. O sqflite permanece como dependência somente
  para ler esse arquivo durante a transição.
- IDs inválidos, vínculos órfãos e pagamentos antigos que tenham apenas
  `customer_id` interrompem a migração, sem gravação parcial. Não é possível
  inferir com segurança a venda de um pagamento pelo cliente. Esses vínculos
  precisam ser resolvidos na origem antes de tentar novamente.
- Se a migração falhar, o app apresenta o erro e não abre as telas de cadastro.
  Após corrigir a causa, reinicie o app para tentar novamente.

Não volte simplesmente à versão SQLite depois de cadastrar dados no ObjectBox:
o arquivo antigo é uma cópia do estado anterior e não recebe novas alterações.

## Manutenção

As telas continuam usando `CustomerRepository`, `SaleRepository` e
`PaymentRepository`. Os repositórios verificam a existência dos pais e fazem a
exclusão em cascata em transações. Não grave diretamente nas boxes fora dessa
camada. Os totais e o critério de clientes pendentes mantêm o comportamento
anterior (cliente com alguma venda sem pagamento).

Após alterar uma entidade:

```sh
dart run build_runner build
```

Versione **lib/objectbox-model.json** e **lib/objectbox.g.dart** junto com as
entidades. Não apague/recrie o JSON: seus UIDs identificam o esquema persistido.
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
bases temporárias, não abrem os dados reais do usuário.

Cobertura: CRUD, unicidade, RGs nulos, score nulo, agregações, ordenação, cascatas,
persistência após reabrir, importação única, rollback e leitura de SQLite real
sem mudar o arquivo original.

## Integração futura com Supabase

O esquema remoto não é uma cópia do local: usa UUIDs, `score` decimal e parcelas
em `tb_parcela`. A sincronização futura precisa definir o mapeamento desses
campos, IDs remotos, conflitos e autenticação. A migração local não inventa
conversões nem regras de score.

## Resultados da validação

Consulte [o relatório de testes executados](objectbox-validacao.md), incluindo
as falhas de interface reproduzidas na base e os limites de compilação nativa.
