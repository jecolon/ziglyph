# ziglyph
Unicode processing with Zig, and a UTF-8 string type: [Zigstr](src/zigstr).

## Status
This is pre-1.0 software. Althogh breaking changes are less frequent with each minor version release,
they still will occur until we reach 1.0.

*   2021-04-09: Unicode database ETL and analysis phase. Working out the best way to split the data
    and apply the spec rules.
*   2021-04-18: ETL working well, now on to API design and implementation. Initial basic code point
    type detection, case conversion, case folding, decomposition, normalization, and grapheme cluster 
    breaks passing Unicode supplied tests.
*   2021-04-24: Work on Zigstr, a UTF-8 string type, has begun; basic functionality working.
*   2021-04-27: Major refactor introducing `Context`, a struct that centralizes the major component 
    data structures, avoiding repeated allocations of these, which can be very large. Also, initial 
    support for code point and string width calculation added.

## Background
This library has been built from scratch in Zig. Although initially inspired by the Go `unicode`
package, Ziglyph is now completely independent and unique in and of itself.

### The Zigstr String Type
`Zigstr` is a UTF-8 string type that incorporates many of Ziglyph's Unicode processing tools. You can
learn more in the [Zigstr subdirectory](src/zigstr).

## Integrating Ziglyph in your Project
In a `libs` subdirectory under the root of your project, clone this repository via

```sh
$  git clone https://github.com/jecolon/ziglyph.git
```

Now in your build.zig, you can add:

```zig
exe.addPackagePath("Ziglyph", "libs/ziglyph/src/ziglyph.zig");
```

to the `exe` section for the executable where you wish to have Ziglyph available. Now in the code, you
can import components like this:

```zig
const Ziglyph = @import("Ziglyph").Ziglyph;
const Letter = @import("Ziglyph").Letter;
const Number = @import("Ziglyph").Number;
```

Finally, you can build the project with:

```sh
$ zig build
```

Note that to build in relase modes, either specify them in the `build.zig` file or on the command line
via the `-Drealease-fast=true`, `-Drealease-small=true`, `-Drealease-safe=true` options to `zig build`.

### Usage Overview
The basic workflow consists of seting up a global `Context` which will centralize the major data structures
to reduce memory footprint. This `Context` can then be passed to the `new` and `init` functions of other
components of the library. The `Ziglyph` struct consolidates many frequently-used functions for Unicode
code point type and letter case detection, letter case conversion, along with their ASCII counterparts.
More specific aggregate structs are also available such as `Letter`, `Punct`, `Symbol`, and others to
provide more granular control over memory usage.

### Using the Ziglyph Struct
```zig
const Context = @import("Context.zig");
const Ziglyph = @import("Ziglyph").Ziglyph;

test "Ziglyph struct" {
    var ctx = Context.init(std.testing.allocator);
    defer ctx.deinit();

    var ziglyph = try Ziglyph.new(&ctx);

    const z = 'z';
    expect(try ziglyph.isLetter(z));
    expect(try ziglyph.isAlphaNum(z));
    expect(try ziglyph.isPrint(z));
    expect(!try ziglyph.isUpper(z));
    const uz = try ziglyph.toUpper(z);
    expect(try ziglyph.isUpper(uz));
    expectEqual(uz, 'Z');
}
```

### Using the aggregate Structs
```zig
const Letter = @import("components/aggregate/Letter.zig");
const Punct = @import("components/aggregate/Punct.zig");

test "Aggregate struct" {
    var ctx = Context.init(std.testing.allocator);
    defer ctx.deinit();

    var letter = Letter.new(&ctx);
    var punct = Punct.new(&ctx);

    const z = 'z';
    expect(try letter.isLetter(z));
    expect(!try letter.isUpper(z));
    expect(!try punct.isPunct(z));
    expect(try punct.isPunct('!'));
    const uz = try letter.toUpper(z);
    expect(try letter.isUpper(uz));
    expectEqual(uz, 'Z');
}
```

### Using individual low-level component structs
```zig
test "Component structs" {
    var ctx = Context.init(std.testing.allocator);
    defer ctx.deinit();

    const lower = try ctx.getLower();
    const upper = try ctx.getUpper();
    const upper_map = try ctx.getUpperMap();

    const z = 'z';
    expect(lower.isLowercaseLetter(z));
    expect(!upper.isUppercaseLetter(z));
    const uz = upper_map.toUpper(z);
    expect(upper.isUppercaseLetter(uz));
    expectEqual(uz, 'Z');
}
```

## Decomposition and Normalization
In addition to the basic functions to detect and convert code point case, the `DecomposeMap` struct 
provides code point decomposition and string normalization methods. This library currently only 
performs full canonical and compatibility decomposition and normalization (NFD and NFKD). Future 
versions may add more normalization forms.

```zig
test "normalizeTo" {
    var allocator = std.testing.allocator;
    var ctx = Context.init(allocator);
    defer ctx.deinit();

    const decomp_map = try ctx.getDecomposeMap();

    // Canonical (NFD)
    var input = "Complex char: \u{03D3}";
    var want = "Complex char: \u{03D2}\u{0301}";
    var got = try decomp_map.normalizeTo(allocator, .D, input);
    defer allocator.free(got);
    expectEqualSlices(u8, want, got);
    allocator.free(got);

    // Compatibility (NFKD)
    input = "Complex char: \u{03D3}";
    want = "Complex char: \u{03A5}\u{0301}";
    got = try decomp_map.normalizeTo(allocator, .KD, input);
    expectEqualSlices(u8, want, got);
}
```

## Grapheme Clusters
Many programming languages and libraries provide a basic `Character` or `char` type to represent what
we normally consider to be the characters that we see printed out composing strings of text. Unfortunately,
these implementations map these types to what Unicode calls a *code point*, which is only correct if 
you're working with basic latin letters and numbers, mostly in the ASCII character set space. When 
dealing with the vast majority of other languages, code points do not map directly to what we would 
consider *characters* of a string, but rather a single visible character can be composed of many code points,
combined to form a single human-readable character. In Unicode, these combinations of code points are
called *Grapheme Clusters* and Ziglyph provides the `GraphemeIterator` to extract individual *characters* 
(not just single code points) from a string.

```
const GraphemeIterator = @import("Ziglyph").GraphemeIterator;

test "GraphemeIterator" {
    var ctx = Context.init(std.testing.allocator);
    defer ctx.deinit();

    var iter = try GraphemeIterator.new(&ctx, "H\u{0065}\u{0301}llo");

    const want = &[_][]const u8{ "H", "\u{0065}\u{0301}", "l", "l", "o" };

    var i: usize = 0;
    while (try iter.next()) |gc| : (i += 1) {
        expect(gc.eql(want[i]));
    }
}
```

## Code Point and String Width
When working with environments in which text is rendered in a fixed-width font, such as terminal 
emulators, it's necessary to know how many cells (or columns) a particular code point or string will
occupy. The `Width` component struct provides methods to do just that.

```
const Width = @import("Ziglyph").Zigstr.Width;

test "Code point / string widths" {
    var ctx = Context.init(std.testing.allocator);
    defer ctx.deinit();

    var width = try Width.new(&ctx);

    // The width methods take a second parameter of value .half or .full to determine the width of 
    // ambiguous code points as per the Unicode standard. .half is the most common case.
    expectEqual(try width.codePointWidth('é', .half), 1);
    expectEqual(try width.codePointWidth('😊', .half), 2);
    expectEqual(try width.codePointWidth('统', .half), 2);
    expectEqual(try width.strWidth("Hello\r\n", .half), 5);
    expectEqual(try width.strWidth("\u{1F476}\u{1F3FF}\u{0308}\u{200D}\u{1F476}\u{1F3FF}", .half), 2);
    expectEqual(try width.strWidth("Héllo 🇪🇸", .half), 8);
    expectEqual(try width.strWidth("\u{26A1}\u{FE0E}", .half), 1); // Text sequence
    expectEqual(try width.strWidth("\u{26A1}\u{FE0F}", .half), 2); // Presentation sequence
}
```

## Unicode Data
The Unicode data is the latest available on the Unicode website, and can be refreshed via the 
`ucd_gen.sh` script in the root directory (must be run in the root directory to generate files in the 
proper locations.) The `ucd_gen.sh` script will look for a cached copy of the data, If it finds it, 
it, the `src/ucd_gen` program will parse those files; otherwise it will download the latest version 
from the Unicode website. `src/ucd_gen` is also built with Zig. You can find it in `ucd_gen.zig` in 
the src directory too. To refresh the data, you only have to run `ucd_gen.sh` in the root directory,
which will in turn run `src/ucd_gen` automatically for you.

## Speed Test?
In a corpus test whith about 3.9MiB of text in Chinese, English, French, and Spanish from the full 
texts of "Alice in Wonderland", "Don Quijote", "The Three Musketeers", and a Chinese book I don't have 
the title of, detectiong code point types and converting cases, it takes roughly 47ms. On a Linux, 
Ryzen 5 2600X CPU, 16GiB RAM, SSD storage machine, All texts are courtesy of the 
[Project Gutenberg](https://www.gutenberg.org/) website, so all Public Domain.
