const std = @import("std");
const expect = std.testing.expect;
const expectEqual = std.testing.expectEqual;
const expectEqualSlices = std.testing.expectEqualSlices;

const Control = @import("ziglyph.zig").Control;
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
    var z = Ziglyph.init(std.testing.allocator);
    defer z.deinit();

    const mixed = [_]u21{ '5', 'o', '9', '!', ' ', '℃', 'ᾭ', 'G' };
    for (mixed) |r| {
        std.debug.print("\nFor {u}:\n", .{r});
        if (try z.isControl(r)) { // added 1K to binary
            std.debug.print("\tis control\n", .{});
        }
        if (try z.isNumber(r)) { // added 3K to binary
            std.debug.print("\tis number\n", .{});
        }
        if (try z.isGraphic(r)) { // added 1K to binary
            std.debug.print("\tis graphic\n", .{});
        }
        if (try z.isAlphaNum(r)) {
            std.debug.print("\tis alphanumeric\n", .{});
        }
        if (try z.isLetter(r)) { // added 62K to binary !!
            std.debug.print("\tis letter\n", .{});
        }
        if (try z.isLower(r)) { // added 6K to binary
            std.debug.print("\tis lower case\n", .{});
        }
        if (try z.isMark(r)) { // added 5K to binary
            std.debug.print("\tis mark\n", .{});
        }
        if (try z.isPrint(r)) { // added 1K to binary
            std.debug.print("\tis printable\n", .{});
        }
        if (!try z.isPrint(r)) {
            std.debug.print("\tis not printable\n", .{});
        }
        if (try z.isPunct(r)) { // added 3K to binary
            std.debug.print("\tis punct\n", .{});
        }
        if (try z.isSpace(r)) {
            std.debug.print("\tis space\n", .{});
        }
        if (try z.isSymbol(r)) { // added 5K to binary
            std.debug.print("\tis symbol\n", .{});
        }
        if (try z.isTitle(r)) {
            std.debug.print("\tis title case\n", .{});
        }
        if (try z.isUpper(r)) { // added 5K to binary
            std.debug.print("\tis upper case\n", .{});
        }
    }
}

test "basics" {
    var z = Ziglyph.init(std.testing.allocator);
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

test "toLower" {
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

    expect(z.isControl('\u{0003}'));
    expect(z.isControl('\u{0012}'));
    expect(z.isControl('\u{DC01}'));
    expect(z.isControl('\u{DFF0}'));
    expect(z.isControl('\u{10FFF0}'));
    expect(!z.isControl('A'));
}

test "isGraphic" {
    var z = Ziglyph.init(std.testing.allocator);
    defer z.deinit();

    expect(try z.isGraphic('A'));
    expect(try z.isGraphic('\u{20E4}'));
    expect(try z.isGraphic('1'));
    expect(try z.isGraphic('?'));
    expect(try z.isGraphic(' '));
    expect(try z.isGraphic('='));
    expect(!try z.isGraphic('\u{0003}'));
}

test "isPrint" {
    var z = Ziglyph.init(std.testing.allocator);
    defer z.deinit();

    expect(try z.isPrint('A'));
    expect(try z.isPrint('\u{20E4}'));
    expect(try z.isPrint('1'));
    expect(try z.isPrint('?'));
    expect(try z.isPrint('='));
    expect(!try z.isPrint(' '));
    expect(!try z.isPrint('\t'));
    expect(!try z.isPrint('\u{0003}'));
}

test "isLetter" {
    var z = try Letter.init(std.testing.allocator);
    defer z.deinit();

    expect(z.isLetter('A'));
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

    expect(z.isNumber('1'));
    expect(z.isNumber('0'));
    expect(!z.isNumber('\u{0003}'));
    expect(!z.isNumber('A'));
}

test "isPunct" {
    var z = try Punct.init(std.testing.allocator);
    defer z.deinit();

    expect(z.isPunct('!'));
    expect(z.isPunct('?'));
    expect(!z.isPunct('\u{0003}'));
}

test "isSpace" {
    var z = Ziglyph.init(std.testing.allocator);
    defer z.deinit();

    expect(try z.isSpace(' '));
    expect(try z.isWhiteSpace('\t'));
    expect(!try z.isSpace('\u{0003}'));
}

test "isSymbol" {
    var z = try Symbol.init(std.testing.allocator);
    defer z.deinit();

    expect(z.isSymbol('>'));
    expect(z.isSymbol('='));
    expect(!z.isSymbol('A'));
    expect(!z.isSymbol('?'));
}

test "isAlphaNum" {
    var z = Ziglyph.init(std.testing.allocator);
    defer z.deinit();

    expect(try z.isAlphaNum('1'));
    expect(try z.isAlphaNum('A'));
    expect(!try z.isAlphaNum('='));
}

test "decomposeCodePoint" {
    var z = try DecomposeMap.init(std.testing.allocator);
    defer z.deinit();

    expectEqualSlices(u21, z.decomposeCodePoint('\u{00E9}').?, &[_]u21{ '\u{0065}', '\u{0301}' });
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
