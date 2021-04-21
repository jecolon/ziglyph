const std = @import("std");
const mem = std.mem;
const ascii = @import("../../ascii.zig");

pub const WhiteSpace = @import("../autogen/PropList/WhiteSpace.zig");
pub const Space = @import("../autogen/DerivedGeneralCategory/SpaceSeparator.zig");

const Self = @This();

allocator: *mem.Allocator,
space: Space,
whitespace: WhiteSpace,

pub fn init(allocator: *mem.Allocator) !Self {
    return Self{
        .allocator = allocator,
        .space = try Space.init(allocator),
        .whitespace = try WhiteSpace.init(allocator),
    };
}

pub fn deinit(self: *Self) void {
    self.space.deinit();
    self.whitespace.deinit();
}

/// isSpace detects code points that are Unicode space separators.
pub fn isSpace(self: *Self, cp: u21) bool {
    return self.space.isSpaceSeparator(cp);
}

/// isWhiteSpace checks for spaces.
pub fn isWhiteSpace(self: *Self, cp: u21) bool {
    return self.whitespace.isWhiteSpace(cp);
}

/// isAsciiWhiteSpace detects ASCII only whitespace.
pub fn isAsciiWhiteSpace(self: Self, cp: u21) bool {
    return if (cp < 128) ascii.isSpace(@intCast(u8, cp)) else false;
}
