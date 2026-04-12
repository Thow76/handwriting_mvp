import 'package:flutter_test/flutter_test.dart';
import 'package:handwriting_mvp/models/skeletonizer.dart';

void main() {
  group('Skeletonizer', () {
    test('empty mask returns empty mask', () {
      final mask = List.generate(5, (_) => List.filled(5, false));
      final skeleton = Skeletonizer.skeletonize(mask);
      expect(skeleton.length, 5);
      expect(skeleton[0].length, 5);
      for (final row in skeleton) {
        expect(row.every((p) => !p), true);
      }
    });

    test('single pixel remains', () {
      final mask = List.generate(5, (_) => List.filled(5, false));
      mask[2][2] = true;
      final skeleton = Skeletonizer.skeletonize(mask);
      expect(skeleton[2][2], true);
      // Only one pixel should be set
      var count = 0;
      for (final row in skeleton) {
        for (final pixel in row) {
          if (pixel) count++;
        }
      }
      expect(count, 1);
    });

    test('horizontal line thins to single-pixel-wide line', () {
      // A 3-pixel-tall horizontal bar should thin to ~1 pixel tall
      final mask = List.generate(7, (_) => List.filled(10, false));
      for (var row = 2; row <= 4; row++) {
        for (var col = 1; col <= 8; col++) {
          mask[row][col] = true;
        }
      }
      final skeleton = Skeletonizer.skeletonize(mask);

      // Skeleton should have ink pixels
      var totalInk = 0;
      for (final row in skeleton) {
        for (final pixel in row) {
          if (pixel) totalInk++;
        }
      }
      expect(totalInk, greaterThan(0));

      // Skeleton should be thinner than the original
      var originalInk = 0;
      for (final row in mask) {
        for (final pixel in row) {
          if (pixel) originalInk++;
        }
      }
      expect(totalInk, lessThan(originalInk));
    });

    test('vertical line thins to single-pixel-wide line', () {
      // A 3-pixel-wide vertical bar should thin to ~1 pixel wide
      final mask = List.generate(10, (_) => List.filled(7, false));
      for (var row = 1; row <= 8; row++) {
        for (var col = 2; col <= 4; col++) {
          mask[row][col] = true;
        }
      }
      final skeleton = Skeletonizer.skeletonize(mask);

      var totalInk = 0;
      for (final row in skeleton) {
        for (final pixel in row) {
          if (pixel) totalInk++;
        }
      }
      expect(totalInk, greaterThan(0));

      var originalInk = 0;
      for (final row in mask) {
        for (final pixel in row) {
          if (pixel) originalInk++;
        }
      }
      expect(totalInk, lessThan(originalInk));
    });

    test('filled rectangle thins to a line', () {
      // A 5x10 filled rectangle should produce a thin skeleton
      final mask = List.generate(10, (_) => List.filled(15, false));
      for (var row = 2; row <= 7; row++) {
        for (var col = 2; col <= 12; col++) {
          mask[row][col] = true;
        }
      }
      final skeleton = Skeletonizer.skeletonize(mask);

      var totalInk = 0;
      for (final row in skeleton) {
        for (final pixel in row) {
          if (pixel) totalInk++;
        }
      }
      expect(totalInk, greaterThan(0));

      var originalInk = 0;
      for (final row in mask) {
        for (final pixel in row) {
          if (pixel) originalInk++;
        }
      }
      // Skeleton should be significantly thinner
      expect(totalInk, lessThan(originalInk ~/ 2));
    });

    test('skeleton pixels are subset of original mask', () {
      // Every skeleton pixel must have been an ink pixel in the original
      final mask = List.generate(10, (_) => List.filled(10, false));
      for (var row = 1; row <= 8; row++) {
        for (var col = 1; col <= 8; col++) {
          mask[row][col] = true;
        }
      }
      final skeleton = Skeletonizer.skeletonize(mask);

      for (var row = 0; row < mask.length; row++) {
        for (var col = 0; col < mask[row].length; col++) {
          if (skeleton[row][col]) {
            expect(mask[row][col], true,
                reason: 'Skeleton pixel at ($row,$col) not in original mask');
          }
        }
      }
    });

    test('does not modify the input mask', () {
      final mask = List.generate(5, (_) => List.filled(5, false));
      mask[1][1] = true;
      mask[1][2] = true;
      mask[1][3] = true;
      mask[2][1] = true;
      mask[2][2] = true;
      mask[2][3] = true;
      mask[3][1] = true;
      mask[3][2] = true;
      mask[3][3] = true;

      // Deep copy to compare after
      final original = mask.map((row) => List<bool>.from(row)).toList();

      Skeletonizer.skeletonize(mask);

      for (var row = 0; row < mask.length; row++) {
        for (var col = 0; col < mask[row].length; col++) {
          expect(mask[row][col], original[row][col],
              reason: 'Input mask modified at ($row,$col)');
        }
      }
    });

    test('output has same dimensions as input', () {
      final mask = List.generate(12, (_) => List.filled(8, false));
      final skeleton = Skeletonizer.skeletonize(mask);
      expect(skeleton.length, 12);
      for (final row in skeleton) {
        expect(row.length, 8);
      }
    });

    test('circle-like shape produces thin skeleton', () {
      // Create a rough circle (filled disc) and verify it thins
      final size = 15;
      final center = 7.0;
      final radius = 5.0;
      final mask = List.generate(size, (row) {
        return List.generate(size, (col) {
          final dx = col - center;
          final dy = row - center;
          return (dx * dx + dy * dy) <= radius * radius;
        });
      });

      final skeleton = Skeletonizer.skeletonize(mask);

      var skeletonInk = 0;
      var originalInk = 0;
      for (var row = 0; row < size; row++) {
        for (var col = 0; col < size; col++) {
          if (skeleton[row][col]) skeletonInk++;
          if (mask[row][col]) originalInk++;
        }
      }
      expect(skeletonInk, greaterThan(0));
      expect(skeletonInk, lessThan(originalInk ~/ 2));
    });
  });
}
