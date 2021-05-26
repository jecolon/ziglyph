test "Ziglyph" {
    _ = @import("ziglyph.zig");
}

test "Normalizer" {
    _ = @import("components.zig").Normalizer;
}

test "Grapheme" {
    _ = @import("ziglyph.zig").GraphemeIterator;
}

test "Components" {
    _ = @import("ziglyph.zig").Letter;
    _ = @import("ziglyph.zig").Mark;
    _ = @import("ziglyph.zig").Number;
    _ = @import("ziglyph.zig").Punct;
    _ = @import("ziglyph.zig").Symbol;
}

test "Zigstr" {
    _ = @import("ziglyph.zig").Zigstr;
}

test "Collator" {
    _ = @import("zigstr/Collator.zig");
}

test "Width" {
    _ = @import("components/aggregate/Width.zig");
}
