const std = @import("std");
const mem = std.mem;
const ascii = @import("../../ascii.zig");

pub const WhiteSpace = @import("../autogen/PropList/WhiteSpace.zig");
pub const Space = @import("../autogen/DerivedGeneralCategory/SpaceSeparator.zig");

const Self = @This();

allocator: *mem.Allocator,
space: ?Space = null,
whitespace: ?WhiteSpace = null,

pub fn init(allocator: *mem.Allocator) !Self {
    return Self{ .allocator = allocator };
}

pub fn deinit(self: *Self) void {
    if (self.space) |*space| space.deinit();
    if (self.whitespace) |*whitespace| whitespace.deinit();
}

/// isSpace detects code points that are Unicode space separators.
pub fn isSpace(self: *Self, cp: u21) !bool {
    // Lazy init.
    if (self.space == null) self.space = try Space.init(self.allocator);
    return self.space.?.isSpaceSeparator(cp);
}

/// isWhiteSpace checks for spaces.
pub fn isWhiteSpace(self: *Self, cp: u21) !bool {
    // Lazy init.
    if (self.whitespace == null) self.whitespace = try WhiteSpace.init(self.allocator);
    return self.whitespace.?.isWhiteSpace(cp);
}

/// isAsciiWhiteSpace detects ASCII only whitespace.
pub fn isAsciiWhiteSpace(self: Self, cp: u21) bool {
    return if (cp < 128) ascii.isSpace(@intCast(u8, cp)) else false;
}
