import 'package:regular_scanner/src/range.dart';
import 'package:test/test.dart';

void main() {
  group('leftmostIntersectionOrRightNeighbour', () {
    test('handles empty list', () {
      expect(leftmostIntersectionOrRightNeighbour([], const Range(2, 4)), 0);
    });

    test('handles list with left and right neighbour', () {
      expect(
          leftmostIntersectionOrRightNeighbour(
              [const Range(1, 2), const Range(8, 9)], const Range(4, 6)),
          1);
    });

    test('handles list with only left neighbour', () {
      expect(
          leftmostIntersectionOrRightNeighbour(
              [const Range(1, 2)], const Range(4, 6)),
          1);
    });

    test('handles list with only right neighbour', () {
      expect(
          leftmostIntersectionOrRightNeighbour(
              [const Range(8, 9)], const Range(4, 6)),
          0);
    });

    test('handles multiple intersections', () {
      expect(
          leftmostIntersectionOrRightNeighbour(
              [const Range(1, 2), const Range(4, 5)], const Range(2, 6)),
          0);
    });

    test('handles intersections and neighbours', () {
      expect(
          leftmostIntersectionOrRightNeighbour([
            const Range(1, 2),
            const Range(4, 5),
            const Range(8, 11),
            const Range(15, 19)
          ], const Range(3, 10)),
          1);
    });
  });
}
