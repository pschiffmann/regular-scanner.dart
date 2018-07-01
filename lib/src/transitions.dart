part of 'powerset_construction.dart';

class MutableTransition extends Range {
  MutableTransition(int min, int max) : super(min, max);

  final List<nfa.State> closure = [];
}

///
void addSuccessor(
    List<MutableTransition> transitions, nfa.State successor, Range range) {
  // The next visited element in [transitions].
  var i = leftmostIntersectionOrRightNeighbour(transitions, range);
  // The leftmost value in [range] that has not been processed.
  var left = range.min;
  while (left <= range.max) {
    // The next transition doesn't intersect [range]. Insert a new transition
    // that contains the remainder of [range].
    if (i == transitions.length || range.max < transitions[i].min) {
      transitions.insert(i, new MutableTransition(left, range.max));
    }
    // There's a gap between [left] and the next intersecting transition. Close
    // it with a new transition.
    else if (left < transitions[i].min) {
      transitions.insert(
          i, new MutableTransition(left, transitions[i].min - 1));
    }
    // [range] ends in the middle of `transitions[i]`. Split the current
    // transition so [successor] isn't added to a value outside of [range].
    else if (range.max < transitions[i].max) {
      splitTransition(transitions, i, range.max + 1);
    }
    transitions[i].closure.add(successor);
    left = transitions[i].max + 1;
    i++;
  }
}

void addNegatedSuccessor() {}

void addDefaultSuccessor() {}

/// Splits the element in [transitions] at index [replaceAt] into two new
/// [MutableTransition]s that span the ranges [`min`, `min + splitAt - 1`] and
/// [`min + splitAt`, `max`].
///
/// `min` and `max` refer to the respective properties of the element at index
/// [replaceAt]. The new transitions contain the same `closure` as that element.
void splitTransition(
    List<MutableTransition> transitions, int replaceAt, int splitAt) {
  final old = transitions[replaceAt];
  transitions
    ..[replaceAt] = (new MutableTransition(old.min, old.min + splitAt - 1)
      ..closure.addAll(old.closure))
    ..insert(
        replaceAt + 1,
        new MutableTransition(old.min + splitAt, old.max)
          ..closure.addAll(old.closure));
}

