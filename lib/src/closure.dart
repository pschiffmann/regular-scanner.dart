part of 'powerset_construction.dart';

/// Two closures are considered equal if they contain the same elements.
const IterableEquality<nfa.State> closureEquality = IterableEquality();

/// Sorts the states in a closure first by their pattern, then by their id. The
/// concrete order doesn't matter, but it needs to be unambiguous so that
/// [closureEquality] recognizes semantically equal closures as equal.
int sortClosure(nfa.State a, nfa.State b) => a.root != b.root
    ? a.root.pattern.regularExpression
        .compareTo(b.root.pattern.regularExpression)
    : a.id - b.id;

/// Returns a new [SplayTreeSet] that can be used to construct new closures
/// because it automatically filters out duplicates and orders its elements with
/// [sortClosure].
SplayTreeSet<nfa.State> constructionClosure() => SplayTreeSet(sortClosure);
