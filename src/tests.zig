test "Ziglyph" {
    _ = @import("Ziglyph.zig");
}

test "Normalizer" {
    _ = @import("components.zig").Normalizer;
}

test "Grapheme" {
    _ = @import("components.zig").GraphemeIterator;
}

test "Components" {
    _ = @import("components.zig").Letter;
    _ = @import("components.zig").Mark;
    _ = @import("components.zig").Number;
    _ = @import("components.zig").Punct;
    _ = @import("components.zig").Symbol;
}

test "Zigstr" {
    _ = @import("components.zig").Zigstr;
}

test "Collator" {
    _ = @import("components.zig").Collator;
}

test "Width" {
    _ = @import("components.zig").Width;
}
