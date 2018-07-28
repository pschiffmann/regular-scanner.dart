// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'main.dart';

// **************************************************************************
// TableDrivenScannerGenerator
// **************************************************************************

const _$scanner = rs.Scanner<NamedPattern>.withParseTable([], [
  rs.State([
    rs.Transition(9, 10, 1),
    rs.Transition(13, 13, 1),
    rs.Transition(32, 32, 1),
    rs.Transition(48, 48, 2),
    rs.Transition(49, 57, 3),
  ], defaultTransition: -1),
  rs.State([
    rs.Transition(9, 10, 1),
    rs.Transition(13, 13, 1),
    rs.Transition(32, 32, 1),
  ], defaultTransition: -1, accept: whitespace),
  rs.State([
    rs.Transition(48, 55, 4),
    rs.Transition(56, 57, 3),
    rs.Transition(98, 98, 5),
    rs.Transition(120, 120, 6),
  ],
      defaultTransition: -1,
      accept: NamedPattern('[0-9]+', 'decimal', precedence: 0)),
  rs.State([
    rs.Transition(48, 57, 3),
  ],
      defaultTransition: -1,
      accept: NamedPattern('[0-9]+', 'decimal', precedence: 0)),
  rs.State([
    rs.Transition(48, 55, 4),
    rs.Transition(56, 57, 3),
  ],
      defaultTransition: -1,
      accept: NamedPattern('0[0-7]+', 'octal', precedence: 1)),
  rs.State([
    rs.Transition(48, 49, 7),
  ], defaultTransition: -1),
  rs.State([
    rs.Transition(48, 57, 8),
    rs.Transition(65, 70, 8),
    rs.Transition(97, 102, 8),
  ], defaultTransition: -1),
  rs.State([
    rs.Transition(48, 49, 7),
  ], defaultTransition: -1, accept: NamedPattern('0b[01]+', 'binary')),
  rs.State([
    rs.Transition(48, 57, 8),
    rs.Transition(65, 70, 8),
    rs.Transition(97, 102, 8),
  ],
      defaultTransition: -1,
      accept: NamedPattern('0x[0-9A-Fa-f]+', 'hexadecimal')),
]);
