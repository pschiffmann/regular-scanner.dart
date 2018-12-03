// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'main.dart';

// **************************************************************************
// TableDrivenScannerGenerator
// **************************************************************************

const _$scanner = Scanner<NamedRegex>.withParseTable([], [
  State([
    Transition(9, 10, 1),
    Transition(13, 13, 1),
    Transition(32, 32, 1),
    Transition(48, 48, 2),
    Transition(49, 57, 3),
  ], defaultTransition: -1),
  State([
    Transition(9, 10, 1),
    Transition(13, 13, 1),
    Transition(32, 32, 1),
  ], defaultTransition: -1, accept: whitespace),
  State([
    Transition(48, 55, 4),
    Transition(56, 57, 3),
    Transition(98, 98, 5),
    Transition(120, 120, 6),
  ],
      defaultTransition: -1,
      accept: NamedRegex('[0-9]+', 'decimal', precedence: 0)),
  State([
    Transition(48, 57, 3),
  ],
      defaultTransition: -1,
      accept: NamedRegex('[0-9]+', 'decimal', precedence: 0)),
  State([
    Transition(48, 55, 4),
    Transition(56, 57, 3),
  ],
      defaultTransition: -1,
      accept: NamedRegex('0[0-7]+', 'octal', precedence: 1)),
  State([
    Transition(48, 49, 7),
  ], defaultTransition: -1),
  State([
    Transition(48, 57, 8),
    Transition(65, 70, 8),
    Transition(97, 102, 8),
  ], defaultTransition: -1),
  State([
    Transition(48, 49, 7),
  ], defaultTransition: -1, accept: NamedRegex('0b[01]+', 'binary')),
  State([
    Transition(48, 57, 8),
    Transition(65, 70, 8),
    Transition(97, 102, 8),
  ],
      defaultTransition: -1,
      accept: NamedRegex('0x[0-9A-Fa-f]+', 'hexadecimal')),
]);
