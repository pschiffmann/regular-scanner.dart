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
  for (var i = 0; i < sortedList.length; i++) {
    if (sortedList[i].intersects(range)) {
      return i;
    }
  }
  return sortedList.length;
}

/// Represents an integer range from [min] to [max], both inclusive.
class Range {
  const Range(this.min, this.max) : assert(min <= max);

  const factory Range.single(int value) = SingleElementRange;

  /// The lower bound of this range.
  final int min;

  /// The upper bound of this range.
  final int max;

  /// The number of [int]s contained in this range. This value is always greater
  /// than 0.
  int get length => max - min + 1;

  bool contains(int value) => min <= value && value <= max;

  bool intersects(Range other) => other.min <= max && min <= other.max;

  @override
  String toString() => '[$min, $max]';
}

/// Represents an integer range from [min] to [max], both inclusive.
class SingleElementRange implements Range {
  const SingleElementRange(this.value);

  final int value;

  @override
  int get min => value;
  @override
  int get max => value;

  @override
  int get length => 1;

  @override
  bool contains(int value) => this.value == value;
  @override
  bool intersects(Range other) => other.contains(value);

  @override
  String toString() => value.toString();
}
