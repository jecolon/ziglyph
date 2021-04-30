const std = @import("std");
const mem = std.mem;

const Context = @import("../../Context.zig");

const Self = @This();

context: *Context,

pub fn new(ctx: *Context) Self {
    return Self{ .context = ctx };
}

/// isMark detects special code points that serve as marks in different alphabets.
pub fn isMark(self: Self, cp: u21) bool {
    return self.context.spacing.isSpacingMark(cp) or self.context.nonspacing.isNonspacingMark(cp) or self.context.enclosing.isEnclosingMark(cp);
}

const expect = std.testing.expect;

test "Component isMark" {
    var ctx = try Context.init(std.testing.allocator);
    defer ctx.deinit();

    var mark = new(&ctx);

    expect(mark.isMark('\u{20E4}'));
    expect(!mark.isMark('='));
}
