# Validação da migração para ObjectBox

Validação local em 05/11/2026, macOS ARM64, usando o Flutter instalado em
`/Users/mickaelbernardino/Faculdade/flutter/bin/flutter` e ObjectBox 5.3.2.
Os comandos abaixo usam `flutter` como abreviação desse executável.

## Resultados executados

| Comando (em app/cesta_flow) | Resultado |
| --- | --- |
| `flutter test test/objectbox_storage_test.dart` | 6 aprovados; `All tests passed!` |
| `flutter test test/objectbox_storage_test.dart test/customer_model_test.dart test/sale_details_test.dart` | 11 aprovados |
| `flutter test` | 17 aprovados, 4 falhas de interface |
| `flutter analyze` | 0 erros, 3 warnings, 15 infos; código de saída 1 |
| `git diff --check` | Sem problemas de whitespace |

A suíte completa e a análise estática foram executadas novamente antes do commit.
Não se trata de uma validação integralmente verde.

## Testes do armazenamento real

`test/objectbox_storage_test.dart` abre stores ObjectBox nativos em diretórios
temporários. A importação também usa um arquivo SQLite real, criado para o teste.

1. CRUD, score nullable, unicidade de documentos e múltiplos RGs nulos.
2. Validação de vínculos, agregações, ordenação e exclusão em cascata.
3. Migração preservando IDs, endereço antigo e nulos, sem duplicação em nova
   execução; confirmação da persistência depois de fechar e reabrir o store.
4. Pagamento antigo sem venda explícita cancela toda a transação, sem importação
   parcial, e permite nova tentativa depois de corrigir o vínculo.
5. Rejeição de vendas órfãs e de destino já preenchido sem marcador de migração.
6. Importação de SQLite legado sem mudar os bytes do arquivo original.

Nenhum teste utiliza o banco real do usuário ou modifica o Supabase.

## Falhas de interface e comparação com a base

As mesmas quatro falhas foram reproduzidas em uma cópia temporária do commit
`ae1e0bf`, anterior à migração:

- `customer_details_test.dart`: edita o cadastro existente e atualiza os detalhes
  ao retornar.
- `login_screen_test.dart`: valida campos, aplica máscara e navega após preencher.
- `tela_clientes_test.dart`: consulta o repositório, usa barras compartilhadas e
  exibe score nulo.
- `tela_clientes_test.dart`: navegação compartilhada abre o Dashboard.

Na base: **11 aprovados / 4 falhas**. Na implementação: **17 aprovados / 4 falhas**.
Para permitir compilar os testes da base, foi preenchido apenas o argumento
obrigatório `adress_number` em três fixtures, exatamente como nesta alteração.
As expectativas dos testes não foram removidas, relaxadas ou desabilitadas.

Os warnings do analyzer são campo/método não usados em `customer_registration`
e import não usado em `sale_customer_selection`. Os infos incluem nomes legados
como `adress_number` (também refletidos pelo gerador), `print` e uso de contexto
após operação assíncrona.

## Limites da verificação

- `flutter build apk --debug`: bloqueado por ausência do Android SDK.
- `flutter build macos --debug`: não há projeto macOS configurado no repositório.
- Não houve validação em aparelho/emulador Android ou iOS.
- A geração com `dart run build_runner build` foi concluída, mas o gerador estável
  emite aviso sobre a versão de linguagem do SDK ser mais recente que seu analyzer.
- ObjectBox local não suporta Flutter Web. Dados guardados no Chrome e dados
  remotos do Supabase não são importados por esta migração.
