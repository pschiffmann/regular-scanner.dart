import 'dart:collection';

import 'package:quiver/core.dart';

import 'dfa.dart';

/// Modified version of Hopcrofts algorithm.
List<int> resolveEquivalenceClasses(List<DState> dfa) {
  /// Mapping from [dfa] states to the equivalence class they belong to.
  final equivalenceClasses = _approximateEquivalenceClasses(dfa);
  final queue = equivalenceClasses.where((s) => s.length > 1).toSet();
  while (queue.isNotEmpty) {
    final current = queue.first;
    queue.remove(current);

    // ignore: prefer_final_locals
    for (var i = 0, l = current.first.transitions.length; i < l; i++) {}
  }

  final result = List<int>(dfa.length);
  return result;
}

/// What happens for `/a(b[bc]+|c[bc]+)/`?
List<Set<DState>> _approximateEquivalenceClasses(List<DState> dfa) {
  final equivalenceClasses = List<Set<DState>>(dfa.length);
  final byTransitions = LinkedHashMap<DState, int>(
      equals: (a, b) {
        if (a.accept != b.accept) return false;
        final aHasDefaultTransition = a.defaultTransition != Dfa.errorState;
        final bHasDefaultTransition = b.defaultTransition != Dfa.errorState;
        if (aHasDefaultTransition != bHasDefaultTransition) return false;
        if (a.transitions.length != b.transitions.length) return false;
        for (var i = 0; i < a.transitions.length; i++) {
          if (a.transitions[i] != b.transitions[i]) return false;
        }
        return true;
      },
      hashCode: (state) => hash4(
          hashObjects(state.transitions.map((t) => t.min)),
          hashObjects(state.transitions.map((t) => t.max)),
          state.defaultTransition != Dfa.errorState,
          state.accept));

  for (var i = 0; i < dfa.length; i++) {
    final state = dfa[i];
    final existing = byTransitions[state];
    if (existing != null) {
      equivalenceClasses[i] = equivalenceClasses[existing]..add(state);
    } else {
      byTransitions[state] = i;
      equivalenceClasses[i] = {state};
    }
  }

  return equivalenceClasses;
}
