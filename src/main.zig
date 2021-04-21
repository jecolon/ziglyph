const std = @import("std");
const ArrayList = std.ArrayList;
const expect = std.testing.expect;
const expectEqual = std.testing.expectEqual;
const expectEqualSlices = std.testing.expectEqualSlices;
const io = std.io;
const fmt = std.fmt;
const mem = std.mem;
const unicode = std.unicode;

const Control = @import("ziglyph.zig").Control;
const DecomposeMap = @import("ziglyph.zig").DecomposeMap;
const Decomposed = DecomposeMap.Decomposed;
const GraphemeIterator = @import("ziglyph.zig").GraphemeIterator;
const Letter = @import("ziglyph.zig").Letter;
const Number = @import("ziglyph.zig").Number;
const Ziglyph = @import("ziglyph.zig").Ziglyph;

// UTF-8 BOM = EFBBBF
pub fn main() !void {
    var z = try Ziglyph.init(std.testing.allocator);
    defer z.deinit();
    var letter = try Letter.init(std.testing.allocator);
    defer letter.deinit();

    const mixed = [_]u21{ '5', 'o', '9', '!', ' ', '℃', 'ᾭ', 'G' };
    for (mixed) |r| {
        std.debug.print("\nFor {u}:\n", .{r});
        if (z.isControl(r)) { // added 1.1M to binary!!
            std.debug.print("\tis control\n", .{});
        }
        if (z.isAsciiControl(r)) { // added 1.1M to binary!!
            std.debug.print("\tis ASCII control\n", .{});
        }
        if (z.isAsciiDigit(r)) { // added 1.1M to binary!!
            std.debug.print("\tis ASCII digit\n", .{});
        }
        if (z.isNumber(r)) { // added 100K to binary
            std.debug.print("\tis number\n", .{});
        }
        if (z.isAsciiNumber(r)) { // added 100K to binary
            std.debug.print("\tis ASCII number\n", .{});
        }
        if (z.isHexDigit(r)) { // added 100K to binary
            std.debug.print("\tis hex digit\n", .{});
        }
        if (z.isAsciiHexDigit(r)) { // added 100K to binary
            std.debug.print("\tis ASCII hex digit\n", .{});
        }
        if (z.isGraphic(r)) { // added 0 to binary
            std.debug.print("\tis graphic\n", .{});
        }
        if (z.isAsciiGraphic(r)) { // added 0 to binary
            std.debug.print("\tis ASCII graphic\n", .{});
        }
        if (z.isAlphaNum(r)) { // adds 0 to binary
            std.debug.print("\tis alphanumeric\n", .{});
        }
        if (z.isAsciiAlphaNum(r)) { // adds 0 to binary
            std.debug.print("\tis ASCII alphanumeric\n", .{});
        }
        if (z.isLetter(r)) { // added 200K to binary !!
            std.debug.print("\tis letter\n", .{});
        }
        if (z.isAsciiLetter(r)) { // added 200K to binary !!
            std.debug.print("\tis ASCII letter\n", .{});
        }
        if (z.isLower(r)) { // added 200K to binary
            std.debug.print("\tis lower case\n", .{});
        }
        if (z.isAsciiLower(r)) { // added 200K to binary
            std.debug.print("\tis ASCII lower case\n", .{});
        }
        if (z.isMark(r)) { // added 1.1M to binary !!
            std.debug.print("\tis mark\n", .{});
        }
        if (z.isPrint(r)) { // added 0 to binary
            std.debug.print("\tis printable\n", .{});
        }
        if (z.isAsciiPrint(r)) { // added 0 to binary
            std.debug.print("\tis ASCII printable\n", .{});
        }
        if (!z.isPrint(r)) {
            std.debug.print("\tis not printable\n", .{});
        }
        if (!z.isAsciiPrint(r)) {
            std.debug.print("\tis not ASCII printable\n", .{});
        }
        if (z.isPunct(r)) { // added 137K to binary
            std.debug.print("\tis punct\n", .{});
        }
        if (z.isAsciiPunct(r)) { // added 137K to binary
            std.debug.print("\tis ASCII punct\n", .{});
        }
        if (z.isWhiteSpace(r)) { // Adds 12K to binary
            std.debug.print("\tis whitespace\n", .{});
        }
        if (z.isAsciiWhiteSpace(r)) { // Adds 12K to binary
            std.debug.print("\tis ASCII whitespace\n", .{});
        }
        if (z.isSymbol(r)) { // added 131K to binary
            std.debug.print("\tis symbol\n", .{});
        }
        if (z.isAsciiSymbol(r)) { // added 131K to binary
            std.debug.print("\tis ASCII symbol\n", .{});
        }
        if (z.isTitle(r)) { // Base binary at 18K
            std.debug.print("\tis title case\n", .{});
        }
        if (z.isUpper(r)) { // added 100K to binary
            std.debug.print("\tis upper case\n", .{});
            std.debug.print("\tcase folded: {}\n", .{letter.toCaseFold(r)});
        }
        if (z.isAsciiUpper(r)) { // added 100K to binary
            std.debug.print("\tis ASCII upper case\n", .{});
        }
    }
}

test "ASCII methods" {
    var ziglyph = try Ziglyph.init(std.testing.allocator);
    defer ziglyph.deinit();

    const z = 'F';
    expect(ziglyph.isAsciiAlphabetic(z));
    expect(ziglyph.isAsciiAlphaNum(z));
    expect(ziglyph.isAsciiHexDigit(z));
    expect(ziglyph.isAsciiGraphic(z));
    expect(ziglyph.isAsciiPrint(z));
    expect(ziglyph.isAsciiUpper(z));
    expect(!ziglyph.isAsciiControl(z));
    expect(!ziglyph.isAsciiDigit(z));
    expect(!ziglyph.isAsciiNumber(z));
    expect(!ziglyph.isAsciiLower(z));
    expectEqual(ziglyph.toAsciiLower(z), 'f');
    expect(ziglyph.isAsciiLower(ziglyph.toAsciiLower(z)));
}

test "Ziglyph struct" {
    // init and defer deinit.
    var ziglyph = try Ziglyph.init(std.testing.allocator);
    defer ziglyph.deinit();

    const z = 'z';
    expect(ziglyph.isAlphaNum(z));
    expect(!ziglyph.isControl(z));
    expect(!ziglyph.isDecimal(z));
    expect(!ziglyph.isDigit(z));
    expect(!ziglyph.isHexDigit(z));
    expect(ziglyph.isGraphic(z));
    expect(ziglyph.isLetter(z));
    expect(ziglyph.isLower(z));
    expect(!ziglyph.isMark(z));
    expect(!ziglyph.isNumber(z));
    expect(ziglyph.isPrint(z));
    expect(!ziglyph.isPunct(z));
    expect(!ziglyph.isWhiteSpace(z));
    expect(!ziglyph.isSymbol(z));
    expect(!ziglyph.isTitle(z));
    expect(!ziglyph.isUpper(z));
    const uz = ziglyph.toUpper(z);
    expect(ziglyph.isUpper(uz));
    expectEqual(uz, 'Z');
    const lz = ziglyph.toLower(uz);
    expect(ziglyph.isLower(lz));
    expectEqual(lz, 'z');
    const tz = ziglyph.toTitle(lz);
    expect(ziglyph.isUpper(tz));
    expectEqual(tz, 'Z');
}

test "Component struct" {
    // Simple structs don't require init / deinit.
    var letter = try Letter.init(std.testing.allocator);
    defer letter.deinit();

    const z = 'z';
    expect(letter.isLetter(z));
    expect(!letter.isUpper(z));
    const uz = letter.toUpper(z);
    expect(letter.isUpper(uz));
    expectEqual(uz, 'Z');
}

test "basics" {
    var z = try Ziglyph.init(std.testing.allocator);
    defer z.deinit();

    const mixed = [_]u21{ '5', 'o', '9', '!', ' ', '℃', 'ᾭ', 'G' };
    for (mixed) |r| {
        std.debug.print("\nFor {u}:\n", .{r});
        if (z.isControl(r)) { // added 1.1M to binary!!
            std.debug.print("\tis control\n", .{});
        }
        if (z.isAsciiControl(r)) { // added 1.1M to binary!!
            std.debug.print("\tis ASCII control\n", .{});
        }
        if (z.isAsciiDigit(r)) { // added 1.1M to binary!!
            std.debug.print("\tis ASCII digit\n", .{});
        }
        if (z.isNumber(r)) { // added 100K to binary
            std.debug.print("\tis number\n", .{});
        }
        if (z.isAsciiNumber(r)) { // added 100K to binary
            std.debug.print("\tis ASCII number\n", .{});
        }
        if (z.isHexDigit(r)) { // added 100K to binary
            std.debug.print("\tis hex digit\n", .{});
        }
        if (z.isAsciiHexDigit(r)) { // added 100K to binary
            std.debug.print("\tis ASCII hex digit\n", .{});
        }
        if (z.isGraphic(r)) { // added 0 to binary
            std.debug.print("\tis graphic\n", .{});
        }
        if (z.isAsciiGraphic(r)) { // added 0 to binary
            std.debug.print("\tis ASCII graphic\n", .{});
        }
        if (z.isAlphaNum(r)) { // adds 0 to binary
            std.debug.print("\tis alphanumeric\n", .{});
        }
        if (z.isAsciiAlphaNum(r)) { // adds 0 to binary
            std.debug.print("\tis ASCII alphanumeric\n", .{});
        }
        if (z.isLetter(r)) { // added 200K to binary !!
            std.debug.print("\tis letter\n", .{});
        }
        if (z.isAsciiLetter(r)) { // added 200K to binary !!
            std.debug.print("\tis ASCII letter\n", .{});
        }
        if (z.isLower(r)) { // added 200K to binary
            std.debug.print("\tis lower case\n", .{});
        }
        if (z.isAsciiLower(r)) { // added 200K to binary
            std.debug.print("\tis ASCII lower case\n", .{});
        }
        if (z.isMark(r)) { // added 1.1M to binary !!
            std.debug.print("\tis mark\n", .{});
        }
        if (z.isPrint(r)) { // added 0 to binary
            std.debug.print("\tis printable\n", .{});
        }
        if (z.isAsciiPrint(r)) { // added 0 to binary
            std.debug.print("\tis ASCII printable\n", .{});
        }
        if (!z.isPrint(r)) {
            std.debug.print("\tis not printable\n", .{});
        }
        if (!z.isAsciiPrint(r)) {
            std.debug.print("\tis not ASCII printable\n", .{});
        }
        if (z.isPunct(r)) { // added 137K to binary
            std.debug.print("\tis punct\n", .{});
        }
        if (z.isAsciiPunct(r)) { // added 137K to binary
            std.debug.print("\tis ASCII punct\n", .{});
        }
        if (z.isWhiteSpace(r)) { // Adds 12K to binary
            std.debug.print("\tis whitespace\n", .{});
        }
        if (z.isAsciiWhiteSpace(r)) { // Adds 12K to binary
            std.debug.print("\tis ASCII whitespace\n", .{});
        }
        if (z.isSymbol(r)) { // added 131K to binary
            std.debug.print("\tis symbol\n", .{});
        }
        if (z.isAsciiSymbol(r)) { // added 131K to binary
            std.debug.print("\tis ASCII symbol\n", .{});
        }
        if (z.isTitle(r)) { // Base binary at 18K
            std.debug.print("\tis title case\n", .{});
        }
        if (z.isUpper(r)) { // added 100K to binary
            std.debug.print("\tis upper case\n", .{});
        }
        if (z.isAsciiUpper(r)) { // added 100K to binary
            std.debug.print("\tis ASCII upper case\n", .{});
        }
    }
}

test "isCased" {
    var z = try Letter.init(std.testing.allocator);
    defer z.deinit();

    expect(z.isCased('a'));
    expect(z.isCased('A'));
    expect(!z.isCased('1'));
}

test "isLower" {
    var z = try Letter.init(std.testing.allocator);
    defer z.deinit();

    expect(z.isLower('a'));
    expect(z.isLower('é'));
    expect(z.isLower('i'));
    expect(!z.isLower('A'));
    expect(!z.isLower('É'));
    expect(!z.isLower('İ'));
    // Numbers are lower, upper, and title all at once.
    expect(z.isLower('1'));
}

test "toCaseFold" {
    var z = try Letter.init(std.testing.allocator);
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
    var z = try Letter.init(std.testing.allocator);
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
    expectEqual(z.toLower('1'), '1');
}

test "isUpper" {
    var z = try Letter.init(std.testing.allocator);
    defer z.deinit();

    expect(!z.isUpper('a'));
    expect(!z.isUpper('é'));
    expect(!z.isUpper('i'));
    expect(z.isUpper('A'));
    expect(z.isUpper('É'));
    expect(z.isUpper('İ'));
    // Numbers are lower, upper, and title all at once.
    expect(z.isUpper('1'));
}

test "toUpper" {
    var z = try Letter.init(std.testing.allocator);
    defer z.deinit();

    expectEqual(z.toUpper('a'), 'A');
    expectEqual(z.toUpper('A'), 'A');
    expectEqual(z.toUpper('i'), 'I');
    expectEqual(z.toUpper('é'), 'É');
    expectEqual(z.toUpper(0x80), 0x80);
    expectEqual(z.toUpper('Å'), 'Å');
    expectEqual(z.toUpper('å'), 'Å');
    expectEqual(z.toUpper('1'), '1');
}

test "isTitle" {
    var z = try Letter.init(std.testing.allocator);
    defer z.deinit();

    expect(!z.isTitle('a'));
    expect(!z.isTitle('é'));
    expect(!z.isTitle('i'));
    expect(z.isTitle('\u{1FBC}'));
    expect(z.isTitle('\u{1FCC}'));
    expect(z.isTitle('ǈ'));
    // Numbers are lower, upper, and title all at once.
    expect(z.isTitle('1'));
}

test "toTitle" {
    var z = try Letter.init(std.testing.allocator);
    defer z.deinit();

    expectEqual(z.toTitle('a'), 'A');
    expectEqual(z.toTitle('A'), 'A');
    expectEqual(z.toTitle('i'), 'I');
    expectEqual(z.toTitle('é'), 'É');
    expectEqual(z.toTitle('1'), '1');
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
    var z = try Number.init(std.testing.allocator);
    defer z.deinit();

    var cp: u21 = '0';
    while (cp <= '9') : (cp += 1) {
        expect(z.isDecimal(cp));
    }
    expect(!z.isDecimal('\u{0003}'));
    expect(!z.isDecimal('A'));
}

test "isHexDigit" {
    var z = try Number.init(std.testing.allocator);
    defer z.deinit();

    var cp: u21 = '0';
    while (cp <= '9') : (cp += 1) {
        expect(z.isHexDigit(cp));
    }
    expect(!z.isHexDigit('\u{0003}'));
    expect(!z.isHexDigit('Z'));
}

test "isGraphic" {
    var z = try Ziglyph.init(std.testing.allocator);
    defer z.deinit();

    expect(z.isGraphic('A'));
    expect(z.isGraphic('\u{20E4}'));
    expect(z.isGraphic('1'));
    expect(z.isGraphic('?'));
    expect(z.isGraphic(' '));
    expect(z.isGraphic('='));
    expect(!z.isGraphic('\u{0003}'));
}

test "isHexDigit" {
    var z = try Ziglyph.init(std.testing.allocator);
    defer z.deinit();

    var cp: u21 = '0';
    while (cp <= '9') : (cp += 1) {
        expect(z.isHexDigit(cp));
    }
    cp = 'A';
    while (cp <= 'F') : (cp += 1) {
        expect(z.isHexDigit(cp));
    }
    cp = 'a';
    while (cp <= 'f') : (cp += 1) {
        expect(z.isHexDigit(cp));
    }
    expect(!z.isHexDigit('\u{0003}'));
    expect(!z.isHexDigit('Z'));
}

test "isPrint" {
    var z = try Ziglyph.init(std.testing.allocator);
    defer z.deinit();

    expect(z.isPrint('A'));
    expect(z.isPrint('\u{20E4}'));
    expect(z.isPrint('1'));
    expect(z.isPrint('?'));
    expect(z.isPrint('='));
    expect(z.isPrint(' '));
    expect(z.isPrint('\t'));
    expect(!z.isPrint('\u{0003}'));
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
    var z = try Ziglyph.init(std.testing.allocator);
    defer z.deinit();

    expect(z.isMark('\u{20E4}'));
    expect(!z.isMark('='));
}

test "isNumber" {
    var z = try Ziglyph.init(std.testing.allocator);
    defer z.deinit();

    var cp: u21 = '0';
    while (cp <= '9') : (cp += 1) {
        expect(z.isNumber(cp));
    }
    expect(!z.isNumber('\u{0003}'));
    expect(!z.isNumber('A'));
}

test "isPunct" {
    var z = try Ziglyph.init(std.testing.allocator);
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

test "isWhiteSpace" {
    var z = try Ziglyph.init(std.testing.allocator);
    defer z.deinit();

    expect(z.isWhiteSpace(' '));
    expect(z.isWhiteSpace('\t'));
    expect(!z.isWhiteSpace('\u{0003}'));
}

test "isSymbol" {
    var z = try Ziglyph.init(std.testing.allocator);
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
        expect(z.isAlphaNum(cp));
    }
    cp = 'a';
    while (cp <= 'z') : (cp += 1) {
        expect(z.isAlphaNum(cp));
    }
    cp = 'A';
    while (cp <= 'Z') : (cp += 1) {
        expect(z.isAlphaNum(cp));
    }
    expect(!z.isAlphaNum('='));
}

test "codePointTo D" {
    var allocator = std.testing.allocator;
    var z = try DecomposeMap.init(allocator);
    defer z.deinit();

    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    var arena_allocator = &arena.allocator;

    var result = try z.codePointTo(arena_allocator, .D, '\u{00E9}');
    expectEqualSlices(u21, result, &[2]u21{ 0x0065, 0x0301 });

    result = try z.codePointTo(arena_allocator, .D, '\u{03D3}');
    expectEqualSlices(u21, result, &[2]u21{ 0x03D2, 0x0301 });
}

test "codePointTo KD" {
    var allocator = std.testing.allocator;
    var z = try DecomposeMap.init(allocator);
    defer z.deinit();

    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    var arena_allocator = &arena.allocator;

    var result = try z.codePointTo(arena_allocator, .KD, '\u{00E9}');
    expectEqualSlices(u21, result, &[2]u21{ 0x0065, 0x0301 });

    result = try z.codePointTo(arena_allocator, .KD, '\u{03D3}');
    expectEqualSlices(u21, result, &[2]u21{ 0x03A5, 0x0301 });
}

test "normalizeTo" {
    var allocator = std.testing.allocator;
    var z = try DecomposeMap.init(allocator);
    defer z.deinit();

    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    var arena_allocator = &arena.allocator;

    var file = try std.fs.cwd().openFile("src/data/ucd/NormalizationTest.txt", .{});
    defer file.close();
    var buf_reader = io.bufferedReader(file.reader());
    var input_stream = buf_reader.reader();
    var buf: [640]u8 = undefined;
    while (try input_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        // Skip comments or empty lines.
        if (line.len == 0 or line[0] == '#' or line[0] == '@') continue;
        // Iterate over fields.
        var fields = mem.split(line, ";");
        var field_index: usize = 0;
        var input: []u8 = undefined;
        while (fields.next()) |field| : (field_index += 1) {
            if (field_index == 0) {
                var i_buf = ArrayList(u8).init(arena_allocator);
                var i_fields = mem.split(field, " ");
                while (i_fields.next()) |s| {
                    const icp = try fmt.parseInt(u21, s, 16);
                    var cp_buf: [4]u8 = undefined;
                    const len = try unicode.utf8Encode(icp, &cp_buf);
                    try i_buf.appendSlice(cp_buf[0..len]);
                }
                input = i_buf.toOwnedSlice();
            } else if (field_index == 2) {
                // NFD, time to test.
                var w_buf = ArrayList(u8).init(arena_allocator);
                var w_fields = mem.split(field, " ");
                while (w_fields.next()) |s| {
                    const wcp = try fmt.parseInt(u21, s, 16);
                    var cp_buf: [4]u8 = undefined;
                    const len = try unicode.utf8Encode(wcp, &cp_buf);
                    try w_buf.appendSlice(cp_buf[0..len]);
                }
                const want = w_buf.toOwnedSlice();
                const got = try z.normalizeTo(arena_allocator, .D, input);
                expectEqualSlices(u8, want, got);
                continue;
            } else if (field_index == 4) {
                // NFKD, time to test.
                var w_buf = ArrayList(u8).init(arena_allocator);
                var w_fields = mem.split(field, " ");
                while (w_fields.next()) |s| {
                    const wcp = try fmt.parseInt(u21, s, 16);
                    var cp_buf: [4]u8 = undefined;
                    const len = try unicode.utf8Encode(wcp, &cp_buf);
                    try w_buf.appendSlice(cp_buf[0..len]);
                }
                const want = w_buf.toOwnedSlice();
                const got = try z.normalizeTo(arena_allocator, .KD, input);
                expectEqualSlices(u8, want, got);
                continue;
            } else {
                continue;
            }
        }
    }
}

test "isAsciiStr" {
    var z = try Ziglyph.init(std.testing.allocator);
    defer z.deinit();

    expect(try z.isAsciiStr("Hello!"));
    expect(!try z.isAsciiStr("Héllo!"));
}

test "isLatin1Str" {
    var z = try Ziglyph.init(std.testing.allocator);
    defer z.deinit();

    expect(try z.isLatin1Str("Hello!"));
    expect(try z.isLatin1Str("Héllo!"));
    expect(!try z.isLatin1Str("H\u{0065}\u{0301}llo!"));
    expect(!try z.isLatin1Str("H😀llo!"));
}

test "grapheme iterator" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    var allocator = &arena.allocator;

    var file = try std.fs.cwd().openFile("src/data/ucd/auxiliary/GraphemeBreakTest.txt", .{});
    defer file.close();
    var buf_reader = io.bufferedReader(file.reader());
    var input_stream = buf_reader.reader();

    var buf: [640]u8 = undefined;
    var line_no: usize = 1;
    var giter: ?GraphemeIterator = null;

    while (try input_stream.readUntilDelimiterOrEof(&buf, '\n')) |raw| : (line_no += 1) {
        // Skip comments or empty lines.
        if (raw.len == 0 or raw[0] == '#' or raw[0] == '@') continue;

        // Clean up.
        var line = mem.trimLeft(u8, raw, "÷ ");
        if (mem.indexOf(u8, line, " ÷\t#")) |octo| {
            line = line[0..octo];
        }

        // Iterate over fields.
        var want = ArrayList([]const u8).init(allocator);
        var all_bytes = ArrayList(u8).init(allocator);
        var fields = mem.split(line, " ÷ ");

        while (fields.next()) |field| {
            var bytes = ArrayList(u8).init(allocator);
            var sub_fields = mem.split(field, " ");
            var cp_buf: [4]u8 = undefined;

            while (sub_fields.next()) |sub_field| {
                if (mem.eql(u8, sub_field, "×")) continue;
                const cp: u21 = try fmt.parseInt(u21, sub_field, 16);
                const len = try unicode.utf8Encode(cp, &cp_buf);
                try all_bytes.appendSlice(cp_buf[0..len]);
                try bytes.appendSlice(cp_buf[0..len]);
            }
            try want.append(bytes.toOwnedSlice());
        }

        if (giter) |*gi| {
            try gi.reinit(all_bytes.items);
        } else {
            giter = try GraphemeIterator.init(allocator, all_bytes.items);
        }

        // Chaeck.
        for (want.items) |w| {
            const g = giter.?.next().?;
            //std.debug.print("line {d}: w:{s}, g:{s}\n", .{ line_no, w, g });
            expectEqualSlices(u8, w, g);
        }
    }
}
