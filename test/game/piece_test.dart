import 'package:flutter_test/flutter_test.dart';
import 'package:gridpop/game/piece.dart';

void main() {
  group('Cell', () {
    test('addition offsets both coordinates', () {
      expect(const Cell(1, 2) + const Cell(3, 4), const Cell(4, 6));
    });

    test('equality and hashCode are value-based', () {
      expect(const Cell(2, 3), const Cell(2, 3));
      expect(const Cell(2, 3).hashCode, const Cell(2, 3).hashCode);
      expect(const Cell(2, 3) == const Cell(3, 2), isFalse);
    });
  });

  group('Piece normalization', () {
    test('shifts cells so min row and col are 0', () {
      final p = Piece('x', const [Cell(5, 5), Cell(5, 6), Cell(6, 5)], 1);
      expect(p.cells.any((c) => c.row == 0), isTrue);
      expect(p.cells.any((c) => c.col == 0), isTrue);
      expect(p.cells.every((c) => c.row >= 0 && c.col >= 0), isTrue);
    });

    test('computes bounding box width and height', () {
      final p = Piece('x', const [Cell(0, 0), Cell(0, 1), Cell(0, 2)], 1);
      expect(p.width, 3);
      expect(p.height, 1);
      expect(p.size, 3);
    });

    test('rejects empty cell list', () {
      expect(() => Piece('bad', const [], 1), throwsA(isA<AssertionError>()));
    });

    test('rejects non-positive weight', () {
      expect(
        () => Piece('bad', const [Cell(0, 0)], 0),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('catalog', () {
    final catalog = buildCatalog();

    test('all ids are unique', () {
      final ids = catalog.map((p) => p.id).toSet();
      expect(ids.length, catalog.length);
    });

    test('expected cell counts per family', () {
      Piece byId(String id) => catalog.firstWhere((p) => p.id == id);
      expect(byId('dot').size, 1);
      expect(byId('line5_h').size, 5);
      expect(byId('square3').size, 9);
      expect(byId('rect2x3').size, 6);
      expect(byId('lsmall_0').size, 3);
      expect(byId('lbig_0').size, 5);
      expect(byId('t_0').size, 4);
      expect(byId('s_h').size, 4);
    });

    test('weights match the spec', () {
      Piece byId(String id) => catalog.firstWhere((p) => p.id == id);
      expect(byId('dot').weight, 4);
      expect(byId('line2_h').weight, 6);
      expect(byId('line4_h').weight, 5);
      expect(byId('line5_h').weight, 3);
      expect(byId('square2').weight, 6);
      expect(byId('square3').weight, 3);
      expect(byId('t_0').weight, 4);
    });

    test('every piece is normalized and within an 8x8 board', () {
      for (final p in catalog) {
        expect(p.cells.every((c) => c.row >= 0 && c.col >= 0), isTrue,
            reason: '${p.id} has negative cells');
        expect(p.width <= 8 && p.height <= 8, isTrue,
            reason: '${p.id} does not fit an 8x8 board');
      }
    });

    test('T rotations all have 4 cells', () {
      for (final id in ['t_0', 't_1', 't_2', 't_3']) {
        expect(catalog.firstWhere((p) => p.id == id).size, 4);
      }
    });
  });
}
