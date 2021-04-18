const std = @import("std");
const mem = std.mem;
const unicode = std.unicode;

allocator: *mem.Allocator,
bytes: []const u8,
code_points: []const u21,

const Self = @This();
pub fn fromStr(allocator: *mem.Allocator, str: []const u8) !Self {
    // Passed-in str can't be freed, so we must copy it.
    const b = try allocator.alloc(u8, str.len);
    mem.copy(u8, b, str);
    return try fromBytes(allocator, b);
}

/// Caller must pass in owned bytes, and must not free them.
pub fn fromBytes(allocator: *mem.Allocator, bytes: []const u8) !Self {
    return Self{
        .allocator = allocator,
        .bytes = bytes,
        .code_points = blk2: {
            var iter = (try unicode.Utf8View.init(bytes)).iterator();
            var buf = std.ArrayList(u21).init(allocator);
            defer buf.deinit();
            while (iter.nextCodePoint()) |cp| {
                try buf.append(cp);
            }
            break :blk2 buf.toOwnedSlice();
        },
    };
}

pub fn fromCodePoints(allocator: *mem.Allocator, code_points: []const u21) !Self {
    return Self{
        .allocator = allocator,
        .bytes = blk: {
            var buf = std.ArrayList(u8).init(allocator);
            defer buf.deinit();
            var b: [4]u8 = undefined;
            for (code_points) |cp| {
                const len = try unicode.utf8Encode(cp, &b);
                try buf.appendSlice(b[0..len]);
            }
            break :blk buf.toOwnedSlice();
        },
        .code_points = blk2: {
            var buf = try allocator.alloc(u21, code_points.len);
            mem.copy(u21, buf, code_points);
            break :blk2 buf;
        },
    };
}

pub fn deinit(self: *Self) void {
    self.allocator.free(self.bytes);
    self.allocator.free(self.code_points);
}
