import 'package:cesta_flow/core/constants/data/brazil_locations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('carrega estados e municípios do IBGE', () async {
    final locations = await BrazilLocations.load();
    expect(locations.states.length, 27);
    expect(locations.citiesFor('PR'), contains('Toledo'));
  });
}
