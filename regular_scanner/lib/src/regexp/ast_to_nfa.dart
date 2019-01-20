/// AST does NOT implement NState because we don't want to track `accept` in
/// there.
library a;

import 'dart:collection';

import '../../regular_scanner.dart';
import '../state_machine/nfa.dart';
import 'ast.dart';

NState<T> astToNfa<T extends Regex>(Expression ast, T regex) {
  final acceptingStates = ast.last.toSet();

  NState<T> nstateForLeaf(dynamic leaf) {
    leaf = leaf as AtomicExpression;
    final accept = acceptingStates.contains(leaf) ? regex : null;
    if (leaf is Literal) {
      return NState<T>.value(leaf.codePoint, successors: [], accept: accept);
    } else if (leaf is CharacterSet) {
      return NState.range(leaf.codePoints.first.min, leaf.codePoints.first.max,
          negated: leaf.negated, successors: [], accept: accept);
    } else if (leaf is Wildcard) {
      return NState.wildcard(successors: [], accept: accept);
    }
    throw UnimplementedError();
  }

  final nstates = LinkedHashMap<AtomicExpression, NState<T>>.fromIterable(
      ast.leafs,
      value: nstateForLeaf);
  nstates.forEach((state, nstate) {
    for (final successor in state.successors.toSet()) {
      (nstate.successors as List).add(nstates[successor]);
    }
  });

  return NState.start(
      successors: ast.first.map((state) => nstates[state]).toList(),
      accept: ast.optional ? regex : null);
}
