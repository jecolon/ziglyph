const values = @import("values.zig");
const tables = @import("tables.zig");

const Digit = values.Digit;
const Letter = values.Letter;
const Mark = values.Mark;
const Number = values.Number;
const Punct = values.Punct;
const Space = values.Space;
const Symbol = values.Symbol;
const rune = values.rune;
const L = values.L;
const M = values.M;
const N = values.N;
const P = values.P;
const S = values.S;
const Zs = values.Zs;

const isExcludingLatin = tables.isExcludingLatin;
const max_latin_1 = values.max_latin_1;
const pC = values.pC;
const pN = values.pN;
const pP = values.pP;
const pS = values.pS;
const pg = values.pg;
const pp = values.pp;
const pLmask = values.pLmask;
const properties = values.properties;
const range_tables = tables.range_tables;
const runeIs = tables.runeIs;

/// inGraphicRanges checks whether a rune is a graphic character.
pub fn inGraphicRanges(r: rune) bool {
    if (runeIs(range_tables[@enumToInt(L)], r)) {
        return true;
    } else if (runeIs(range_tables[@enumToInt(M)], r)) {
        return true;
    } else if (runeIs(range_tables[@enumToInt(N)], r)) {
        return true;
    } else if (runeIs(range_tables[@enumToInt(P)], r)) {
        return true;
    } else if (runeIs(range_tables[@enumToInt(S)], r)) {
        return true;
    } else if (runeIs(range_tables[@enumToInt(Zs)], r)) {
        return true;
    } else return false;
}

/// inPrintRanges checks whether a rune is a printable character.
/// ASCII space, U+0020, is handled separately.
pub fn inPrintRanges(r: rune) bool {
    if (runeIs(range_tables[@enumToInt(L)], r)) {
        return true;
    } else if (runeIs(range_tables[@enumToInt(M)], r)) {
        return true;
    } else if (runeIs(range_tables[@enumToInt(N)], r)) {
        return true;
    } else if (runeIs(range_tables[@enumToInt(P)], r)) {
        return true;
    } else if (runeIs(range_tables[@enumToInt(S)], r)) {
        return true;
    } else return false;
}

/// isGraphic reports whether the rune is defined as a Graphic by Unicode.
/// Such characters include letters, marks, numbers, punctuation, symbols, and
/// spaces, from categories L, M, N, P, S, Zs.
pub fn isGraphic(r: rune) bool {
    // We convert to u32 to avoid the extra test for negative,
    // and in the index we convert to u8 to avoid the range check.
    if (r <= max_latin_1) {
        return properties[r] & pg != 0;
    }
    return inGraphicRanges(r);
}

/// isPrint reports whether the rune is defined as printable by Go. Such
/// characters include letters, marks, numbers, punctuation, symbols, and the
/// ASCII space character, from categories L, M, N, P, S and the ASCII space
/// character. This categorization is the same as IsGraphic except that the
/// only spacing character is ASCII space, U+0020.
pub fn isPrint(r: rune) bool {
    if (r <= max_latin_1) {
        return properties[r] & pp != 0;
    }
    return inPrintRanges(r);
}

/// isControl reports whether the rune is a control character.
/// The C (Other) Unicode category includes more code points
/// such as surrogates; use Is(C, r) to test for them.
pub fn isControl(r: rune) bool {
    if (r <= max_latin_1) {
        return properties[r] & pC != 0;
    }
    // All control characters are < max_latin_1.
    return false;
}

/// isLetter reports whether the rune is a letter (category L).
pub fn isLetter(r: rune) bool {
    if (r <= max_latin_1) {
        return properties[r] & (pLmask) != 0;
    }
    return isExcludingLatin(range_tables[@enumToInt(Letter)], r);
}

/// isMark reports whether the rune is a mark character (category M).
pub fn isMark(r: rune) bool {
    // There are no mark characters in Latin-1.
    return isExcludingLatin(range_tables[@enumToInt(Mark)], r);
}

/// isNumber reports whether the rune is a number (category N).
pub fn isNumber(r: rune) bool {
    if (r <= max_latin_1) {
        return properties[r] & pN != 0;
    }
    return isExcludingLatin(range_tables[@enumToInt(Number)], r);
}

/// isPunct reports whether the rune is a Unicode punctuation character
/// (category P).
pub fn isPunct(r: rune) bool {
    if (r <= max_latin_1) {
        return properties[r] & pP != 0;
    }
    return runeIs(range_tables[@enumToInt(Punct)], r);
}

/// isSpace reports whether the rune is a space character as defined
/// by Unicode's White Space property; in the Latin-1 space
/// this is
///	'\t', '\n', '\v', '\f', '\r', ' ', U+0085 (NEL), U+00A0 (NBSP).
/// Other definitions of spacing characters are set by category
/// Z and property Pattern_White_Space.
pub fn isSpace(r: rune) bool {
    // This property isn't the same as Z; special-case it.
    if (r <= max_latin_1) {
        return switch (r) {
            '\t', '\n', '\r', ' ', 0x0B, 0x0C, 0x85, 0xA0 => true,
            else => false,
        };
    }
    return isExcludingLatin(range_tables[@enumToInt(Space)], r);
}

/// isSymbol reports whether the rune is a symbolic character.
pub fn isSymbol(r: rune) bool {
    if (r <= max_latin_1) {
        return properties[r] & pS != 0;
    }
    return isExcludingLatin(range_tables[@enumToInt(Symbol)], r);
}

/// isDigit reports whether the rune is a decimal digit.
pub fn isDigit(r: rune) bool {
    if (r <= max_latin_1) {
        return '0' <= r and r <= '9';
    }
    return isExcludingLatin(range_tables[@enumToInt(Digit)], r);
}
