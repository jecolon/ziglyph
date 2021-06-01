test "Ziglyph" {
    _ = @import("Ziglyph.zig");
}

test "Normalizer" {
    _ = @import("components.zig").Normalizer;
}

test "Grapheme" {
    _ = @import("Ziglyph.zig").GraphemeIterator;
}

test "Components" {
    _ = @import("Ziglyph.zig").Letter;
    _ = @import("Ziglyph.zig").Mark;
    _ = @import("Ziglyph.zig").Number;
    _ = @import("Ziglyph.zig").Punct;
    _ = @import("Ziglyph.zig").Symbol;
}

test "Zigstr" {
    _ = @import("Ziglyph.zig").Zigstr;
}

test "Collator" {
    _ = @import("zigstr/Collator.zig");
}

test "Width" {
    _ = @import("components/aggregate/Width.zig");
}
