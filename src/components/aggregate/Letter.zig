const std = @import("std");
const mem = std.mem;
const ascii = @import("../../ascii.zig");

const Context = @import("../../context.zig").Context;
pub const CaseFoldMap = @import("../../context.zig").CaseFoldMap;
pub const CaseFold = CaseFoldMap.CaseFold;
pub const Cased = @import("../../context.zig").Cased;
pub const Lower = @import("../../context.zig").Lower;
pub const LowerMap = @import("../../context.zig").LowerMap;
pub const ModifierLetter = @import("../../context.zig").ModifierLetter;
pub const OtherLetter = @import("../../context.zig").OtherLetter;
pub const Title = @import("../../context.zig").Title;
pub const TitleMap = @import("../../context.zig").TitleMap;
pub const Upper = @import("../../context.zig").Upper;
pub const UpperMap = @import("../../context.zig").UpperMap;

const Self = @This();

fold_map: *CaseFoldMap,
cased: *Cased,
lower: *Lower,
lower_map: *LowerMap,
modifier_letter: *ModifierLetter,
other_letter: *OtherLetter,
title: *Title,
title_map: *TitleMap,
upper: *Upper,
upper_map: *UpperMap,

pub fn new(ctx: anytype) Self {
    return Self{
        .fold_map = &ctx.fold_map,
        .cased = &ctx.cased,
        .lower = &ctx.lower,
        .lower_map = &ctx.lower_map,
        .modifier_letter = &ctx.modifier_letter,
        .other_letter = &ctx.other_letter,
        .title = &ctx.title,
        .title_map = &ctx.title_map,
        .upper = &ctx.upper,
        .upper_map = &ctx.upper_map,
    };
}

/// isCased detects cased letters.
pub fn isCased(self: Self, cp: u21) bool {
    return self.cased.isCased(cp);
}

/// isLetter covers all letters in Unicode, not just ASCII.
pub fn isLetter(self: Self, cp: u21) bool {
    return self.lower.isLowercaseLetter(cp) or self.modifier_letter.isModifierLetter(cp) or
        self.other_letter.isOtherLetter(cp) or self.title.isTitlecaseLetter(cp) or
        self.upper.isUppercaseLetter(cp);
}

/// isAscii detects ASCII only letters.
pub fn isAscii(cp: u21) bool {
    return if (cp < 128) ascii.isAlpha(@intCast(u8, cp)) else false;
}

/// isLower detects code points that are lowercase.
pub fn isLower(self: Self, cp: u21) bool {
    return self.lower.isLowercaseLetter(cp) or !self.isCased(cp);
}

/// isAsciiLower detects ASCII only lowercase letters.
pub fn isAsciiLower(cp: u21) bool {
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
pub fn isAsciiUpper(cp: u21) bool {
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

const expect = std.testing.expect;
const expectEqual = std.testing.expectEqual;

test "Component struct" {
    var ctx = try Context(.letter).init(std.testing.allocator);
    defer ctx.deinit();

    var letter = new(&ctx);

    const z = 'z';
    expect(letter.isLetter(z));
    expect(!letter.isUpper(z));
    const uz = letter.toUpper(z);
    expect(letter.isUpper(uz));
    expectEqual(uz, 'Z');
}

test "Component isCased" {
    var ctx = try Context(.letter).init(std.testing.allocator);
    defer ctx.deinit();

    var letter = new(&ctx);

    expect(letter.isCased('a'));
    expect(letter.isCased('A'));
    expect(!letter.isCased('1'));
}

test "Component isLower" {
    var ctx = try Context(.letter).init(std.testing.allocator);
    defer ctx.deinit();

    var letter = new(&ctx);

    expect(letter.isLower('a'));
    expect(letter.isLower('é'));
    expect(letter.isLower('i'));
    expect(!letter.isLower('A'));
    expect(!letter.isLower('É'));
    expect(!letter.isLower('İ'));
    // Numbers are lower, upper, and title all at once.
    expect(letter.isLower('1'));
}

const expectEqualSlices = std.testing.expectEqualSlices;

test "Component toCaseFold" {
    var ctx = try Context(.letter).init(std.testing.allocator);
    defer ctx.deinit();

    var letter = new(&ctx);

    var result = letter.toCaseFold('A');
    switch (result) {
        .simple => |cp| expectEqual(cp, 'a'),
        .full => @panic("Got .full, wanted .simple for A"),
    }

    result = letter.toCaseFold('a');
    switch (result) {
        .simple => |cp| expectEqual(cp, 'a'),
        .full => @panic("Got .full, wanted .simple for a"),
    }

    result = letter.toCaseFold('1');
    switch (result) {
        .simple => |cp| expectEqual(cp, '1'),
        .full => @panic("Got .full, wanted .simple for 1"),
    }

    result = letter.toCaseFold('\u{00DF}');
    switch (result) {
        .simple => @panic("Got .simple, wanted .full for 0x00DF"),
        .full => |s| expectEqualSlices(u21, s, &[_]u21{ 0x0073, 0x0073 }),
    }

    result = letter.toCaseFold('\u{0390}');
    switch (result) {
        .simple => @panic("Got .simple, wanted .full for 0x0390"),
        .full => |s| expectEqualSlices(u21, s, &[_]u21{ 0x03B9, 0x0308, 0x0301 }),
    }
}

test "Component toLower" {
    var ctx = try Context(.letter).init(std.testing.allocator);
    defer ctx.deinit();

    var letter = new(&ctx);

    expectEqual(letter.toLower('a'), 'a');
    expectEqual(letter.toLower('A'), 'a');
    expectEqual(letter.toLower('İ'), 'i');
    expectEqual(letter.toLower('É'), 'é');
    expectEqual(letter.toLower(0x80), 0x80);
    expectEqual(letter.toLower(0x80), 0x80);
    expectEqual(letter.toLower('Å'), 'å');
    expectEqual(letter.toLower('å'), 'å');
    expectEqual(letter.toLower('\u{212A}'), 'k');
    expectEqual(letter.toLower('1'), '1');
}

test "Component isUpper" {
    var ctx = try Context(.letter).init(std.testing.allocator);
    defer ctx.deinit();

    var letter = new(&ctx);

    expect(!letter.isUpper('a'));
    expect(!letter.isUpper('é'));
    expect(!letter.isUpper('i'));
    expect(letter.isUpper('A'));
    expect(letter.isUpper('É'));
    expect(letter.isUpper('İ'));
    // Numbers are lower, upper, and title all at once.
    expect(letter.isUpper('1'));
}

test "Component toUpper" {
    var ctx = try Context(.letter).init(std.testing.allocator);
    defer ctx.deinit();

    var letter = new(&ctx);

    expectEqual(letter.toUpper('a'), 'A');
    expectEqual(letter.toUpper('A'), 'A');
    expectEqual(letter.toUpper('i'), 'I');
    expectEqual(letter.toUpper('é'), 'É');
    expectEqual(letter.toUpper(0x80), 0x80);
    expectEqual(letter.toUpper('Å'), 'Å');
    expectEqual(letter.toUpper('å'), 'Å');
    expectEqual(letter.toUpper('1'), '1');
}

test "Component isTitle" {
    var ctx = try Context(.letter).init(std.testing.allocator);
    defer ctx.deinit();

    var letter = new(&ctx);

    expect(!letter.isTitle('a'));
    expect(!letter.isTitle('é'));
    expect(!letter.isTitle('i'));
    expect(letter.isTitle('\u{1FBC}'));
    expect(letter.isTitle('\u{1FCC}'));
    expect(letter.isTitle('ǈ'));
    // Numbers are lower, upper, and title all at once.
    expect(letter.isTitle('1'));
}

test "Component toTitle" {
    var ctx = try Context(.letter).init(std.testing.allocator);
    defer ctx.deinit();

    var letter = new(&ctx);

    expectEqual(letter.toTitle('a'), 'A');
    expectEqual(letter.toTitle('A'), 'A');
    expectEqual(letter.toTitle('i'), 'I');
    expectEqual(letter.toTitle('é'), 'É');
    expectEqual(letter.toTitle('1'), '1');
}

test "Component isLetter" {
    var ctx = try Context(.letter).init(std.testing.allocator);
    defer ctx.deinit();

    var letter = new(&ctx);

    var cp: u21 = 'a';
    while (cp <= 'z') : (cp += 1) {
        expect(letter.isLetter(cp));
    }

    cp = 'A';
    while (cp <= 'Z') : (cp += 1) {
        expect(letter.isLetter(cp));
    }

    expect(letter.isLetter('É'));
    expect(letter.isLetter('\u{2CEB3}'));
    expect(!letter.isLetter('\u{0003}'));
}
