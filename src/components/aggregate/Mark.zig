const std = @import("std");
const mem = std.mem;

pub const Enclosing = @import("../../components.zig").Enclosing;
pub const Nonspacing = @import("../../components.zig").Nonspacing;
pub const Spacing = @import("../../components.zig").Spacing;

const Self = @This();

allocator: *mem.Allocator,
enclosing: Enclosing,
nonspacing: Nonspacing,
spacing: Spacing,

const Singleton = struct {
    instance: *Self,
    ref_count: usize,
};

var singleton: ?Singleton = null;

pub fn init(allocator: *mem.Allocator) !*Self {
    if (singleton) |*s| {
        s.ref_count += 1;
        return s.instance;
    }

    var instance = try allocator.create(Self);

    instance.* = Self{
        .allocator = allocator,
        .enclosing = Enclosing{},
        .nonspacing = Nonspacing{},
        .spacing = Spacing{},
    };

    singleton = Singleton{
        .instance = instance,
        .ref_count = 1,
    };

    return instance;
}

pub fn deinit(self: *Self) void {
    if (singleton) |*s| {
        s.ref_count -= 1;
        if (s.ref_count == 0) {
            self.allocator.destroy(s.instance);
            singleton = null;
        }
    }
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
