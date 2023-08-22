test {
    _ = @import("normalizer/Normalizer.zig");
    _ = @import("collator/Collator.zig");

    _ = @import("segmenter/CodePoint.zig");
    _ = @import("segmenter/Grapheme.zig");
    _ = @import("segmenter/Sentence.zig");
    _ = @import("segmenter/Word.zig");

    _ = @import("category/letter.zig");
    _ = @import("category/mark.zig");
    _ = @import("category/number.zig");
    _ = @import("category/punct.zig");

    _ = @import("ziglyph.zig");
    _ = @import("display_width.zig");

    _ = @import("readme_tests.zig");
}
