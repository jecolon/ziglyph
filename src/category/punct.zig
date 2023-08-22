//! `punct` containes functions related to Unicode punctuation code points; category (P).

const std = @import("std");

const cats = @import("../autogen/derived_general_category.zig");

/// `isPunct` detects punctuation characters. Note some punctuation maybe considered symbols by Unicode.
pub fn isPunct(cp: u21) bool {
    return cats.isClosePunctuation(cp) or cats.isConnectorPunctuation(cp) or
        cats.isDashPunctuation(cp) or cats.isFinalPunctuation(cp) or
        cats.isInitialPunctuation(cp) or cats.isOpenPunctuation(cp) or
        cats.isOtherPunctuation(cp);
}

test "punct isPunct" {
    try std.testing.expect(isPunct('!'));
    try std.testing.expect(isPunct('?'));
    try std.testing.expect(isPunct(','));
    try std.testing.expect(isPunct('.'));
    try std.testing.expect(isPunct(':'));
    try std.testing.expect(isPunct(';'));
    try std.testing.expect(isPunct('\''));
    try std.testing.expect(isPunct('"'));
    try std.testing.expect(isPunct('¿'));
    try std.testing.expect(isPunct('¡'));
    try std.testing.expect(isPunct('-'));
    try std.testing.expect(isPunct('('));
    try std.testing.expect(isPunct(')'));
    try std.testing.expect(isPunct('{'));
    try std.testing.expect(isPunct('}'));
    try std.testing.expect(isPunct('–'));
    // Punct? in Unicode.
    try std.testing.expect(isPunct('@'));
    try std.testing.expect(isPunct('#'));
    try std.testing.expect(isPunct('%'));
    try std.testing.expect(isPunct('&'));
    try std.testing.expect(isPunct('*'));
    try std.testing.expect(isPunct('_'));
    try std.testing.expect(isPunct('/'));
    try std.testing.expect(isPunct('\\'));
    try std.testing.expect(!isPunct('\u{0003}'));
}
