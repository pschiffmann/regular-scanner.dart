import 'package:charcode/ascii.dart';
import 'package:regular_scanner/src/regexp/ast.dart';
import 'package:test/test.dart';

final Matcher throwsAssertionError =
    throwsA(const TypeMatcher<AssertionError>());

void main() {
  State state;
  setUp(() => state = Literal(65));

  group('Expression', () {
    test('property `repetition` can be set while the expression is not sealed',
        () {
      expect(() => state.repetition = Repetition.oneOrMore, returnsNormally);
    });

    test('becomes immutable after sealing it with a [Root]', () {
      Root(state, null);
      expect(
          () => state.repetition = Repetition.oneOrMore, throwsAssertionError);
    });
  });

  group('State', () {
    test('is its own successor if `repeat` is true', () {
      state.repetition = Repetition.oneOrMore;
      expect(state.successors, contains(state));
    });
  });

  group('DelegatingExpression', () {
    test("can't take children that are already assigned to another parent", () {
      expect(() => Sequence([state]), returnsNormally);
      expect(() => Sequence([state]), throwsAssertionError);
    });
  });

  group('Sequence', () {
    Expression a, b, c;
    Sequence sequence;
    setUp(() {
      a = Literal(65);
      b = Literal(66);
      c = Literal(67);
      sequence = Sequence([a, b, c]);
    });

    test('is optional if `repetition` is optional', () {
      sequence.repetition = Repetition.zeroOrOne;
      expect(sequence.optional, isTrue);
    });

    test('is optional if all children are optional', () {
      a.repetition = b.repetition = c.repetition = Repetition.zeroOrOne;
      expect(sequence.optional, isTrue);
    });

    test(
        'is not optional if one child is not optional '
        'and `repetition` is not optional', () {
      a.repetition = c.repetition = Repetition.zeroOrOne;
      expect(sequence.optional, isFalse);
    });

    test(
        '`first` returns all children up to and including '
        'the first non-optional child', () {
      a.repetition = c.repetition = Repetition.zeroOrOne;
      expect(sequence.first, equals([a, b]));
    });

    test(
        '`last` returns all children up to and including '
        'the first non-optional child', () {
      a.repetition = c.repetition = Repetition.zeroOrOne;
      expect(sequence.last, equals([c, b]));
    });

    test(
        '`siblings` returns all elements right of `child` up to and including '
        'the first non-optional child', () {
      b.repetition = Repetition.zeroOrOne;
      expect(sequence.siblings(a), equals([b, c]));
    });

    test('`siblings` wraps around if `sequence.repeat` is true', () {
      c.repetition = Repetition.zeroOrOne;
      a.repetition = Repetition.zeroOrOne;
      sequence.repetition = Repetition.oneOrMore;
      expect(sequence.siblings(b), equals([c, a, b]));
    });
  });

  group('Alternation', () {
    Expression a, b, c;
    Alternation alternation;
    setUp(() {
      a = Literal(65);
      b = Literal(66);
      c = Literal(67);
      alternation = Alternation([a, b, c]);
    });

    test('is optional if `repetition` is optional', () {
      alternation.repetition = Repetition.zeroOrOne;
      expect(alternation.optional, isTrue);
    });

    test('is optional if any child is optional', () {
      b.repetition = Repetition.zeroOrOne;
      expect(alternation.optional, isTrue);
    });

    test('`siblings` returns all elements if `sequence` wraps around', () {
      alternation.repetition = Repetition.oneOrMore;
      expect(alternation.siblings(b), equals([a, b, c]));
    });
  });

  test('Repetition union yields the property-wise maximum', () {
    for (final left in Repetition.values) {
      for (final right in Repetition.values) {
        final union = left | right;
        expect(union.optional, left.optional || right.optional);
        expect(union.repeat, left.repeat || right.repeat);
      }
    }
  });

  group('tree traversal example:', () {
    // a?(b?(cd|e+))*
    final a = Literal($a, Repetition.zeroOrOne);
    final b = Literal($b, Repetition.zeroOrOne);
    final c = Literal($c);
    final d = Literal($d);
    final e = Literal($e, Repetition.oneOrMore);
    final root = Root(
        Sequence([
          a,
          Sequence([
            b,
            Alternation([
              Sequence([c, d]),
              e
            ])
          ], Repetition.zeroOrMore)
        ]),
        null);

    test('finds correct `root.leafs`', () {
      expect(root.leafs, unorderedEquals([a, b, c, d, e]));
    });

    test('finds correct `root.first`', () {
      expect(root.first, unorderedEquals([a, b, c, e]));
    });

    test('finds correct `root.last`', () {
      expect(root.last, unorderedEquals([a, d, e]));
    });

    group('finds correct `successors`', () {
      test('of `a`', () => expect(a.successors, unorderedEquals([b, c, e])));
      test('of `b`', () => expect(b.successors, unorderedEquals([c, e])));
      test('of `c`', () => expect(c.successors, unorderedEquals([d])));
      test('of `d`', () => expect(d.successors, unorderedEquals([b, c, e])));
      test('of `e`',
          () => expect(e.successors.toSet(), unorderedEquals([b, c, e])));
    });
  });
}
