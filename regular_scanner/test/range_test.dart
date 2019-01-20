// ignore_for_file: prefer_const_constructors

import 'package:regular_scanner/src/range.dart';
import 'package:test/test.dart';

void main() {
  group('binarySearch', () {
    final buckets = [
      /* 0 */ Range(-4, 0),
      /* 1 */ Range(1, 3),
      /* 2 */ Range(8, 9),
      /* 3 */ Range(10, 12),
      /* 4 */ Range(14, 15),
      /* 5 */ Range(17, 17),
      /* 6 */ Range(20, 21)
    ];

    test('handles an empty list', () => expect(binarySearch([], 4), -1));

    test(
        'returns the correct index if a bucket contains element',
        () => {
              -3: 0,
              1: 1,
              8: 2,
              11: 3,
              15: 4,
              17: 5,
              20: 6,
            }.forEach((value, expectedIndex) =>
                expect(binarySearch(buckets, value), expectedIndex)));

    test('returns -1 for missing elements', () {
      for (final value in [-100, -5, 5, 13, 16]) {
        expect(binarySearch(buckets, value), -1);
      }
    });
  });

  group('findContainingOrNext()', () {
    const exampleRanges = [
      /* 0 */ Range(-10, -8),
      /* 1 */ Range(-5, -5),
      /* 2 */ Range(-4, -3),
      /* 3 */ Range(-2, -0),
      /* 4 */ Range(2, 2),
      /* 5 */ Range(4, 8),
      /* 6 */ Range(9, 9),
      /* 7 */ Range(10, 11),
      /* 8 */ Range(12, 12),
      /* 9 */ Range(19, 20)
    ];

    test('returns 0 for empty list',
        () => expect(findContainingOrNext([], 2), 0));

    test('returns correct index for list with greater and smaller elements',
        () {
      expect(findContainingOrNext(exampleRanges, -5), 1);
      expect(findContainingOrNext(exampleRanges, -4), 2);
      expect(findContainingOrNext(exampleRanges, 10), 7);
    });

    test('returns correct index for list with match and only greater elements',
        () => expect(findContainingOrNext(exampleRanges, -9), 0));

    test('returns correct index for list with match and only smaller elements',
        () => expect(findContainingOrNext(exampleRanges, 20), 9));

    test(
        'returns next index for list with no match and '
        'greater and smaller elements', () {
      expect(findContainingOrNext(exampleRanges, -6), 1);
      expect(findContainingOrNext(exampleRanges, 3), 5);
      expect(findContainingOrNext(exampleRanges, 13), 9);
    });

    test('returns 0 for list with no match and only greater elements',
        () => expect(findContainingOrNext(exampleRanges, -30), 0));

    test(
        'returns `list.length` for list with no match and '
        'only smaller elements',
        () => expect(findContainingOrNext(exampleRanges, 30), 10));
  });

  group('reserve()', () {
    List<Range> ranges;
    setUp(() => ranges = [
          Range(0, 1),
          Range(5, 6),
          Range(8, 11),
          Range(12, 12),
          Range(15, 20),
        ]);

    test('handles empty list', () {
      final ranges = <Range>[];
      reserve(ranges, Range(3, 9));
      expect(ranges, [Range(3, 9)]);
    });

    test('ignores non-intersecting elements', () {
      reserve(ranges, Range(7, 7));
      expect(ranges, [
        Range(0, 1),
        Range(5, 6),
        Range(7, 7),
        Range(8, 11),
        Range(12, 12),
        Range(15, 20),
      ]);
    });

    test(
        'splits the first intersecting element into an intersecting and a '
        'non-intersecting part', () {
      reserve(ranges, Range(6, 6));
      expect(ranges, [
        Range(0, 1),
        Range(5, 5),
        Range(6, 6),
        Range(8, 11),
        Range(12, 12),
        Range(15, 20),
      ]);
    });

    test(
        'inserts a leading range if `block` starts left of the first '
        'intersecting range', () {
      reserve(ranges, Range(3, 6));
      expect(ranges, [
        Range(0, 1),
        Range(3, 4),
        Range(5, 6),
        Range(8, 11),
        Range(12, 12),
        Range(15, 20),
      ]);
    });

    test('steps over elements in `ranges` completely contained in `block`', () {
      reserve(ranges, Range(8, 12));
      expect(ranges, [
        Range(0, 1),
        Range(5, 6),
        Range(8, 11),
        Range(12, 12),
        Range(15, 20),
      ]);
    });

    test('fills gaps between contained ranges', () {
      reserve(ranges, Range(0, 6));
      expect(ranges, [
        Range(0, 1),
        Range(2, 4),
        Range(5, 6),
        Range(8, 11),
        Range(12, 12),
        Range(15, 20),
      ]);
    });

    test(
        'splits the last intersecting element into an intersecting and a '
        'non-intersecting part', () {
      reserve(ranges, Range(8, 10));
      expect(ranges, [
        Range(0, 1),
        Range(5, 6),
        Range(8, 10),
        Range(11, 11),
        Range(12, 12),
        Range(15, 20),
      ]);
    });

    test(
        'inserts a trailing range if `block` ends right of the last '
        'intersecting range', () {
      reserve(ranges, Range(5, 7));
      expect(ranges, [
        Range(0, 1),
        Range(5, 6),
        Range(7, 7),
        Range(8, 11),
        Range(12, 12),
        Range(15, 20),
      ]);
    });

    test('handles a complex situation', () {
      reserve(ranges, Range(4, 10));
      expect(ranges, [
        Range(0, 1),
        Range(4, 4),
        Range(5, 6),
        Range(7, 7),
        Range(8, 10),
        Range(11, 11),
        Range(12, 12),
        Range(15, 20),
      ]);
    });
  });

  test('split() splits element at `split`', () {
    final ranges = [Range(0, 3), Range(4, 8)];
    split(ranges, 1, 6);
    expect(ranges, [Range(0, 3), Range(4, 6), Range(7, 8)]);
    split(ranges, 0, 2);
    expect(ranges, [Range(0, 2), Range(3, 3), Range(4, 6), Range(7, 8)]);
  });
}
