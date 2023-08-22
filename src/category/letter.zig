//! `letter` provides functions for hte Letter (L) Unicode category.

const std = @import("std");

const case_fold_map = @import("../autogen/case_folding.zig");
const props = @import("../autogen/derived_core_properties.zig");
const cats = @import("../autogen/derived_general_category.zig");
const lower_map = @import("../autogen/lower_map.zig");
const title_map = @import("../autogen/title_map.zig");
const upper_map = @import("../autogen/upper_map.zig");

/// `isCased` detects letters that can be either upper, lower, or title cased.
pub fn isCased(cp: u21) bool {
    // ASCII optimization.
    if (('A' <= cp and cp <= 'Z') or ('a' <= cp and cp <= 'z')) return true;
    return props.isCased(cp);
}

/// `isLetter` covers all letters in Unicode, not just ASCII.
pub fn isLetter(cp: u21) bool {
    // ASCII optimization.
    if (('A' <= cp and cp <= 'Z') or ('a' <= cp and cp <= 'z')) return true;
    return cats.isLowercaseLetter(cp) or cats.isModifierLetter(cp) or cats.isOtherLetter(cp) or
        cats.isTitlecaseLetter(cp) or cats.isUppercaseLetter(cp);
}

/// `isAscii` detects ASCII only letters.
pub fn isAsciiLetter(cp: u21) bool {
    return ('A' <= cp and cp <= 'Z') or ('a' <= cp and cp <= 'z');
}

/// `isLower` detects code points that are lowercase.
pub fn isLower(cp: u21) bool {
    // ASCII optimization.
    if ('a' <= cp and cp <= 'z') return true;
    return props.isLowercase(cp);
}

/// `isAsciiLower` detects ASCII only lowercase letters.
pub fn isAsciiLower(cp: u21) bool {
    return 'a' <= cp and cp <= 'z';
}

/// `isTitle` detects code points in titlecase.
pub fn isTitle(cp: u21) bool {
    return cats.isTitlecaseLetter(cp);
}

/// `isUpper` detects code points in uppercase.
pub fn isUpper(cp: u21) bool {
    // ASCII optimization.
    if (('A' <= cp and cp <= 'Z')) return true;
    return props.isUppercase(cp);
}

/// `isAsciiUpper` detects ASCII only uppercase letters.
pub fn isAsciiUpper(cp: u21) bool {
    return 'A' <= cp and cp <= 'Z';
}

/// `toLower` returns the lowercase mapping for the given code point, or itself if none found.
pub fn toLower(cp: u21) u21 {
    // ASCII optimization.
    if ('A' <= cp and cp <= 'Z') return cp ^ 32;
    return lower_map.toLower(cp);
}

/// `toAsciiLower` converts an ASCII letter to lowercase.
pub fn toAsciiLower(cp: u21) u21 {
    return if ('A' <= cp and cp <= 'Z') cp ^ 32 else cp;
}

/// `toTitle` returns the titlecase mapping for the given code point, or itself if none found.
pub fn toTitle(cp: u21) u21 {
    return title_map.toTitle(cp);
}

/// `toUpper` returns the uppercase mapping for the given code point, or itself if none found.
pub fn toUpper(cp: u21) u21 {
    // ASCII optimization.
    if ('a' <= cp and cp <= 'z') return cp ^ 32;
    return upper_map.toUpper(cp);
}

/// `toAsciiUpper` converts an ASCII letter to uppercase.
pub fn toAsciiUpper(cp: u21) u21 {
    return if ('a' <= cp and cp <= 'z') cp ^ 32 else cp;
}

/// `toCaseFold` will convert a code point into its case folded equivalent. Note that this can result
/// in a mapping to more than one code point, known as the full case fold. The returned array has 3
/// elements and the code points span until the first element equal to 0 or the end, whichever is first.
pub fn toCaseFold(cp: u21) [3]u21 {
    return case_fold_map.toCaseFold(cp);
}

test "letter" {
    const z = 'z';
    try std.testing.expect(isLetter(z));
    try std.testing.expect(!isUpper(z));
    const uz = toUpper(z);
    try std.testing.expect(isUpper(uz));
    try std.testing.expectEqual(uz, 'Z');
}

test "letter isCased" {
    try std.testing.expect(isCased('a'));
    try std.testing.expect(isCased('A'));
    try std.testing.expect(!isCased('1'));
}

test "letter isLower" {
    try std.testing.expect(isLower('a'));
    try std.testing.expect(isAsciiLower('a'));
    try std.testing.expect(isLower('é'));
    try std.testing.expect(isLower('i'));
    try std.testing.expect(!isLower('A'));
    try std.testing.expect(!isLower('É'));
    try std.testing.expect(!isLower('İ'));
}

test "letter toCaseFold" {
    var result = toCaseFold('A');
    try std.testing.expectEqualSlices(u21, &[_]u21{ 'a', 0, 0 }, &result);

    result = toCaseFold('a');
    try std.testing.expectEqualSlices(u21, &[_]u21{ 'a', 0, 0 }, &result);

    result = toCaseFold('1');
    try std.testing.expectEqualSlices(u21, &[_]u21{ '1', 0, 0 }, &result);

    result = toCaseFold('\u{00DF}');
    try std.testing.expectEqualSlices(u21, &[_]u21{ 0x0073, 0x0073, 0 }, &result);

    result = toCaseFold('\u{0390}');
    try std.testing.expectEqualSlices(u21, &[_]u21{ 0x03B9, 0x0308, 0x0301 }, &result);
}

test "letter toLower" {
    try std.testing.expectEqual(toLower('a'), 'a');
    try std.testing.expectEqual(toLower('A'), 'a');
    try std.testing.expectEqual(toLower('İ'), 'i');
    try std.testing.expectEqual(toLower('É'), 'é');
    try std.testing.expectEqual(toLower(0x80), 0x80);
    try std.testing.expectEqual(toLower(0x80), 0x80);
    try std.testing.expectEqual(toLower('Å'), 'å');
    try std.testing.expectEqual(toLower('å'), 'å');
    try std.testing.expectEqual(toLower('\u{212A}'), 'k');
    try std.testing.expectEqual(toLower('1'), '1');
}

test "letter isUpper" {
    try std.testing.expect(!isUpper('a'));
    try std.testing.expect(!isAsciiUpper('a'));
    try std.testing.expect(!isUpper('é'));
    try std.testing.expect(!isUpper('i'));
    try std.testing.expect(isUpper('A'));
    try std.testing.expect(isUpper('É'));
    try std.testing.expect(isUpper('İ'));
}

test "letter toUpper" {
    try std.testing.expectEqual(toUpper('a'), 'A');
    try std.testing.expectEqual(toUpper('A'), 'A');
    try std.testing.expectEqual(toUpper('i'), 'I');
    try std.testing.expectEqual(toUpper('é'), 'É');
    try std.testing.expectEqual(toUpper(0x80), 0x80);
    try std.testing.expectEqual(toUpper('Å'), 'Å');
    try std.testing.expectEqual(toUpper('å'), 'Å');
    try std.testing.expectEqual(toUpper('1'), '1');
}

test "letter isTitle" {
    try std.testing.expect(!isTitle('a'));
    try std.testing.expect(!isTitle('é'));
    try std.testing.expect(!isTitle('i'));
    try std.testing.expect(isTitle('\u{1FBC}'));
    try std.testing.expect(isTitle('\u{1FCC}'));
    try std.testing.expect(isTitle('ǈ'));
}

test "letter toTitle" {
    try std.testing.expectEqual(toTitle('a'), 'A');
    try std.testing.expectEqual(toTitle('A'), 'A');
    try std.testing.expectEqual(toTitle('i'), 'I');
    try std.testing.expectEqual(toTitle('é'), 'É');
    try std.testing.expectEqual(toTitle('1'), '1');
}

test "letter isLetter" {
    var cp: u21 = 'a';
    while (cp <= 'z') : (cp += 1) {
        try std.testing.expect(isLetter(cp));
    }

    cp = 'A';
    while (cp <= 'Z') : (cp += 1) {
        try std.testing.expect(isLetter(cp));
    }

    try std.testing.expect(isLetter('É'));
    try std.testing.expect(isLetter('\u{2CEB3}'));
    try std.testing.expect(!isLetter('\u{0003}'));
}
