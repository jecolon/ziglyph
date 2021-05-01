const std = @import("std");
const mem = std.mem;

const Context = @import("../../context.zig").Context;
pub const Enclosing = @import("../../context.zig").Enclosing;
pub const Nonspacing = @import("../../context.zig").Nonspacing;
pub const Spacing = @import("../../context.zig").Spacing;

const Self = @This();

enclosing: *Enclosing,
nonspacing: *Nonspacing,
spacing: *Spacing,

pub fn new(ctx: anytype) Self {
    return Self{
        .enclosing = &ctx.enclosing,
        .nonspacing = &ctx.nonspacing,
        .spacing = &ctx.spacing,
    };
}

/// isMark detects special code points that serve as marks in different alphabets.
pub fn isMark(self: Self, cp: u21) bool {
    return self.spacing.isSpacingMark(cp) or self.nonspacing.isNonspacingMark(cp) or self.enclosing.isEnclosingMark(cp);
}

const expect = std.testing.expect;

test "Component isMark" {
    var ctx = try Context(.mark).init(std.testing.allocator);
    defer ctx.deinit();

    var mark = new(&ctx);

    expect(mark.isMark('\u{20E4}'));
    expect(!mark.isMark('='));
}
