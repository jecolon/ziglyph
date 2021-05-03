const std = @import("std");
const mem = std.mem;
const ascii = @import("../../ascii.zig");

const Context = @import("../../context.zig").Context;
pub const Space = @import("../../context.zig").Space;
pub const WhiteSpace = @import("../../context.zig").WhiteSpace;

const Self = @This();

space: *Space,
whitespace: *WhiteSpace,
sctx: ?*Context(.space),

pub fn init(allocator: *mem.Allocator) !Self {
    var sctx = try Context(.space).init(allocator);

    return Self{
        .space = sctx.space,
        .whitespace = sctx.whitespace,
        .sctx = sctx,
    };
}

pub fn deinit(self: *Self) void {
    if (self.sctx) |sctx| sctx.deinit();
}

pub fn initWithContext(ctx: anytype) Self {
    return Self{
        .space = ctx.space,
        .whitespace = ctx.whitespace,
        .sctx = null,
    };
}

/// isSpace detects code points that are Unicode space separators.
pub fn isSpace(self: Self, cp: u21) bool {
    return self.space.isSpaceSeparator(cp);
}

/// isWhiteSpace checks for spaces.
pub fn isWhiteSpace(self: Self, cp: u21) bool {
    return self.whitespace.isWhiteSpace(cp);
}

/// isAsciiWhiteSpace detects ASCII only whitespace.
pub fn isAsciiWhiteSpace(cp: u21) bool {
    return if (cp < 128) ascii.isSpace(@intCast(u8, cp)) else false;
}

const expect = std.testing.expect;

test "Component isSpace" {
    var space = try init(std.testing.allocator);
    defer space.deinit();

    expect(space.isSpace(' '));
    expect(!space.isSpace('\t'));
    expect(!space.isSpace('\u{0003}'));
}

test "Component isWhiteSpace" {
    var ctx = try Context(.space).init(std.testing.allocator);
    defer ctx.deinit();

    var space = initWithContext(ctx);
    defer space.deinit();

    expect(space.isWhiteSpace(' '));
    expect(space.isWhiteSpace('\t'));
    expect(!space.isWhiteSpace('\u{0003}'));
}

test "Component isAsciiWhiteSpace" {
    expect(isAsciiWhiteSpace(' '));
    expect(isAsciiWhiteSpace('\t'));
    expect(!isAsciiWhiteSpace('\u{0003}'));
}
