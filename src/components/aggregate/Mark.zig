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
mctx: ?*Context(.mark),

pub fn init(allocator: *mem.Allocator) !Self {
    var mctx = try Context(.mark).init(allocator);

    return Self{
        .enclosing = mctx.enclosing,
        .nonspacing = mctx.nonspacing,
        .spacing = mctx.spacing,
        .mctx = mctx,
    };
}

pub fn deinit(self: *Self) void {
    if (self.mctx) |mctx| mctx.deinit();
}

pub fn initWithContext(ctx: anytype) Self {
    return Self{
        .enclosing = ctx.enclosing,
        .nonspacing = ctx.nonspacing,
        .spacing = ctx.spacing,
        .mctx = null,
    };
}

/// isMark detects special code points that serve as marks in different alphabets.
pub fn isMark(self: Self, cp: u21) bool {
    return self.spacing.isSpacingMark(cp) or self.nonspacing.isNonspacingMark(cp) or self.enclosing.isEnclosingMark(cp);
}

const expect = std.testing.expect;

test "Component isMark" {
    var mark = try init(std.testing.allocator);
    defer mark.deinit();

    expect(mark.isMark('\u{20E4}'));
    expect(!mark.isMark('='));
}
