const std = @import("std");
const mem = std.mem;
const ascii = @import("../../ascii.zig");

const Context = @import("../../Context.zig");

const Self = @This();

context: *Context,

pub fn new(ctx: *Context) Self {
    return Self{ .context = ctx };
}

/// isSpace detects code points that are Unicode space separators.
pub fn isSpace(self: Self, cp: u21) bool {
    return self.context.space.isSpaceSeparator(cp);
}

/// isWhiteSpace checks for spaces.
pub fn isWhiteSpace(self: Self, cp: u21) bool {
    return self.context.whitespace.isWhiteSpace(cp);
}

/// isAsciiWhiteSpace detects ASCII only whitespace.
pub fn isAsciiWhiteSpace(cp: u21) bool {
    return if (cp < 128) ascii.isSpace(@intCast(u8, cp)) else false;
}

const expect = std.testing.expect;

test "Component isSpace" {
    var ctx = try Context.init(std.testing.allocator);
    defer ctx.deinit();

    var space = new(&ctx);

    expect(space.isSpace(' '));
    expect(!space.isSpace('\t'));
    expect(!space.isSpace('\u{0003}'));
}

test "Component isWhiteSpace" {
    var ctx = try Context.init(std.testing.allocator);
    defer ctx.deinit();

    var space = new(&ctx);

    expect(space.isWhiteSpace(' '));
    expect(space.isWhiteSpace('\t'));
    expect(!space.isWhiteSpace('\u{0003}'));
}

test "Component isAsciiWhiteSpace" {
    expect(isAsciiWhiteSpace(' '));
    expect(isAsciiWhiteSpace('\t'));
    expect(!isAsciiWhiteSpace('\u{0003}'));
}
