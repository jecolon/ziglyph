//! Ziglyph provides Unicode processing in Zig.

const std = @import("std");
const mem = std.mem;
const testing = std.testing;
const unicode = std.unicode;
const ascii = @import("ascii.zig");

pub usingnamespace @import("components.zig");

pub fn isAlphabetic(cp: u21) bool {
    return DerivedCoreProperties.isAlphabetic(cp);
}

pub fn isAsciiAlphabetic(cp: u21) bool {
    return (cp >= 'A' and cp <= 'Z') or (cp >= 'a' and cp <= 'z');
}

pub fn isAlphaNum(cp: u21) bool {
    return isAlphabetic(cp) or isNumber(cp);
}

pub fn isAsciiAlphaNum(cp: u21) bool {
    return (cp >= 'A' and cp <= 'Z') or (cp >= 'a' and cp <= 'z') or (cp >= '0' and cp <= '9');
}

/// isCased detects cased code points, usually letters.
pub fn isCased(cp: u21) bool {
    return Letter.isCased(cp);
}

/// isCasedStr returns true when all code points in `s` can be mapped to a different case.
pub fn isCasedStr(s: []const u8) !bool {
    var iter = (try unicode.Utf8View.init(s)).iterator();

    return while (iter.nextCodepoint()) |cp| {
        if (!isCased(cp)) break false;
    } else true;
}

test "Ziglyph isCasedStr" {
    try testing.expect(try isCasedStr("abc"));
    try testing.expect(!try isCasedStr("abc123"));
    try testing.expect(!try isCasedStr("123"));
}

/// isDecimal detects all Unicode decimal numbers.
pub fn isDecimal(cp: u21) bool {
    return Number.isDecimal(cp);
}

/// isDigit detects all Unicode digits, which curiosly don't include the ASCII digits.
pub fn isDigit(cp: u21) bool {
    return Number.isDigit(cp);
}

pub fn isAsciiDigit(cp: u21) bool {
    return cp >= '0' and cp <= '9';
}

/// isGraphic detects any code point that can be represented graphically, including spaces.
pub fn isGraphic(cp: u21) bool {
    return isPrint(cp) or isWhiteSpace(cp);
}

pub fn isAsciiGraphic(cp: u21) bool {
    return ascii.isGraph(@intCast(u8, cp));
}

// isHex detects hexadecimal code points.
pub fn isHexDigit(cp: u21) bool {
    return Number.isHexDigit(cp);
}

pub fn isAsciiHexDigit(cp: u21) bool {
    return (cp >= 'a' and cp <= 'f') or (cp >= 'A' and cp <= 'F') or (cp >= '0' and cp <= '9');
}

/// isPrint detects any code point that can be printed, excluding spaces.
pub fn isPrint(cp: u21) bool {
    return isAlphaNum(cp) or isMark(cp) or isPunct(cp) or
        isSymbol(cp) or isWhiteSpace(cp);
}

pub fn isAsciiPrint(cp: u21) bool {
    return ascii.isPrint(@intCast(u8, cp));
}

pub fn isControl(cp: u21) bool {
    return DerivedGeneralCategory.isControl(cp);
}

pub fn isAsciiControl(cp: u21) bool {
    return ascii.isCntrl(@intCast(u8, cp));
}

pub fn isLetter(cp: u21) bool {
    return Letter.isLetter(cp);
}

pub fn isAsciiLetter(cp: u21) bool {
    return (cp >= 'A' and cp <= 'Z') or (cp >= 'a' and cp <= 'z');
}

/// isLower detects code points that are lowercase.
pub fn isLower(cp: u21) bool {
    return Letter.isLower(cp);
}

pub fn isAsciiLower(cp: u21) bool {
    return cp >= 'a' and cp <= 'z';
}

/// isLowerStr returns true when all code points in `s` are lowercase.
pub fn isLowerStr(s: []const u8) !bool {
    var iter = (try unicode.Utf8View.init(s)).iterator();

    return while (iter.nextCodepoint()) |cp| {
        if (isCased(cp) and !isLower(cp)) break false;
    } else true;
}

test "Ziglyph isLowerStr" {
    try testing.expect(try isLowerStr("abc"));
    try testing.expect(try isLowerStr("abc123"));
    try testing.expect(!try isLowerStr("Abc123"));
}

/// isMark detects special code points that serve as marks in different alphabets.
pub fn isMark(cp: u21) bool {
    return Mark.isMark(cp);
}

pub fn isNumber(cp: u21) bool {
    return Number.isNumber(cp);
}

pub fn isAsciiNumber(cp: u21) bool {
    return cp >= '0' and cp <= '9';
}

/// isPunct detects punctuation characters. Note some punctuation may be considered as symbols by Unicode.
pub fn isPunct(cp: u21) bool {
    return Punct.isPunct(cp);
}

pub fn isAsciiPunct(cp: u21) bool {
    return ascii.isPunct(@intCast(u8, cp));
}

/// isWhiteSpace detects code points that have the Unicode *WhiteSpace* property.
pub fn isWhiteSpace(cp: u21) bool {
    return PropList.isWhiteSpace(cp);
}

pub fn isAsciiWhiteSpace(cp: u21) bool {
    return ascii.isSpace(@intCast(u8, cp));
}

// isSymbol detects symbols which may include code points commonly considered punctuation.
pub fn isSymbol(cp: u21) bool {
    return Symbol.isSymbol(cp);
}

pub fn isAsciiSymbol(cp: u21) bool {
    return ascii.isSymbol(@intCast(u8, cp));
}

/// isTitle detects code points in titlecase.
pub fn isTitle(cp: u21) bool {
    return Letter.isTitle(cp);
}

/// isUpper detects code points in uppercase.
pub fn isUpper(cp: u21) bool {
    return Letter.isUpper(cp);
}

pub fn isAsciiUpper(cp: u21) bool {
    return cp >= 'A' and cp <= 'Z';
}

/// isUpperStr returns true when all code points in `s` are uppercase.
pub fn isUpperStr(s: []const u8) !bool {
    var iter = (try unicode.Utf8View.init(s)).iterator();

    return while (iter.nextCodepoint()) |cp| {
        if (isCased(cp) and !isUpper(cp)) break false;
    } else true;
}

test "Ziglyph isUpperStr" {
    try testing.expect(try isUpperStr("ABC"));
    try testing.expect(try isUpperStr("ABC123"));
    try testing.expect(!try isUpperStr("abc123"));
}

/// toLower returns the lowercase code point for the given code point. It returns the same 
/// code point given if no mapping exists.
pub fn toLower(cp: u21) u21 {
    return Letter.toLower(cp);
}

pub fn toAsciiLower(cp: u21) u21 {
    return if (cp >= 'A' and cp <= 'Z') cp ^ 32 else cp;
}

/// toCaseFoldStr returns the lowercase version of `s`. Caller must free returned memory with `allocator`.
pub fn toCaseFoldStr(allocator: *std.mem.Allocator, s: []const u8) ![]u8 {
    var result = std.ArrayList(u8).init(allocator);
    defer result.deinit();
    var buf: [4]u8 = undefined;
    var iter = (try unicode.Utf8View.init(s)).iterator();

    while (iter.nextCodepoint()) |cp| {
        const cf = Letter.toCaseFold(cp);
        for (cf) |cfcp| {
            if (cfcp == 0) break;
            const len = try unicode.utf8Encode(cfcp, &buf);
            try result.appendSlice(buf[0..len]);
        }
    }

    return result.toOwnedSlice();
}

test "Ziglyph toCaseFoldStr" {
    var allocator = std.testing.allocator;
    const got = try toCaseFoldStr(allocator, "AbC123\u{0390}");
    defer allocator.free(got);
    try testing.expect(std.mem.eql(u8, "abc123\u{03B9}\u{0308}\u{0301}", got));
}

/// toLowerStr returns the lowercase version of `s`. Caller must free returned memory with `allocator`.
pub fn toLowerStr(allocator: *std.mem.Allocator, s: []const u8) ![]u8 {
    var result = std.ArrayList(u8).init(allocator);
    defer result.deinit();
    var buf: [4]u8 = undefined;
    var iter = (try unicode.Utf8View.init(s)).iterator();

    while (iter.nextCodepoint()) |cp| {
        const len = try unicode.utf8Encode(toLower(cp), &buf);
        try result.appendSlice(buf[0..len]);
    }

    return result.toOwnedSlice();
}

test "Ziglyph toLowerStr" {
    var allocator = std.testing.allocator;
    const got = try toLowerStr(allocator, "AbC123");
    defer allocator.free(got);
    try testing.expect(std.mem.eql(u8, "abc123", got));
}

/// toTitle returns the titlecase code point for the given code point. It returns the same 
/// code point given if no mapping exists.
pub fn toTitle(cp: u21) u21 {
    return Letter.toTitle(cp);
}

/// toTitleStr returns the titlecase version of `s`. Caller must free returned memory with `allocator`.
pub fn toTitleStr(allocator: *std.mem.Allocator, s: []const u8) ![]u8 {
    var words = try WordIterator.init(allocator, s);
    defer words.deinit();
    var result = std.ArrayList(u8).init(allocator);
    defer result.deinit();
    var buf: [4]u8 = undefined;

    while (words.next()) |word| {
        var code_points = CodePointIterator{ .bytes = word.bytes };
        var got_f = false;

        while (code_points.nextCodePoint()) |cp| {
            var len: usize = 0;

            if (!got_f and isCased(cp.scalar)) {
                // First cased is titlecase.
                len = try unicode.utf8Encode(toTitle(cp.scalar), &buf);
                got_f = true;
            } else if (isCased(cp.scalar)) {
                // Subsequent cased are lowercase.
                len = try unicode.utf8Encode(toLower(cp.scalar), &buf);
            } else {
                // Uncased remain the same.
                len = try unicode.utf8Encode(cp.scalar, &buf);
            }

            try result.appendSlice(buf[0..len]);
        }
    }

    return result.toOwnedSlice();
}

test "Ziglyph toTitleStr" {
    var allocator = std.testing.allocator;
    const got = try toTitleStr(allocator, "the aBc123 broWn. fox");
    defer allocator.free(got);
    try testing.expectEqualStrings("The Abc123 Brown. Fox", got);
}

/// toUpper returns the uppercase code point for the given code point. It returns the same 
/// code point given if no mapping exists.
pub fn toUpper(cp: u21) u21 {
    return Letter.toUpper(cp);
}

pub fn toAsciiUpper(cp: u21) u21 {
    return if (cp >= 'a' and cp <= 'z') cp ^ 32 else cp;
}

/// toUpperStr returns the uppercase version of `s`. Caller must free returned memory with `allocator`.
pub fn toUpperStr(allocator: *std.mem.Allocator, s: []const u8) ![]u8 {
    var result = std.ArrayList(u8).init(allocator);
    defer result.deinit();
    var buf: [4]u8 = undefined;
    var iter = (try unicode.Utf8View.init(s)).iterator();

    while (iter.nextCodepoint()) |cp| {
        const len = try unicode.utf8Encode(toUpper(cp), &buf);
        try result.appendSlice(buf[0..len]);
    }

    return result.toOwnedSlice();
}

test "Ziglyph toUpperStr" {
    var allocator = std.testing.allocator;
    const got = try toUpperStr(allocator, "aBc123");
    defer allocator.free(got);
    try testing.expect(std.mem.eql(u8, "ABC123", got));
}

test "Ziglyph ASCII methods" {
    const z = 'F';
    try testing.expect(isAsciiAlphabetic(z));
    try testing.expect(isAsciiAlphaNum(z));
    try testing.expect(isAsciiHexDigit(z));
    try testing.expect(isAsciiGraphic(z));
    try testing.expect(isAsciiPrint(z));
    try testing.expect(isAsciiUpper(z));
    try testing.expect(!isAsciiControl(z));
    try testing.expect(!isAsciiDigit(z));
    try testing.expect(!isAsciiNumber(z));
    try testing.expect(!isAsciiLower(z));
    try testing.expectEqual(toAsciiLower(z), 'f');
    try testing.expectEqual(toAsciiUpper('a'), 'A');
    try testing.expect(isAsciiLower(toAsciiLower(z)));
}

test "Ziglyph struct" {
    const z = 'z';
    try testing.expect(isAlphaNum(z));
    try testing.expect(!isControl(z));
    try testing.expect(!isDecimal(z));
    try testing.expect(!isDigit(z));
    try testing.expect(!isHexDigit(z));
    try testing.expect(isGraphic(z));
    try testing.expect(isLetter(z));
    try testing.expect(isLower(z));
    try testing.expect(!isMark(z));
    try testing.expect(!isNumber(z));
    try testing.expect(isPrint(z));
    try testing.expect(!isPunct(z));
    try testing.expect(!isWhiteSpace(z));
    try testing.expect(!isSymbol(z));
    try testing.expect(!isTitle(z));
    try testing.expect(!isUpper(z));
    const uz = toUpper(z);
    try testing.expect(isUpper(uz));
    try testing.expectEqual(uz, 'Z');
    const lz = toLower(uz);
    try testing.expect(isLower(lz));
    try testing.expectEqual(lz, 'z');
    const tz = toTitle(lz);
    try testing.expect(isUpper(tz));
    try testing.expectEqual(tz, 'Z');
}

test "Ziglyph isGraphic" {
    try testing.expect(isGraphic('A'));
    try testing.expect(isGraphic('\u{20E4}'));
    try testing.expect(isGraphic('1'));
    try testing.expect(isGraphic('?'));
    try testing.expect(isGraphic(' '));
    try testing.expect(isGraphic('='));
    try testing.expect(!isGraphic('\u{0003}'));
}

test "Ziglyph isHexDigit" {
    var cp: u21 = '0';
    while (cp <= '9') : (cp += 1) {
        try testing.expect(isHexDigit(cp));
    }

    cp = 'A';
    while (cp <= 'F') : (cp += 1) {
        try testing.expect(isHexDigit(cp));
    }

    cp = 'a';
    while (cp <= 'f') : (cp += 1) {
        try testing.expect(isHexDigit(cp));
    }

    try testing.expect(!isHexDigit('\u{0003}'));
    try testing.expect(!isHexDigit('Z'));
}

test "Ziglyph isPrint" {
    try testing.expect(isPrint('A'));
    try testing.expect(isPrint('\u{20E4}'));
    try testing.expect(isPrint('1'));
    try testing.expect(isPrint('?'));
    try testing.expect(isPrint('='));
    try testing.expect(isPrint(' '));
    try testing.expect(isPrint('\t'));
    try testing.expect(!isPrint('\u{0003}'));
}

test "Ziglyph isAlphaNum" {
    var cp: u21 = '0';
    while (cp <= '9') : (cp += 1) {
        try testing.expect(isAlphaNum(cp));
    }

    cp = 'a';
    while (cp <= 'z') : (cp += 1) {
        try testing.expect(isAlphaNum(cp));
    }

    cp = 'A';
    while (cp <= 'Z') : (cp += 1) {
        try testing.expect(isAlphaNum(cp));
    }

    try testing.expect(!isAlphaNum('='));
}

test "Ziglyph isControl" {
    try testing.expect(isControl('\t'));
    try testing.expect(isControl('\u{0008}'));
    try testing.expect(isControl('\u{0012}'));
    try testing.expect(isControl('\n'));
    try testing.expect(isControl('\r'));
    try testing.expect(!isControl('A'));
}
