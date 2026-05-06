import 'package:flutter_test/flutter_test.dart';
import 'package:songs_folk_app/models/app_appearance.dart';

void main() {
  test('fromJson aplica default y clamp con valores inválidos', () {
    final appearance = AppAppearance.fromJson({
      'accent_seed_color_hex': '  ',
      'background_overlay_opacity': 9,
    });
    expect(appearance.accentSeedHex, isNull);
    expect(appearance.backgroundOverlayOpacity, 1.0);
  });

  test('parseHexColor devuelve null ante corruptos', () {
    expect(parseHexColor('zzzzzz'), isNull);
    expect(parseHexColor('#12345'), isNull);
  });
}
