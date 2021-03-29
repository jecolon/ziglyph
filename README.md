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
    // init and defer deinit.
    var ziglyph = Ziglyph.init(std.testing.allocator);
    defer ziglyph.deinit();

    const z = 'z';
    expect(ziglyph.isLetter(z));
    expect(ziglyph.isAlphaNum(z));
    expect(ziglyph.isPrint(z));
    expect(!ziglyph.isUpper(z));
    // The Ziglyph struct uses lazy init, so 
    // using a case mapping may init a HashMap
    // which may produce an error. That's why you
    // need 'try' here.
    const uz = try ziglyph.toUpper(z);
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
    // Simple structs don't require init / deinit.
    const letter = Letter.new();
    const upper = Upper.new();
    // Case mappings require init and defer deinit.
    var upper_map = try UpperMap.init(std.testing.allocator);
    defer upper_map.deinit();

    const z = 'z';
    expect(letter.isLetter(z));
    expect(!upper.isUpper(z));
    // No lazy init, no 'try' here.
    const uz = upper_map.toUpper(z);
    expect(upper.isUpper(uz));
    expectEqual(uz, 'Z');
}
```

## Source Doc Comments
You can get descriptions for all the public methods in the [src/ziglyph.zig](src/ziglyph.zig) file
doc comments. This structure exposes the same methods as all the components in one place, plus a few
more.
