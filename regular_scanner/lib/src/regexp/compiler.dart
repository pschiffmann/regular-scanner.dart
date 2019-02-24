/// The [compile] function from this library translates a [Regex] to an [Nfa]
/// state graph that can then be used to match an input string.
///
/// The compilation process is executed in these steps:
///  1. The [Regex.pattern] string is split into tokens. Token types are defined
///     in `token.dart`. Token recognition is implemented in `lexer.dart`.
///  2. The tokens are parsed into a syntax tree. The syntax tree is defined in
///     `ast.dart`. The parser is implemented in `parser.dart`.
///  3. The syntax tree is translated into a nondeterministic state machine.
///     This is implemented in [compile].
///  4. [Scanner.unambiguous] and [Scanner.ambiguous] pass the result from
///     [compile] to [powersetConstruction] to convert it to an equivalent
///     deterministic state machine.
///
/// In the [Nfa], [Literal]s and [Wildcard]s are represented by a single
/// [NState], and [CharacterSet]s are represented by one [NState] per element in
/// [CharacterSet.codePoints]. Non-[AtomicExpression]s are not represented in
/// the state machine at all – they were only needed to define the transitions
/// between states.
library regular_scanner.regex.compiler;

import 'package:quiver/collection.dart';

import '../../regular_scanner.dart';
import '../state_machine/nfa.dart';
import 'ast.dart';
import 'parser.dart';

/// Generates a nondeterministic state machine that accepts the language
/// specified by [regex]. Returns the start state of that state machine.
///
/// The [NState.accept] of all accepting states contain [regex].
NState<T> compile<T extends Regex>(T regex) {
  final ast = parse(regex.pattern);

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
