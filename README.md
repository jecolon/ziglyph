# ziglyph
Unicode processing with Zig.

## Background
This library started as a direct translation of the Go unicode base package 
from the Go standard library. Still wohk to be done, to make it more idiomatic Zig, but 
practiacally all basic feature tests are now passing. See [src/main.zig](src/main.zig) for 
sample usage in the tests.

## Usage
There are two modes of usage: via the consolidated Ziglyph struct or using the individual component
structs for more fine grained control over memory use and binary size.

### Using the Ziglyph Struct
```zig
const std = @import("std");
const expect = std.testing.expect;
const expectEqual = std.testing.expectEqual;
// Import the struct.
const Ziglyph = @import("ziglyph.zig").Ziglyph;

test "Ziglyph struct" {
    var ziglyph = Ziglyph{};

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

### Using Individual Components
```zig
const std = @import("std");
const expect = std.testing.expect;
const expectEqual = std.testing.expectEqual;
// Import the structs.
const Letter = @import("ziglyph.zig").Letter;
const Upper = @import("ziglyph.zig").Upper;
const UpperMap = @import("ziglyph.zig").UpperMap;

test "Component structs" {
    const letter = Letter.new();
    const upper = Upper.new();
    var upper_map = UpperMap.new();

    const z = 'z';
    expect(letter.isLetter(z));
    expect(!upper.isUpper(z));
    const uz = upper_map.toUpper(z);
    expect(upper.isUpper(uz));
    expectEqual(uz, 'Z');
}
```

## Code Point Decomposition
In addition to the basic functions to detect and convert code points, the `DecomposeMap` struct provides
code point and `[]const u8` decomposition methods.

```zig
const std = @import("std");
const expectEqualSlices = std.testing.expectEqualSlices;

// Import struct.
const DecomposeMap = @import("ziglyph.zig").DecomposeMap;

test "decomposeCodePoint" {
    var z = try DecomposeMap.init(std.testing.allocator);
    defer z.deinit();

    expectEqualSlices(u21, z.decomposeCodePoint('\u{00E9}').?, &[_]u21{ '\u{0065}', '\u{0301}' });
}

test "decomposeString" {
    var z = try DecomposeMap.init(std.testing.allocator);
    defer z.deinit();

    const input = "H\u{00E9}llo";
    const want = "H\u{0065}\u{0301}llo";
    const got = try z.decomposeString(input);
    defer std.testing.allocator.free(got);
    expectEqualSlices(u8, want, got);
}
```

## Source Doc Comments
You can get descriptions for all the public methods in the [src/ziglyph.zig](src/ziglyph.zig) file
doc comments. This structure exposes the same methods as all the components in one place, plus a few
more.
