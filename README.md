# ziglyph
Unicode processing with Zig.

## Background
This library has been built from scratch in Zig. Although initially inspired by the Go `unicode`
package, Ziglyph is now completely independent and unique in and of itself.

## Usage
There are two modes of usage: via the consolidated Ziglyph struct or using the individual component
structs for more fine grained control over memory usage and binary size. The Ziglyph struct provides
the convenience of having all the methods in one place, with lazy initialization of the underlying
structs to only use the resources necessary. However this comes at the cost of more error handling,
given that when calling a method such as `isUpper`, Ziglyph may need to lazily initialize the `Upper`
struct, which may fail. The same method directly on the `Upper` struct doesn't allocate and thus cannot
fail.

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
    expect(!try ziglyph.isPrint(z));
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
const Letter = @import("ziglyph.zig").Letter;
const Upper = @import("ziglyph.zig").Upper;
const UpperMap = @import("ziglyph.zig").UpperMap;

test "Component structs" {
    var letter = try Letter.init(std.testing.allocator);
    defer letter.deinit();
    var upper = try Upper.init(std.testing.allocator);
    defer upper.deinit();
    var upper_map = try UpperMap.init(std.testing.allocator);
    defer upper_map.deinit();

    const z = 'z';
    // No lazy init, no 'try' here.
    expect(letter.isLetter(z));
    expect(!upper.isUpper(z));
    const uz = upper_map.toUpper(z);
    expect(upper.isUpper(uz));
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

    expectEqualSlices(u21, decomp_map.decomposeCodePoint('\u{00E9}').?, &[_]u21{ '\u{0065}', '\u{0301}' });
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
`ucd_gen` utility in the src directory (must be run in the src directory to generate files in the 
proper locations.) The `ucd_gen` utility will look for a cached copy of the data in a file named
`UnicodeData.txt` in the src/data directory. If it finds it, it will parse that file; otherwise it 
will download the latest version from the Unicode website. `ucd_gen` is also built with Zig. You can
find it in `ucd_gen.zig` in the src directory too.

## Speed Test?
You can build [src/corpus__test.zig](src/corpus_test.zig), in `ReleaseFast` mode and use the `time`
utility (Linux or Mac) to gauge the execution speed of Ziglyph. This program reads 
[src/data/lang_mix.txt](src/data/lang_mix.txt), which is about 3.9MiB of text in Chinese, English, 
French, and Spanish from the full texts of "Alice in Wonderland", "Don Quijote", "The Three Musketeers",
and a Chinese book I don't have the title of. All from the [Project Gutenberg](https://www.gutenberg.org/)
website, so all Public Domain. On my Linux, Ryzen 5 2600X, 16GiB RAM machine, it takes roughly 45ms.

## Source Doc Comments
You can get descriptions for all the public methods in the [src/ziglyph.zig](src/ziglyph.zig)  and
[src/components/DecomposeMap.zig](src/components/DecomposeMap.zig) files' doc comments.
