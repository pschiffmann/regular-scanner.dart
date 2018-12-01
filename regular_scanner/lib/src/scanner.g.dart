// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scanner.dart';

// **************************************************************************
// TableDrivenScannerGenerator
// **************************************************************************

const _$defaultContextScanner = Scanner<TokenType>.withParseTable([], [
  State([
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
  State([], defaultTransition: -1, accept: groupStart),
  State([], defaultTransition: -1, accept: groupEnd),
  State([], defaultTransition: -1, accept: repetition),
  State([], defaultTransition: -1, accept: dot),
  State([], defaultTransition: -1, accept: characterSetStart),
  State([
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
  State([], defaultTransition: -1, accept: characterSetEnd),
  State([], defaultTransition: -1, accept: choice),
  State([], defaultTransition: -1, accept: _defaultContextEscapes),
  State([], defaultTransition: -1, accept: _controlCharacterEscape),
  State([], defaultTransition: -1, accept: characterSetAlias),
  State([
    Transition(123, 123, 14),
  ], defaultTransition: -1),
  State([], defaultTransition: -1, accept: _sharedContextEscapes),
  State([
    Transition(48, 57, 15),
    Transition(65, 70, 15),
    Transition(97, 102, 15),
  ], defaultTransition: -1),
  State([
    Transition(48, 57, 15),
    Transition(65, 70, 15),
    Transition(97, 102, 15),
    Transition(125, 125, 16),
  ], defaultTransition: -1),
  State([], defaultTransition: -1, accept: _unicodeEscape),
]);

const _$characterSetScanner = Scanner<TokenType>.withParseTable([], [
  State([
    Transition(45, 45, 1),
    Transition(91, 91, 2),
    Transition(92, 92, 3),
    Transition(93, 93, 4),
    Transition(94, 94, 5),
  ], defaultTransition: -1),
  State([], defaultTransition: -1, accept: rangeSeparator),
  State([], defaultTransition: -1, accept: characterSetStart),
  State([
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
  State([], defaultTransition: -1, accept: characterSetEnd),
  State([], defaultTransition: -1, accept: negation),
  State([], defaultTransition: -1, accept: _characterSetEscapes),
  State([], defaultTransition: -1, accept: _controlCharacterEscape),
  State([
    Transition(123, 123, 10),
  ], defaultTransition: -1),
  State([], defaultTransition: -1, accept: _sharedContextEscapes),
  State([
    Transition(48, 57, 11),
    Transition(65, 70, 11),
    Transition(97, 102, 11),
  ], defaultTransition: -1),
  State([
    Transition(48, 57, 11),
    Transition(65, 70, 11),
    Transition(97, 102, 11),
    Transition(125, 125, 12),
  ], defaultTransition: -1),
  State([], defaultTransition: -1, accept: _unicodeEscape),
]);
