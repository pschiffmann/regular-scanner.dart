part of 'powerset_construction.dart';

class MutableTransition extends Range {
  MutableTransition(int min, int max) : super(min, max);

  final SplayTreeSet<nfa.State> closure = new SplayTreeSet(_sortClosure);
}

///
void addSuccessor(
    List<MutableTransition> transitions, nfa.State successor, Range range) {
  // The next visited element in [transitions].
  var i = leftmostIntersectionOrRightNeighbour(transitions, range);

  // The first intersection starts left of [range]. Split that part off and step
  // over it.
  if (i != transitions.length && transitions[i].min < range.min) {
    splitTransition(transitions, i, range.min);
    i++;
  }

  for (var left = range.min;
      left <= range.max;
      left = transitions[i].max + 1, i++) {
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
  }
}

void addNegatedSuccessor(
    List<MutableTransition> transitions, nfa.State successor, Range range) {}

void addDefaultSuccessor(
    List<MutableTransition> transitions, nfa.State successor) {}

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

/// Converts a sorted list of [MutableTransition]s to corresponding
/// [dfa.Transition]s.
///
/// This method merges adjacent transitions if possible. For example, the
/// expression `(a|b)c` will be parsed into an NFA tree where `a` and `b` are
/// represented as two different states, and so they will be represented in
/// [transitions] as two different [MutableTransition]s. This method will merge
/// them together, as if the expression had been `[ab]c`.
List<dfa.Transition> finalizeTransitions(List<MutableTransition> transitions,
    int Function(List<nfa.State>) lookupId) {
  final result = <dfa.Transition>[];
  var i = 0;

  while (i < transitions.length) {
    final closure = transitions[i].closure;
    final min = transitions[i].min;
    var max = transitions[i].max;
    i++;
    while (i < transitions.length &&
        max + 1 == transitions[i].min &&
        closure == transitions[i].closure) {
      max = transitions[i].max;
      i++;
    }
    result.add(new dfa.Transition(
        min, max, lookupId(closure.toList(growable: false))));
  }
  return result;
}
