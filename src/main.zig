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
const Letter = @import("ziglyph.zig").Letter;
const Number = @import("ziglyph.zig").Number;
const Ziglyph = @import("ziglyph.zig").Ziglyph;
const GraphemeIterator = @import("zigstr/Zigstr.zig").GraphemeIterator;

// UTF-8 BOM = EFBBBF
pub fn main() !void {
    var z = Ziglyph.init(std.testing.allocator);
    defer z.deinit();
    var letter = try Letter.init(std.testing.allocator);
    defer letter.deinit();

    var fold_map = try letter.init(std.testing.allocator);
    defer fold_map.deinit();

    const mixed = [_]u21{ '5', 'o', '9', '!', ' ', '℃', 'ᾭ', 'G' };
    for (mixed) |r| {
        std.debug.print("\nFor {u}:\n", .{r});
        if (try z.isControl(r)) { // added 1.1M to binary!!
            std.debug.print("\tis control\n", .{});
        }
        if (z.isAsciiControl(r)) { // added 1.1M to binary!!
            std.debug.print("\tis ASCII control\n", .{});
        }
        if (z.isAsciiDigit(r)) { // added 1.1M to binary!!
            std.debug.print("\tis ASCII digit\n", .{});
        }
        if (try z.isNumber(r)) { // added 100K to binary
            std.debug.print("\tis number\n", .{});
        }
        if (z.isAsciiNumber(r)) { // added 100K to binary
            std.debug.print("\tis ASCII number\n", .{});
        }
        if (try z.isHexDigit(r)) { // added 100K to binary
            std.debug.print("\tis hex digit\n", .{});
        }
        if (z.isAsciiHexDigit(r)) { // added 100K to binary
            std.debug.print("\tis ASCII hex digit\n", .{});
        }
        if (try z.isGraphic(r)) { // added 0 to binary
            std.debug.print("\tis graphic\n", .{});
        }
        if (z.isAsciiGraphic(r)) { // added 0 to binary
            std.debug.print("\tis ASCII graphic\n", .{});
        }
        if (try z.isAlphaNum(r)) { // adds 0 to binary
            std.debug.print("\tis alphanumeric\n", .{});
        }
        if (z.isAsciiAlphaNum(r)) { // adds 0 to binary
            std.debug.print("\tis ASCII alphanumeric\n", .{});
        }
        if (try z.isLetter(r)) { // added 200K to binary !!
            std.debug.print("\tis letter\n", .{});
        }
        if (z.isAsciiLetter(r)) { // added 200K to binary !!
            std.debug.print("\tis ASCII letter\n", .{});
        }
        if (try z.isLower(r)) { // added 200K to binary
            std.debug.print("\tis lower case\n", .{});
        }
        if (z.isAsciiLower(r)) { // added 200K to binary
            std.debug.print("\tis ASCII lower case\n", .{});
        }
        if (try z.isMark(r)) { // added 1.1M to binary !!
            std.debug.print("\tis mark\n", .{});
        }
        if (try z.isPrint(r)) { // added 0 to binary
            std.debug.print("\tis printable\n", .{});
        }
        if (z.isAsciiPrint(r)) { // added 0 to binary
            std.debug.print("\tis ASCII printable\n", .{});
        }
        if (!try z.isPrint(r)) {
            std.debug.print("\tis not printable\n", .{});
        }
        if (!z.isAsciiPrint(r)) {
            std.debug.print("\tis not ASCII printable\n", .{});
        }
        if (try z.isPunct(r)) { // added 137K to binary
            std.debug.print("\tis punct\n", .{});
        }
        if (z.isAsciiPunct(r)) { // added 137K to binary
            std.debug.print("\tis ASCII punct\n", .{});
        }
        if (try z.isWhiteSpace(r)) { // Adds 12K to binary
            std.debug.print("\tis whitespace\n", .{});
        }
        if (z.isAsciiWhiteSpace(r)) { // Adds 12K to binary
            std.debug.print("\tis ASCII whitespace\n", .{});
        }
        if (try z.isSymbol(r)) { // added 131K to binary
            std.debug.print("\tis symbol\n", .{});
        }
        if (z.isAsciiSymbol(r)) { // added 131K to binary
            std.debug.print("\tis ASCII symbol\n", .{});
        }
        if (try z.isTitle(r)) { // Base binary at 18K
            std.debug.print("\tis title case\n", .{});
        }
        if (try z.isUpper(r)) { // added 100K to binary
            std.debug.print("\tis upper case\n", .{});
            std.debug.print("\tcase folded: {}\n", .{fold_map.toCaseFold(r)});
        }
        if (z.isAsciiUpper(r)) { // added 100K to binary
            std.debug.print("\tis ASCII upper case\n", .{});
        }
    }
}

test "ASCII methods" {
    var ziglyph = Ziglyph.init(std.testing.allocator);
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
    var ziglyph = Ziglyph.init(std.testing.allocator);
    defer ziglyph.deinit();

    const z = 'z';
    expect(try ziglyph.isAlphaNum(z));
    expect(!try ziglyph.isControl(z));
    expect(!try ziglyph.isDecimal(z));
    expect(!try ziglyph.isDigit(z));
    expect(!try ziglyph.isHexDigit(z));
    expect(try ziglyph.isGraphic(z));
    expect(try ziglyph.isLetter(z));
    expect(try ziglyph.isLower(z));
    expect(!try ziglyph.isMark(z));
    expect(!try ziglyph.isNumber(z));
    expect(try ziglyph.isPrint(z));
    expect(!try ziglyph.isPunct(z));
    expect(!try ziglyph.isWhiteSpace(z));
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

test "Component struct" {
    // Simple structs don't require init / deinit.
    var letter = try Letter.init(std.testing.allocator);
    defer letter.deinit();

    const z = 'z';
    expect(try letter.isLetter(z));
    expect(!try letter.isUpper(z));
    const uz = try letter.toUpper(z);
    expect(try letter.isUpper(uz));
    expectEqual(uz, 'Z');
}

test "basics" {
    var z = Ziglyph.init(std.testing.allocator);
    defer z.deinit();

    const mixed = [_]u21{ '5', 'o', '9', '!', ' ', '℃', 'ᾭ', 'G' };
    for (mixed) |r| {
        std.debug.print("\nFor {u}:\n", .{r});
        if (try z.isControl(r)) { // added 1.1M to binary!!
            std.debug.print("\tis control\n", .{});
        }
        if (z.isAsciiControl(r)) { // added 1.1M to binary!!
            std.debug.print("\tis ASCII control\n", .{});
        }
        if (z.isAsciiDigit(r)) { // added 1.1M to binary!!
            std.debug.print("\tis ASCII digit\n", .{});
        }
        if (try z.isNumber(r)) { // added 100K to binary
            std.debug.print("\tis number\n", .{});
        }
        if (z.isAsciiNumber(r)) { // added 100K to binary
            std.debug.print("\tis ASCII number\n", .{});
        }
        if (try z.isHexDigit(r)) { // added 100K to binary
            std.debug.print("\tis hex digit\n", .{});
        }
        if (z.isAsciiHexDigit(r)) { // added 100K to binary
            std.debug.print("\tis ASCII hex digit\n", .{});
        }
        if (try z.isGraphic(r)) { // added 0 to binary
            std.debug.print("\tis graphic\n", .{});
        }
        if (z.isAsciiGraphic(r)) { // added 0 to binary
            std.debug.print("\tis ASCII graphic\n", .{});
        }
        if (try z.isAlphaNum(r)) { // adds 0 to binary
            std.debug.print("\tis alphanumeric\n", .{});
        }
        if (z.isAsciiAlphaNum(r)) { // adds 0 to binary
            std.debug.print("\tis ASCII alphanumeric\n", .{});
        }
        if (try z.isLetter(r)) { // added 200K to binary !!
            std.debug.print("\tis letter\n", .{});
        }
        if (z.isAsciiLetter(r)) { // added 200K to binary !!
            std.debug.print("\tis ASCII letter\n", .{});
        }
        if (try z.isLower(r)) { // added 200K to binary
            std.debug.print("\tis lower case\n", .{});
        }
        if (z.isAsciiLower(r)) { // added 200K to binary
            std.debug.print("\tis ASCII lower case\n", .{});
        }
        if (try z.isMark(r)) { // added 1.1M to binary !!
            std.debug.print("\tis mark\n", .{});
        }
        if (try z.isPrint(r)) { // added 0 to binary
            std.debug.print("\tis printable\n", .{});
        }
        if (z.isAsciiPrint(r)) { // added 0 to binary
            std.debug.print("\tis ASCII printable\n", .{});
        }
        if (!try z.isPrint(r)) {
            std.debug.print("\tis not printable\n", .{});
        }
        if (!z.isAsciiPrint(r)) {
            std.debug.print("\tis not ASCII printable\n", .{});
        }
        if (try z.isPunct(r)) { // added 137K to binary
            std.debug.print("\tis punct\n", .{});
        }
        if (z.isAsciiPunct(r)) { // added 137K to binary
            std.debug.print("\tis ASCII punct\n", .{});
        }
        if (try z.isWhiteSpace(r)) { // Adds 12K to binary
            std.debug.print("\tis whitespace\n", .{});
        }
        if (z.isAsciiWhiteSpace(r)) { // Adds 12K to binary
            std.debug.print("\tis ASCII whitespace\n", .{});
        }
        if (try z.isSymbol(r)) { // added 131K to binary
            std.debug.print("\tis symbol\n", .{});
        }
        if (z.isAsciiSymbol(r)) { // added 131K to binary
            std.debug.print("\tis ASCII symbol\n", .{});
        }
        if (try z.isTitle(r)) { // Base binary at 18K
            std.debug.print("\tis title case\n", .{});
        }
        if (try z.isUpper(r)) { // added 100K to binary
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

    expect(try z.isCased('a'));
    expect(try z.isCased('A'));
    expect(!try z.isCased('1'));
}

test "isLower" {
    var z = try Letter.init(std.testing.allocator);
    defer z.deinit();

    expect(try z.isLower('a'));
    expect(try z.isLower('é'));
    expect(try z.isLower('i'));
    expect(!try z.isLower('A'));
    expect(!try z.isLower('É'));
    expect(!try z.isLower('İ'));
    // Numbers are lower, upper, and title all at once.
    expect(try z.isLower('1'));
}

test "toCaseFold" {
    var z = try Letter.init(std.testing.allocator);
    defer z.deinit();

    var result = try z.toCaseFold('A');
    switch (result) {
        .simple => |cp| expectEqual(cp, 'a'),
        .full => @panic("Got .full, wanted .simple for A"),
    }
    result = try z.toCaseFold('a');
    switch (result) {
        .simple => |cp| expectEqual(cp, 'a'),
        .full => @panic("Got .full, wanted .simple for a"),
    }
    result = try z.toCaseFold('1');
    switch (result) {
        .simple => |cp| expectEqual(cp, '1'),
        .full => @panic("Got .full, wanted .simple for 1"),
    }
    result = try z.toCaseFold('\u{00DF}');
    switch (result) {
        .simple => @panic("Got .simple, wanted .full for 0x00DF"),
        .full => |s| expectEqualSlices(u21, s, &[_]u21{ 0x0073, 0x0073 }),
    }
    result = try z.toCaseFold('\u{0390}');
    switch (result) {
        .simple => @panic("Got .simple, wanted .full for 0x0390"),
        .full => |s| expectEqualSlices(u21, s, &[_]u21{ 0x03B9, 0x0308, 0x0301 }),
    }
}

test "toLower" {
    var z = try Letter.init(std.testing.allocator);
    defer z.deinit();

    expectEqual(try z.toLower('a'), 'a');
    expectEqual(try z.toLower('A'), 'a');
    expectEqual(try z.toLower('İ'), 'i');
    expectEqual(try z.toLower('É'), 'é');
    expectEqual(try z.toLower(0x80), 0x80);
    expectEqual(try z.toLower(0x80), 0x80);
    expectEqual(try z.toLower('Å'), 'å');
    expectEqual(try z.toLower('å'), 'å');
    expectEqual(try z.toLower('\u{212A}'), 'k');
    expectEqual(try z.toLower('1'), '1');
}

test "isUpper" {
    var z = try Letter.init(std.testing.allocator);
    defer z.deinit();

    expect(!try z.isUpper('a'));
    expect(!try z.isUpper('é'));
    expect(!try z.isUpper('i'));
    expect(try z.isUpper('A'));
    expect(try z.isUpper('É'));
    expect(try z.isUpper('İ'));
    // Numbers are lower, upper, and title all at once.
    expect(try z.isUpper('1'));
}

test "toUpper" {
    var z = try Letter.init(std.testing.allocator);
    defer z.deinit();

    expectEqual(try z.toUpper('a'), 'A');
    expectEqual(try z.toUpper('A'), 'A');
    expectEqual(try z.toUpper('i'), 'I');
    expectEqual(try z.toUpper('é'), 'É');
    expectEqual(try z.toUpper(0x80), 0x80);
    expectEqual(try z.toUpper('Å'), 'Å');
    expectEqual(try z.toUpper('å'), 'Å');
    expectEqual(try z.toUpper('1'), '1');
}

test "isTitle" {
    var z = try Letter.init(std.testing.allocator);
    defer z.deinit();

    expect(!try z.isTitle('a'));
    expect(!try z.isTitle('é'));
    expect(!try z.isTitle('i'));
    expect(try z.isTitle('\u{1FBC}'));
    expect(try z.isTitle('\u{1FCC}'));
    expect(try z.isTitle('ǈ'));
    // Numbers are lower, upper, and title all at once.
    expect(try z.isTitle('1'));
}

test "toTitle" {
    var z = try Letter.init(std.testing.allocator);
    defer z.deinit();

    expectEqual(try z.toTitle('a'), 'A');
    expectEqual(try z.toTitle('A'), 'A');
    expectEqual(try z.toTitle('i'), 'I');
    expectEqual(try z.toTitle('é'), 'É');
    expectEqual(try z.toTitle('1'), '1');
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
        expect(try z.isDecimal(cp));
    }
    expect(!try z.isDecimal('\u{0003}'));
    expect(!try z.isDecimal('A'));
}

test "isHexDigit" {
    var z = try Number.init(std.testing.allocator);
    defer z.deinit();

    var cp: u21 = '0';
    while (cp <= '9') : (cp += 1) {
        expect(try z.isHexDigit(cp));
    }
    expect(!try z.isHexDigit('\u{0003}'));
    expect(!try z.isHexDigit('Z'));
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

test "isHexDigit" {
    var z = Ziglyph.init(std.testing.allocator);
    defer z.deinit();

    var cp: u21 = '0';
    while (cp <= '9') : (cp += 1) {
        expect(try z.isHexDigit(cp));
    }
    cp = 'A';
    while (cp <= 'F') : (cp += 1) {
        expect(try z.isHexDigit(cp));
    }
    cp = 'a';
    while (cp <= 'f') : (cp += 1) {
        expect(try z.isHexDigit(cp));
    }
    expect(!try z.isHexDigit('\u{0003}'));
    expect(!try z.isHexDigit('Z'));
}

test "isPrint" {
    var z = Ziglyph.init(std.testing.allocator);
    defer z.deinit();

    expect(try z.isPrint('A'));
    expect(try z.isPrint('\u{20E4}'));
    expect(try z.isPrint('1'));
    expect(try z.isPrint('?'));
    expect(try z.isPrint('='));
    expect(try z.isPrint(' '));
    expect(try z.isPrint('\t'));
    expect(!try z.isPrint('\u{0003}'));
}

test "isLetter" {
    var z = try Letter.init(std.testing.allocator);
    defer z.deinit();

    var cp: u21 = 'a';
    while (cp <= 'z') : (cp += 1) {
        expect(try z.isLetter(cp));
    }
    cp = 'A';
    while (cp <= 'Z') : (cp += 1) {
        expect(try z.isLetter(cp));
    }
    expect(try z.isLetter('É'));
    expect(try z.isLetter('\u{2CEB3}'));
    expect(!try z.isLetter('\u{0003}'));
}

test "isMark" {
    var z = Ziglyph.init(std.testing.allocator);
    defer z.deinit();

    expect(try z.isMark('\u{20E4}'));
    expect(!try z.isMark('='));
}

test "isNumber" {
    var z = Ziglyph.init(std.testing.allocator);
    defer z.deinit();

    var cp: u21 = '0';
    while (cp <= '9') : (cp += 1) {
        expect(try z.isNumber(cp));
    }
    expect(!try z.isNumber('\u{0003}'));
    expect(!try z.isNumber('A'));
}

test "isPunct" {
    var z = Ziglyph.init(std.testing.allocator);
    defer z.deinit();

    expect(try z.isPunct('!'));
    expect(try z.isPunct('?'));
    expect(try z.isPunct(','));
    expect(try z.isPunct('.'));
    expect(try z.isPunct(':'));
    expect(try z.isPunct(';'));
    expect(try z.isPunct('\''));
    expect(try z.isPunct('"'));
    expect(try z.isPunct('¿'));
    expect(try z.isPunct('¡'));
    expect(try z.isPunct('-'));
    expect(try z.isPunct('('));
    expect(try z.isPunct(')'));
    expect(try z.isPunct('{'));
    expect(try z.isPunct('}'));
    expect(try z.isPunct('–'));
    // Punct? in Unicode.
    expect(try z.isPunct('@'));
    expect(try z.isPunct('#'));
    expect(try z.isPunct('%'));
    expect(try z.isPunct('&'));
    expect(try z.isPunct('*'));
    expect(try z.isPunct('_'));
    expect(try z.isPunct('/'));
    expect(try z.isPunct('\\'));
    expect(!try z.isPunct('\u{0003}'));
}

test "isWhiteSpace" {
    var z = Ziglyph.init(std.testing.allocator);
    defer z.deinit();

    expect(try z.isWhiteSpace(' '));
    expect(try z.isWhiteSpace('\t'));
    expect(!try z.isWhiteSpace('\u{0003}'));
}

test "isSymbol" {
    var z = Ziglyph.init(std.testing.allocator);
    defer z.deinit();

    expect(try z.isSymbol('<'));
    expect(try z.isSymbol('>'));
    expect(try z.isSymbol('='));
    expect(try z.isSymbol('$'));
    expect(try z.isSymbol('^'));
    expect(try z.isSymbol('+'));
    expect(try z.isSymbol('|'));
    expect(!try z.isSymbol('A'));
    expect(!try z.isSymbol('?'));
}

test "isAlphaNum" {
    var z = Ziglyph.init(std.testing.allocator);
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
    var z = Ziglyph.init(std.testing.allocator);
    defer z.deinit();

    expect(try z.isAsciiStr("Hello!"));
    expect(!try z.isAsciiStr("Héllo!"));
}

test "isLatin1Str" {
    var z = Ziglyph.init(std.testing.allocator);
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
