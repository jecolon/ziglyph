const std = @import("std");
const mem = std.mem;
const ascii = @import("../../ascii.zig");

pub const Enclosing = @import("../autogen/DerivedGeneralCategory/EnclosingMark.zig");
pub const Nonspacing = @import("../autogen/DerivedGeneralCategory/NonspacingMark.zig");
pub const Spacing = @import("../autogen/DerivedGeneralCategory/SpacingMark.zig");

const Self = @This();

allocator: *mem.Allocator,
enclosing: ?Enclosing = null,
nonspacing: ?Nonspacing = null,
spacing: ?Spacing = null,

pub fn init(allocator: *mem.Allocator) !Self {
    return Self{ .allocator = allocator };
}

pub fn deinit(self: *Self) void {
    if (self.enclosing) |*enclosing| enclosing.deinit();
    if (self.nonspacing) |*nonspacing| nonspacing.deinit();
    if (self.spacing) |*spacing| spacing.deinit();
}

/// isMark detects special code points that serve as marks in different alphabets.
pub fn isMark(self: *Self, cp: u21) !bool {
    // Lazy init.
    if (self.spacing == null) self.spacing = try Spacing.init(self.allocator);
    if (self.nonspacing == null) self.nonspacing = try Nonspacing.init(self.allocator);
    if (self.enclosing == null) self.enclosing = try Enclosing.init(self.allocator);

    return self.spacing.?.isSpacingMark(cp) or self.nonspacing.?.isNonspacingMark(cp) or
        self.enclosing.?.isEnclosingMark(cp);
}
