const std = @import("std");
const mem = std.mem;

const Context = @import("../../Context.zig");

const Self = @This();

context: *Context,

pub fn new(ctx: *Context) Self {
    return Self{ .context = ctx };
}

/// isMark detects special code points that serve as marks in different alphabets.
pub fn isMark(self: Self, cp: u21) !bool {
    const enclosing = try self.context.getEnclosing();
    const nonspacing = try self.context.getNonspacing();
    const spacing = try self.context.getSpacing();

    return spacing.isSpacingMark(cp) or nonspacing.isNonspacingMark(cp) or enclosing.isEnclosingMark(cp);
}

const expect = std.testing.expect;

test "Component isMark" {
    var ctx = Context.init(std.testing.allocator);
    defer ctx.deinit();

    var mark = new(&ctx);

    expect(try mark.isMark('\u{20E4}'));
    expect(!try mark.isMark('='));
}
