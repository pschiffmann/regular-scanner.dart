/// AST does NOT implement NState because we don't want to track `accept` in
/// there.
library a;

import 'package:quiver/collection.dart';

import '../../regular_scanner.dart';
import '../state_machine/nfa.dart';
import 'ast.dart';

NState<T> astToNfa<T extends Regex>(Expression ast, T regex) {
  final acceptingStates = ast.last.toSet();
  final nstates = ListMultimap<AtomicExpression, NState<T>>();

  for (final leaf in ast.leafs) {
    final accept = acceptingStates.contains(leaf) ? regex : null;
    if (leaf is Literal) {
      nstates.add(leaf,
          NState<T>.value(leaf.codePoint, successors: [], accept: accept));
    } else if (leaf is CharacterSet) {
      nstates.addValues(
          leaf,
          leaf.codePoints.map((range) => NState.range(range.min, range.max,
              negated: leaf.negated, successors: [], accept: accept)));
    } else if (leaf is Wildcard) {
      nstates.add(leaf, NState.wildcard(successors: [], accept: accept));
    } else {
      throw UnimplementedError();
    }
  }

  nstates.forEach((leaf, nstate) {
    for (final successor in leaf.successors.toSet()) {
      (nstate.successors as List<NState<T>>).addAll(nstates[successor]);
    }
  });

  return NState.start(
      successors: ast.first.expand((state) => nstates[state]).toList(),
      accept: ast.optional ? regex : null);
}
