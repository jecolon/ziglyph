const std = @import("std");
const expect = std.testing.expect;
const expectEqual = std.testing.expectEqual;
const expectEqualSlices = std.testing.expectEqualSlices;

const CaseFoldMap = @import("ziglyph.zig").CaseFoldMap;
const Control = @import("ziglyph.zig").Control;
const Decimal = @import("ziglyph.zig").Decimal;
const Digit = @import("ziglyph.zig").Digit;
const DecomposeMap = @import("ziglyph.zig").DecomposeMap;
const Letter = @import("ziglyph.zig").Letter;
const Lower = @import("ziglyph.zig").Lower;
const LowerMap = @import("ziglyph.zig").LowerMap;
const Mark = @import("ziglyph.zig").Mark;
const Number = @import("ziglyph.zig").Number;
const Punct = @import("ziglyph.zig").Punct;
const Space = @import("ziglyph.zig").Space;
const Symbol = @import("ziglyph.zig").Symbol;
const Title = @import("ziglyph.zig").Title;
const TitleMap = @import("ziglyph.zig").TitleMap;
const Upper = @import("ziglyph.zig").Upper;
const UpperMap = @import("ziglyph.zig").UpperMap;
const Ziglyph = @import("ziglyph.zig").Ziglyph;

pub fn main() !void {
    var z = try Ziglyph.init(std.testing.allocator);
    defer z.deinit();
    var fold_map = try CaseFoldMap.init(std.testing.allocator);
    defer fold_map.deinit();

    const mixed = [_]u21{ '5', 'o', '9', '!', ' ', '℃', 'ᾭ', 'G' };
    for (mixed) |r| {
        std.debug.print("\nFor {u}:\n", .{r});
        if (try z.isControl(r)) { // added 1.1M to binary!!
            std.debug.print("\tis control\n", .{});
        }
        if (try z.isNumber(r)) { // added 100K to binary
            std.debug.print("\tis number\n", .{});
        }
        if (try z.isGraphic(r)) { // added 0 to binary
            std.debug.print("\tis graphic\n", .{});
        }
        if (try z.isAlphaNum(r)) { // adds 0 to binary
            std.debug.print("\tis alphanumeric\n", .{});
        }
        if (try z.isLetter(r)) { // added 200K to binary !!
            std.debug.print("\tis letter\n", .{});
        }
        if (try z.isLower(r)) { // added 200K to binary
            std.debug.print("\tis lower case\n", .{});
        }
        if (try z.isMark(r)) { // added 1.1M to binary !!
            std.debug.print("\tis mark\n", .{});
        }
        if (try z.isPrint(r)) { // added 0 to binary
            std.debug.print("\tis printable\n", .{});
        }
        if (!try z.isPrint(r)) {
            std.debug.print("\tis not printable\n", .{});
        }
        if (try z.isPunct(r)) { // added 137K to binary
            std.debug.print("\tis punct\n", .{});
        }
        if (try z.isSpace(r)) { // Adds 12K to binary
            std.debug.print("\tis space\n", .{});
        }
        if (try z.isSymbol(r)) { // added 131K to binary
            std.debug.print("\tis symbol\n", .{});
        }
        if (try z.isTitle(r)) { // Base binary at 18K
            std.debug.print("\tis title case\n", .{});
        }
        if (try z.isUpper(r)) { // added 100K to binary
            std.debug.print("\tis upper case\n", .{});
            std.debug.print("\tcase folded: {}\n", .{fold_map.toCaseFold(r)});
        }
    }
}

test "Ziglyph struct" {
    // init and defer deinit.
    var ziglyph = try Ziglyph.init(std.testing.allocator);
    defer ziglyph.deinit();

    const z = 'z';
    expect(try ziglyph.isAlphaNum(z));
    expect(!try ziglyph.isControl(z));
    expect(!try ziglyph.isDecimal(z));
    expect(!try ziglyph.isDigit(z));
    expect(try ziglyph.isGraphic(z));
    expect(try ziglyph.isLetter(z));
    expect(try ziglyph.isLower(z));
    expect(!try ziglyph.isMark(z));
    expect(!try ziglyph.isNumber(z));
    expect(try ziglyph.isPrint(z));
    expect(!try ziglyph.isPunct(z));
    expect(!try ziglyph.isSpace(z));
    expect(!try ziglyph.isSymbol(z));
    expect(!try ziglyph.isTitle(z));
    expect(!try ziglyph.isUpper(z));
    const uz = try ziglyph.toUpper(z);
    expect(try ziglyph.isUpper(uz));
    expectEqual(uz, 'Z');
    const lz = try ziglyph.toLower(uz);
    expect(try ziglyph.isLower(lz));
    expectEqual(lz, 'z');
    const tz = try ziglyph.toTitle(lz);
    expect(try ziglyph.isUpper(tz));
    expectEqual(tz, 'Z');
}

test "Component structs" {
    // Simple structs don't require init / deinit.
    var letter = try Letter.init(std.testing.allocator);
    defer letter.deinit();
    var upper = try Upper.init(std.testing.allocator);
    defer upper.deinit();
    var upper_map = try UpperMap.init(std.testing.allocator);
    defer upper_map.deinit();

    const z = 'z';
    // No lazy init, no 'try' here.
    expect(letter.isLetter(z));
    expect(!upper.isUpper(z));
    const uz = upper_map.toUpper(z);
    expect(upper.isUpper(uz));
    expectEqual(uz, 'Z');
}

test "basics" {
    var z = try Ziglyph.init(std.testing.allocator);
    defer z.deinit();

    const mixed = [_]u21{ '5', 'o', '9', '!', ' ', '℃', 'ᾭ', 'G' };
    for (mixed) |r| {
        std.debug.print("\nFor {u}:\n", .{r});
        if (try z.isControl(r)) {
            std.debug.print("\tis control\n", .{});
        }
        if (try z.isNumber(r)) {
            std.debug.print("\tis number\n", .{});
        }
        if (try z.isGraphic(r)) {
            std.debug.print("\tis graphic\n", .{});
        }
        if (try z.isLetter(r)) {
            std.debug.print("\tis letter\n", .{});
        }
        if (try z.isLower(r)) {
            std.debug.print("\tis lower case\n", .{});
        }
        if (try z.isMark(r)) {
            std.debug.print("\tis mark\n", .{});
        }
        if (try z.isPrint(r)) {
            std.debug.print("\tis printable\n", .{});
        }
        if (!try z.isPrint(r)) {
            std.debug.print("\tis not printable\n", .{});
        }
        if (try z.isPunct(r)) {
            std.debug.print("\tis punct\n", .{});
        }
        if (try z.isSpace(r)) {
            std.debug.print("\tis space\n", .{});
        }
        if (try z.isSymbol(r)) {
            std.debug.print("\tis symbol\n", .{});
        }
        if (try z.isTitle(r)) {
            std.debug.print("\tis title case\n", .{});
        }
        if (try z.isUpper(r)) {
            std.debug.print("\tis upper case\n", .{});
        }
    }
}

test "isLower" {
    var z = try Lower.init(std.testing.allocator);
    defer z.deinit();

    expect(z.isLower('a'));
    expect(z.isLower('é'));
    expect(z.isLower('i'));
    expect(!z.isLower('A'));
    expect(!z.isLower('É'));
    expect(!z.isLower('İ'));
}

test "toCaseFold" {
    //var z = try LowerMap.init(std.testing.allocator);
    var z = try CaseFoldMap.init(std.testing.allocator);
    defer z.deinit();

    var result = z.toCaseFold('A');
    switch (result) {
        .simple => |cp| expectEqual(cp, 'a'),
        .full => @panic("Got .full, wanted .simple for A"),
    }
    result = z.toCaseFold('a');
    switch (result) {
        .simple => |cp| expectEqual(cp, 'a'),
        .full => @panic("Got .full, wanted .simple for a"),
    }
    result = z.toCaseFold('1');
    switch (result) {
        .simple => |cp| expectEqual(cp, '1'),
        .full => @panic("Got .full, wanted .simple for 1"),
    }
    result = z.toCaseFold('\u{00DF}');
    switch (result) {
        .simple => @panic("Got .simple, wanted .full for 0x00DF"),
        .full => |s| expectEqualSlices(u21, s, &[_]u21{ 0x0073, 0x0073 }),
    }
    result = z.toCaseFold('\u{0390}');
    switch (result) {
        .simple => @panic("Got .simple, wanted .full for 0x0390"),
        .full => |s| expectEqualSlices(u21, s, &[_]u21{ 0x03B9, 0x0308, 0x0301 }),
    }
}

test "toLower" {
    //var z = try LowerMap.init(std.testing.allocator);
    var z = try LowerMap.init(std.testing.allocator);
    defer z.deinit();

    expectEqual(z.toLower('a'), 'a');
    expectEqual(z.toLower('A'), 'a');
    expectEqual(z.toLower('İ'), 'i');
    expectEqual(z.toLower('É'), 'é');
    expectEqual(z.toLower(0x80), 0x80);
    expectEqual(z.toLower(0x80), 0x80);
    expectEqual(z.toLower('Å'), 'å');
    expectEqual(z.toLower('å'), 'å');
    expectEqual(z.toLower('\u{212A}'), 'k');
}

test "isUpper" {
    var z = try Upper.init(std.testing.allocator);
    defer z.deinit();

    expect(!z.isUpper('a'));
    expect(!z.isUpper('é'));
    expect(!z.isUpper('i'));
    expect(z.isUpper('A'));
    expect(z.isUpper('É'));
    expect(z.isUpper('İ'));
}

test "toUpper" {
    var z = try UpperMap.init(std.testing.allocator);
    defer z.deinit();

    expectEqual(z.toUpper('a'), 'A');
    expectEqual(z.toUpper('A'), 'A');
    expectEqual(z.toUpper('i'), 'I');
    expectEqual(z.toUpper('é'), 'É');
    expectEqual(z.toUpper(0x80), 0x80);
    expectEqual(z.toUpper('Å'), 'Å');
    expectEqual(z.toUpper('å'), 'Å');
}

test "isTitle" {
    var z = try Title.init(std.testing.allocator);
    defer z.deinit();

    expect(!z.isTitle('a'));
    expect(!z.isTitle('é'));
    expect(!z.isTitle('i'));
    expect(z.isTitle('\u{1FBC}'));
    expect(z.isTitle('\u{1FCC}'));
    expect(z.isTitle('ǈ'));
}

test "toTitle" {
    var z = try TitleMap.init(std.testing.allocator);
    defer z.deinit();

    expectEqual(z.toTitle('a'), 'A');
    expectEqual(z.toTitle('A'), 'A');
    expectEqual(z.toTitle('i'), 'I');
    expectEqual(z.toTitle('é'), 'É');
}

test "isControl" {
    var z = try Control.init(std.testing.allocator);
    defer z.deinit();

    expect(z.isControl('\n'));
    expect(z.isControl('\r'));
    expect(z.isControl('\t'));
    expect(z.isControl('\u{0003}'));
    expect(z.isControl('\u{0012}'));
    expect(!z.isControl('A'));
}

test "isDecimal" {
    var z = try Decimal.init(std.testing.allocator);
    defer z.deinit();

    var cp: u21 = '0';
    while (cp <= '9') : (cp += 1) {
        expect(z.isDecimal(cp));
    }
    expect(!z.isDecimal('\u{0003}'));
    expect(!z.isDecimal('A'));
}

test "isDigit" {
    var z = try Digit.init(std.testing.allocator);
    defer z.deinit();

    var cp: u21 = '0';
    while (cp <= '9') : (cp += 1) {
        expect(z.isDigit(cp));
    }
    expect(!z.isDigit('\u{0003}'));
    expect(!z.isDigit('A'));
}

test "isGraphic" {
    var z = try Ziglyph.init(std.testing.allocator);
    defer z.deinit();

    expect(try z.isGraphic('A'));
    expect(try z.isGraphic('\u{20E4}'));
    expect(try z.isGraphic('1'));
    expect(try z.isGraphic('?'));
    expect(try z.isGraphic(' '));
    expect(try z.isGraphic('='));
    expect(!try z.isGraphic('\u{0003}'));
}

test "isHex" {
    var z = try Ziglyph.init(std.testing.allocator);
    defer z.deinit();

    var cp: u21 = '0';
    while (cp <= '9') : (cp += 1) {
        expect(z.isHex(cp));
    }
    cp = 'A';
    while (cp <= 'F') : (cp += 1) {
        expect(z.isHex(cp));
    }
    cp = 'a';
    while (cp <= 'f') : (cp += 1) {
        expect(z.isHex(cp));
    }
    expect(!z.isHex('\u{0003}'));
    expect(!z.isHex('Z'));
}
test "isPrint" {
    var z = try Ziglyph.init(std.testing.allocator);
    defer z.deinit();

    expect(try z.isPrint('A'));
    expect(try z.isPrint('\u{20E4}'));
    expect(try z.isPrint('1'));
    expect(try z.isPrint('?'));
    expect(try z.isPrint('='));
    expect(try z.isPrint(' '));
    expect(!try z.isPrint('\t'));
    expect(!try z.isPrint('\u{0003}'));
}

test "isLetter" {
    var z = try Letter.init(std.testing.allocator);
    defer z.deinit();

    var cp: u21 = 'a';
    while (cp <= 'z') : (cp += 1) {
        expect(z.isLetter(cp));
    }
    cp = 'A';
    while (cp <= 'Z') : (cp += 1) {
        expect(z.isLetter(cp));
    }
    expect(z.isLetter('É'));
    expect(z.isLetter('\u{2CEB3}'));
    expect(!z.isLetter('\u{0003}'));
}

test "isMark" {
    var z = try Mark.init(std.testing.allocator);
    defer z.deinit();

    expect(z.isMark('\u{20E4}'));
    expect(!z.isMark('='));
}

test "isNumber" {
    var z = try Number.init(std.testing.allocator);
    defer z.deinit();

    var cp: u21 = '0';
    while (cp <= '9') : (cp += 1) {
        expect(z.isNumber(cp));
    }
    expect(!z.isNumber('\u{0003}'));
    expect(!z.isNumber('A'));
}

test "isPunct" {
    var z = try Punct.init(std.testing.allocator);
    defer z.deinit();

    expect(z.isPunct('!'));
    expect(z.isPunct('?'));
    expect(z.isPunct(','));
    expect(z.isPunct('.'));
    expect(z.isPunct(':'));
    expect(z.isPunct(';'));
    expect(z.isPunct('\''));
    expect(z.isPunct('"'));
    expect(z.isPunct('¿'));
    expect(z.isPunct('¡'));
    expect(z.isPunct('-'));
    expect(z.isPunct('('));
    expect(z.isPunct(')'));
    expect(z.isPunct('{'));
    expect(z.isPunct('}'));
    expect(z.isPunct('–'));
    // Punct? in Unicode.
    expect(z.isPunct('@'));
    expect(z.isPunct('#'));
    expect(z.isPunct('%'));
    expect(z.isPunct('&'));
    expect(z.isPunct('*'));
    expect(z.isPunct('_'));
    expect(z.isPunct('/'));
    expect(z.isPunct('\\'));
    expect(!z.isPunct('\u{0003}'));
}

test "isSpace" {
    var z = try Ziglyph.init(std.testing.allocator);
    defer z.deinit();

    expect(try z.isSpace(' '));
    expect(try z.isSpace('\t'));
    expect(!try z.isSpace('\u{0003}'));
}

test "isSymbol" {
    var z = try Symbol.init(std.testing.allocator);
    defer z.deinit();

    expect(z.isSymbol('<'));
    expect(z.isSymbol('>'));
    expect(z.isSymbol('='));
    expect(z.isSymbol('$'));
    expect(z.isSymbol('^'));
    expect(z.isSymbol('+'));
    expect(z.isSymbol('|'));
    expect(!z.isSymbol('A'));
    expect(!z.isSymbol('?'));
}

test "isAlphaNum" {
    var z = try Ziglyph.init(std.testing.allocator);
    defer z.deinit();

    var cp: u21 = '0';
    while (cp <= '9') : (cp += 1) {
        expect(try z.isAlphaNum(cp));
    }
    cp = 'a';
    while (cp <= 'z') : (cp += 1) {
        expect(try z.isAlphaNum(cp));
    }
    cp = 'A';
    while (cp <= 'Z') : (cp += 1) {
        expect(try z.isAlphaNum(cp));
    }
    expect(!try z.isAlphaNum('='));
}

test "decomposeCodePoint" {
    var z = try DecomposeMap.init(std.testing.allocator);
    defer z.deinit();

    var result = z.decomposeCodePoint('\u{00E9}');
    switch (result) {
        .same => @panic("Expected .seq, got .same for \\u{00E9}"),
        .seq => |seq| expectEqualSlices(u21, seq, &[_]u21{ '\u{0065}', '\u{0301}' }),
    }
    result = z.decomposeCodePoint('A');
    switch (result) {
        .same => |cp| expectEqual(cp, 'A'),
        .seq => @panic("Expected .seq, got .same for \\u{00E9}"),
    }
}

test "decomposeString" {
    var z = try DecomposeMap.init(std.testing.allocator);
    defer z.deinit();

    const input = "H\u{00E9}llo";
    const want = "H\u{0065}\u{0301}llo";
    const got = try z.decomposeString(input);
    defer std.testing.allocator.free(got);
    expectEqualSlices(u8, want, got);
}
