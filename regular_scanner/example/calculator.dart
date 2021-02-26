import 'dart:math';

import 'package:lookaround_iterator/lookaround_iterator.dart';
import 'package:regular_scanner/regular_scanner.dart';

const lparen = Regex(r'\(');
const rparen = Regex(r'\)');
const binNum = Regex(r'-?0b[01]+');
const decNum = Regex(r'-?[0-9]+');
const hexNum = Regex(r'-?0x[0-9A-Fa-f]+');
const opAdd = Regex(r'\+');
const opSub = Regex(r'-');
const opMul = Regex(r'\*');
const opDiv = Regex(r'/');
const opPow = Regex(r'\*\*');
const whitespace = Regex(r'\s+');

final scanner = Scanner.unambiguous([
  lparen,
  rparen,
  binNum,
  decNum,
  hexNum,
  opAdd,
  opSub,
  opMul,
  opDiv,
  opPow,
  whitespace
]);

const radix = {binNum: 2, decNum: 10, hexNum: 16};
const precedenceMap = {'+': 1, '-': 1, '*': 2, '/': 2, '**': 3};

void main(List<String> args) {
  if (args.isEmpty) {
    print('Enter a basic arithmetic expression to evaluate');
    return;
  }
  for (final expr in args) {
    try {
      final tokens = scan(expr);
      final ast = parse(LookaroundIterator(tokens.iterator, lookahead: 1));
      print('$expr = ${ast.evaluate()}');
    } on FormatException catch (e) {
      print(e);
    }
  }
}

Iterable scan(String expr) sync* {
  var position = 0;
  while (position < expr.length) {
    final m = scanner.matchAsPrefix(expr, position);
    if (m == null) {
      throw FormatException('Unexpected character');
    }
    position = m.end;
    switch (m.regex) {
      case whitespace:
        break;
      case binNum:
      case decNum:
      case hexNum:
        yield int.parse(m.capture, radix: radix[m.regex]);
        break;
      case opAdd:
      case opSub:
      case opMul:
      case opDiv:
      case opPow:
      case lparen:
      case rparen:
        yield m.capture;
        break;
    }
  }
}

/// [tokens] must be an iterator of [int] and [String]s, with a lookahead of 1.
///
/// Simplified version of:
/// http://journal.stuffwithstuff.com/2011/03/19/pratt-parsers-expression-parsing-made-easy/
Expression parse(LookaroundIterator tokens, [int precedence = 0]) {
  var left = parsePrefix(tokens);
  while (precedence < (precedenceMap[tokens.current] ?? 0)) {
    final token = tokens.current;
    tokens.moveNext();
  }
  return null;
}

Expression parsePrefix(LookaroundIterator tokens) {
  final token = tokens.current;
  tokens.moveNext();
  if (token is int) {
    return Value(token);
  } else if (token == '(') {
    final result = parse(tokens);
    if (tokens.current != ')') {
      throw FormatException('Missing `)`');
    }
    tokens.moveNext();
    return result;
  } else {
    throw FormatException('Unexpected token');
  }
}

abstract class Expression {
  num evaluate();
}

class Value implements Expression {
  Value(this.value);
  final num value;
  @override
  num evaluate() => value;
}

class BinaryExpression implements Expression {
  BinaryExpression(this.left, this.op, this.right)
      : assert({'+', '-', '*', '/', '**'}.contains(op));
  final Expression left;
  final Expression right;
  final String op;
  @override
  num evaluate() {
    switch (op) {
      case '+':
        return left.evaluate() + right.evaluate();
      case '-':
        return left.evaluate() - right.evaluate();
      case '*':
        return left.evaluate() * right.evaluate();
      case '/':
        return left.evaluate() / right.evaluate();
      case '**':
        return pow(left.evaluate(), right.evaluate());
    }
    throw UnimplementedError();
  }
}
