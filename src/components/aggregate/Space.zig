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
pub fn isSpace(self: Self, cp: u21) !bool {
    const space = try self.context.getSpace();
    return space.isSpaceSeparator(cp);
}

/// isWhiteSpace checks for spaces.
pub fn isWhiteSpace(self: Self, cp: u21) !bool {
    const whitespace = try self.context.getWhiteSpace();
    return whitespace.isWhiteSpace(cp);
}

/// isAsciiWhiteSpace detects ASCII only whitespace.
pub fn isAsciiWhiteSpace(cp: u21) bool {
    return if (cp < 128) ascii.isSpace(@intCast(u8, cp)) else false;
}

const expect = std.testing.expect;

test "Component isSpace" {
    var ctx = Context.init(std.testing.allocator);
    defer ctx.deinit();

    var space = new(&ctx);

    expect(try space.isSpace(' '));
    expect(!try space.isSpace('\t'));
    expect(!try space.isSpace('\u{0003}'));
}

test "Component isWhiteSpace" {
    var ctx = Context.init(std.testing.allocator);
    defer ctx.deinit();

    var space = new(&ctx);

    expect(try space.isWhiteSpace(' '));
    expect(try space.isWhiteSpace('\t'));
    expect(!try space.isWhiteSpace('\u{0003}'));
}

test "Component isAsciiWhiteSpace" {
    expect(isAsciiWhiteSpace(' '));
    expect(isAsciiWhiteSpace('\t'));
    expect(!isAsciiWhiteSpace('\u{0003}'));
}
