const std = @import("std");
const mem = std.mem;
const ascii = @import("../../ascii.zig");

const Context = @import("../../Context.zig");

const Self = @This();

context: *Context,

pub fn new(ctx: *Context) Self {
    return Self{ .context = ctx };
}

/// isCased detects cased letters.
pub fn isCased(self: Self, cp: u21) !bool {
    var cased = try self.context.getCased();
    return cased.isCased(cp);
}

/// isLetter covers all letters in Unicode, not just ASCII.
pub fn isLetter(self: Self, cp: u21) !bool {
    const lower = try self.context.getLower();
    const modifier_letter = try self.context.getModifierLetter();
    const other_letter = try self.context.getOtherLetter();
    const title = try self.context.getTitle();
    const upper = try self.context.getUpper();

    return lower.isLowercaseLetter(cp) or
        modifier_letter.isModifierLetter(cp) or
        other_letter.isOtherLetter(cp) or
        title.isTitlecaseLetter(cp) or
        upper.isUppercaseLetter(cp);
}

/// isAscii detects ASCII only letters.
pub fn isAscii(cp: u21) bool {
    return if (cp < 128) ascii.isAlpha(@intCast(u8, cp)) else false;
}

/// isLower detects code points that are lowercase.
pub fn isLower(self: Self, cp: u21) !bool {
    const lower = try self.context.getLower();
    return lower.isLowercaseLetter(cp) or (!try self.isCased(cp));
}

/// isAsciiLower detects ASCII only lowercase letters.
pub fn isAsciiLower(cp: u21) bool {
    return if (cp < 128) ascii.isLower(@intCast(u8, cp)) else false;
}

/// isTitle detects code points in titlecase.
pub fn isTitle(self: Self, cp: u21) !bool {
    const title = try self.context.getTitle();
    return title.isTitlecaseLetter(cp) or (!try self.isCased(cp));
}

/// isUpper detects code points in uppercase.
pub fn isUpper(self: Self, cp: u21) !bool {
    const upper = try self.context.getUpper();
    return upper.isUppercaseLetter(cp) or (!try self.isCased(cp));
}

/// isAsciiUpper detects ASCII only uppercase letters.
pub fn isAsciiUpper(cp: u21) bool {
    return if (cp < 128) ascii.isUpper(@intCast(u8, cp)) else false;
}

/// toLower returns the lowercase code point for the given code point. It returns the same 
/// code point given if no mapping exists.
pub fn toLower(self: Self, cp: u21) !u21 {
    // Only cased letters.
    if (!try self.isCased(cp)) return cp;
    const lower_map = try self.context.getLowerMap();
    return lower_map.toLower(cp);
}

/// toAsciiLower converts an ASCII letter to lowercase.
pub fn toAsciiLower(self: Self, cp: u21) !u21 {
    return if (cp < 128) ascii.toLower(@intCast(u8, cp)) else cp;
}

/// toTitle returns the titlecase code point for the given code point. It returns the same 
/// code point given if no mapping exists.
pub fn toTitle(self: Self, cp: u21) !u21 {
    // Only cased letters.
    if (!try self.isCased(cp)) return cp;
    const title_map = try self.context.getTitleMap();
    return title_map.toTitle(cp);
}

/// toUpper returns the uppercase code point for the given code point. It returns the same 
/// code point given if no mapping exists.
pub fn toUpper(self: Self, cp: u21) !u21 {
    // Only cased letters.
    if (!try self.isCased(cp)) return cp;
    const upper_map = try self.context.getUpperMap();
    return upper_map.toUpper(cp);
}

/// toAsciiUpper converts an ASCII letter to uppercase.
pub fn toAsciiUpper(self: Self, cp: u21) !u21 {
    return if (cp < 128) ascii.toUpper(@intCast(u8, cp)) else false;
}

/// toCaseFold will convert a code point into its case folded equivalent. Note that this can result
/// in a mapping to more than one code point, known as the full case fold.
pub fn toCaseFold(self: Self, cp: u21) !Context.CaseFold {
    const fold_map = try self.context.getCaseFoldMap();
    return fold_map.toCaseFold(cp);
}

const expect = std.testing.expect;
const expectEqual = std.testing.expectEqual;

test "Component struct" {
    var ctx = Context.init(std.testing.allocator);
    defer ctx.deinit();

    var letter = new(&ctx);

    const z = 'z';
    expect(try letter.isLetter(z));
    expect(!try letter.isUpper(z));
    const uz = try letter.toUpper(z);
    expect(try letter.isUpper(uz));
    expectEqual(uz, 'Z');
}

test "Component isCased" {
    var ctx = Context.init(std.testing.allocator);
    defer ctx.deinit();

    var letter = new(&ctx);

    expect(try letter.isCased('a'));
    expect(try letter.isCased('A'));
    expect(!try letter.isCased('1'));
}

test "Component isLower" {
    var ctx = Context.init(std.testing.allocator);
    defer ctx.deinit();

    var letter = new(&ctx);

    expect(try letter.isLower('a'));
    expect(try letter.isLower('é'));
    expect(try letter.isLower('i'));
    expect(!try letter.isLower('A'));
    expect(!try letter.isLower('É'));
    expect(!try letter.isLower('İ'));
    // Numbers are lower, upper, and title all at once.
    expect(try letter.isLower('1'));
}

const expectEqualSlices = std.testing.expectEqualSlices;

test "Component toCaseFold" {
    var ctx = Context.init(std.testing.allocator);
    defer ctx.deinit();

    var letter = new(&ctx);

    var result = try letter.toCaseFold('A');
    switch (result) {
        .simple => |cp| expectEqual(cp, 'a'),
        .full => @panic("Got .full, wanted .simple for A"),
    }

    result = try letter.toCaseFold('a');
    switch (result) {
        .simple => |cp| expectEqual(cp, 'a'),
        .full => @panic("Got .full, wanted .simple for a"),
    }

    result = try letter.toCaseFold('1');
    switch (result) {
        .simple => |cp| expectEqual(cp, '1'),
        .full => @panic("Got .full, wanted .simple for 1"),
    }

    result = try letter.toCaseFold('\u{00DF}');
    switch (result) {
        .simple => @panic("Got .simple, wanted .full for 0x00DF"),
        .full => |s| expectEqualSlices(u21, s, &[_]u21{ 0x0073, 0x0073 }),
    }

    result = try letter.toCaseFold('\u{0390}');
    switch (result) {
        .simple => @panic("Got .simple, wanted .full for 0x0390"),
        .full => |s| expectEqualSlices(u21, s, &[_]u21{ 0x03B9, 0x0308, 0x0301 }),
    }
}

test "Component toLower" {
    var ctx = Context.init(std.testing.allocator);
    defer ctx.deinit();

    var letter = new(&ctx);

    expectEqual(try letter.toLower('a'), 'a');
    expectEqual(try letter.toLower('A'), 'a');
    expectEqual(try letter.toLower('İ'), 'i');
    expectEqual(try letter.toLower('É'), 'é');
    expectEqual(try letter.toLower(0x80), 0x80);
    expectEqual(try letter.toLower(0x80), 0x80);
    expectEqual(try letter.toLower('Å'), 'å');
    expectEqual(try letter.toLower('å'), 'å');
    expectEqual(try letter.toLower('\u{212A}'), 'k');
    expectEqual(try letter.toLower('1'), '1');
}

test "Component isUpper" {
    var ctx = Context.init(std.testing.allocator);
    defer ctx.deinit();

    var letter = new(&ctx);

    expect(!try letter.isUpper('a'));
    expect(!try letter.isUpper('é'));
    expect(!try letter.isUpper('i'));
    expect(try letter.isUpper('A'));
    expect(try letter.isUpper('É'));
    expect(try letter.isUpper('İ'));
    // Numbers are lower, upper, and title all at once.
    expect(try letter.isUpper('1'));
}

test "Component toUpper" {
    var ctx = Context.init(std.testing.allocator);
    defer ctx.deinit();

    var letter = new(&ctx);

    expectEqual(try letter.toUpper('a'), 'A');
    expectEqual(try letter.toUpper('A'), 'A');
    expectEqual(try letter.toUpper('i'), 'I');
    expectEqual(try letter.toUpper('é'), 'É');
    expectEqual(try letter.toUpper(0x80), 0x80);
    expectEqual(try letter.toUpper('Å'), 'Å');
    expectEqual(try letter.toUpper('å'), 'Å');
    expectEqual(try letter.toUpper('1'), '1');
}

test "Component isTitle" {
    var ctx = Context.init(std.testing.allocator);
    defer ctx.deinit();

    var letter = new(&ctx);

    expect(!try letter.isTitle('a'));
    expect(!try letter.isTitle('é'));
    expect(!try letter.isTitle('i'));
    expect(try letter.isTitle('\u{1FBC}'));
    expect(try letter.isTitle('\u{1FCC}'));
    expect(try letter.isTitle('ǈ'));
    // Numbers are lower, upper, and title all at once.
    expect(try letter.isTitle('1'));
}

test "Component toTitle" {
    var ctx = Context.init(std.testing.allocator);
    defer ctx.deinit();

    var letter = new(&ctx);

    expectEqual(try letter.toTitle('a'), 'A');
    expectEqual(try letter.toTitle('A'), 'A');
    expectEqual(try letter.toTitle('i'), 'I');
    expectEqual(try letter.toTitle('é'), 'É');
    expectEqual(try letter.toTitle('1'), '1');
}

test "Component isLetter" {
    var ctx = Context.init(std.testing.allocator);
    defer ctx.deinit();

    var letter = new(&ctx);

    var cp: u21 = 'a';
    while (cp <= 'z') : (cp += 1) {
        expect(try letter.isLetter(cp));
    }

    cp = 'A';
    while (cp <= 'Z') : (cp += 1) {
        expect(try letter.isLetter(cp));
    }

    expect(try letter.isLetter('É'));
    expect(try letter.isLetter('\u{2CEB3}'));
    expect(!try letter.isLetter('\u{0003}'));
}
