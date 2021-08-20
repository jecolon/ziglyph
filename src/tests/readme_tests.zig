const std = @import("std");
const expect = std.testing.expect;
const expectEqual = std.testing.expectEqual;
const expectEqualSlices = std.testing.expectEqualSlices;

// Import structs.
const Ziglyph = @import("../Ziglyph.zig");
const Collator = Ziglyph.Collator;
const GraphemeIterator = Ziglyph.GraphemeIterator;
const Letter = Ziglyph.Letter;
const Normalizer = Ziglyph.Normalizer;
const Punct = Ziglyph.Punct;
const UpperMap = Ziglyph.UpperMap;
const Width = Ziglyph.Width;

test "Ziglyph struct" {
    const z = 'z';
    try expect(Ziglyph.isLetter(z));
    try expect(Ziglyph.isAlphaNum(z));
    try expect(Ziglyph.isPrint(z));
    try expect(!Ziglyph.isUpper(z));
    const uz = Ziglyph.toUpper(z);
    try expect(Ziglyph.isUpper(uz));
    try expectEqual(uz, 'Z');

    // String toLower and toUpper.
    var allocator = std.testing.allocator;
    var got = try Ziglyph.toLowerStr(allocator, "AbC123");
    errdefer allocator.free(got);
    try expect(std.mem.eql(u8, "abc123", got));
    allocator.free(got);
    got = try Ziglyph.toUpperStr(allocator, "aBc123");
    defer allocator.free(got);
    try expect(std.mem.eql(u8, "ABC123", got));
}

test "Aggregate struct" {
    const z = 'z';
    try expect(Letter.isLetter(z));
    try expect(!Letter.isUpper(z));
    try expect(!Punct.isPunct(z));
    try expect(Punct.isPunct('!'));
    const uz = Letter.toUpper(z);
    try expect(Letter.isUpper(uz));
    try expectEqual(uz, 'Z');
}

test "Component structs" {
    const z = 'z';
    try expect(Letter.isLower(z));
    try expect(!Letter.isUpper(z));
    const uz = UpperMap.toUpper(z);
    try expect(Letter.isUpper(uz));
    try expectEqual(uz, 'Z');
}

test "normalizeTo" {
    var allocator = std.testing.allocator;
    var normalizer = try Normalizer.init(allocator, "src/data/ucd/Decompositions.bin");
    defer normalizer.deinit();

    // Canonical Composition (NFC)
    const input_nfc = "Complex char: \u{03D2}\u{0301}";
    const want_nfc = "Complex char: \u{03D3}";
    const got_nfc = try normalizer.normalizeTo(.composed, input_nfc);
    try expectEqualSlices(u8, want_nfc, got_nfc);

    // Compatibility Composition (NFKC)
    const input_nfkc = "Complex char: \u{03A5}\u{0301}";
    const want_nfkc = "Complex char: \u{038E}";
    const got_nfkc = try normalizer.normalizeTo(.komposed, input_nfkc);
    try expectEqualSlices(u8, want_nfkc, got_nfkc);

    // Canonical Decomposition (NFD)
    const input_nfd = "Complex char: \u{03D3}";
    const want_nfd = "Complex char: \u{03D2}\u{0301}";
    const got_nfd = try normalizer.normalizeTo(.canon, input_nfd);
    try expectEqualSlices(u8, want_nfd, got_nfd);

    // Compatibility Decomposition (NFKD)
    const input_nfkd = "Complex char: \u{03D3}";
    const want_nfkd = "Complex char: \u{03A5}\u{0301}";
    const got_nfkd = try normalizer.normalizeTo(.compat, input_nfkd);
    try expectEqualSlices(u8, want_nfkd, got_nfkd);

    // String comparisons.
    try expect(try normalizer.eqlBy("foé", "foe\u{0301}", .normalize));
    try expect(try normalizer.eqlBy("foϓ", "fo\u{03D2}\u{0301}", .normalize));
    try expect(try normalizer.eqlBy("Foϓ", "fo\u{03D2}\u{0301}", .norm_ignore));
    try expect(try normalizer.eqlBy("FOÉ", "foe\u{0301}", .norm_ignore)); // foÉ == foé
    try expect(try normalizer.eqlBy("Foé", "foé", .ident)); // Unicode Identifiers caseless match.
}

test "GraphemeIterator" {
    var allocator = std.testing.allocator;
    var giter = try GraphemeIterator.init(allocator, "H\u{0065}\u{0301}llo");
    defer giter.deinit();

    const want = &[_][]const u8{ "H", "\u{0065}\u{0301}", "l", "l", "o" };

    var i: usize = 0;
    while (giter.next()) |gc| : (i += 1) {
        try expect(gc.eql(want[i]));
    }
}

test "Code point / string widths" {
    var allocator = std.testing.allocator;
    try expectEqual(Width.codePointWidth('é', .half), 1);
    try expectEqual(Width.codePointWidth('😊', .half), 2);
    try expectEqual(Width.codePointWidth('统', .half), 2);
    try expectEqual(try Width.strWidth(allocator, "Hello\r\n", .half), 5);
    try expectEqual(try Width.strWidth(allocator, "\u{1F476}\u{1F3FF}\u{0308}\u{200D}\u{1F476}\u{1F3FF}", .half), 2);
    try expectEqual(try Width.strWidth(allocator, "Héllo 🇪🇸", .half), 8);
    try expectEqual(try Width.strWidth(allocator, "\u{26A1}\u{FE0E}", .half), 1); // Text sequence
    try expectEqual(try Width.strWidth(allocator, "\u{26A1}\u{FE0F}", .half), 2); // Presentation sequence

    // padLeft, center, padRight
    const right_aligned = try Width.padLeft(allocator, "w😊w", 10, "-");
    defer allocator.free(right_aligned);
    try expectEqualSlices(u8, "------w😊w", right_aligned);

    const centered = try Width.center(allocator, "w😊w", 10, "-");
    defer allocator.free(centered);
    try expectEqualSlices(u8, "---w😊w---", centered);

    const left_aligned = try Width.padRight(allocator, "w😊w", 10, "-");
    defer allocator.free(left_aligned);
    try expectEqualSlices(u8, "w😊w------", left_aligned);
}

test "Collation" {
    var allocator = std.testing.allocator;
    var normalizer = try Normalizer.init(allocator, "src/data/ucd/Decompositions.bin");
    defer normalizer.deinit();
    var collator = try Collator.init(allocator, "src/data/uca/allkeys.bin", &normalizer);
    defer collator.deinit();

    try expect(collator.tertiaryAsc("abc", "def"));
    try expect(collator.tertiaryDesc("def", "abc"));
    try expect(try collator.orderFn("José", "jose", .primary, .eq));

    var strings: [3][]const u8 = .{ "xyz", "def", "abc" };
    collator.sortAsc(&strings);
    try expectEqual(strings[0], "abc");
    try expectEqual(strings[1], "def");
    try expectEqual(strings[2], "xyz");

    strings = .{ "xyz", "def", "abc" };
    collator.sortAsciiAsc(&strings);
    try expectEqual(strings[0], "abc");
    try expectEqual(strings[1], "def");
    try expectEqual(strings[2], "xyz");
}
