//! `mark` contains a function to detect Unicode marks, category (M).

const std = @import("std");

const cats = @import("../autogen/derived_general_category.zig");

/// `isMark` detects any type of Unicode mark (M) code point.
pub fn isMark(cp: u21) bool {
    return cats.isSpacingMark(cp) or
        cats.isNonspacingMark(cp) or
        cats.isEnclosingMark(cp);
}

test "mark isMark" {
    try std.testing.expect(isMark('\u{20E4}'));
    try std.testing.expect(isMark(0x0301));
    try std.testing.expect(!isMark('='));
}
