# ziglyph
Unicode processing with Zig.

## Status
This is pre-release software. Breaking changes and rough edges abound!
* 2021-04-09: Unicode database ETL and analysis phase. Working out the best way to split the data
and apply the spec rules.

## Background
This library has been built from scratch in Zig. Although initially inspired by the Go `unicode`
package, Ziglyph is now completely independent and unique in and of itself.

## Usage
There are two modes of usage: via the consolidated Ziglyph struct or using the individual component
structs for more fine grained control over memory usage and binary size. The Ziglyph struct provides
the convenience of having all the methods in one place, with lazy initialization of the underlying
structs to only use the resources necessary. However this comes at the cost of more error handling,
given that when calling a method such as `isUpper`, Ziglyph may need to lazily initialize underlying
structs, which may fail. The same method directly on the `Upper` struct doesn't allocate and thus cannot
fail. On the other hand, methods that consolidate Unicode General Categories such as `isLetter`, can
only be found on the `Ziglyph` struct itself. View the source for such methods to see which component
structs are involved to comply with the Unicode spec's rules.

### Using the Ziglyph Struct
```zig
const std = @import("std");
const expect = std.testing.expect;
const expectEqual = std.testing.expectEqual;

// Import the struct.
const Ziglyph = @import("ziglyph.zig").Ziglyph;

test "Ziglyph struct" {
    var ziglyph = try Ziglyph.init(std.testing.allocator);
    defer ziglyph.deinit();

    const z = 'z';
    // Lazy init requires 'try'
    expect(try ziglyph.isLetter(z));
    expect(try ziglyph.isAlphaNum(z));
    expect(try ziglyph.isPrint(z));
    expect(!try ziglyph.isUpper(z));
    const uz = try ziglyph.toUpper(z);
    expect(try ziglyph.isUpper(uz));
    expectEqual(uz, 'Z');
}
```

### Using Individual Components
```zig
const std = @import("std");
const expect = std.testing.expect;
const expectEqual = std.testing.expectEqual;

// Import the components.
// A letter in Unicode is not a trivial thing!
const Lower = @import("ziglyph.zig").Lower;
const Title = @import("ziglyph.zig").Title;
const Upper = @import("ziglyph.zig").Upper;
const ModLetter = @import("components/DerivedGeneralCategory/ModifierLetter.zig");
const OtherLetter = @import("components/DerivedGeneralCategory/OtherLetter.zig");
// Case mapping.
const UpperMap = @import("ziglyph.zig").UpperMap;

test "Component structs" {
    var mod_letter = try ModLetter.init(allocator);
    defer mod_letter.deinit();
    var other_letter = try OtherLetter.init(allocator);
    defer other_letter.deinit();
    var lower = try Lower.init(allocator);
    defer lower.deinit();
    var title = try Title.init(allocator);
    defer title.deinit();
    var upper = try Upper.init(std.testing.allocator);
    defer upper.deinit();
    var upper_map = try UpperMap.init(std.testing.allocator);
    defer upper_map.deinit();

    const z = 'z';
    // No lazy init, no 'try' here.
    // The Ziglyph.isLetter method does this internally to detect a letter.
    expect(lower.isLowercaseLetter(z) or
        mod_letter.isModifierLetter(z) or
        other_letter.isOtherLetter(z) or
        title.isTitlecaseLetter(z) or
        upper.isUppercaseLetter(z));
    expect(!upper.isUppercaseLetter(z));
    const uz = upper_map.toUpper(z);
    expect(upper.isUppercaseLetter(uz));
    expectEqual(uz, 'Z');
}
```

## Code Point Decomposition
In addition to the basic functions to detect and convert code point case, the `DecomposeMap` struct provides
code point and `[]const u8` decomposition methods.

```zig
const std = @import("std");
const expectEqualSlices = std.testing.expectEqualSlices;

// Import struct.
const DecomposeMap = @import("ziglyph.zig").DecomposeMap;

test "decomposeCodePoint" {
    var decomp_map = try DecomposeMap.init(std.testing.allocator);
    defer decomp_map.deinit();

    var result = z.decomposeCodePoint('\u{00E9}');
    switch (result) {
        .same => @panic("Expected .seq, got .same for \\u{00E9}"),
        .seq => |seq| expectEqualSlices(u21, seq, &[_]u21{ '\u{0065}', '\u{0301}' }),
    }
}

test "decomposeString" {
    var decomp_map = try DecomposeMap.init(std.testing.allocator);
    defer decomp_map.deinit();

    const input = "H\u{00E9}llo";
    const want = "H\u{0065}\u{0301}llo";
    // decomposeString allocates memory for the returned slice, so it can fail.
    const got = try decomp_map.decomposeString(input);
    // We must free the returned slice when done.
    defer std.testing.allocator.free(got);
    expectEqualSlices(u8, want, got);
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
You can build [src/corpus__test.zig](src/corpus_test.zig), in `ReleaseFast` mode and use the `time`
utility (Linux or Mac) to gauge the execution speed of Ziglyph. This program reads 
[src/data/lang_mix.txt](src/data/lang_mix.txt), which is about 3.9MiB of text in Chinese, English, 
French, and Spanish from the full texts of "Alice in Wonderland", "Don Quijote", "The Three Musketeers",
and a Chinese book I don't have the title of. All from the [Project Gutenberg](https://www.gutenberg.org/)
website, so all Public Domain. On my Linux, Ryzen 5 2600X, 16GiB RAM machine, it takes roughly 59ms.
