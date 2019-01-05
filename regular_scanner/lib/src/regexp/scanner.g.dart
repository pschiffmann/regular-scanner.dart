// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scanner.dart';

// **************************************************************************
// TableDrivenScannerGenerator
// **************************************************************************

const _$defaultContextScanner = StateMachineScanner<TokenType>([
  DState([
    Transition(40, 40, 1),
    Transition(41, 41, 2),
    Transition(42, 43, 3),
    Transition(46, 46, 4),
    Transition(63, 63, 3),
    Transition(91, 91, 5),
    Transition(92, 92, 6),
    Transition(93, 93, 7),
    Transition(124, 124, 8),
  ], defaultTransition: -1),
  DState([], defaultTransition: -1, accept: groupStart),
  DState([], defaultTransition: -1, accept: groupEnd),
  DState([], defaultTransition: -1, accept: repetition),
  DState([], defaultTransition: -1, accept: dot),
  DState([], defaultTransition: -1, accept: characterSetStart),
  DState([
    Transition(40, 43, 9),
    Transition(46, 46, 9),
    Transition(48, 48, 10),
    Transition(63, 63, 9),
    Transition(68, 68, 11),
    Transition(83, 83, 11),
    Transition(85, 85, 12),
    Transition(87, 87, 11),
    Transition(91, 93, 13),
    Transition(100, 100, 11),
    Transition(102, 102, 10),
    Transition(110, 110, 10),
    Transition(114, 114, 10),
    Transition(115, 115, 11),
    Transition(116, 116, 10),
    Transition(117, 117, 12),
    Transition(118, 118, 10),
    Transition(119, 119, 11),
    Transition(124, 124, 9),
  ], defaultTransition: -1),
  DState([], defaultTransition: -1, accept: characterSetEnd),
  DState([], defaultTransition: -1, accept: choice),
  DState([], defaultTransition: -1, accept: _defaultContextEscapes),
  DState([], defaultTransition: -1, accept: _controlCharacterEscape),
  DState([], defaultTransition: -1, accept: characterSetAlias),
  DState([
    Transition(123, 123, 14),
  ], defaultTransition: -1),
  DState([], defaultTransition: -1, accept: _sharedContextEscapes),
  DState([
    Transition(48, 57, 15),
    Transition(65, 70, 15),
    Transition(97, 102, 15),
  ], defaultTransition: -1),
  DState([
    Transition(48, 57, 15),
    Transition(65, 70, 15),
    Transition(97, 102, 15),
    Transition(125, 125, 16),
  ], defaultTransition: -1),
  DState([], defaultTransition: -1, accept: _unicodeEscape),
]);

const _$characterSetScanner = StateMachineScanner<TokenType>([
  DState([
    Transition(45, 45, 1),
    Transition(91, 91, 2),
    Transition(92, 92, 3),
    Transition(93, 93, 4),
    Transition(94, 94, 5),
  ], defaultTransition: -1),
  DState([], defaultTransition: -1, accept: rangeSeparator),
  DState([], defaultTransition: -1, accept: characterSetStart),
  DState([
    Transition(45, 45, 6),
    Transition(48, 48, 7),
    Transition(85, 85, 8),
    Transition(91, 93, 9),
    Transition(94, 94, 6),
    Transition(102, 102, 7),
    Transition(110, 110, 7),
    Transition(114, 114, 7),
    Transition(116, 116, 7),
    Transition(117, 117, 8),
    Transition(118, 118, 7),
  ], defaultTransition: -1),
  DState([], defaultTransition: -1, accept: characterSetEnd),
  DState([], defaultTransition: -1, accept: negation),
  DState([], defaultTransition: -1, accept: _characterSetEscapes),
  DState([], defaultTransition: -1, accept: _controlCharacterEscape),
  DState([
    Transition(123, 123, 10),
  ], defaultTransition: -1),
  DState([], defaultTransition: -1, accept: _sharedContextEscapes),
  DState([
    Transition(48, 57, 11),
    Transition(65, 70, 11),
    Transition(97, 102, 11),
  ], defaultTransition: -1),
  DState([
    Transition(48, 57, 11),
    Transition(65, 70, 11),
    Transition(97, 102, 11),
    Transition(125, 125, 12),
  ], defaultTransition: -1),
  DState([], defaultTransition: -1, accept: _unicodeEscape),
]);
