# Validação do armazenamento ObjectBox

Validação local em 11/11/2026, macOS ARM64, usando Flutter em
`/Users/mickaelbernardino/Faculdade/flutter/bin/flutter` e ObjectBox 5.3.2.
Os comandos abaixo usam `flutter` como abreviação desse executável.

## Resultados executados

| Comando (em app/cesta_flow) | Resultado |
| --- | --- |
| `flutter test test/objectbox_storage_test.dart test/customer_model_test.dart test/sale_details_test.dart` | 8 aprovados |
| `flutter test` | 14 aprovados, 4 falhas de interface |
| `flutter analyze` | 0 erros, 9 warnings, 7 infos; código de saída 1 |
| `dart run build_runner build` | Esquema gerado com sucesso |
| `git diff --check` | Sem problemas de whitespace |

## Testes do armazenamento real

`test/objectbox_storage_test.dart` abre stores ObjectBox nativos em diretórios
temporários e contém três testes:

1. CRUD, score nullable, unicidade de documentos e múltiplos RGs nulos.
2. Validação de vínculos, agregações, ordenação e exclusão em cascata.
3. Persistência de cliente, venda e pagamento ao fechar e reabrir o store,
   conferindo endereço, score nulo e vínculos.

Os demais testes focados verificam o model de cliente e a tela de detalhes de
vendas. As bases de teste são descartadas ao terminar.

## Falhas da suíte completa

Permanecem as quatro falhas de interface já identificadas anteriormente:

- `customer_details_test.dart`: edita o cadastro existente e atualiza os detalhes
  ao retornar.
- `login_screen_test.dart`: valida campos, aplica máscara e navega após preencher.
- `tela_clientes_test.dart`: consulta o repositório, usa barras compartilhadas e
  exibe score nulo.
- `tela_clientes_test.dart`: navegação compartilhada abre o Dashboard.

As expectativas desses testes continuam ativas. A suíte completa não está verde.
Os warnings/infos atuais estão nas telas de cadastro de cliente, pagamento,
seleção de cliente, venda e formulário compartilhado (imports/declarações não
usados, operadores de nulidade desnecessários e uso de `print`).

## Limites da verificação

- Não houve teste em aparelho/emulador Android ou iOS nesta revisão.
- Na verificação anterior, o build Android ficou bloqueado pela ausência do
  Android SDK; o repositório também não tem target macOS configurado.
- O gerador estável concluiu a geração, com aviso sobre a versão de linguagem
  do SDK ser mais recente que seu analyzer.
- A execução do app requer plataforma nativa; Flutter Web não é suportado.
