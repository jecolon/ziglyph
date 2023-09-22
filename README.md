# ziglyph
## ⚠️ Attention! Ziglyph has moved to Codeberg!
Visit the repo at: https://codeberg.org/dude_the_builder/ziglyph and update your dependencies! The source code 
on this GitHub repo will be removed on September 30, 2023 11:59 PM (AST-4), leaving only instructions on how to
find the project on Codeberg.org and integrate it into your project.

Unicode text processing for the Zig Programming Language.

## In-Depth Articles on Unicode Processing with Zig and Ziglyph
The [Unicode Processing with Zig](https://zig.news/dude_the_builder/series/6) series of articles over on
ZigNEWS covers important aspects of Unicode in general and in particular how to use this library to process 
Unicode text. Note that the examples in that series are pre-Zig v0.11, so changes may be necessary to make
them work.

## Status
This is pre-1.0 software. Although breaking changes are less frequent with each minor version release,
they will still occur until we reach 1.0.

## Zig Version
The main branch follows Zig's master branch, which is the latest dev version of Zig. There will also be 
branches and tags that will work with the previous two (2) stable Zig releases.

## Integrating Ziglyph in your Project
### Zig Package Manager
In the `build.zig.zon` file, add the following to the dependencies object.

```zig
.ziglyph = .{
    .url = "https://github.com/jecolon/ziglyph/archive/refs/tags/v0.11.1.tar.gz",
}
```

The compiler will produce a hash mismatch error, add the `.hash` field to `build.zig.zon`
with the hash the compiler tells you it found.

Then in your `build.zig` file add the following to the `exe` section for the executable where you wish to have Ziglyph available.

```zig
const ziglyph = b.dependency("ziglyph", .{
    .optimize = optimize,
    .target = target,
});
// for exe, lib, tests, etc.
exe.addModule("ziglyph", ziglyph.module("ziglyph"));
```

Now in the code, you can import components like this:

```zig
const ziglyph = @import("ziglyph");
or const letter = ziglyph.letter;
const number = ziglyph.number;
```

### Using the `ziglyph` Namespace
The `ziglyph` namespace provides convenient acces to the most frequently-used functions related to Unicode
code points and strings.

```zig
const ziglyph = @import("ziglyph");

test "ziglyph namespace" {
    const z = 'z';
    try expect(ziglyph.isLetter(z));
    try expect(ziglyph.isAlphaNum(z));
    try expect(ziglyph.isPrint(z));
    try expect(!ziglyph.isUpper(z));
    const uz = ziglyph.toUpper(z);
    try expect(ziglyph.isUpper(uz));
    try expectEqual(uz, 'Z');

    // String toLower, toTitle, and toUpper.
    var allocator = std.testing.allocator;
    var got = try ziglyph.toLowerStr(allocator, "AbC123");
    errdefer allocator.free(got);
    try expect(std.mem.eql(u8, "abc123", got));
    allocator.free(got);

    got = try ziglyph.toUpperStr(allocator, "aBc123");
    errdefer allocator.free(got);
    try expect(std.mem.eql(u8, "ABC123", got));
    allocator.free(got);

    got = try ziglyph.toTitleStr(allocator, "thE aBc123 moVie. yes!");
    defer allocator.free(got);
    try expect(std.mem.eql(u8, "The Abc123 Movie. Yes!", got));
}
```

### Category Namespaces
Namespaces for frequently-used Unicode General Categories are available.
See [ziglyph.zig](src/ziglyph.zig) for a full list of all components.

```zig
const letter = @import("ziglyph").letter;
const punct = @import("ziglyph").punct;

test "Category namespaces" {
    const z = 'z';
    try expect(letter.isletter(z));
    try expect(!letter.isUpper(z));
    try expect(!punct.ispunct(z));
    try expect(punct.ispunct('!'));
    const uz = letter.toUpper(z);
    try expect(letter.isUpper(uz));
    try expectEqual(uz, 'Z');
}
```

## Normalization
In addition to the basic functions to detect and convert code point case, the `Normalizer` struct 
provides code point and string normalization methods. All normalization forms are supported (NFC,
NFKC, NFD, NFKD.).

```zig
const Normalizer = @import("ziglyph").Normalizer;

test "normalizeTo" {
    var allocator = std.testing.allocator;
    var normalizer = try Normalizer.init(allocator);
    defer normalizer.deinit();

    // Canonical Composition (NFC)
    const input_nfc = "Complex char: \u{03D2}\u{0301}";
    const want_nfc = "Complex char: \u{03D3}";
    var got_nfc = try normalizer.nfc(allocator, input_nfc);
    defer got_nfc.deinit();
    try testing.expectEqualSlices(u8, want_nfc, got_nfc.slice);

    // Compatibility Composition (NFKC)
    const input_nfkc = "Complex char: \u{03A5}\u{0301}";
    const want_nfkc = "Complex char: \u{038E}";
    var got_nfkc = try normalizer.nfkc(allocator, input_nfkc);
    defer got_nfkc.deinit();
    try testing.expectEqualSlices(u8, want_nfkc, got_nfkc.slice);

    // Canonical Decomposition (NFD)
    const input_nfd = "Complex char: \u{03D3}";
    const want_nfd = "Complex char: \u{03D2}\u{0301}";
    var got_nfd = try normalizer.nfd(allocator, input_nfd);
    defer got_nfd.deinit();
    try testing.expectEqualSlices(u8, want_nfd, got_nfd.slice);

    // Compatibility Decomposition (NFKD)
    const input_nfkd = "Complex char: \u{03D3}";
    const want_nfkd = "Complex char: \u{03A5}\u{0301}";
    var got_nfkd = try normalizer.nfkd(allocator, input_nfkd);
    defer got_nfkd.deinit();
    try testing.expectEqualSlices(u8, want_nfkd, got_nfkd.slice);

    // String comparisons.
    try testing.expect(try normalizer.eql(allocator, "foé", "foe\u{0301}"));
    try testing.expect(try normalizer.eql(allocator, "foϓ", "fo\u{03D2}\u{0301}"));
    try testing.expect(try normalizer.eqlCaseless(allocator, "Foϓ", "fo\u{03D2}\u{0301}"));
    try testing.expect(try normalizer.eqlCaseless(allocator, "FOÉ", "foe\u{0301}")); // foÉ == foé
    // Note: eqlIdentifiers is not a method, it's just a function in the Normalizer namespace.
    try testing.expect(try Normalizer.eqlIdentifiers(allocator, "Foé", "foé")); // Unicode Identifiers caseless match.
}
```

## Collation (String Ordering)
One of the most common operations required by string processing is sorting and ordering comparisons.
The Unicode Collation Algorithm was developed to attend this area of string processing. The `Collator`
struct implements the algorithm, allowing for proper sorting and order comparison of Unicode strings.

```zig
const Collator = @import("ziglyph").Collator;

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
```

### Tailoring with allkeys.txt 
You can tailor the sorting of Unicode text by modifying the sort element weights found in
the Unicode data file: allkeys.txt. This will require that you have use a vendored Ziglyph
dependency, since you will be tailoring it to your specific needs. The process is as follows:

```sh 
$ cd /<path to your project root>/
$ mkdir deps && cd deps
$ git clone https://github.com/jecolon/ziglyph
$ cd ziglyph/
$ zig build fetch
$ cp zig-cache/_ziglyph-data/uca/allkeys.txt src/data/tailor/
$ vim src/data/tailor/allkeys.txt # <- Modify the file
$ zig build akcompress
[...output snipped...]
$ mv src/data/allkeys-diffs.txt.deflate src/data/allkeys-diffs.txt.deflate.bak # <- backup original
$ mv src/data/tailor/allkeys-diffs.txt.deflate src/data/
$ cd /<path to your project root>/
```

Now to use this vendored Ziglyph dependency, replace the `b.dependency` call described above in `build.zig` with:

```zig
const ziglyph = b.anonymousDependency("deps/ziglyph", @import("deps/ziglyph/build.zig"), .{
    .optimize = optimize,
    .target = target,
});
```

## Text Segmentation (Grapheme Clusters, Words, Sentences)
Ziglyph has iterators to traverse text as Grapheme Clusters (what most people recognize as *characters*), 
Words, and Sentences. All of these text segmentation functions adhere to the Unicode Text Segmentation rules,
which may surprise you in terms of what's included and excluded at each break point. Test before assuming any
results!

```zig
const Grapheme = @import("ziglyph").Grapheme;
const GraphemeIterator = Grapheme.GraphemeIterator;
const SentenceIterator = Sentence.SentenceIterator;
const ComptimeSentenceIterator = Sentence.ComptimeSentenceIterator;
const Word = @import("ziglyph").Word;
const WordIterator = Word.WordIterator;

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
    var sentences: [n]Sentence = undefined;
    comptime {
        var ct_i: usize = 0;
        while (ct_iter.next()) |sentence| : (ct_i += 1) {
            sentences[ct_i] = sentence;
        }
    }

    for (sentences) |sentence, j| {
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
```

## Code Point and String Display Width
When working with environments in which text is rendered in a fixed-width font, such as terminal 
emulators, it's necessary to know how many cells (or columns) a particular code point or string will
occupy. The `display_width` namespace provides functions to do just that.

```zig
const dw = @import("ziglyph").display_width;

test "Code point / string widths" {
    // The width methods take a second parameter of value .half or .full to determine the width of 
    // ambiguous code points as per the Unicode standard. .half is the most common case.

    // Note that codePointWidth returns an i3 because code points like backspace have width -1.
    try expectEqual(dw.codePointWidth('é', .half), 1);
    try expectEqual(dw.codePointWidth('😊', .half), 2);
    try expectEqual(dw.codePointWidth('统', .half), 2);

    var allocator = std.testing.allocator;

    // strWidth returns usize because it can never be negative, regardless of the code points it contains.
    try expectEqual(try dw.strWidth("Hello\r\n", .half), 5);
    try expectEqual(try dw.strWidth("\u{1F476}\u{1F3FF}\u{0308}\u{200D}\u{1F476}\u{1F3FF}", .half), 2);
    try expectEqual(try dw.strWidth("Héllo 🇵🇷", .half), 8);
    try expectEqual(try dw.strWidth("\u{26A1}\u{FE0E}", .half), 1); // Text sequence
    try expectEqual(try dw.strWidth("\u{26A1}\u{FE0F}", .half), 2); // Presentation sequence

    // padLeft, center, padRight
    const right_aligned = try dw.padLeft(allocator, "w😊w", 10, "-");
    defer allocator.free(right_aligned);
    try expectEqualSlices(u8, "------w😊w", right_aligned);

    const centered = try dw.center(allocator, "w😊w", 10, "-");
    defer allocator.free(centered);
    try expectEqualSlices(u8, "---w😊w---", centered);

    const left_aligned = try dw.padRight(allocator, "w😊w", 10, "-");
    defer allocator.free(left_aligned);
    try expectEqualSlices(u8, "w😊w------", left_aligned);
}
```

## Word Wrap
If you need to wrap a string to a specific number of columns according to Unicode Word boundaries and display width,
you can use the `display_width` struct's `wrap` function for this. You can also specify a threshold value indicating how close
a word boundary can be to the column limit and trigger a line break.

```zig
const dw = @import("ziglyph").display_width;

test "display_width wrap" {
    var allocator = testing.allocator;
    var input = "The quick brown fox\r\njumped over the lazy dog!";
    var got = try dw.wrap(allocator, input, 10, 3);
    defer allocator.free(got);
    var want = "The quick\n brown \nfox jumped\n over the\n lazy dog\n!";
    try testing.expectEqualStrings(want, got);
}
```
