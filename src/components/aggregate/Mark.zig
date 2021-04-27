const std = @import("std");
const mem = std.mem;

pub const Enclosing = @import("../autogen/DerivedGeneralCategory/EnclosingMark.zig");
pub const Nonspacing = @import("../autogen/DerivedGeneralCategory/NonspacingMark.zig");
pub const Spacing = @import("../autogen/DerivedGeneralCategory/SpacingMark.zig");

const Self = @This();

allocator: *mem.Allocator,
enclosing: Enclosing,
nonspacing: Nonspacing,
spacing: Spacing,

pub fn init(allocator: *mem.Allocator) !Self {
    return Self{
        .allocator = allocator,
        .enclosing = try Enclosing.init(allocator),
        .nonspacing = try Nonspacing.init(allocator),
        .spacing = try Spacing.init(allocator),
    };
}

pub fn deinit(self: *Self) void {
    self.enclosing.deinit();
    self.nonspacing.deinit();
    self.spacing.deinit();
}

/// isMark detects special code points that serve as marks in different alphabets.
pub fn isMark(self: Self, cp: u21) bool {
    return self.spacing.isSpacingMark(cp) or self.nonspacing.isNonspacingMark(cp) or
        self.enclosing.isEnclosingMark(cp);
}

test "isMark" {
    var z = try init(std.testing.allocator);
    defer z.deinit();

    std.testing.expect(z.isMark('\u{20E4}'));
    std.testing.expect(!z.isMark('='));
}
