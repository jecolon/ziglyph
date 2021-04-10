const std = @import("std");
const expect = std.testing.expect;
const expectEqual = std.testing.expectEqual;
const expectEqualSlices = std.testing.expectEqualSlices;

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

// Import the struct.
const Letter = @import("ziglyph.zig").Letter;
const Punct = @import("ziglyph.zig").Punct;

test "Ziglyph struct" {
    var letter = try Letter.init(std.testing.allocator);
    defer letter.deinit();
    var punct = try Punct.init(std.testing.allocator);
    defer punct.deinit();

    const z = 'z';
    // Aggregate structs also use lezy init.
    expect(try letter.isLetter(z));
    expect(!try letter.isUpper(z));
    expect(!try punct.isPunct(z));
    expect(try punct.isPunct('!'));
    const uz = try letter.toUpper(z);
    expect(try letter.isUpper(uz));
    expectEqual(uz, 'Z');
}

// Import the components.
const Lower = @import("ziglyph.zig").Letter.Lower;
const Upper = @import("ziglyph.zig").Letter.Upper;
// Case mapping.
const UpperMap = @import("ziglyph.zig").Letter.UpperMap;

test "Component structs" {
    var lower = try Lower.init(std.testing.allocator);
    defer lower.deinit();
    var upper = try Upper.init(std.testing.allocator);
    defer upper.deinit();
    var upper_map = try UpperMap.init(std.testing.allocator);
    defer upper_map.deinit();

    const z = 'z';
    // No lazy init, no 'try' here.
    expect(lower.isLowercaseLetter(z));
    expect(!upper.isUppercaseLetter(z));
    const uz = upper_map.toUpper(z);
    expect(upper.isUppercaseLetter(uz));
    expectEqual(uz, 'Z');
}

// Import struct.
const DecomposeMap = @import("ziglyph.zig").DecomposeMap;

test "decomposeCodePoint" {
    var decomp_map = try DecomposeMap.init(std.testing.allocator);
    defer decomp_map.deinit();

    var result = decomp_map.decomposeCodePoint('\u{00E9}');
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
