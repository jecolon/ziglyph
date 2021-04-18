const std = @import("std");
const mem = std.mem;
const unicode = std.unicode;
const Control = @import("../components/autogen/GraphemeBreakProperty/Control.zig");
const Extend = @import("../components/autogen/GraphemeBreakProperty/Extend.zig");
const ExtPic = @import("../components/autogen/emoji-data/ExtendedPictographic.zig");
const Prepend = @import("../components/autogen/GraphemeBreakProperty/Prepend.zig");
const RegionalIndicator = @import("../components/autogen/GraphemeBreakProperty/RegionalIndicator.zig");
const SpacingMark = @import("../components/autogen/GraphemeBreakProperty/SpacingMark.zig");
const HangulMap = @import("../components/autogen/HangulSyllableType/HangulMap.zig");
const Zigchar = @import("../zigchar/Zigchar.zig");

allocator: *mem.Allocator,
bytes: []u8,
chars: []zigchar,
code_points: []u21,

const Self = @This();
pub fn init(allocator: *mem.Allocator, str: []const u8) !Self {
    var control = Control.init(allocator);
    defer control.deinit();
    var extend = Extend.init(allocator);
    defer extend.deinit();
    var extpic = ExtendedPictographic.init(allocator);
    defer extpic.deinit();
    var prepend = Prepend.init(allocator);
    defer prepend.deinit();
    var regional = RegionalIndicator.init(allocator);
    defer regional.deinit();
    var spacing = SpacingMark.init(allocator);
    defer spacing.deinit();
    var han_map = HangulMap.init(allocator);
    defer han_map.deinit();

    // Gather code points.
    var code_points = std.ArrayList(u21).init(allocator);
    defer code_points.deinit();
    var iter = (try unicode.Utf8View.init(str)).iterator();
    while (try iter.nextCodePoint()) |cp| {
        try code_points.append(cp);
    }

    return Self{
        .allocator = allocator,
        .bytes = blk: {
            const b = try allocator.alloc(u8, str.len);
            mem.copy(u8, b, str);
            break :blk b;
        },
        .chars = &[0]Zigchar{},
        .code_points = code_points.toOwnedSlice(),
    };
}

pub fn deinit(self: *Self) void {
    self.allocator.free(self.bytes);
    for (self.chars) |char| {
        char.deinit();
    }
    self.allocator.free(self.chars);
    self.allocator.free(self.code_points);
}
