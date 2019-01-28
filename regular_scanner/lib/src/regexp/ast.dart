library regular_scanner.regex.ast;

import '../range.dart';

abstract class Expression {
  _Parent get parent => _parent;
  _Parent _parent;
  int _parentIndex;

  Iterable<AtomicExpression> get leafs;

  /// Returns all recursive children of type [AtomicExpression] in this subtree that can
  /// be reached with a single transition from a preceding expression.
  ///
  /// May contain duplicates. See [Sequence.successors] for an explanation when
  /// this happens.
  Iterable<AtomicExpression> get first;

  /// Returns all recursive children of this that can exit this subtree with a
  /// single transition.
  Iterable<AtomicExpression> get last;

  bool get optional;
}

/// Marker interface.
abstract class _Parent implements Expression {
  /// Returns all successors of [child] that it can reach with a single
  /// transition, including successors from [parent]. `child.parent` must be
  /// `this`.
  Iterable<AtomicExpression> successors(final Expression child);
}

///
abstract class AtomicExpression extends Expression {
  AtomicExpression(this._repetition);

  final Repetition _repetition;

  @override
  Iterable<AtomicExpression> get leafs => [this];
  @override
  Iterable<AtomicExpression> get first => [this];
  @override
  Iterable<AtomicExpression> get last => [this];

  /// Returns all states that are reachable from this state with a single
  /// transition.
  Iterable<AtomicExpression> get successors sync* {
    if (_repetition.repeat) yield this;
    if (parent != null) yield* parent.successors(this);
  }

  @override
  bool get optional => _repetition.optional;
}

class Literal extends AtomicExpression {
  Literal(this.codePoint, [Repetition repetition = Repetition.one])
      : super(repetition);

  final int codePoint;

  @override
  String toString() => '${String.fromCharCode(codePoint)}$_repetition';
}

class CharacterSet extends AtomicExpression {
  CharacterSet(this.codePoints,
      {this.negated = false, Repetition repetition = Repetition.one})
      : super(repetition);

  final List<Range> codePoints;
  final bool negated;

  @override
  String toString() {
    final contents = StringBuffer('[');
    if (negated) contents.write('^');
    for (final range in codePoints) {
      contents.writeCharCode(range.min);
      if (range.min != range.max) {
        contents
          ..write('-')
          ..writeCharCode(range.max);
      }
    }
    contents.write(']');
    return contents.toString();
  }
}

class Wildcard extends AtomicExpression {
  Wildcard([Repetition repetition = Repetition.one]) : super(repetition);

  @override
  String toString() => '.$_repetition';
}

class Group extends Expression implements _Parent {
  Group(this.child, [this._repetition = Repetition.one]) {
    assert(child._parent == null, '$child is already assigned to a parent');
    child
      .._parent = this
      .._parentIndex = 0;
  }

  final Expression child;
  final Repetition _repetition;

  @override
  Iterable<AtomicExpression> get leafs => child.leafs;
  @override
  Iterable<AtomicExpression> get first => child.first;
  @override
  Iterable<AtomicExpression> get last => child.last;

  @override
  Iterable<AtomicExpression> successors(Expression child) sync* {
    assert(child == this.child);
    if (_repetition.repeat) yield* child.first;
    if (parent != null) yield* parent.successors(this);
  }

  @override
  bool get optional => _repetition.optional || child.optional;

  @override
  String toString() => '($child)$_repetition';
}

abstract class CompositeExpression extends Expression implements _Parent {
  CompositeExpression(Iterable<Expression> children)
      : children = List.unmodifiable(children),
        assert(children.isNotEmpty) {
    for (var i = 0; i < this.children.length; i++) {
      assert(this.children[i]._parent == null,
          '${this.children[i]} is already assigned to a parent');
      this.children[i]
        .._parent = this
        .._parentIndex = i;
    }
  }

  final List<Expression> children;

  @override
  Iterable<AtomicExpression> get leafs =>
      children.expand((child) => child.leafs);
}

/// A sequence matches iff all of its children match in order. This represents
/// the concatenation of e.g. _`a`, then `b`_ in the expression `ab`.
class Sequence extends CompositeExpression {
  Sequence(Iterable<Expression> children) : super(children);

  @override
  Iterable<AtomicExpression> get first sync* {
    for (final child in children) {
      yield* child.first;
      if (!child.optional) return;
    }
  }

  @override
  Iterable<AtomicExpression> get last sync* {
    for (final child in children.reversed) {
      yield* child.last;
      if (!child.optional) return;
    }
  }

  @override
  Iterable<AtomicExpression> successors(Expression child) sync* {
    assert(child.parent == this);
    for (var i = child._parentIndex + 1; i < children.length; i++) {
      yield* children[i].first;
      if (!children[i].optional) return;
    }
    if (parent != null) yield* parent.successors(this);
  }

  @override
  bool get optional => children.every((child) => child.optional);

  @override
  String toString() => children.join('');
}

/// An alternation matches iff any of its children matches. This represents e.g.
/// _`a` or `b` or_ in the expression `a|b`.
class Alternation extends CompositeExpression {
  Alternation(Iterable<Expression> children) : super(children);

  @override
  Iterable<AtomicExpression> get first =>
      children.expand((child) => child.first);

  @override
  Iterable<AtomicExpression> get last => children.expand((child) => child.last);

  @override
  Iterable<AtomicExpression> successors(final Expression child) sync* {
    assert(child.parent == this);
    if (parent != null) yield* parent.successors(this);
  }

  @override
  bool get optional => children.any((child) => child.optional);

  @override
  String toString() => children.join('|');
}

/// Pseudo-enum that represents the possible repetition specifiers `+`, `?` and
/// `*` as well as the default repetition _not optional, don't repeat_.
class Repetition {
  const Repetition._(this._stringRepresentation, this.optional, this.repeat);

  static const Repetition one = Repetition._('', false, false);
  static const Repetition oneOrMore = Repetition._('+', false, true);
  static const Repetition zeroOrOne = Repetition._('?', true, false);
  static const Repetition zeroOrMore = Repetition._('*', true, true);

  static const List<Repetition> values = [
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
