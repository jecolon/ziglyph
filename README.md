# ziglyph
Unicode processing with Zig.

## Status
This is pre-release software. Breaking changes and rough edges abound!
* 2021-04-09: Unicode database ETL and analysis phase. Working out the best way to split the data
and apply the spec rules.
* 2021-04-18: ETL working well, now on to API design and implementation. Initial basic code point
type detection, case conversion, case folding, decomposition, normalization, and grapheme cluster 
breaks passing Unicode supplied tests.
* 2021-04-24: Work on Zigstr, a UTF-8 string type, has begun; basic functionality working.

## Background
This library has been built from scratch in Zig. Although initially inspired by the Go `unicode`
package, Ziglyph is now completely independent and unique in and of itself.

## Usage
There are two modes of usage: via the consolidated Ziglyph struct or using the individual component
structs for more fine grained control over memory usage and binary size. The Ziglyph struct provides
the convenience of having all the most frequently used methods in one place. There is a sub-level of
component structs that expose this same consolidated interface but with more specific scope; i.e. 
`Letter`, `Punct`, and `Symbol`. The component structs like `Lower` and `Upper` are the lowest level.
These structs are also auto-generated code from the Unicode Character Database (UCD) files.

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

### Using the Ziglyph Struct
```zig
// Import the struct.
const Ziglyph = @import("Ziglyph").Ziglyph;

test "Ziglyph struct" {
    var ziglyph = try Ziglyph.init(std.testing.allocator);
    defer ziglyph.deinit();

    const z = 'z';
    expect(ziglyph.isLetter(z));
    expect(ziglyph.isAlphaNum(z));
    expect(ziglyph.isPrint(z));
    expect(!ziglyph.isUpper(z));
    const uz = ziglyph.toUpper(z);
    expect(ziglyph.isUpper(uz));
    expectEqual(uz, 'Z');
}
```

### Using the aggregate Structs
```zig
// Import the structs.
const Letter = @import("Ziglyph").Letter;
const Punct = @import("Ziglyph").Punct;

test "Aggregate structs" {
    var letter = try Letter.init(std.testing.allocator);
    defer letter.deinit();
    var punct = try Punct.init(std.testing.allocator);
    defer punct.deinit();

    const z = 'z';
    expect(letter.isLetter(z));
    expect(!letter.isUpper(z));
    expect(!punct.isPunct(z));
    expect(punct.isPunct('!'));
    const uz = letter.toUpper(z);
    expect(letter.isUpper(uz));
    expectEqual(uz, 'Z');
}
```

### Using individual low-level component structs
```zig
// Import the components.
const Lower = @import("Ziglyph").Letter.Lower;
const Upper = @import("Ziglyph").Letter.Upper;
const UpperMap = @import("Ziglyph").Letter.UpperMap;

test "Component structs" {
    var lower = try Lower.init(std.testing.allocator);
    defer lower.deinit();
    var upper = try Upper.init(std.testing.allocator);
    defer upper.deinit();
    var upper_map = try UpperMap.init(std.testing.allocator);
    defer upper_map.deinit();

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
// Import the structs.
const DecomposeMap = @import("Ziglyph").DecomposeMap;
const Decomposed = DecomposeMap.Decomposed;

// Normalization Forms: D == Canonical, KD == Compatibility
test "decomposeTo" {
    var allocator = std.testing.allocator;
    var z = try DecomposeMap.init(allocator);
    defer z.deinit();

    // D: ox03D3 -> 0x03D2, 0x0301
    var src = [1]Decomposed{.{ .src = '\u{03D3}' }};
    var result = try z.decomposeTo(allocator, .D, &src);
    defer allocator.free(result);
    expectEqual(result.len, 2);
    expectEqual(result[0].same, 0x03D2);
    expectEqual(result[1].same, 0x0301);
    allocator.free(result);

    // KD: ox03D3 -> 0x03D2, 0x0301 -> 0x03A5, 0x0301
    src = [1]Decomposed{.{ .src = '\u{03D3}' }};
    result = try z.decomposeTo(allocator, .KD, &src);
    expectEqual(result.len, 2);
    expect(result[0] == .same);
    expectEqual(result[0].same, 0x03A5);
    expect(result[1] == .same);
    expectEqual(result[1].same, 0x0301);
}

test "normalizeTo" {
    var allocator = std.testing.allocator;
    var z = try DecomposeMap.init(allocator);
    defer z.deinit();

    // Canonical (NFD)
    var input = "Complex char: \u{03D3}";
    var want = "Complex char: \u{03D2}\u{0301}";
    var got = try z.normalizeTo(allocator, .D, input);
    defer allocator.free(got);
    expectEqualSlices(u8, want, got);
    allocator.free(got);

    // Compatibility (NFKD)
    input = "Complex char: \u{03D3}";
    want = "Complex char: \u{03A5}\u{0301}";
    got = try z.normalizeTo(allocator, .KD, input);
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
// Import the struct.
const GraphemeIterator = @import("Ziglyph").GraphemeIterator;

test "GraphemeIterator" {
    var iter = try GraphemeIterator.init(std.testing.allocator, "H\u{0065}\u{0301}llo"); // Héllo
    defer iter.deinit();

    const want = &[_][]const u8{ "H", "\u{0065}\u{0301}", "l", "l", "o" };

    for (want) |w| {
        expectEqualSlices(u8, w, iter.next().?);
    }
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
