/// This library defines the [abstract syntax tree][1] structure for regular
/// expressions. For example, the expression `a(bc)+|[0-9]` would be represented
/// by the following snytax tree:
///
/// ```
/// Alternation
/// ├╴Sequence
/// │ ├╴Literal a
/// │ └╴Group+
/// │   └╴Sequence
/// │     ├╴Literal b
/// │     └╴Literal c
/// └╴CharacterSet
///   └╴Range 0..9
/// ```
///
/// Syntax trees are created by [parse] and consumed by [compile]. The ony API
/// used in [compile] are the methods and properties of the [Expression] and
/// [AtomicExpression] interfaces. Especially the methods of
/// [DelegatingExpression] are only relevant inside this library.
///
/// [1]: https://en.wikipedia.org/wiki/Abstract_syntax_tree
library regular_scanner.regex.ast;

import '../../state_machine.dart';
import '../range.dart';
import 'compiler.dart';
import 'parser.dart';

/// The basic interface shared by all expressions. All expressions are either
/// [AtomicExpression]s or [DelegatingExpression]s.
abstract class Expression {
  /// The parent of this expression, or `null` if this has no parent.
  ///
  /// The parent/child relationship is established by the constructor of the
  /// [DelegatingExpression]. An expression can only be child of a single
  /// parent; once [parent] is not `null`, passing it to an additional parent
  /// will cause an [AssertionError]. Assignment to the parent is irreversible.
  DelegatingExpression get parent => _parent;
  DelegatingExpression _parent;

  /// If [_parent] is a [_CompositeExpression], the index of this in
  /// [_CompositeExpression.children]. If [_parent] is a [Group], 0.
  int _parentIndex;

  /// All [AtomicExpression]s in this expression subtree.
  Iterable<AtomicExpression> get leafs;

  /// Returns all recursive children of type [AtomicExpression] in this subtree
  /// that can be reached with a single transition from a preceding expression.
  ///
  /// For example, in the expression `a(bc|de)`, [first] of the group `(bc|de)`
  /// contains the [Literal]s `b` and `d`.
  ///
  /// This property is used in two places:
  ///  1. This property tells [compile] which states are the successors of a
  ///     given state. For example, the successors of `a` are `b` and `d`.
  ///  2. The [first] set of the root expression is used by [compile] as the
  ///     successors of the start state.
  Iterable<AtomicExpression> get first;

  /// Returns all recursive children of this that can exit this subtree with a
  /// single transition.
  ///
  /// This property serves a single purpose: The [last] set of the root
  /// expression contains all accepting states of the expression.
  Iterable<AtomicExpression> get last;

  /// If `true`, this expression can match the empty string.
  ///
  /// This can happen if this expression is annotated with `*` or `?`, or if
  /// this is a [DelegatingExpression] and the children are [optional].
  bool get optional;
}

/// [AtomicExpression]s represent expressions that actually consume input
/// characters: [Literal], [CharacterSet] and [Wildcard].
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
  ///
  /// May contain duplicates. For example, in the expression `(a+)+`, both the
  /// `a+` [Literal] and the `()+` [Group] will wrap around and report `a` as a
  /// successor of itself. Use [Iterable.toSet] on the result of this to filter
  /// out duplicates.
  Iterable<AtomicExpression> get successors sync* {
    if (_repetition.repeat) yield this;
    if (parent != null) yield* parent.successors(this);
  }

  @override
  bool get optional => _repetition.optional;
}

/// [DelegatingExpression]s don't consume input characters directly, but
/// delegate this work to their children.
///
/// A [DelegatingExpression] claims ownership of its children when it is
/// created. Passing an expression that already has a [Expression.parent] to a
/// [DelegatingExpression] constructor will cause an [AssertionError].
abstract class DelegatingExpression extends Expression {
  /// Returns all successors of [child] that it can reach with a single
  /// transition, including successors from [parent]. `child.parent` must be
  /// `this`.
  ///
  /// May contain duplicates. See [AtomicExpression.successors] for details.
  Iterable<AtomicExpression> successors(final Expression child);
}

/// Represents a single literal character pattern, like `a*`.
class Literal extends AtomicExpression {
  Literal(this.codePoint, [Repetition repetition = Repetition.one])
      : super(repetition);

  final int codePoint;

  @override
  String toString() => '${String.fromCharCode(codePoint)}$_repetition';
}

/// Represents a character set pattern, like `[A-Za-z_]`.
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

/// Represents the wildcard pattern `.`.
class Wildcard extends AtomicExpression {
  Wildcard([Repetition repetition = Repetition.one]) : super(repetition);

  @override
  String toString() => '.$_repetition';
}

/// Represents the grouping operator `()`.
class Group extends DelegatingExpression {
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

/// Superclass for [Alternation] and [Sequence] to share code. A composite
/// expression is a [DelegatingExpression] that has multiple children.
abstract class _CompositeExpression extends DelegatingExpression {
  _CompositeExpression(Iterable<Expression> children)
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

/// Represents the concatenation of e.g. _`a`, then `b`_ in the expression `ab`.
class Sequence extends _CompositeExpression {
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

/// Represents e.g. _`a` or `b`_ in the expression `a|b`.
class Alternation extends _CompositeExpression {
  Alternation(Iterable<Expression> children) : super(children);

  @override
  Iterable<AtomicExpression> get first =>
      children.expand((child) => child.first);

  @override
  Iterable<AtomicExpression> get last => children.expand((child) => child.last);

  @override
  Iterable<AtomicExpression> successors(final Expression child) {
    assert(child.parent == this);
    return parent != null ? parent.successors(this) : [];
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

  /// `true` for `*` and `?`.
  final bool optional;

  /// `true` for `+` and `*`.
  final bool repeat;

  /// Returns the union of this and [other]. [optional] and [repeat] of the
  /// result are `true` if the respective value is true in either this or
  /// [other].
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
