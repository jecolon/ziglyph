const std = @import("std");
const mem = std.mem;
const ascii = @import("../../ascii.zig");

/// Case fold mappings.
pub const CaseFoldMap = @import("../autogen/CaseFolding/CaseFoldMap.zig");
const CaseFold = @import("../autogen/CaseFolding/CaseFoldMap.zig").CaseFold;
/// Cased code points are either lower, upper, or title cased, but not all three.
pub const Cased = @import("../autogen/DerivedCoreProperties/Cased.zig");
/// Lowercase
pub const Lower = @import("../autogen/DerivedGeneralCategory/LowercaseLetter.zig");
pub const LowerMap = @import("../autogen/UnicodeData/LowerMap.zig");
/// Modifier
pub const Modifier = @import("../autogen/DerivedGeneralCategory/ModifierLetter.zig");
/// Other
pub const Other = @import("../autogen/DerivedGeneralCategory/OtherLetter.zig");
/// Titlecase
pub const Title = @import("../autogen/DerivedGeneralCategory/TitlecaseLetter.zig");
pub const TitleMap = @import("../autogen/UnicodeData/TitleMap.zig");
/// Uppercase
pub const Upper = @import("../autogen/DerivedGeneralCategory/UppercaseLetter.zig");
pub const UpperMap = @import("../autogen/UnicodeData/UpperMap.zig");

const Self = @This();

allocator: *mem.Allocator,
cased: Cased,
fold_map: CaseFoldMap,
lower: Lower,
lower_map: LowerMap,
modifier: Modifier,
other: Other,
title: Title,
title_map: TitleMap,
upper: Upper,
upper_map: UpperMap,

pub fn init(allocator: *mem.Allocator) !Self {
    return Self{
        .allocator = allocator,
        .cased = try Cased.init(allocator),
        .fold_map = try CaseFoldMap.init(allocator),
        .lower = try Lower.init(allocator),
        .lower_map = try LowerMap.init(allocator),
        .modifier = try Modifier.init(allocator),
        .other = try Other.init(allocator),
        .title = try Title.init(allocator),
        .title_map = try TitleMap.init(allocator),
        .upper = try Upper.init(allocator),
        .upper_map = try UpperMap.init(allocator),
    };
}

pub fn deinit(self: *Self) void {
    self.cased.deinit();
    self.fold_map.deinit();
    self.lower.deinit();
    self.lower_map.deinit();
    self.modifier.deinit();
    self.other.deinit();
    self.title.deinit();
    self.title_map.deinit();
    self.upper.deinit();
    self.upper_map.deinit();
}

/// isCased detects cased letters.
pub fn isCased(self: Self, cp: u21) bool {
    return self.cased.isCased(cp);
}

/// isLetter covers all letters in Unicode, not just ASCII.
pub fn isLetter(self: Self, cp: u21) bool {
    return self.lower.isLowercaseLetter(cp) or
        self.modifier.isModifierLetter(cp) or
        self.other.isOtherLetter(cp) or
        self.title.isTitlecaseLetter(cp) or
        self.upper.isUppercaseLetter(cp);
}

/// isAscii detects ASCII only letters.
pub fn isAscii(self: Self, cp: u21) bool {
    return if (cp < 128) ascii.isAlpha(@intCast(u8, cp)) else false;
}

/// isLower detects code points that are lowercase.
pub fn isLower(self: Self, cp: u21) bool {
    return self.lower.isLowercaseLetter(cp) or !self.isCased(cp);
}

/// isAsciiLower detects ASCII only lowercase letters.
pub fn isAsciiLower(self: Self, cp: u21) bool {
    return if (cp < 128) ascii.isLower(@intCast(u8, cp)) else false;
}

/// isTitle detects code points in titlecase.
pub fn isTitle(self: Self, cp: u21) bool {
    return self.title.isTitlecaseLetter(cp) or !self.isCased(cp);
}

/// isUpper detects code points in uppercase.
pub fn isUpper(self: Self, cp: u21) bool {
    return self.upper.isUppercaseLetter(cp) or !self.isCased(cp);
}

/// isAsciiUpper detects ASCII only uppercase letters.
pub fn isAsciiUpper(self: Self, cp: u21) bool {
    return if (cp < 128) ascii.isUpper(@intCast(u8, cp)) else false;
}

/// toLower returns the lowercase code point for the given code point. It returns the same 
/// code point given if no mapping exists.
pub fn toLower(self: Self, cp: u21) u21 {
    // Only cased letters.
    if (!self.isCased(cp)) return cp;
    return self.lower_map.toLower(cp);
}

/// toAsciiLower converts an ASCII letter to lowercase.
pub fn toAsciiLower(self: Self, cp: u21) u21 {
    return if (cp < 128) ascii.toLower(@intCast(u8, cp)) else cp;
}

/// toTitle returns the titlecase code point for the given code point. It returns the same 
/// code point given if no mapping exists.
pub fn toTitle(self: Self, cp: u21) u21 {
    // Only cased letters.
    if (!self.isCased(cp)) return cp;
    return self.title_map.toTitle(cp);
}

/// toUpper returns the uppercase code point for the given code point. It returns the same 
/// code point given if no mapping exists.
pub fn toUpper(self: Self, cp: u21) u21 {
    // Only cased letters.
    if (!self.isCased(cp)) return cp;
    return self.upper_map.toUpper(cp);
}

/// toAsciiUpper converts an ASCII letter to uppercase.
pub fn toAsciiUpper(self: Self, cp: u21) u21 {
    return if (cp < 128) ascii.toUpper(@intCast(u8, cp)) else false;
}

/// toCaseFold will convert a code point into its case folded equivalent. Note that this can result
/// in a mapping to more than one code point, known as the full case fold.
pub fn toCaseFold(self: Self, cp: u21) CaseFold {
    return self.fold_map.toCaseFold(cp);
}

test "Component struct" {
    // Simple structs don't require init / deinit.
    var letter = try init(std.testing.allocator);
    defer letter.deinit();

    const z = 'z';
    std.testing.expect(letter.isLetter(z));
    std.testing.expect(!letter.isUpper(z));
    const uz = letter.toUpper(z);
    std.testing.expect(letter.isUpper(uz));
    std.testing.expectEqual(uz, 'Z');
}

test "isCased" {
    var z = try init(std.testing.allocator);
    defer z.deinit();

    std.testing.expect(z.isCased('a'));
    std.testing.expect(z.isCased('A'));
    std.testing.expect(!z.isCased('1'));
}

test "isLower" {
    var z = try init(std.testing.allocator);
    defer z.deinit();

    std.testing.expect(z.isLower('a'));
    std.testing.expect(z.isLower('é'));
    std.testing.expect(z.isLower('i'));
    std.testing.expect(!z.isLower('A'));
    std.testing.expect(!z.isLower('É'));
    std.testing.expect(!z.isLower('İ'));
    // Numbers are lower, upper, and title all at once.
    std.testing.expect(z.isLower('1'));
}

test "toCaseFold" {
    var z = try init(std.testing.allocator);
    defer z.deinit();

    var result = z.toCaseFold('A');
    switch (result) {
        .simple => |cp| std.testing.expectEqual(cp, 'a'),
        .full => @panic("Got .full, wanted .simple for A"),
    }
    result = z.toCaseFold('a');
    switch (result) {
        .simple => |cp| std.testing.expectEqual(cp, 'a'),
        .full => @panic("Got .full, wanted .simple for a"),
    }
    result = z.toCaseFold('1');
    switch (result) {
        .simple => |cp| std.testing.expectEqual(cp, '1'),
        .full => @panic("Got .full, wanted .simple for 1"),
    }
    result = z.toCaseFold('\u{00DF}');
    switch (result) {
        .simple => @panic("Got .simple, wanted .full for 0x00DF"),
        .full => |s| std.testing.expectEqualSlices(u21, s, &[_]u21{ 0x0073, 0x0073 }),
    }
    result = z.toCaseFold('\u{0390}');
    switch (result) {
        .simple => @panic("Got .simple, wanted .full for 0x0390"),
        .full => |s| std.testing.expectEqualSlices(u21, s, &[_]u21{ 0x03B9, 0x0308, 0x0301 }),
    }
}

test "toLower" {
    var z = try init(std.testing.allocator);
    defer z.deinit();

    std.testing.expectEqual(z.toLower('a'), 'a');
    std.testing.expectEqual(z.toLower('A'), 'a');
    std.testing.expectEqual(z.toLower('İ'), 'i');
    std.testing.expectEqual(z.toLower('É'), 'é');
    std.testing.expectEqual(z.toLower(0x80), 0x80);
    std.testing.expectEqual(z.toLower(0x80), 0x80);
    std.testing.expectEqual(z.toLower('Å'), 'å');
    std.testing.expectEqual(z.toLower('å'), 'å');
    std.testing.expectEqual(z.toLower('\u{212A}'), 'k');
    std.testing.expectEqual(z.toLower('1'), '1');
}

test "isUpper" {
    var z = try init(std.testing.allocator);
    defer z.deinit();

    std.testing.expect(!z.isUpper('a'));
    std.testing.expect(!z.isUpper('é'));
    std.testing.expect(!z.isUpper('i'));
    std.testing.expect(z.isUpper('A'));
    std.testing.expect(z.isUpper('É'));
    std.testing.expect(z.isUpper('İ'));
    // Numbers are lower, upper, and title all at once.
    std.testing.expect(z.isUpper('1'));
}

test "toUpper" {
    var z = try init(std.testing.allocator);
    defer z.deinit();

    std.testing.expectEqual(z.toUpper('a'), 'A');
    std.testing.expectEqual(z.toUpper('A'), 'A');
    std.testing.expectEqual(z.toUpper('i'), 'I');
    std.testing.expectEqual(z.toUpper('é'), 'É');
    std.testing.expectEqual(z.toUpper(0x80), 0x80);
    std.testing.expectEqual(z.toUpper('Å'), 'Å');
    std.testing.expectEqual(z.toUpper('å'), 'Å');
    std.testing.expectEqual(z.toUpper('1'), '1');
}

test "isTitle" {
    var z = try init(std.testing.allocator);
    defer z.deinit();

    std.testing.expect(!z.isTitle('a'));
    std.testing.expect(!z.isTitle('é'));
    std.testing.expect(!z.isTitle('i'));
    std.testing.expect(z.isTitle('\u{1FBC}'));
    std.testing.expect(z.isTitle('\u{1FCC}'));
    std.testing.expect(z.isTitle('ǈ'));
    // Numbers are lower, upper, and title all at once.
    std.testing.expect(z.isTitle('1'));
}

test "toTitle" {
    var z = try init(std.testing.allocator);
    defer z.deinit();

    std.testing.expectEqual(z.toTitle('a'), 'A');
    std.testing.expectEqual(z.toTitle('A'), 'A');
    std.testing.expectEqual(z.toTitle('i'), 'I');
    std.testing.expectEqual(z.toTitle('é'), 'É');
    std.testing.expectEqual(z.toTitle('1'), '1');
}

test "isLetter" {
    var z = try init(std.testing.allocator);
    defer z.deinit();

    var cp: u21 = 'a';
    while (cp <= 'z') : (cp += 1) {
        std.testing.expect(z.isLetter(cp));
    }
    cp = 'A';
    while (cp <= 'Z') : (cp += 1) {
        std.testing.expect(z.isLetter(cp));
    }
    std.testing.expect(z.isLetter('É'));
    std.testing.expect(z.isLetter('\u{2CEB3}'));
    std.testing.expect(!z.isLetter('\u{0003}'));
}
