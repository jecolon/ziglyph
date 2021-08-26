# ziglyph
Unicode text processing for the Zig Programming Language.

## Looking for an UTF-8 String Type?
`Zigstr` is a UTF-8 string type that incorporates many of Ziglyph's Unicode processing tools. You can
learn more in the [Zigstr repo](https://github.com/jecolon/zigstr).

## Main Branch
This is the `main` development branch. Breaking changes may occur. For a version that stays stable with
the latest stable version of Zig, check out the `stable` branch.

## Status
This is pre-1.0 software. Although breaking changes are less frequent with each minor version release,
they still will occur until we reach 1.0.

## Integrating Ziglyph in your Project
### Using Zigmod
```sh
$ zigmod aq add 1/jecolon/zigstr
$ zigmod fetch
```
Now in your `build.zig` you add this import:

```
const deps = @import("deps.zig");
```
In the `exe` section for the executable where you wish to have Zigstr available, add:

```
deps.addAllTo(exe);
```

### Manually via Git
In a `libs` subdirectory under the root of your project, clone this repository via

```sh
$  git clone https://github.com/jecolon/ziglyph.git
```
Now in your build.zig, you can add:

```zig
exe.addPackagePath("ziglyph", "libs/ziglyph/src/Ziglyph.zig");
```
to the `exe` section for the executable where you wish to have Ziglyph available. Now in the code, you
can import components like this:

```zig
const ziglyph = @import("ziglyph");
const Letter = @import("ziglyph").Letter; // or const Letter = Ziglyph.Letter;
const Number = @import("ziglyph").Number; // or const Number = Ziglyph.Number;

```

### Using the Ziglyph Struct
The `Ziglyph` struct provides convenient acces to the most frequently-used functions related to Unicode
code points and strings.

```zig
const ziglyph = @import("ziglyph");

test "Ziglyph struct" {
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

### Using Component Structs
Smaller aggregate structs are privided for specific areas of functionality.
See [components.zig](src/components.zig) for a full list of all components.

```zig
const Letter = @import("ziglyph").Letter;
const Punct = @import("ziglyph").Punct;

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
```

## Normalization
In addition to the basic functions to detect and convert code point case, the `Normalizer` struct 
provides code point and string normalization methods. All normalization forms are supported (NFC,
NFKC, NFD, NFKD.) The `init` function takes an allocator and the path to the compressed 
`Decompositions.bin` file derived from the Unicode Character Database. A copy of this file
is found in the `src/data/ucd` directory. See the section on Collation for more information on the 
compression algorithm applied to the the Unicode data files for both Normalization and Collation.

```zig
const Normalizer = @import("ziglyph").Normalizer;

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
```

## Collation (String Ordering)
One of the most common operations required by string processing is sorting and ordering comparisons.
The Unicode Collation Algorithm was developed to attend this area of string processing. The `Collator`
struct implements the algorithm, allowing for proper sorting and order comparison of Unicode strings.
The `init` function requires the path to a file with derived Unicode sort keys. The full file of keys
can be found [here](http://www.unicode.org/Public/UCA/latest/allkeys.txt). The derived copy of this file
can be found in the `src/data/uca` directory. This derived copy is compressed with a novel compression
algorithm developed by @slimsag / @hexops called Unicode Data Differential Compression (UDDC). The
algorithm achieves extremely efficient compression of the large Unicode data files required for 
Normalization and Collation. You can read more about it in 
[this blog post](https://devlog.hexops.com/2021/unicode-data-file-compression).
`init` also takes a pointer to a `Normalizer` because collation depends on normaliztion.

```
const Collator = @import("ziglyph").Collator;

test "Collation" {
    var allocator = std.testing.allocator;
    var normalizer = try Normalizer.init(allocator, "../libs/ziglyph/src/data/ucd/Decompositions.bin");
    defer normalizer.deinit();
    var collator = try Collator.init(allocator, "../libs/ziglyph/src/data/uca/allkeys.bin", &normalizer);
    defer collator.deinit();

    // Collation weight levels overview:
    // * .primary: different letters.
    // * .secondary: could be same letters but with marks (like accents) differ.
    // * .tertiary: same letters and marks but case is different.
    // So cab < dab at .primary, and cab < cáb at .secondary, and cáb < Cáb at .tertiary level.
    testing.expect(collator.tertiaryAsc("abc", "def"));
    testing.expect(collator.tertiaryDesc("def", "abc"));

    // At only primary level, José and jose are equal because base letters are the same, only marks 
    // and case differ, which are .secondary and .tertiary respectively.
    testing.expect(try collator.orderFn("José", "jose", .primary, .eq));

    // Full Unicode sort.
    var strings: [3][]const u8 = .{ "xyz", "def", "abc" };
    collator.sortAsc(&strings);
    testing.expectEqual(strings[0], "abc");
    testing.expectEqual(strings[1], "def");
    testing.expectEqual(strings[2], "xyz");

    // ASCII only binary sort. If you know the strings are ASCII only, this is much faster.
    strings = .{ "xyz", "def", "abc" };
    collator.sortAsciiAsc(&strings);
    testing.expectEqual(strings[0], "abc");
    testing.expectEqual(strings[1], "def");
    testing.expectEqual(strings[2], "xyz");
}
```

## Text Segmentation (Grapheme Clusters, Words, Sentences)
Ziglyph has iterators to traverse text as Grapheme Clusters (what most people recognize as *characters*), 
Words, and Sentences. All of these text segmentation functions adhere to the Unicode Text Segmentation rules,
which may surprise you in terms of what's included and excluded at each break point. Test before assuming any
results! There are also non-allocating compile-time versions for use with string literals or embedded files.

```
const Grapheme = @import("ziglyph").Grapheme;
const GraphemeIterator = Grapheme.GraphemeIterator;
const ComptimeGraphemeIterator = Grapheme.ComptimeGraphemeIterator;
const SentenceIterator = @import("ziglyph").SentenceIterator;
const WordIterator = @import("ziglyph").WordIterator;

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
    while (sentences.next()) |sentence| : (i += 1) {
        try testing.expectEqualStrings(sentence.bytes, want[i]);
    }
}

test "WordIterator" {
    var allocator = std.testing.allocator;
    var words = try WordIterator.init(allocator, "The (quick) fox. Fast! ");
    defer words.deinit();

    const want = &[_][]const u8{ "The", " ", "(", "quick", ")", " ", "fox", ".", " ", "Fast", "!", " " };

    var i: usize = 0;
    while (words.next()) |word| : (i += 1) {
        try testing.expectEqualStrings(word.bytes, want[i]);
    }
}
```

## Code Point and String Width
When working with environments in which text is rendered in a fixed-width font, such as terminal 
emulators, it's necessary to know how many cells (or columns) a particular code point or string will
occupy. The `Width` component struct provides methods to do just that.

```
const Width = @import("ziglyph").Width;

test "Code point / string widths" {
    // The width methods take a second parameter of value .half or .full to determine the width of 
    // ambiguous code points as per the Unicode standard. .half is the most common case.

    // Note that codePointWidth returns an i3 because code points like backspace have width -1.
    try expectEqual(Width.codePointWidth('é', .half), 1);
    try expectEqual(Width.codePointWidth('😊', .half), 2);
    try expectEqual(Width.codePointWidth('统', .half), 2);

    var allocator = std.testing.allocator;

    // strWidth returns usize because it can never be negative, regardless of the code points it contains.
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
```
