import 'package:flutter/material.dart';

/// Custom TextEditingController that provides syntax highlighting for 8051 assembly language
class AssemblySyntaxHighlightingController extends TextEditingController {
  final Brightness brightness;

  AssemblySyntaxHighlightingController({
    required this.brightness,
    String? text,
  }) : super(text: text);

  // Classic IDE color scheme - Dark theme
  static const Color _darkInstruction = Color(0xFFAE81FF); // Purple
  static const Color _darkComment = Color(0xFF75715E); // Muted green
  static const Color _darkNumber = Color(0xFFFD971F); // Orange
  static const Color _darkRegister = Color(0xFF66D9EF); // Cyan
  static const Color _darkDirective = Color(0xFFF92672); // Pink/red
  static const Color _darkLabel = Color(0xFFF8F8F2); // Off-white
  static const Color _darkDefault = Color(0xFFFFFFFF); // White

  // Classic IDE color scheme - Light theme
  static const Color _lightInstruction = Color(0xFF7C3AED); // Brighter purple
  static const Color _lightComment = Color(0xFF059669); // Teal green
  static const Color _lightNumber = Color(0xFFEA580C); // Brighter orange
  static const Color _lightRegister = Color(0xFF0891B2); // Brighter cyan
  static const Color _lightDirective = Color(0xFFDC2626); // Brighter red
  static const Color _lightLabel = Color(0xFF1F2937); // Dark gray
  static const Color _lightDefault = Color(0xFF000000); // Black

  // Token regex patterns
  static final RegExp _commentPattern = RegExp(r';.*$|//.*$', multiLine: true);

  static final RegExp _instructionPattern = RegExp(
    r'\b(MOV|MOVC|MOVX|ADD|ADDC|SUBB|INC|DEC|MUL|DIV|DA|'
    r'ANL|ORL|XRL|CLR|CPL|RL|RLC|RR|RRC|SWAP|'
    r'SETB|PUSH|POP|XCH|XCHD|'
    r'SJMP|LJMP|AJMP|JMP|JZ|JNZ|JC|JNC|JB|JNB|JBC|CJNE|DJNZ|'
    r'ACALL|LCALL|RET|RETI|NOP|AB)\b',
    caseSensitive: false,
  );

  static final RegExp _registerPattern = RegExp(
    r'\b(R[0-7]|A|B|C|DPTR|DPL|DPH|PC|SP|PSW|ACC|'
    r'P[0-3]|IE|IP|TCON|TMOD|TH[01]|TL[01]|SCON|SBUF|PCON)\b',
    caseSensitive: false,
  );

  static final RegExp _directivePattern = RegExp(
    r'\b(ORG|END|DB|DW|EQU)\b',
    caseSensitive: false,
  );

  static final RegExp _numberPattern = RegExp(
    r'#?0[xX][0-9A-Fa-f]+\b|'  // 0x notation with optional #
    r'#?[0-9A-Fa-f]+[hH]\b|'    // suffix h with optional #
    r'#?[01]+[bB]\b|'            // binary with b suffix
    r'#\d+\b|'                   // # prefix for immediate decimal
    r'\b\d+\b'                   // plain decimal
  );

  static final RegExp _labelPattern = RegExp(r'^\s*\w+:', multiLine: true);

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final String textContent = text;

    if (textContent.isEmpty) {
      return TextSpan(text: '', style: style);
    }

    // Get base colors based on theme
    final Color instructionColor = brightness == Brightness.dark ? _darkInstruction : _lightInstruction;
    final Color commentColor = brightness == Brightness.dark ? _darkComment : _lightComment;
    final Color numberColor = brightness == Brightness.dark ? _darkNumber : _lightNumber;
    final Color registerColor = brightness == Brightness.dark ? _darkRegister : _lightRegister;
    final Color directiveColor = brightness == Brightness.dark ? _darkDirective : _lightDirective;
    final Color labelColor = brightness == Brightness.dark ? _darkLabel : _lightLabel;
    final Color defaultColor = brightness == Brightness.dark ? _darkDefault : _lightDefault;

    // Create list of all token matches
    final List<_Token> tokens = [];

    // Find all comments first (they have highest priority)
    for (final match in _commentPattern.allMatches(textContent)) {
      tokens.add(_Token(match.start, match.end, _TokenType.comment));
    }

    // Find all other tokens only if they're not inside comments
    for (final match in _instructionPattern.allMatches(textContent)) {
      if (!_isInsideComment(match.start, tokens)) {
        tokens.add(_Token(match.start, match.end, _TokenType.instruction));
      }
    }

    for (final match in _registerPattern.allMatches(textContent)) {
      if (!_isInsideComment(match.start, tokens)) {
        tokens.add(_Token(match.start, match.end, _TokenType.register));
      }
    }

    for (final match in _directivePattern.allMatches(textContent)) {
      if (!_isInsideComment(match.start, tokens)) {
        tokens.add(_Token(match.start, match.end, _TokenType.directive));
      }
    }

    for (final match in _numberPattern.allMatches(textContent)) {
      if (!_isInsideComment(match.start, tokens)) {
        tokens.add(_Token(match.start, match.end, _TokenType.number));
      }
    }

    for (final match in _labelPattern.allMatches(textContent)) {
      if (!_isInsideComment(match.start, tokens)) {
        tokens.add(_Token(match.start, match.end, _TokenType.label));
      }
    }

    // Sort tokens by position
    tokens.sort((a, b) => a.start.compareTo(b.start));

    // Remove overlapping tokens (keep first occurrence)
    final List<_Token> cleanedTokens = [];
    int lastEnd = 0;
    for (final token in tokens) {
      if (token.start >= lastEnd) {
        cleanedTokens.add(token);
        lastEnd = token.end;
      }
    }

    // Build TextSpan children
    if (cleanedTokens.isEmpty) {
      return TextSpan(
        text: textContent,
        style: style?.copyWith(color: defaultColor),
      );
    }

    final List<TextSpan> children = [];
    int currentPosition = 0;

    for (final token in cleanedTokens) {
      // Add unstyled text before this token
      if (token.start > currentPosition) {
        children.add(TextSpan(
          text: textContent.substring(currentPosition, token.start),
          style: style?.copyWith(color: defaultColor),
        ));
      }

      // Add styled token
      final Color tokenColor;
      switch (token.type) {
        case _TokenType.comment:
          tokenColor = commentColor;
          break;
        case _TokenType.instruction:
          tokenColor = instructionColor;
          break;
        case _TokenType.register:
          tokenColor = registerColor;
          break;
        case _TokenType.directive:
          tokenColor = directiveColor;
          break;
        case _TokenType.number:
          tokenColor = numberColor;
          break;
        case _TokenType.label:
          tokenColor = labelColor;
          break;
      }

      children.add(TextSpan(
        text: textContent.substring(token.start, token.end),
        style: style?.copyWith(color: tokenColor),
      ));

      currentPosition = token.end;
    }

    // Add remaining unstyled text
    if (currentPosition < textContent.length) {
      children.add(TextSpan(
        text: textContent.substring(currentPosition),
        style: style?.copyWith(color: defaultColor),
      ));
    }

    return TextSpan(children: children, style: style);
  }

  /// Check if a position is inside a comment token
  bool _isInsideComment(int position, List<_Token> tokens) {
    for (final token in tokens) {
      if (token.type == _TokenType.comment &&
          position >= token.start &&
          position < token.end) {
        return true;
      }
    }
    return false;
  }
}

/// Token type enumeration
enum _TokenType {
  comment,
  instruction,
  register,
  directive,
  number,
  label,
}

/// Internal token class for tracking matched tokens
class _Token {
  final int start;
  final int end;
  final _TokenType type;

  _Token(this.start, this.end, this.type);
}
