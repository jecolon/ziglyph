test "Ziglyph" {
    _ = @import("Ziglyph.zig");
}

test "Normalizer" {
    _ = @import("components.zig").Normalizer;
}

test "Segmentation" {
    _ = @import("components.zig").CodePoint;
    _ = @import("components.zig").Grapheme;
    _ = @import("components.zig").Word;
    _ = @import("components.zig").Sentence;
}

test "components" {
    _ = @import("components.zig").Letter;
    _ = @import("components.zig").Mark;
    _ = @import("components.zig").Number;
    _ = @import("components.zig").Punct;
    _ = @import("components.zig").Symbol;
}

test "Collator" {
    _ = @import("components.zig").Collator;
}

test "Width" {
    _ = @import("components.zig").Width;
}

test "READMEs" {
    _ = @import("tests/readme_tests.zig");
}
