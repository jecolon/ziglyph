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
*   2021-05-02: Major refactor to make handling of `Context` more ergonomic and efficient, via singletons
    caching, and convenience functions.

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
const Context = @import("Ziglyph").Context;
const Letter = @import("Ziglyph").Letter;
const Number = @import("Ziglyph").Number;
```

Finally, you can build the project with:

```sh
$ zig build
```

Note that to build in realase modes, either specify them in the `build.zig` file or on the command line
via the `-Drelease-fast=true`, `-Drelease-small=true`, `-Drelease-safe=true` options to `zig build`.

### Usage Overview
#### Unicode Data and Contexts
Unicode is a large standard, and the data needed to implement it is also large. Given that the nature
and use of parts of this data are varied, it would be inefficient to load all the data all the time, 
so the Ziglyph library provides the concept of a `Context`, which loads only parts of the data needed
by the components used in your program. For example, if you're only dealing with the `Number` component,
the `Context(.number)` only loads the required data to handle Unicode number functions. Here's the code:

```zig
const Context = @import("Ziglyph").Context;
const Number = Context.Number;

// First the Context
var ctx = try Context(.number).init(std.testing.allocator);
defer ctx.deinit();

// and now the component struct
var number = Number.initWithContext(ctx);
defer number.deinit();

// do stuff with number
expect(number.isNumber('1'));
```

Creating a `Context` can be useful when you plan on using a single `Context` with more than one component.
The context types are defined in the `DataSet` enum in the `Context` struct. They practically mirror the 
major components of the library.

For convenience, if you won't be using different components, you can create your component directly 
without a `Context`, an internal one will be created and managed for you:

```zig
const Number = @import("Ziglyph").Context.Number;

// No need for a context if you don't want one.
var number = try Number.init(std.testing.allocator);
defer number.deinit();

// do stuff with number
expect(number.isNumber('1'));
```

Not all `Context` types can be used with all componets, the compiler will let you know this. ;)

### Using the Ziglyph Struct
```zig
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
const Context = @import("Ziglyph").Context;
const Letter = Context.Letter;
const Punct = Context.Punct;

test "Aggregate struct" {
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

test "Aggregate struct, shared Context" {
    // The .ziglyph context has all the fequently used data, including what Letter and Punct need.
    // The individual .letter and .punct contexts wouldn't suffice for both component structs at once.
    var ctx = try Context(.ziglyph).init(std.testing.allocator);
    defer ctx.deinit();

    var letter = Letter.initWithContext(ctx);
    defer letter.deinit();
    var punct = Punct.initWithContext(ctx);
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
const Context = @import("Ziglyph").Context;

test "Component structs" {
    var ctx = try Context(.ziglyph).init(std.testing.allocator);
    defer ctx.deinit();

    const z = 'z';
    expect(ctx.lower.isLowercaseLetter(z));
    expect(!ctx.upper.isUppercaseLetter(z));
    const uz = ctx.upper_map.toUpper(z);
    expect(ctx.upper.isUppercaseLetter(uz));
    expectEqual(uz, 'Z');
}
```

## Decomposition and Normalization
In addition to the basic functions to detect and convert code point case, the `DecomposeMap` struct 
provides code point decomposition and string normalization methods. This library currently only 
performs full canonical and compatibility decomposition and normalization (NFD and NFKD). Future 
versions may add more normalization forms.

```zig
const DecomposeMap = @import("Ziglyph").Context.DecomposeMap;

test "normalizeTo" {
    var allocator = std.testing.allocator;
    var decomp_map = try DecomposeMap.init(allocator);
    defer decomp_map.deinit();

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
const GraphemeIterator = @import("Ziglyph").Context.GraphemeIterator;

test "GraphemeIterator" {
    var giter = try GraphemeIterator.init(std.testing.allocator, "H\u{0065}\u{0301}llo");
    defer giter.deinit();

    const want = &[_][]const u8{ "H", "\u{0065}\u{0301}", "l", "l", "o" };

    var i: usize = 0;
    while (giter.next()) |gc| : (i += 1) {
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
    var width = try Width.init(std.testing.allocator);
    defer width.deinit();

    // The width methods take a second parameter of value .half or .full to determine the width of 
    // ambiguous code points as per the Unicode standard. .half is the most common case.
    expectEqual(width.codePointWidth('é', .half), 1);
    expectEqual(width.codePointWidth('😊', .half), 2);
    expectEqual(width.codePointWidth('统', .half), 2);
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
proper locations.) [LICENSE](src/data/ucd/LICENSE-UNICODE)
