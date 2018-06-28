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

/// Represents an integer range from [min] to [max], both inclusive.
class Range {
  const Range(this.min, this.max)
      : assert(
            min < max,
            '`min` must be less than `max` '
            '(for `min == max`, use `Range.single` instead');

  const factory Range.single(int value) = SingleElementRange;

  final int min;
  final int max;

  bool contains(int value) => min <= value && value <= max;

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
  bool contains(int value) => this.value == value;

  @override
  String toString() => value.toString();
}
