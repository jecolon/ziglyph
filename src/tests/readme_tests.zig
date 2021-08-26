const std = @import("std");
const testing = std.testing;

// Import structs.
const Ziglyph = @import("../Ziglyph.zig");
const Collator = Ziglyph.Collator;
const Grapheme = Ziglyph.Grapheme;
const GraphemeIterator = Grapheme.GraphemeIterator;
const ComptimeGraphemeIterator = Grapheme.ComptimeGraphemeIterator;
const Letter = Ziglyph.Letter;
const Normalizer = Ziglyph.Normalizer;
const Punct = Ziglyph.Punct;
const SentenceIterator = Ziglyph.SentenceIterator;
const UpperMap = Ziglyph.UpperMap;
const Width = Ziglyph.Width;
const Word = Ziglyph.Word;
const WordIterator = Word.WordIterator;
const ComptimeWordIterator = Word.ComptimeWordIterator;

test "Ziglyph struct" {
    const z = 'z';
    try testing.expect(Ziglyph.isLetter(z));
    try testing.expect(Ziglyph.isAlphaNum(z));
    try testing.expect(Ziglyph.isPrint(z));
    try testing.expect(!Ziglyph.isUpper(z));
    const uz = Ziglyph.toUpper(z);
    try testing.expect(Ziglyph.isUpper(uz));
    try testing.expectEqual(uz, 'Z');
    const tz = Ziglyph.toTitle(z);
    try testing.expect(Ziglyph.isUpper(tz));
    try testing.expectEqual(tz, 'Z');

    // String toLower, toTitle and toUpper.
    var allocator = std.testing.allocator;
    var got = try Ziglyph.toLowerStr(allocator, "AbC123");
    errdefer allocator.free(got);
    try testing.expect(std.mem.eql(u8, "abc123", got));
    allocator.free(got);
    got = try Ziglyph.toUpperStr(allocator, "aBc123");
    errdefer allocator.free(got);
    try testing.expect(std.mem.eql(u8, "ABC123", got));
    allocator.free(got);
    got = try Ziglyph.toTitleStr(allocator, "thE aBc123 moVie. yes!");
    defer allocator.free(got);
    try testing.expect(std.mem.eql(u8, "The Abc123 Movie. Yes!", got));
}

test "Aggregate struct" {
    const z = 'z';
    try testing.expect(Letter.isLetter(z));
    try testing.expect(!Letter.isUpper(z));
    try testing.expect(!Punct.isPunct(z));
    try testing.expect(Punct.isPunct('!'));
    const uz = Letter.toUpper(z);
    try testing.expect(Letter.isUpper(uz));
    try testing.expectEqual(uz, 'Z');
}

test "Component structs" {
    const z = 'z';
    try testing.expect(Letter.isLower(z));
    try testing.expect(!Letter.isUpper(z));
    const uz = UpperMap.toUpper(z);
    try testing.expect(Letter.isUpper(uz));
    try testing.expectEqual(uz, 'Z');
}

test "normalizeTo" {
    var allocator = std.testing.allocator;
    var normalizer = try Normalizer.init(allocator, "src/data/ucd/Decompositions.bin");
    defer normalizer.deinit();

    // Canonical Composition (NFC)
    const input_nfc = "Complex char: \u{03D2}\u{0301}";
    const want_nfc = "Complex char: \u{03D3}";
    const got_nfc = try normalizer.normalizeTo(.composed, input_nfc);
    try testing.expectEqualSlices(u8, want_nfc, got_nfc);

    // Compatibility Composition (NFKC)
    const input_nfkc = "Complex char: \u{03A5}\u{0301}";
    const want_nfkc = "Complex char: \u{038E}";
    const got_nfkc = try normalizer.normalizeTo(.komposed, input_nfkc);
    try testing.expectEqualSlices(u8, want_nfkc, got_nfkc);

    // Canonical Decomposition (NFD)
    const input_nfd = "Complex char: \u{03D3}";
    const want_nfd = "Complex char: \u{03D2}\u{0301}";
    const got_nfd = try normalizer.normalizeTo(.canon, input_nfd);
    try testing.expectEqualSlices(u8, want_nfd, got_nfd);

    // Compatibility Decomposition (NFKD)
    const input_nfkd = "Complex char: \u{03D3}";
    const want_nfkd = "Complex char: \u{03A5}\u{0301}";
    const got_nfkd = try normalizer.normalizeTo(.compat, input_nfkd);
    try testing.expectEqualSlices(u8, want_nfkd, got_nfkd);

    // String comparisons.
    try testing.expect(try normalizer.eqlBy("foé", "foe\u{0301}", .normalize));
    try testing.expect(try normalizer.eqlBy("foϓ", "fo\u{03D2}\u{0301}", .normalize));
    try testing.expect(try normalizer.eqlBy("Foϓ", "fo\u{03D2}\u{0301}", .norm_ignore));
    try testing.expect(try normalizer.eqlBy("FOÉ", "foe\u{0301}", .norm_ignore)); // foÉ == foé
    try testing.expect(try normalizer.eqlBy("Foé", "foé", .ident)); // Unicode Identifiers caseless match.
}

test "GraphemeIterator" {
    var allocator = std.testing.allocator;
    const input = "H\u{0065}\u{0301}llo";
    var iter = try GraphemeIterator.init(allocator, input);
    defer iter.deinit();

    const want = &[_][]const u8{ "H", "\u{0065}\u{0301}", "l", "l", "o" };

    var i: usize = 0;
    while (iter.next()) |grapheme| : (i += 1) {
        try testing.expect(grapheme.eql(want[i]));
    }

    // Need your grapheme clusters at compile time?
    comptime var ct_iter = ComptimeGraphemeIterator(input){};
    const n: usize = comptime ct_iter.count();
    comptime var graphemes: [n]Grapheme = undefined;
    comptime {
        var ct_i: usize = 0;
        while (ct_iter.next()) |grapheme| : (ct_i += 1) {
            graphemes[ct_i] = grapheme;
        }
    }

    for (graphemes) |grapheme, j| {
        try testing.expect(grapheme.eql(want[j]));
    }
}

test "SentenceIterator" {
    var allocator = std.testing.allocator;
    const input =
        \\("Go.") ("He said.")
    ;
    var sentences = try SentenceIterator.init(allocator, input);
    defer sentences.deinit();

    const s1 =
        \\("Go.") 
    ;
    const s2 =
        \\("He said.")
    ;
    const want = &[_][]const u8{ s1, s2 };

    var i: usize = 0;
    while (sentences.next()) |sentence| : (i += 1) {
        try testing.expectEqualStrings(sentence.bytes, want[i]);
    }
}

test "WordIterator" {
    var allocator = std.testing.allocator;
    const input = "The (quick) fox. Fast! ";
    var iter = try WordIterator.init(allocator, input);
    defer iter.deinit();

    const want = &[_][]const u8{ "The", " ", "(", "quick", ")", " ", "fox", ".", " ", "Fast", "!", " " };

    var i: usize = 0;
    while (iter.next()) |word| : (i += 1) {
        try testing.expectEqualStrings(word.bytes, want[i]);
    }

    // Need your words at compile time?
    @setEvalBranchQuota(2_000);

    comptime var ct_iter = ComptimeWordIterator(input){};
    const n: usize = comptime ct_iter.count();
    comptime var words: [n]Word = undefined;
    comptime {
        var ct_i: usize = 0;
        while (ct_iter.next()) |word| : (ct_i += 1) {
            words[ct_i] = word;
        }
    }

    for (words) |word, j| {
        try testing.expect(word.eql(want[j]));
    }
}

test "Code point / string widths" {
    var allocator = std.testing.allocator;
    try testing.expectEqual(Width.codePointWidth('é', .half), 1);
    try testing.expectEqual(Width.codePointWidth('😊', .half), 2);
    try testing.expectEqual(Width.codePointWidth('统', .half), 2);
    try testing.expectEqual(try Width.strWidth(allocator, "Hello\r\n", .half), 5);
    try testing.expectEqual(try Width.strWidth(allocator, "\u{1F476}\u{1F3FF}\u{0308}\u{200D}\u{1F476}\u{1F3FF}", .half), 2);
    try testing.expectEqual(try Width.strWidth(allocator, "Héllo 🇪🇸", .half), 8);
    try testing.expectEqual(try Width.strWidth(allocator, "\u{26A1}\u{FE0E}", .half), 1); // Text sequence
    try testing.expectEqual(try Width.strWidth(allocator, "\u{26A1}\u{FE0F}", .half), 2); // Presentation sequence

    // padLeft, center, padRight
    const right_aligned = try Width.padLeft(allocator, "w😊w", 10, "-");
    defer allocator.free(right_aligned);
    try testing.expectEqualSlices(u8, "------w😊w", right_aligned);

    const centered = try Width.center(allocator, "w😊w", 10, "-");
    defer allocator.free(centered);
    try testing.expectEqualSlices(u8, "---w😊w---", centered);

    const left_aligned = try Width.padRight(allocator, "w😊w", 10, "-");
    defer allocator.free(left_aligned);
    try testing.expectEqualSlices(u8, "w😊w------", left_aligned);
}

test "Collation" {
    var allocator = std.testing.allocator;
    var normalizer = try Normalizer.init(allocator, "src/data/ucd/Decompositions.bin");
    defer normalizer.deinit();
    var collator = try Collator.init(allocator, "src/data/uca/allkeys.bin", &normalizer);
    defer collator.deinit();

    try testing.expect(collator.tertiaryAsc("abc", "def"));
    try testing.expect(collator.tertiaryDesc("def", "abc"));
    try testing.expect(try collator.orderFn("José", "jose", .primary, .eq));

    var strings: [3][]const u8 = .{ "xyz", "def", "abc" };
    collator.sortAsc(&strings);
    try testing.expectEqual(strings[0], "abc");
    try testing.expectEqual(strings[1], "def");
    try testing.expectEqual(strings[2], "xyz");

    strings = .{ "xyz", "def", "abc" };
    collator.sortAsciiAsc(&strings);
    try testing.expectEqual(strings[0], "abc");
    try testing.expectEqual(strings[1], "def");
    try testing.expectEqual(strings[2], "xyz");
}
