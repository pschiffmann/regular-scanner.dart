part of 'powerset_construction.dart';

class ConstructionTransition extends Range {
  ConstructionTransition(int min, int max) : super(min, max);

  final SplayTreeSet<nfa.State> closure = constructionClosure();
}

///
void reserveTransition(List<ConstructionTransition> transitions, Range range,
    {nfa.State successor}) {
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
      transitions.insert(i, new ConstructionTransition(left, range.max));
    }
    // There's a gap between [left] and the next intersecting transition. Close
    // it with a new transition.
    else if (left < transitions[i].min) {
      transitions.insert(
          i, new ConstructionTransition(left, transitions[i].min - 1));
    }
    // [range] ends in the middle of `transitions[i]`. Split the current
    // transition so [successor] isn't added to a value outside of [range].
    else if (range.max < transitions[i].max) {
      splitTransition(transitions, i, range.max + 1);
    }
    if (successor != null) {
      transitions[i].closure.add(successor);
    }
  }
}

/// Splits the element in [transitions] at index [splitElement] into two new
/// [ConstructionTransition]s that span the ranges [`min`, `rightStart - 1`] and
/// [`rightStart`, `max`].
///
/// `min` and `max` refer to the respective properties of the element at index
/// [splitElement]. The new transitions contain the same `closure` as that
/// element.
void splitTransition(List<ConstructionTransition> transitions, int splitElement,
    int rightStart) {
  final old = transitions[splitElement];
  assert(old.min < rightStart && rightStart < old.max,
      "Can't split off a transition with length 0");
  transitions
    ..[splitElement] = (new ConstructionTransition(old.min, rightStart - 1)
      ..closure.addAll(old.closure))
    ..insert(
        splitElement + 1,
        new ConstructionTransition(rightStart, old.max)
          ..closure.addAll(old.closure));
}

/// Converts a sorted list of [ConstructionTransition]s to corresponding
/// [dfa.Transition]s.
///
/// This method merges adjacent transitions if possible. For example, the
/// expression `(a|b)c` will be parsed into an NFA tree where `a` and `b` are
/// represented as two different states, and so they will be represented in
/// [transitions] as two different [ConstructionTransition]s. This method will merge
/// them together, as if the expression had been `[ab]c`.
List<dfa.Transition> finalizeTransitions(
    List<ConstructionTransition> transitions,
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
        closureEquality.equals(closure, transitions[i].closure)) {
      max = transitions[i].max;
      i++;
    }
    result.add(new dfa.Transition(
        min, max, lookupId(closure.toList(growable: false))));
  }
  return result;
}
