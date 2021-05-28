const std = @import("std");

pub const Enclosing = @import("../../components.zig").Enclosing;
pub const Nonspacing = @import("../../components.zig").Nonspacing;
pub const Spacing = @import("../../components.zig").Spacing;

/// isMark detects special code points that serve as marks in different alphabets.
pub fn isMark(cp: u21) bool {
    return Spacing.isSpacingMark(cp) or Nonspacing.isNonspacingMark(cp) or Enclosing.isEnclosingMark(cp);
}

const expect = std.testing.expect;

test "Component isMark" {
    try expect(isMark('\u{20E4}'));
    try expect(!isMark('='));
}
