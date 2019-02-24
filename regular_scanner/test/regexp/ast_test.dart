import 'package:regular_scanner/src/regex/ast.dart';
import 'package:regular_scanner/src/regex/parser.dart';
import 'package:test/test.dart';

void main() {
  final alt1 = parse(r'a(b?c?|d*ef)+g.|[i-j][^k]') as Alternation;
  final seq1 = alt1.children[0] as Sequence; // a(b?c?|d*ef)+g.
  final a = seq1.children[0] as Literal;
  final group = seq1.children[1] as Group; // (b?c?|d*ef)+
  final alt2 = group.child as Alternation; // b?c?|d*ef
  final seq2 = alt2.children[0] as Sequence; // b?c?
  final b = seq2.children[0] as Literal;
  final c = seq2.children[1] as Literal;
  final seq3 = alt2.children[1] as Sequence; // d*ef
  final d = seq3.children[0] as Literal;
  final e = seq3.children[1] as Literal;
  final f = seq3.children[2] as Literal;
  final g = seq1.children[2] as Literal;
  final dot = seq1.children[3] as Wildcard;
  final seq4 = alt1.children[1] as Sequence; // [i-j][^k]
  final setij = seq4.children[0] as CharacterSet;
  final setk = seq4.children[1] as CharacterSet;

  test('Expression.optional', () {
    expect(alt1.optional, isFalse);
    expect(seq1.optional, isFalse);
    expect(group.optional, isTrue);
    expect(alt2.optional, isTrue);
    expect(seq2.optional, isTrue);
    expect(seq3.optional, isFalse);
    expect(seq4.optional, isFalse);
  });

  test('Expression.leafs finds all AtomicExpressions',
      () => expect(alt1.leafs, [a, b, c, d, e, f, g, dot, setij, setk]));

  test('Expression.first finds all first leafs', () {
    expect(alt1.first, unorderedEquals([a, setij]));
    expect(seq1.first, unorderedEquals([a]));
    expect(alt2.first, unorderedEquals([b, c, d, e]));
    expect(seq2.first, unorderedEquals([b, c]));
    expect(seq3.first, unorderedEquals([d, e]));
    expect(seq4.first, unorderedEquals([setij]));
  });

  test('Expression.last finds all last leafs', () {
    expect(alt1.last, unorderedEquals([setk, dot]));
    expect(seq1.last, unorderedEquals([dot]));
    expect(alt2.last, unorderedEquals([f, c, b]));
    expect(seq2.last, unorderedEquals([c, b]));
    expect(seq3.last, unorderedEquals([f]));
    expect(seq4.last, unorderedEquals([setk]));
  });

  test('_Parent.successors()', () {
    expect(alt1.successors(seq1).toSet(), isEmpty);
    expect(alt1.successors(seq4).toSet(), isEmpty);

    expect(seq1.successors(a).toSet(), unorderedEquals([b, c, d, e, g]));
    expect(seq1.successors(group).toSet(), unorderedEquals([g]));
    expect(seq1.successors(g).toSet(), unorderedEquals([dot]));
    expect(seq1.successors(dot).toSet(), isEmpty);

    final groupSuccessors = unorderedEquals([b, c, d, e, g]);
    expect(group.successors(alt2).toSet(), groupSuccessors);
    expect(alt2.successors(seq2).toSet(), groupSuccessors);
    expect(alt2.successors(seq3).toSet(), groupSuccessors);
    expect(seq2.successors(b).toSet(), groupSuccessors);
    expect(seq2.successors(c).toSet(), groupSuccessors);

    expect(seq3.successors(d).toSet(), unorderedEquals([e]));
    expect(seq3.successors(e).toSet(), unorderedEquals([f]));
    expect(seq3.successors(f).toSet(), groupSuccessors);

    expect(seq4.successors(setij).toSet(), unorderedEquals([setk]));
    expect(seq4.successors(setk).toSet(), isEmpty);
  });

  test('AtomicExpression.successors', () {
    expect(a.successors.toSet(), unorderedEquals([b, c, d, e, g]));
    expect(b.successors.toSet(), unorderedEquals([b, c, d, e, g]));
    expect(c.successors.toSet(), unorderedEquals([b, c, d, e, g]));
    expect(d.successors.toSet(), unorderedEquals([d, e]));
    expect(e.successors.toSet(), unorderedEquals([f]));
    expect(f.successors.toSet(), unorderedEquals([b, c, d, e, g]));
    expect(g.successors.toSet(), unorderedEquals([dot]));
    expect(dot.successors.toSet(), isEmpty);
    expect(setij.successors.toSet(), unorderedEquals([setk]));
    expect(setk.successors.toSet(), isEmpty);
  });
}
