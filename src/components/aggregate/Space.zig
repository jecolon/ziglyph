const std = @import("std");
const mem = std.mem;
const ascii = @import("../../ascii.zig");

pub const Space = @import("../../components.zig").Space;
pub const WhiteSpace = @import("../../components.zig").WhiteSpace;

const Self = @This();

allocator: *mem.Allocator,
space: *Space,
whitespace: *WhiteSpace,

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
        .space = try Space.init(allocator),
        .whitespace = try WhiteSpace.init(allocator),
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
            self.space.deinit();
            self.whitespace.deinit();

            self.allocator.destroy(s.instance);
            singleton = null;
        }
    }
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
    var space = try init(std.testing.allocator);
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
