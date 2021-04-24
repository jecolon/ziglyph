test "Ziglyph" {
    _ = @import("ziglyph.zig");
}

test "Decomp Norm" {
    _ = @import("ziglyph.zig").DecomposeMap;
}

test "Grapheme" {
    _ = @import("ziglyph.zig").GraphemeIterator;
}

test "Components" {
    _ = @import("ziglyph.zig").Letter;
    _ = @import("ziglyph.zig").Mark;
    _ = @import("ziglyph.zig").Number;
    _ = @import("ziglyph.zig").Punct;
    _ = @import("ziglyph.zig").Space;
    _ = @import("ziglyph.zig").Symbol;
}

test "Zigstr" {
    _ = @import("ziglyph.zig").Zigstr;
}
