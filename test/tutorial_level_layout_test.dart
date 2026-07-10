import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('tutorial final route remains reachable', () async {
    final map = await File('assets/tiles/level_01.tmx').readAsString();

    expect(RegExp('name="coin"').allMatches(map), hasLength(5));
    expect(map, contains('name="coin" x="448" y="152"'));
    expect(map, contains('name="coin" x="544" y="152"'));
    expect(map, isNot(contains('name="spike_5"')));
    expect(
      map,
      contains('name="exit" x="600" y="128" width="32" height="48"'),
    );
  });
}
