//! `number` contains functions related to Unicode numbers; category (N).

const std = @import("std");

const cats = @import("../autogen/derived_general_category.zig");
const numeric = @import("../autogen/derived_numeric_type.zig");
const props = @import("../autogen/prop_list.zig");

/// `isDecimal` detects all Unicode decimal numbers.
pub fn isDecimal(cp: u21) bool {
    // ASCII optimization.
    if ('0' <= cp and cp <= '9') return true;
    return numeric.isDecimal(cp);
}

/// `isDigit` detects all Unicode digits..
pub fn isDigit(cp: u21) bool {
    // ASCII optimization.
    if ('0' <= cp and cp <= '9') return true;
    return numeric.isDigit(cp) or isDecimal(cp);
}

/// `isAsciiDigit` detects ASCII only digits.
pub fn isAsciiDigit(cp: u21) bool {
    return '0' <= cp and cp <= '9';
}

/// `isHex` detects the 16 ASCII characters 0-9 A-F, and a-f.
pub fn isHexDigit(cp: u21) bool {
    // ASCII optimization.
    if (('a' <= cp and cp <= 'f') or ('A' <= cp and cp <= 'F') or (cp >= '0' and cp <= '9')) return true;
    return props.isHexDigit(cp);
}

/// `isAsciiHexDigit` detects ASCII only hexadecimal digits.
pub fn isAsciiHexDigit(cp: u21) bool {
    return ('a' <= cp and cp <= 'f') or ('A' <= cp and cp <= 'F') or (cp >= '0' and cp <= '9');
}

/// `isNumber` covers all Unicode numbers, not just ASII.
pub fn isNumber(cp: u21) bool {
    // ASCII optimization.
    if ('0' <= cp and cp <= '9') return true;
    return isDecimal(cp) or isDigit(cp) or cats.isLetterNumber(cp) or cats.isOtherNumber(cp);
}

/// isAsciiNumber detects ASCII only numbers.
pub fn isAsciiNumber(cp: u21) bool {
    return '0' <= cp and cp <= '9';
}

test "number isDecimal" {
    var cp: u21 = '0';
    while (cp <= '9') : (cp += 1) {
        try std.testing.expect(isDecimal(cp));
        try std.testing.expect(isAsciiDigit(cp));
        try std.testing.expect(isAsciiNumber(cp));
    }

    try std.testing.expect(!isDecimal('\u{0003}'));
    try std.testing.expect(!isDecimal('A'));
}

test "number isHexDigit" {
    var cp: u21 = '0';
    while (cp <= '9') : (cp += 1) {
        try std.testing.expect(isHexDigit(cp));
    }

    try std.testing.expect(!isHexDigit('\u{0003}'));
    try std.testing.expect(!isHexDigit('Z'));
}

test "number isNumber" {
    var cp: u21 = '0';
    while (cp <= '9') : (cp += 1) {
        try std.testing.expect(isNumber(cp));
    }

    try std.testing.expect(!isNumber('\u{0003}'));
    try std.testing.expect(!isNumber('A'));
}
