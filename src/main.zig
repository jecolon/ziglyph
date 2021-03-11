const std = @import("std");
const ziglyph = @import("ziglyph.zig");

const expect = std.testing.expect;
const expectEqual = std.testing.expectEqual;

const casing = ziglyph.casing;
const kinds = ziglyph.kinds;
const tables = ziglyph.tables;
const values = ziglyph.values;

// Functions starting with "is" can be used to inspect which table of range a
// rune belongs to. Note that runes may fit into more than one range.
test "runeIs" {
    // constant with mixed type runes
    const mixed = [_]u21{ '5', 'o', '9', '!', ' ', '℃', 'ᾭ', 'G' };
    for (mixed) |c| {
        const r = @intCast(values.rune, c);
        std.debug.print("\nFor {u}:\n", .{c});
        if ((ziglyph.isControl(r))) {
            std.debug.print("\tis control rune\n", .{});
        }
        if ((ziglyph.isDigit(r))) {
            std.debug.print("\tis digit rune\n", .{});
        }
        if ((ziglyph.isGraphic(r))) {
            std.debug.print("\tis graphic rune\n", .{});
        }
        if ((ziglyph.isLetter(r))) {
            std.debug.print("\tis letter rune\n", .{});
        }
        if ((ziglyph.isLower(r))) {
            std.debug.print("\tis lower case rune\n", .{});
        }
        if ((ziglyph.isMark(r))) {
            std.debug.print("\tis mark rune\n", .{});
        }
        if ((ziglyph.isNumber(r))) {
            std.debug.print("\tis number rune\n", .{});
        }
        if ((ziglyph.isPrint(r))) {
            std.debug.print("\tis printable rune\n", .{});
        }
        if ((!ziglyph.isPrint(r))) {
            std.debug.print("\tis not printable rune\n", .{});
        }
        if ((ziglyph.isPunct(r))) {
            std.debug.print("\tis punct rune\n", .{});
        }
        if ((ziglyph.isSpace(r))) {
            std.debug.print("\tis space rune\n", .{});
        }
        if ((ziglyph.isSymbol(r))) {
            std.debug.print("\tis symbol rune\n", .{});
        }
        if ((ziglyph.isTitle(r))) {
            std.debug.print("\tis title case rune\n", .{});
        }
        if ((ziglyph.isUpper(r))) {
            std.debug.print("\tis upper case rune\n", .{});
        }
    }
}

test "simpleFold" {
    expectEqual(casing.simpleFold('A'), 'a');
    expectEqual(casing.simpleFold('a'), 'A');
    expectEqual(casing.simpleFold('K'), 'k');
    expectEqual(casing.simpleFold('k'), '\u{212A}');
    expectEqual(casing.simpleFold('\u{212A}'), 'K');
    expectEqual(casing.simpleFold('1'), '1');
}

test "mapTo" {
    const lcG = 'g';
    expectEqual(casing.mapTo(casing.Cases.upper, lcG), 'G');
    expectEqual(casing.mapTo(casing.Cases.lower, lcG), 'g');
    expectEqual(casing.mapTo(casing.Cases.title, lcG), 'G');

    const ucG = 'G';
    expectEqual(casing.mapTo(casing.Cases.upper, ucG), 'G');
    expectEqual(casing.mapTo(casing.Cases.lower, ucG), 'g');
    expectEqual(casing.mapTo(casing.Cases.title, ucG), 'G');
}

test "toLower" {
    const ucG = 'G';
    expectEqual(casing.toLower(ucG), 'g');
}

test "toTitle" {
    const ucG = 'g';
    expectEqual(casing.toTitle(ucG), 'G');
}

test "toUpper" {
    const ucG = 'g';
    expectEqual(casing.toUpper(ucG), 'G');
}

test "SpecialCase" {
    var t = casing.TurkishCase;

    const lci = 'i';
    expectEqual(t.specialToLower(lci), 'i');
    expectEqual(t.specialToTitle(lci), 'İ');
    expectEqual(t.specialToUpper(lci), 'İ');

    const uci = 'İ';
    expectEqual(t.specialToLower(uci), 'i');
    expectEqual(t.specialToTitle(uci), 'İ');
    expectEqual(t.specialToUpper(uci), 'İ');
}

const test_digit = [_]values.rune{
    0x0030,
    0x0039,
    0x0661,
    0x06F1,
    0x07C9,
    0x0966,
    0x09EF,
    0x0A66,
    0x0AEF,
    0x0B66,
    0x0B6F,
    0x0BE6,
    0x0BEF,
    0x0C66,
    0x0CEF,
    0x0D66,
    0x0D6F,
    0x0E50,
    0x0E59,
    0x0ED0,
    0x0ED9,
    0x0F20,
    0x0F29,
    0x1040,
    0x1049,
    0x1090,
    0x1091,
    0x1099,
    0x17E0,
    0x17E9,
    0x1810,
    0x1819,
    0x1946,
    0x194F,
    0x19D0,
    0x19D9,
    0x1B50,
    0x1B59,
    0x1BB0,
    0x1BB9,
    0x1C40,
    0x1C49,
    0x1C50,
    0x1C59,
    0xA620,
    0xA629,
    0xA8D0,
    0xA8D9,
    0xA900,
    0xA909,
    0xAA50,
    0xAA59,
    0xFF10,
    0xFF19,
    0x104A1,
    0x1D7CE,
};

const test_letter = [_]values.rune{
    0x0041,
    0x0061,
    0x00AA,
    0x00BA,
    0x00C8,
    0x00DB,
    0x00F9,
    0x02EC,
    0x0535,
    0x06E6,
    0x093D,
    0x0A15,
    0x0B99,
    0x0DC0,
    0x0EDD,
    0x1000,
    0x1200,
    0x1312,
    0x1401,
    0x1885,
    0x2C00,
    0xA800,
    0xF900,
    0xFA30,
    0xFFDA,
    0xFFDC,
    0x10000,
    0x10300,
    0x10400,
    0x20000,
    0x2F800,
    0x2FA1D,
};

test "digit" {
    for (test_digit) |r| {
        expect(ziglyph.isDigit(r));
    }
    for (test_letter) |r| {
        expect(!ziglyph.isDigit(r));
    }
}

// Test that the special case in isDigit agrees with the table
test "digit optimization" {
    var i: values.rune = 0;
    while (i <= values.max_latin_1) : (i += 1) {
        expectEqual(tables.runeIs(tables.range_tables[@enumToInt(values.Digit)], i), ziglyph.isDigit(i));
    }
}

test "isControlLatin1" {
    var i: values.rune = 0;
    while (i <= values.max_latin_1) : (i += 1) {
        const got = ziglyph.isControl(i);
        var want = false;
        if (0x00 <= i and i <= 0x1F) want = true;
        if (0x7F <= i and i <= 0x9F) want = true;
        expectEqual(got, want);
    }
}

test "isLetterLatin1" {
    var i: values.rune = 0;
    while (i <= values.max_latin_1) : (i += 1) {
        const got = ziglyph.isLetter(i);
        const want = tables.runeIs(tables.range_tables[@enumToInt(values.Letter)], i);
        expectEqual(got, want);
    }
}

test "isUpperLatin1" {
    var i: values.rune = 0;
    while (i <= values.max_latin_1) : (i += 1) {
        const got = casing.isUpper(i);
        const want = tables.runeIs(tables.range_tables[@enumToInt(values.Upper)], i);
        expectEqual(got, want);
    }
}

test "isLowerLatin1" {
    var i: values.rune = 0;
    while (i <= values.max_latin_1) : (i += 1) {
        const got = casing.isLower(i);
        const want = tables.runeIs(tables.range_tables[@enumToInt(values.Lower)], i);
        expectEqual(got, want);
    }
}

test "NumberLatin1" {
    var i: values.rune = 0;
    while (i <= values.max_latin_1) : (i += 1) {
        const got = ziglyph.isNumber(i);
        const want = tables.runeIs(tables.range_tables[@enumToInt(values.Number)], i);
        expectEqual(got, want);
    }
}

test "isPrintLatin1" {
    var i: values.rune = 0;
    while (i <= values.max_latin_1) : (i += 1) {
        const got = ziglyph.isPrint(i);
        var want = kinds.inPrintRanges(i);
        if (i == ' ') want = true;
        expectEqual(got, want);
    }
}

test "isGraphicLatin1" {
    var i: values.rune = 0;
    while (i <= values.max_latin_1) : (i += 1) {
        const got = ziglyph.isGraphic(i);
        const want = kinds.inGraphicRanges(i);
        expectEqual(got, want);
    }
}

test "isPunctLatin1" {
    var i: values.rune = 0;
    while (i <= values.max_latin_1) : (i += 1) {
        const got = ziglyph.isPunct(i);
        const want = tables.runeIs(tables.range_tables[@enumToInt(values.Punct)], i);
        expectEqual(got, want);
    }
}

test "isSpaceLatin1" {
    var i: values.rune = 0;
    while (i <= values.max_latin_1) : (i += 1) {
        const got = ziglyph.isSpace(i);
        const want = tables.runeIs(tables.properties_tables[@enumToInt(values.Properties.White_Space)], i);
        expectEqual(got, want);
    }
}

test "isSymbolLatin1" {
    var i: values.rune = 0;
    while (i <= values.max_latin_1) : (i += 1) {
        const got = ziglyph.isSymbol(i);
        const want = tables.runeIs(tables.range_tables[@enumToInt(values.Symbol)], i);
        expectEqual(got, want);
    }
}

const upperTest = [_]values.rune{
    0x41,
    0xc0,
    0xd8,
    0x100,
    0x139,
    0x14a,
    0x178,
    0x181,
    0x376,
    0x3cf,
    0x13bd,
    0x1f2a,
    0x2102,
    0x2c00,
    0x2c10,
    0x2c20,
    0xa650,
    0xa722,
    0xff3a,
    0x10400,
    0x1d400,
    0x1d7ca,
};

const notupperTest = [_]values.rune{
    0x40,
    0x5b,
    0x61,
    0x185,
    0x1b0,
    0x377,
    0x387,
    0x2150,
    0xab7d,
    0xffff,
    0x10000,
};

const letterTest = [_]values.rune{
    0x41,
    0x61,
    0xaa,
    0xba,
    0xc8,
    0xdb,
    0xf9,
    0x2ec,
    0x535,
    0x620,
    0x6e6,
    0x93d,
    0xa15,
    0xb99,
    0xdc0,
    0xedd,
    0x1000,
    0x1200,
    0x1312,
    0x1401,
    0x2c00,
    0xa800,
    0xf900,
    0xfa30,
    0xffda,
    0xffdc,
    0x10000,
    0x10300,
    0x10400,
    0x20000,
    0x2f800,
    0x2fa1d,
};

const notletterTest = [_]values.rune{
    0x20,
    0x35,
    0x375,
    0x619,
    0x700,
    0x1885,
    0xfffe,
    0x1ffff,
    0x10ffff,
};

// Contains all the special cased Latin-1 chars.
const spaceTest = [_]values.rune{
    0x09,
    0x0a,
    0x0b,
    0x0c,
    0x0d,
    0x20,
    0x85,
    0xA0,
    0x2000,
    0x3000,
};

const CaseT = struct {
    cas: casing.Cases,
    in: values.rune,
    out: values.rune,
};

const caseTest = [_]CaseT{
    // errors
    //.{ .cas = casing.Cases.upper, .in = -1, .out = -1 },
    //.{ .cas = casing.Cases.upper, .in = 1 << 30, .out = 1 << 30 },

    // ASCII (special-cased so test carefully)
    .{ .cas = casing.Cases.upper, .in = '\n', .out = '\n' },
    .{ .cas = casing.Cases.upper, .in = 'a', .out = 'A' },
    .{ .cas = casing.Cases.upper, .in = 'A', .out = 'A' },
    .{ .cas = casing.Cases.upper, .in = '7', .out = '7' },
    .{ .cas = casing.Cases.lower, .in = '\n', .out = '\n' },
    .{ .cas = casing.Cases.lower, .in = 'a', .out = 'a' },
    .{ .cas = casing.Cases.lower, .in = 'A', .out = 'a' },
    .{ .cas = casing.Cases.lower, .in = '7', .out = '7' },
    .{ .cas = casing.Cases.title, .in = '\n', .out = '\n' },
    .{ .cas = casing.Cases.title, .in = 'a', .out = 'A' },
    .{ .cas = casing.Cases.title, .in = 'A', .out = 'A' },
    .{ .cas = casing.Cases.title, .in = '7', .out = '7' },

    // Latin-1: easy to read the tests!
    .{ .cas = casing.Cases.upper, .in = 0x80, .out = 0x80 },
    .{ .cas = casing.Cases.upper, .in = 'Å', .out = 'Å' },
    .{ .cas = casing.Cases.upper, .in = 'å', .out = 'Å' },
    .{ .cas = casing.Cases.lower, .in = 0x80, .out = 0x80 },
    .{ .cas = casing.Cases.lower, .in = 'Å', .out = 'å' },
    .{ .cas = casing.Cases.lower, .in = 'å', .out = 'å' },
    .{ .cas = casing.Cases.title, .in = 0x80, .out = 0x80 },
    .{ .cas = casing.Cases.title, .in = 'Å', .out = 'Å' },
    .{ .cas = casing.Cases.title, .in = 'å', .out = 'Å' },

    // 0131;LATIN SMALL LETTER DOTLESS I;Ll;0;L;;;;;N;;;0049;;0049
    .{ .cas = casing.Cases.upper, .in = 0x0131, .out = 'I' },
    .{ .cas = casing.Cases.lower, .in = 0x0131, .out = 0x0131 },
    .{ .cas = casing.Cases.title, .in = 0x0131, .out = 'I' },

    // 0133;LATIN SMALL LIGATURE IJ;Ll;0;L;<compat> 0069 006A;;;;N;LATIN SMALL LETTER I J;;0132;;0132
    .{ .cas = casing.Cases.upper, .in = 0x0133, .out = 0x0132 },
    .{ .cas = casing.Cases.lower, .in = 0x0133, .out = 0x0133 },
    .{ .cas = casing.Cases.title, .in = 0x0133, .out = 0x0132 },

    // 212A;KELVIN SIGN;Lu;0;L;004B;;;;N;DEGREES KELVIN;;;006B;
    .{ .cas = casing.Cases.upper, .in = 0x212A, .out = 0x212A },
    .{ .cas = casing.Cases.lower, .in = 0x212A, .out = 'k' },
    .{ .cas = casing.Cases.title, .in = 0x212A, .out = 0x212A },

    // From an UpperLower sequence
    // A640;CYRILLIC CAPITAL LETTER ZEMLYA;Lu;0;L;;;;;N;;;;A641;
    .{ .cas = casing.Cases.upper, .in = 0xA640, .out = 0xA640 },
    .{ .cas = casing.Cases.lower, .in = 0xA640, .out = 0xA641 },
    .{ .cas = casing.Cases.title, .in = 0xA640, .out = 0xA640 },
    // A641;CYRILLIC SMALL LETTER ZEMLYA;Ll;0;L;;;;;N;;;A640;;A640
    .{ .cas = casing.Cases.upper, .in = 0xA641, .out = 0xA640 },
    .{ .cas = casing.Cases.lower, .in = 0xA641, .out = 0xA641 },
    .{ .cas = casing.Cases.title, .in = 0xA641, .out = 0xA640 },
    // A64E;CYRILLIC CAPITAL LETTER NEUTRAL YER;Lu;0;L;;;;;N;;;;A64F;
    .{ .cas = casing.Cases.upper, .in = 0xA64E, .out = 0xA64E },
    .{ .cas = casing.Cases.lower, .in = 0xA64E, .out = 0xA64F },
    .{ .cas = casing.Cases.title, .in = 0xA64E, .out = 0xA64E },
    // A65F;CYRILLIC SMALL LETTER YN;Ll;0;L;;;;;N;;;A65E;;A65E
    .{ .cas = casing.Cases.upper, .in = 0xA65F, .out = 0xA65E },
    .{ .cas = casing.Cases.lower, .in = 0xA65F, .out = 0xA65F },
    .{ .cas = casing.Cases.title, .in = 0xA65F, .out = 0xA65E },

    // From another UpperLower sequence
    // 0139;LATIN CAPITAL LETTER L WITH ACUTE;Lu;0;L;004C 0301;;;;N;LATIN CAPITAL LETTER L ACUTE;;;013A;
    .{ .cas = casing.Cases.upper, .in = 0x0139, .out = 0x0139 },
    .{ .cas = casing.Cases.lower, .in = 0x0139, .out = 0x013A },
    .{ .cas = casing.Cases.title, .in = 0x0139, .out = 0x0139 },
    // 013F;LATIN CAPITAL LETTER L WITH MIDDLE DOT;Lu;0;L;<compat> 004C 00B7;;;;N;;;;0140;
    .{ .cas = casing.Cases.upper, .in = 0x013f, .out = 0x013f },
    .{ .cas = casing.Cases.lower, .in = 0x013f, .out = 0x0140 },
    .{ .cas = casing.Cases.title, .in = 0x013f, .out = 0x013f },
    // 0148;LATIN SMALL LETTER N WITH CARON;Ll;0;L;006E 030C;;;;N;LATIN SMALL LETTER N HACEK;;0147;;0147
    .{ .cas = casing.Cases.upper, .in = 0x0148, .out = 0x0147 },
    .{ .cas = casing.Cases.lower, .in = 0x0148, .out = 0x0148 },
    .{ .cas = casing.Cases.title, .in = 0x0148, .out = 0x0147 },

    // Lowercase lower than uppercase.
    // AB78;CHEROKEE SMALL LETTER GE;Ll;0;L;;;;;N;;;13A8;;13A8
    .{ .cas = casing.Cases.upper, .in = 0xab78, .out = 0x13a8 },
    .{ .cas = casing.Cases.lower, .in = 0xab78, .out = 0xab78 },
    .{ .cas = casing.Cases.title, .in = 0xab78, .out = 0x13a8 },
    .{ .cas = casing.Cases.upper, .in = 0x13a8, .out = 0x13a8 },
    .{ .cas = casing.Cases.lower, .in = 0x13a8, .out = 0xab78 },
    .{ .cas = casing.Cases.title, .in = 0x13a8, .out = 0x13a8 },

    // Last block in the 5.1.0 table
    // 10400;DESERET CAPITAL LETTER LONG I;Lu;0;L;;;;;N;;;;10428;
    .{ .cas = casing.Cases.upper, .in = 0x10400, .out = 0x10400 },
    .{ .cas = casing.Cases.lower, .in = 0x10400, .out = 0x10428 },
    .{ .cas = casing.Cases.title, .in = 0x10400, .out = 0x10400 },
    // 10427;DESERET CAPITAL LETTER EW;Lu;0;L;;;;;N;;;;1044F;
    .{ .cas = casing.Cases.upper, .in = 0x10427, .out = 0x10427 },
    .{ .cas = casing.Cases.lower, .in = 0x10427, .out = 0x1044F },
    .{ .cas = casing.Cases.title, .in = 0x10427, .out = 0x10427 },
    // 10428;DESERET SMALL LETTER LONG I;Ll;0;L;;;;;N;;;10400;;10400
    .{ .cas = casing.Cases.upper, .in = 0x10428, .out = 0x10400 },
    .{ .cas = casing.Cases.lower, .in = 0x10428, .out = 0x10428 },
    .{ .cas = casing.Cases.title, .in = 0x10428, .out = 0x10400 },
    // 1044F;DESERET SMALL LETTER EW;Ll;0;L;;;;;N;;;10427;;10427
    .{ .cas = casing.Cases.upper, .in = 0x1044F, .out = 0x10427 },
    .{ .cas = casing.Cases.lower, .in = 0x1044F, .out = 0x1044F },
    .{ .cas = casing.Cases.title, .in = 0x1044F, .out = 0x10427 },

    // First one not in the 5.1.0 table
    // 10450;SHAVIAN LETTER PEEP;Lo;0;L;;;;;N;;;;;
    .{ .cas = casing.Cases.upper, .in = 0x10450, .out = 0x10450 },
    .{ .cas = casing.Cases.lower, .in = 0x10450, .out = 0x10450 },
    .{ .cas = casing.Cases.title, .in = 0x10450, .out = 0x10450 },

    // Non-letters with case.
    .{ .cas = casing.Cases.lower, .in = 0x2161, .out = 0x2171 },
    .{ .cas = casing.Cases.upper, .in = 0x0345, .out = 0x0399 },
};

test "isLetter" {
    for (upperTest) |r| {
        expect(ziglyph.isLetter(r));
    }
    for (letterTest) |r| {
        expect(ziglyph.isLetter(r));
    }
    for (notletterTest) |r| {
        expect(!ziglyph.isLetter(r));
    }
}

test "casing.isUpper" {
    for (upperTest) |r| {
        expect(casing.isUpper(r));
    }
    for (notupperTest) |r| {
        expect(!casing.isUpper(r));
    }
    for (notletterTest) |r| {
        expect(!casing.isUpper(r));
    }
}

test "mapTo" {
    for (caseTest) |c| {
        const r = casing.mapTo(c.cas, c.in);
        expectEqual(c.out, r);
    }
}

test "ToUpperCase" {
    for (caseTest) |c| {
        if (c.cas != casing.Cases.upper) {
            continue;
        }
        const r = casing.toUpper(c.in);
        expectEqual(c.out, r);
    }
}

test "ToLowerCase" {
    for (caseTest) |c| {
        if (c.cas != casing.Cases.lower) {
            continue;
        }
        const r = casing.toLower(c.in);
        expectEqual(c.out, r);
    }
}

test "ToTitleCase" {
    for (caseTest) |c| {
        if (c.cas != casing.Cases.title) {
            continue;
        }
        const r = casing.toTitle(c.in);
        expectEqual(c.out, r);
    }
}

test "ziglyph.isSpace" {
    for (spaceTest) |c| {
        expect(ziglyph.isSpace(c));
    }
    for (letterTest) |c| {
        expect(!ziglyph.isSpace(c));
    }
}

// Check that the optimizations for IsLetter etc. agree with the tables.
// We only need to check the Latin-1 range.
test "LetterOptimizations" {
    var i: values.rune = 0;
    while (i <= values.max_latin_1) : (i += 1) {
        expectEqual(tables.runeIs(tables.range_tables[@enumToInt(values.Letter)], i), ziglyph.isLetter(i));
        expectEqual(tables.runeIs(tables.range_tables[@enumToInt(values.Upper)], i), casing.isUpper(i));
        expectEqual(tables.runeIs(tables.range_tables[@enumToInt(values.Lower)], i), casing.isLower(i));
        expectEqual(tables.runeIs(tables.range_tables[@enumToInt(values.Title)], i), casing.isTitle(i));
        expectEqual(tables.runeIs(tables.properties_tables[@enumToInt(values.Properties.White_Space)], i), ziglyph.isSpace(i));
        expectEqual(casing.mapTo(casing.Cases.upper, i), casing.toUpper(i));
        expectEqual(casing.mapTo(casing.Cases.lower, i), casing.toLower(i));
        expectEqual(casing.mapTo(casing.Cases.title, i), casing.toTitle(i));
    }
}

test "TurkishCase" {
    const lower = [_]values.rune{ 'a', 'b', 'c', 'ç', 'd', 'e', 'f', 'g', 'ğ', 'h', 'ı', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'ö', 'p', 'r', 's', 'ş', 't', 'u', 'ü', 'v', 'y', 'z' };
    const upper = [_]values.rune{ 'A', 'B', 'C', 'Ç', 'D', 'E', 'F', 'G', 'Ğ', 'H', 'I', 'İ', 'J', 'K', 'L', 'M', 'N', 'O', 'Ö', 'P', 'R', 'S', 'Ş', 'T', 'U', 'Ü', 'V', 'Y', 'Z' };
    for (lower) |l, i| {
        const u = upper[i];
        expectEqual(casing.TurkishCase.specialToLower(l), l);
        expectEqual(casing.TurkishCase.specialToUpper(u), u);
        expectEqual(casing.TurkishCase.specialToUpper(l), u);
        expectEqual(casing.TurkishCase.specialToLower(u), l);
        expectEqual(casing.TurkishCase.specialToTitle(u), u);
        expectEqual(casing.TurkishCase.specialToTitle(l), u);
    }
}

const simpleFoldTests = [_][]const values.rune{
    // simpleFold(x) returns the next equivalent rune > x or wraps
    // around to smaller values.

    // Easy cases.
    &[_]values.rune{ 'A', 'a' },
    &[_]values.rune{ 'δ', 'Δ' },

    // ASCII special cases.
    &[_]values.rune{ 'K', 'k', 'K' },
    &[_]values.rune{ 'S', 's', 'ſ' },

    // Non-ASCII special cases.
    &[_]values.rune{ 'ρ', 'ϱ', 'Ρ' },
    //&[_]values.rune{ 'Ι', 'ι', 'ι' },

    // Extra special cases: has lower/upper but no case fold.
    &[_]values.rune{'İ'},
    &[_]values.rune{'ı'},

    // Upper comes before lower (Cherokee).
    &[_]values.rune{ '\u{13b0}', '\u{ab80}' },
};

test "simpleFold" {
    for (simpleFoldTests) |tt| {
        var r = tt[tt.len - 1];
        for (tt) |out| {
            const lr = casing.simpleFold(r);
            expectEqual(lr, out);
            r = out;
        }
    }

    //const r = casing.simpleFold(-42);
    //expectEqual(r, -42);
}

test "LatinOffset" {
    const all_tables = tables.range_tables ++ tables.properties_tables;

    for (all_tables) |tab, ti| {
        var i: usize = 0;
        while (i < tab.r16.len and tab.r16[i].high <= values.max_latin_1) {
            i += 1;
        }
        if (tab.latin_offset) |off| {
            expectEqual(off, i);
        }
    }
}

const CT = struct {
    rune: values.rune,
    script: values.Categories,
};

const PT = struct {
    rune: values.rune,
    script: values.Properties,
};

const inCategoryTest = [_]CT{
    .{ .rune = 0x0081, .script = values.Categories.Cc },
    .{ .rune = 0x200B, .script = values.Categories.Cf },
    .{ .rune = 0xf0000, .script = values.Categories.Co },
    .{ .rune = 0xdb80, .script = values.Categories.Cs },
    .{ .rune = 0x0236, .script = values.Categories.Ll },
    .{ .rune = 0x1d9d, .script = values.Categories.Lm },
    .{ .rune = 0x07cf, .script = values.Categories.Lo },
    .{ .rune = 0x1f8a, .script = values.Categories.Lt },
    .{ .rune = 0x03ff, .script = values.Categories.Lu },
    .{ .rune = 0x0bc1, .script = values.Categories.Mc },
    .{ .rune = 0x20df, .script = values.Categories.Me },
    .{ .rune = 0x07f0, .script = values.Categories.Mn },
    .{ .rune = 0x1bb2, .script = values.Categories.Nd },
    .{ .rune = 0x10147, .script = values.Categories.Nl },
    .{ .rune = 0x2478, .script = values.Categories.No },
    .{ .rune = 0xfe33, .script = values.Categories.Pc },
    .{ .rune = 0x2011, .script = values.Categories.Pd },
    .{ .rune = 0x301e, .script = values.Categories.Pe },
    .{ .rune = 0x2e03, .script = values.Categories.Pf },
    .{ .rune = 0x2e02, .script = values.Categories.Pi },
    .{ .rune = 0x0022, .script = values.Categories.Po },
    .{ .rune = 0x2770, .script = values.Categories.Ps },
    .{ .rune = 0x00a4, .script = values.Categories.Sc },
    .{ .rune = 0xa711, .script = values.Categories.Sk },
    .{ .rune = 0x25f9, .script = values.Categories.Sm },
    .{ .rune = 0x2108, .script = values.Categories.So },
    .{ .rune = 0x2028, .script = values.Categories.Zl },
    .{ .rune = 0x2029, .script = values.Categories.Zp },
    .{ .rune = 0x202f, .script = values.Categories.Zs },
    // Unifieds.
    .{ .rune = 0x04aa, .script = values.Categories.L },
    .{ .rune = 0x0009, .script = values.Categories.C },
    .{ .rune = 0x1712, .script = values.Categories.M },
    .{ .rune = 0x0031, .script = values.Categories.N },
    .{ .rune = 0x00bb, .script = values.Categories.P },
    .{ .rune = 0x00a2, .script = values.Categories.S },
    .{ .rune = 0x00a0, .script = values.Categories.Z },
};

const inPropTest = [_]PT{
    .{ .rune = 0x0046, .script = values.Properties.ASCII_Hex_Digit },
    .{ .rune = 0x200F, .script = values.Properties.Bidi_Control },
    .{ .rune = 0x2212, .script = values.Properties.Dash },
    .{ .rune = 0xE0001, .script = values.Properties.Deprecated },
    .{ .rune = 0x00B7, .script = values.Properties.Diacritic },
    .{ .rune = 0x30FE, .script = values.Properties.Extender },
    .{ .rune = 0xFF46, .script = values.Properties.Hex_Digit },
    .{ .rune = 0x2E17, .script = values.Properties.Hyphen },
    .{ .rune = 0x2FFB, .script = values.Properties.IDS_Binary_Operator },
    .{ .rune = 0x2FF3, .script = values.Properties.IDS_Trinary_Operator },
    .{ .rune = 0xFA6A, .script = values.Properties.Ideographic },
    .{ .rune = 0x200D, .script = values.Properties.Join_Control },
    .{ .rune = 0x0EC4, .script = values.Properties.Logical_Order_Exception },
    .{ .rune = 0x2FFFF, .script = values.Properties.Noncharacter_Code_Point },
    .{ .rune = 0x065E, .script = values.Properties.Other_Alphabetic },
    .{ .rune = 0x2065, .script = values.Properties.Other_Default_Ignorable_Code_Point },
    .{ .rune = 0x0BD7, .script = values.Properties.Other_Grapheme_Extend },
    .{ .rune = 0x0387, .script = values.Properties.Other_ID_Continue },
    .{ .rune = 0x212E, .script = values.Properties.Other_ID_Start },
    .{ .rune = 0x2094, .script = values.Properties.Other_Lowercase },
    .{ .rune = 0x2040, .script = values.Properties.Other_Math },
    .{ .rune = 0x216F, .script = values.Properties.Other_Uppercase },
    .{ .rune = 0x0027, .script = values.Properties.Pattern_Syntax },
    .{ .rune = 0x0020, .script = values.Properties.Pattern_White_Space },
    .{ .rune = 0x06DD, .script = values.Properties.Prepended_Concatenation_Mark },
    .{ .rune = 0x300D, .script = values.Properties.Quotation_Mark },
    .{ .rune = 0x2EF3, .script = values.Properties.Radical },
    .{ .rune = 0x1f1ff, .script = values.Properties.Regional_Indicator },
    .{ .rune = 0x061F, .script = values.Properties.Sentence_Terminal },
    .{ .rune = 0x2071, .script = values.Properties.Soft_Dotted },
    .{ .rune = 0x003A, .script = values.Properties.Terminal_Punctuation },
    .{ .rune = 0x9FC3, .script = values.Properties.Unified_Ideograph },
    .{ .rune = 0xFE0F, .script = values.Properties.Variation_Selector },
    .{ .rune = 0x0020, .script = values.Properties.White_Space },
};

test "CategoriesAndProperties" {
    for (inCategoryTest) |tst| {
        expect(tables.runeIs(tables.range_tables[@enumToInt(tst.script)], tst.rune));
    }
    for (inPropTest) |tst| {
        expect(tables.runeIs(tables.properties_tables[@enumToInt(tst.script)], tst.rune));
    }
}
