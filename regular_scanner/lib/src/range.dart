import 'package:quiver/core.dart';

/// Returns the index of the element in [sortedList] that contains [value], or
/// `-1` if no such element exists.
///
/// [sortedList] must be in ascending order, and the elements must be
/// non-intersecting.
int binarySearch(final List<Range> sortedList, final int value) {
  var min = 0;
  var max = sortedList.length;
  while (min < max) {
    final mid = min + ((max - min) ~/ 2);
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

/// Searches for the element in [ranges] that contains [value].
///
/// Falls back to the element first element with a [Range.min] greater than
/// [value] if no elements contains [value], or to `ranges.length` if [value] is
/// greater than all elements.
/// [ranges] must be in ascending order, and the elements must be
/// non-intersecting.
int findContainingOrNext(List<Range> ranges, int value) {
  var left = 0;
  var right = ranges.length;
  while (left < right) {
    final mid = left + ((right - left) ~/ 2);
    final current = ranges[mid];
    if (value < current.min) {
      right = mid;
    } else if (value > current.max) {
      left = mid + 1;
    } else {
      return mid;
    }
  }
  return right;
}

/// Splits existing elements or inserts new ones so that [ranges] contains all
/// elements in [block], and each element is either contained in, or does not
/// intersect [block].
///
/// [ranges] must be in ascending order, and the elements must be
/// non-intersecting.
///
/// ```dart
/// final ranges = [
///     Range(0, 1),
///     Range(5, 6),
///     Range(8, 11),
///     Range(12, 12),
///     Range(15, 20)
/// ];
/// reserve(ranges, Range(4, 10));
/// // Now, `ranges` contains the values:
/// // [0..1], [4], [5..6], [7], [8..10], [11], [12], [15..20]
/// ```
void reserve(List<Range> ranges, Range block) {
  var i = findContainingOrNext(ranges, block.min);

  // The first intersecting element starts left of [range]. Split that part off
  // and step over it.
  if (i != ranges.length && ranges[i].min < block.min) {
    split(ranges, i, block.min - 1);
    i++;
  }

  // All values in [block] less than [left] and all elements before `ranges[i]`
  // have already been processed.
  for (var left = block.min; left <= block.max; left = ranges[i].max + 1, i++) {
    // The next element doesn't intersect [block]. Insert a new element that
    // contains the remainder of [block].
    if (i == ranges.length || block.max < ranges[i].min) {
      ranges.insert(i, Range(left, block.max));
    }
    // There's a gap between [left] and the next intersecting element. Close it
    // with a new element.
    else if (left < ranges[i].min) {
      ranges.insert(i, Range(left, ranges[i].min - 1));
    }
    // [block] ends in the middle of `ranges[i]`. Split that element.
    else if (block.max < ranges[i].max) {
      split(ranges, i, block.max);
    }
    // `ranges[i]` is contained in [block]. Nothing to do here, the loop
    // increment will step over it.
  }
}

/// Modifies [ranges], removes the element `[min..max]` at [index] and replaces
/// it with two elements `[min..splitAfter]` and `[splitAfter + 1..max]`.
void split(List<Range> ranges, int index, int splitAfter) {
  assert(ranges[index].contains(splitAfter));
  final left = Range(ranges[index].min, splitAfter);
  final right = Range(splitAfter + 1, ranges[index].max);
  ranges
    ..[index] = right
    ..insert(index, left);
}

/// Represents an integer range from [min] to [max], both inclusive.
class Range {
  const Range(this.min, this.max) : assert(min <= max);

  const Range.single(int value) : this(value, value);

  /// The lower bound of this range.
  final int min;

  /// The upper bound of this range.
  final int max;

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
  String toString() => min == max ? '[$min]' : '[$min..$max]';
}
