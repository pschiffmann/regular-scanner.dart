import 'package:quiver/core.dart';

/// Returns the index of the element in [sortedList] that contains [value], or
/// `-1` if no such element exists.
int binarySearch(final List<Range> sortedList, final int value) {
  var min = 0;
  var max = sortedList.length;
  while (min < max) {
    final mid = min + ((max - min) >> 1);
    final current = sortedList[mid];
    if (value < current.min) {
      max = mid;
    } else if (value > current.max) {
      min = mid + 1;
    } else {
      return mid;
    }
  }
  return -1;
}

/// Returns the index of the leftmost element in [sortedList] that intersects
/// [range]; or the index of the leftmost right neighbour of [range] if no
/// intersection exists; or `sortedList.length` if [range] is right of all
/// elements.
int leftmostIntersectionOrRightNeighbour(List<Range> sortedList, Range range) {
  // TODO: Is this possible in O(log n)?
  var i = 0;
  for (; i < sortedList.length && sortedList[i].max < range.min; i++);
  return i;
}

/// Represents an integer range from [min] to [max], both inclusive.
class Range {
  const Range(this.min, this.max) : assert(min <= max);

  const Range.single(int value) : this(value, value);

  /// The lower bound of this range.
  final int min;

  /// The upper bound of this range.
  final int max;

  /// The number of [int]s contained in this range. This value is always greater
  /// than 0.
  int get length => max - min + 1;

  bool contains(int value) => min <= value && value <= max;

  bool containsRange(Range other) => min <= other.min && other.max <= max;

  bool intersects(Range other) => other.min <= max && min <= other.max;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Range && other.min == min && other.max == max;

  @override
  int get hashCode => hash2(min, max);

  @override
  String toString() => '[$min, $max]';
}
