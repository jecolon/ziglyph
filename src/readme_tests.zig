const std = @import("std");
const testing = std.testing;

// Import structs.
const ziglyph = @import("ziglyph.zig");
const Collator = ziglyph.Collator;
const Grapheme = ziglyph.Grapheme;
const GraphemeIterator = Grapheme.GraphemeIterator;
const letter = ziglyph.letter;
const Normalizer = ziglyph.Normalizer;
const punct = ziglyph.punct;
const Sentence = ziglyph.Sentence;
const SentenceIterator = Sentence.SentenceIterator;
const ComptimeSentenceIterator = Sentence.ComptimeSentenceIterator;
const upper_map = ziglyph.uppercase;
const display_width = ziglyph.display_width;
const Word = ziglyph.Word;
const WordIterator = Word.WordIterator;

test "ziglyph struct" {
    const z = 'z';
    try testing.expect(ziglyph.isLetter(z));
    try testing.expect(ziglyph.isAlphaNum(z));
    try testing.expect(ziglyph.isPrint(z));
    try testing.expect(!ziglyph.isUpper(z));
    const uz = ziglyph.toUpper(z);
    try testing.expect(ziglyph.isUpper(uz));
    try testing.expectEqual(uz, 'Z');
    const tz = ziglyph.toTitle(z);
    try testing.expect(ziglyph.isUpper(tz));
    try testing.expectEqual(tz, 'Z');

    // String toLower, toTitle and toUpper.
    var allocator = std.testing.allocator;
    var got = try ziglyph.toLowerStr(allocator, "AbC123");
    errdefer allocator.free(got);
    try testing.expect(std.mem.eql(u8, "abc123", got));
    allocator.free(got);
    got = try ziglyph.toUpperStr(allocator, "aBc123");
    errdefer allocator.free(got);
    try testing.expect(std.mem.eql(u8, "ABC123", got));
    allocator.free(got);
    got = try ziglyph.toTitleStr(allocator, "thE aBc123 moVie. yes!");
    defer allocator.free(got);
    try testing.expect(std.mem.eql(u8, "The Abc123 Movie. Yes!", got));
}

test "Aggregate struct" {
    const z = 'z';
    try testing.expect(letter.isLetter(z));
    try testing.expect(!letter.isUpper(z));
    try testing.expect(!punct.isPunct(z));
    try testing.expect(punct.isPunct('!'));
    const uz = letter.toUpper(z);
    try testing.expect(letter.isUpper(uz));
    try testing.expectEqual(uz, 'Z');
}

test "Component structs" {
    const z = 'z';
    try testing.expect(letter.isLower(z));
    try testing.expect(!letter.isUpper(z));
    const uz = upper_map.toUpper(z);
    try testing.expect(letter.isUpper(uz));
    try testing.expectEqual(uz, 'Z');
}

test "normalizeTo" {
    var allocator = std.testing.allocator;
    var normalizer = try Normalizer.init(allocator);
    defer normalizer.deinit();

    // Canonical Composition (NFC)
    const input_nfc = "Complex char: \u{03D2}\u{0301}";
    const want_nfc = "Complex char: \u{03D3}";
    var got_nfc = try normalizer.nfc(std.testing.allocator, input_nfc);
    defer got_nfc.deinit();
    try testing.expectEqualSlices(u8, want_nfc, got_nfc.slice);

    // Compatibility Composition (NFKC)
    const input_nfkc = "Complex char: \u{03A5}\u{0301}";
    const want_nfkc = "Complex char: \u{038E}";
    var got_nfkc = try normalizer.nfkc(std.testing.allocator, input_nfkc);
    defer got_nfkc.deinit();
    try testing.expectEqualSlices(u8, want_nfkc, got_nfkc.slice);

    // Canonical Decomposition (NFD)
    const input_nfd = "Complex char: \u{03D3}";
    const want_nfd = "Complex char: \u{03D2}\u{0301}";
    var got_nfd = try normalizer.nfd(std.testing.allocator, input_nfd);
    defer got_nfd.deinit();
    try testing.expectEqualSlices(u8, want_nfd, got_nfd.slice);

    // Compatibility Decomposition (NFKD)
    const input_nfkd = "Complex char: \u{03D3}";
    const want_nfkd = "Complex char: \u{03A5}\u{0301}";
    var got_nfkd = try normalizer.nfkd(std.testing.allocator, input_nfkd);
    defer got_nfkd.deinit();
    try testing.expectEqualSlices(u8, want_nfkd, got_nfkd.slice);

    // String comparisons.
    try testing.expect(try normalizer.eql(std.testing.allocator, "foé", "foe\u{0301}"));
    try testing.expect(try normalizer.eql(std.testing.allocator, "foϓ", "fo\u{03D2}\u{0301}"));
    try testing.expect(try normalizer.eqlCaseless(std.testing.allocator, "Foϓ", "fo\u{03D2}\u{0301}"));
    try testing.expect(try normalizer.eqlCaseless(std.testing.allocator, "FOÉ", "foe\u{0301}")); // foÉ == foé
    // Note: eqlIdentifiers is not a method, it's just a function in the Normalizer namespace.
    try testing.expect(try Normalizer.eqlIdentifiers(std.testing.allocator, "Foé", "foé")); // Unicode Identifiers caseless match.
}

test "GraphemeIterator" {
    const input = "H\u{0065}\u{0301}llo";
    var iter = GraphemeIterator.init(input);

    const want = &[_][]const u8{ "H", "\u{0065}\u{0301}", "l", "l", "o" };

    var i: usize = 0;
    while (iter.next()) |grapheme| : (i += 1) {
        try testing.expect(grapheme.eql(input, want[i]));
    }

    // Need your grapheme clusters at compile time?
    comptime {
        var ct_iter = GraphemeIterator.init(input);
        var j = 0;
        while (ct_iter.next()) |grapheme| : (j += 1) {
            try testing.expect(grapheme.eql(input, want[j]));
        }
    }
}

test "SentenceIterator" {
    var allocator = std.testing.allocator;
    const input =
        \\("Go.") ("He said.")
    ;
    var iter = try SentenceIterator.init(allocator, input);
    defer iter.deinit();

    // Note the space after the closing right parenthesis is included as part
    // of the first sentence.
    const s1 =
        \\("Go.") 
    ;
    const s2 =
        \\("He said.")
    ;
    const want = &[_][]const u8{ s1, s2 };

    var i: usize = 0;
    while (iter.next()) |sentence| : (i += 1) {
        try testing.expectEqualStrings(sentence.bytes, want[i]);
    }

    // Need your sentences at compile time?
    @setEvalBranchQuota(2_000);

    comptime var ct_iter = ComptimeSentenceIterator(input){};
    const n = comptime ct_iter.count();
    comptime var sentences: [n]Sentence = undefined;
    comptime {
        var ct_i: usize = 0;
        while (ct_iter.next()) |sentence| : (ct_i += 1) {
            sentences[ct_i] = sentence;
        }
    }

    for (sentences, 0..) |sentence, j| {
        try testing.expect(sentence.eql(want[j]));
    }
}

test "WordIterator" {
    const input = "The (quick) fox. Fast! ";
    var iter = try WordIterator.init(input);

    const want = &[_][]const u8{ "The", " ", "(", "quick", ")", " ", "fox", ".", " ", "Fast", "!", " " };

    var i: usize = 0;
    while (iter.next()) |word| : (i += 1) {
        try testing.expectEqualStrings(word.bytes, want[i]);
    }

    // Need your words at compile time?
    @setEvalBranchQuota(2_000);

    comptime {
        var ct_iter = try WordIterator.init(input);
        var j = 0;
        while (ct_iter.next()) |word| : (j += 1) {
            try testing.expect(word.eql(want[j]));
        }
    }
}

test "Code point / string widths" {
    var allocator = std.testing.allocator;
    try testing.expectEqual(display_width.codePointWidth('é', .half), 1);
    try testing.expectEqual(display_width.codePointWidth('😊', .half), 2);
    try testing.expectEqual(display_width.codePointWidth('统', .half), 2);
    try testing.expectEqual(try display_width.strWidth("Hello\r\n", .half), 5);
    try testing.expectEqual(try display_width.strWidth("\u{1F476}\u{1F3FF}\u{0308}\u{200D}\u{1F476}\u{1F3FF}", .half), 2);
    try testing.expectEqual(try display_width.strWidth("Héllo 🇪🇸", .half), 8);
    try testing.expectEqual(try display_width.strWidth("\u{26A1}\u{FE0E}", .half), 1); // Text sequence
    try testing.expectEqual(try display_width.strWidth("\u{26A1}\u{FE0F}", .half), 2); // Presentation sequence

    // padLeft, center, padRight
    const right_aligned = try display_width.padLeft(allocator, "w😊w", 10, "-");
    defer allocator.free(right_aligned);
    try testing.expectEqualSlices(u8, "------w😊w", right_aligned);

    const centered = try display_width.center(allocator, "w😊w", 10, "-");
    defer allocator.free(centered);
    try testing.expectEqualSlices(u8, "---w😊w---", centered);

    const left_aligned = try display_width.padRight(allocator, "w😊w", 10, "-");
    defer allocator.free(left_aligned);
    try testing.expectEqualSlices(u8, "w😊w------", left_aligned);
}

test "Collation" {
    var c = try Collator.init(std.testing.allocator);
    defer c.deinit();

    // Ascending / descending sort
    var strings = [_][]const u8{ "def", "xyz", "abc" };
    var want = [_][]const u8{ "abc", "def", "xyz" };

    std.mem.sort([]const u8, &strings, c, Collator.ascending);
    try std.testing.expectEqualSlices([]const u8, &want, &strings);

    want = [_][]const u8{ "xyz", "def", "abc" };
    std.mem.sort([]const u8, &strings, c, Collator.descending);
    try std.testing.expectEqualSlices([]const u8, &want, &strings);

    // Caseless sorting
    strings = [_][]const u8{ "def", "Abc", "abc" };
    want = [_][]const u8{ "Abc", "abc", "def" };

    std.mem.sort([]const u8, &strings, c, Collator.ascendingCaseless);
    try std.testing.expectEqualSlices([]const u8, &want, &strings);

    want = [_][]const u8{ "def", "Abc", "abc" };
    std.mem.sort([]const u8, &strings, c, Collator.descendingCaseless);
    try std.testing.expectEqualSlices([]const u8, &want, &strings);

    // Caseless / markless sorting
    strings = [_][]const u8{ "ábc", "Abc", "abc" };
    want = [_][]const u8{ "ábc", "Abc", "abc" };

    std.mem.sort([]const u8, &strings, c, Collator.ascendingBase);
    try std.testing.expectEqualSlices([]const u8, &want, &strings);

    std.mem.sort([]const u8, &strings, c, Collator.descendingBase);
    try std.testing.expectEqualSlices([]const u8, &want, &strings);
}

test "display_width wrap" {
    var allocator = testing.allocator;
    var input = "The quick brown fox\r\njumped over the lazy dog!";
    var got = try display_width.wrap(allocator, input, 10, 3);
    defer allocator.free(got);
    var want = "The quick\n brown \nfox jumped\n over the\n lazy dog\n!";
    try testing.expectEqualStrings(want, got);
}
