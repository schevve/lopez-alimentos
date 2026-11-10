import 'package:objectbox/objectbox.dart';

/// Gravado na mesma transação da importação para evitar cópias duplicadas.
@Entity()
class MigrationState {
  @Id(assignable: true)
  int id;
  MigrationState({this.id = 1});
}
