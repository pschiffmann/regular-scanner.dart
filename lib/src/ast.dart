import 'dart:core' hide Pattern;

import '../regular_scanner.dart' show Pattern;
import 'ranges.dart';

/// Each expression object represents a coherent, complete regular expression
/// pattern. Each expression is either a [State] or a [DelegatingExpression].
///
/// Expressions are only mutable while the expression tree is still built during
/// parsing. An expression can only be assigned to a [parent] once, and the
/// [repetition] can only be changed until the expression has a [root].
abstract class Expression {
  Expression(this._repetition);

  /// Trying to change this value after this expression has been sealed with a
  /// [Root] will throw a [StateError].
  Repetition get repetition => _repetition;
  set repetition(Repetition repetition) {
    if (root != null) {
      throw new StateError('This expression tree has been sealed');
    }
    _repetition = repetition;
  }

  Repetition _repetition;

  DelegatingExpression get parent => _parent;
  DelegatingExpression _parent;

  Root get root => parent?.root;

  /// The index in [DelegatingExpression.children] where `this` is stored.
  int _parentIndex;

  Iterable<State> get leafs;

  bool get optional => repetition.optional;
  bool get repeat => repetition.repeat;
}

///
abstract class State extends Expression {
  State(Repetition repetition) : super(repetition);

  /// Marks the final states in a pattern. If this state is entered during a
  /// matching process, the input gets accepted. This attribute is set when the
  /// expression tree is sealed by a [Root].
  bool get accepting => _accepting;

  /// Each [State] in an expression has a unique id. This attribute is set when
  /// the expression tree is sealed by a [Root].
  int get id => _id;

  /// These variables may only be set by [new Root].
  bool _accepting = false;
  int _id;

  @override
  Iterable<State> get leafs => [this];

  /// Returns all states that are reachable from this state with a single
  /// transition.
  Iterable<State> get successors sync* {
    if (repeat) {
      yield this;
    }
    if (parent != null) {
      yield* parent.siblings(this);
    }
  }
}

/// A literal matches exactly [rune].
class Literal extends State {
  Literal(this.rune, [Repetition repetition = Repetition.one])
      : super(repetition);

  final int rune;

  @override
  String toString() => '${new String.fromCharCode(rune)}$repetition';
}

/// A dot pattern matches any single character.
class Dot extends State {
  Dot([Repetition repetition = Repetition.one]) : super(repetition);

  @override
  String toString() => '.$repetition';
}

/// A character set represents patterns like `[A-Z]`.
class CharacterSet extends State {
  CharacterSet(this.runes, this.negated,
      [Repetition repetition = Repetition.one])
      : super(repetition);

  final List<Range> runes;
  final bool negated;

  @override
  String toString() {
    final contents = new StringBuffer();
    for (final range in runes) {
      contents.writeCharCode(range.min);
      if (range.max > range.min) {
        contents
          ..write('-')
          ..writeCharCode(range.max);
      }
    }
    return negated ? '[^$contents]' : '[$contents]';
  }
}

///
abstract class DelegatingExpression extends Expression {
  DelegatingExpression(Iterable<Expression> children, Repetition repetition)
      : children = new List.unmodifiable(children),
        super(repetition) {
    for (var i = 0; i < this.children.length; i++) {
      assert(this.children[i]._parent == null);
      this.children[i]
        .._parent = this
        .._parentIndex = i;
    }
  }

  final List<Expression> children;

  @override
  Iterable<State> get leafs => children.expand((child) => child.leafs);

  /// Returns all recursive children of type [State] in this subtree that can
  /// be reached with a single transition from a preceding expression.
  Iterable<State> get first;

  /// Returns all recursive children of this that can exit this subtree with a
  /// single transition.
  Iterable<State> get last;

  /// Returns all siblings of [child] that it can reach with a single
  /// transition, including siblings from [parent]. [child] must be in
  /// [children].
  Iterable<State> siblings(final Expression child);

  String get _childSeparator;

  @override
  String toString() {
    final body = children.join(_childSeparator);
    return repetition == null ? body : '($body)$repetition';
  }
}

/// A sequence matches iff all of its children match in order. This represents
/// the concatenation of e.g. _`a`, then `b`_ in the expression `ab`.
class Sequence extends DelegatingExpression {
  Sequence(Iterable<Expression> children,
      [Repetition repetition = Repetition.one])
      : super(children, repetition);

  @override
  bool get optional =>
      super.optional || children.every((child) => child.optional);

  @override
  Iterable<State> get first sync* {
    for (final child in children) {
      if (child is State) {
        yield child;
      } else {
        yield* (child as DelegatingExpression).first;
      }
      if (!child.optional) return;
    }
  }

  @override
  Iterable<State> get last sync* {
    for (final child in children.reversed) {
      if (child is State) {
        yield child;
      } else {
        yield* (child as DelegatingExpression).last;
      }
      if (!child.optional) return;
    }
  }

  @override
  Iterable<State> siblings(final Expression child) sync* {
    assert(child.parent == this);
    for (final successor in children.skip(child._parentIndex + 1)) {
      if (successor is State) {
        yield successor;
      } else {
        yield* (successor as DelegatingExpression).first;
      }
      if (!successor.optional) return;
    }

    yield* parent.siblings(this);

    if (!repeat) return;
    for (final successor in first) {
      if (successor == child) return;
      yield successor;
    }
  }

  @override
  String get _childSeparator => '';
}

/// An alternation matches iff any of its children matches. This represents e.g.
/// _`a` or `b` or_ in the expression `a|b`.
class Alternation extends DelegatingExpression {
  Alternation(Iterable<Expression> children,
      [Repetition repetition = Repetition.one])
      : super(children, repetition);

  @override
  bool get optional =>
      super.optional || children.any((child) => child.optional);

  @override
  Iterable<State> get first sync* {
    for (final child in children) {
      if (child is State) {
        yield child;
      } else {
        yield* (child as DelegatingExpression).first;
      }
    }
  }

  @override
  Iterable<State> get last => first;

  @override
  Iterable<State> siblings(final Expression child) sync* {
    assert(child.parent == this);
    yield* parent.siblings(this);

    if (!repeat) return;
    for (final successor in first) {
      if (successor != child) yield successor;
    }
  }

  @override
  String get _childSeparator => '|';
}

/// Seals an [Expression] tree. A [Root] can't have a parent, and since children
/// can't be removed from a [DelegatingExpression], a root expressions and its
/// children are effectively immutable.
///
/// An expression root has only a single [child], and stores a reference to the
/// [pattern] it was parsed from.
class Root extends DelegatingExpression {
  Root(Expression child, this.pattern) : super([child], Repetition.one) {
    for (final child in last) {
      child._accepting = true;
    }

    var id = 1;
    for (final state in leafs) {
      state._id = id++;
    }
  }

  @override
  DelegatingExpression get _parent =>
      throw new UnsupportedError("Root can't have a parent");
  @override
  set _parent(DelegatingExpression _) =>
      throw new UnsupportedError("Root can't have a parent");
  @override
  Root get root => this;

  Expression get child => children.first;
  final Pattern pattern;

  @override
  Iterable<State> get leafs => child.leafs;

  @override
  Iterable<State> get first =>
      child is State ? [child] : (child as DelegatingExpression).first;

  @override
  Iterable<State> get last =>
      child is State ? [child] : (child as DelegatingExpression).last;

  @override
  Iterable<State> siblings(final Expression child) => const [];

  @override
  String get _childSeparator => throw new UnimplementedError('Unused');

  @override
  String toString() => child.toString();
}

/// Pseudo-enum that represents the possible repetition specifiers `+`, `?` and
/// `*` as well as the default repetition _not optional, don't repeat_.
class Repetition {
  const Repetition._(this._stringRepresentation, this.optional, this.repeat);

  static const Repetition one = const Repetition._('', false, false);
  static const Repetition oneOrMore = const Repetition._('+', false, true);
  static const Repetition zeroOrOne = const Repetition._('?', true, false);
  static const Repetition zeroOrMore = const Repetition._('*', true, true);

  static const List<Repetition> values = const [
    one,
    oneOrMore,
    zeroOrOne,
    zeroOrMore
  ];

  final String _stringRepresentation;
  final bool optional;
  final bool repeat;

  Repetition operator |(Repetition other) {
    if (optional || other.optional) {
      return repeat || other.repeat ? zeroOrMore : zeroOrOne;
    } else {
      return repeat || other.repeat ? oneOrMore : one;
    }
  }

  @override
  String toString() => _stringRepresentation;
}
