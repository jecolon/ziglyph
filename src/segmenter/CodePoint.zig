//! `CodePoint` represents a Unicode code point by its code, length, and offset in the source bytes.

const std = @import("std");

code: u21,
len: u3,
offset: usize,

const CodePoint = @This();

/// `CodePointIterator` iterates a string one `CodePoint` at-a-time.
pub const CodePointIterator = struct {
    bytes: []const u8,
    i: usize = 0,

    pub fn next(self: *CodePointIterator) ?CodePoint {
        if (self.i >= self.bytes.len) return null;

        if (self.bytes[self.i] < 128) {
            // ASCII fast path
            var cp = CodePoint{
                .code = self.bytes[self.i],
                .len = 1,
                .offset = self.i,
            };

            self.i += 1;

            return cp;
        }

        var cp = CodePoint{
            .code = undefined,
            .len = blk: {
                break :blk switch (self.bytes[self.i]) {
                    0b0000_0000...0b0111_1111 => 1,
                    0b1100_0000...0b1101_1111 => 2,
                    0b1110_0000...0b1110_1111 => 3,
                    0b1111_0000...0b1111_0111 => 4,
                    else => unreachable,
                };
            },
            .offset = self.i,
        };

        self.i += cp.len;
        const cp_bytes = self.bytes[self.i - cp.len .. self.i];

        cp.code = switch (cp.len) {
            2 => (@as(u21, (cp_bytes[0] & 0b00011111)) << 6) | (cp_bytes[1] & 0b00111111),

            3 => (((@as(u21, (cp_bytes[0] & 0b00001111)) << 6) |
                (cp_bytes[1] & 0b00111111)) << 6) |
                (cp_bytes[2] & 0b00111111),

            4 => (((((@as(u21, (cp_bytes[0] & 0b00000111)) << 6) |
                (cp_bytes[1] & 0b00111111)) << 6) |
                (cp_bytes[2] & 0b00111111)) << 6) |
                (cp_bytes[3] & 0b00111111),

            else => unreachable,
        };

        return cp;
    }

    pub fn peek(self: *CodePointIterator) ?CodePoint {
        const saved_i = self.i;
        defer self.i = saved_i;
        return self.next();
    }
};

test "CodePointIterator peek" {
    var iter = CodePointIterator{ .bytes = "Hi" };

    try std.testing.expectEqual(@as(u21, 'H'), iter.next().?.code);
    try std.testing.expectEqual(@as(u21, 'i'), iter.peek().?.code);
    try std.testing.expectEqual(@as(u21, 'i'), iter.next().?.code);
    try std.testing.expectEqual(@as(?CodePoint, null), iter.peek());
    try std.testing.expectEqual(@as(?CodePoint, null), iter.next());
}

/// `readCodePoint` returns the next code point code as a `u21` in the given reader, or null at end-of-input.
pub fn readCodePoint(reader: anytype) !?u21 {
    var buf: [4]u8 = undefined;

    buf[0] = reader.readByte() catch |err| switch (err) {
        error.EndOfStream => return null,
        else => return err,
    };

    if (buf[0] < 128) return @as(u21, buf[0]);

    const len: u3 = switch (buf[0]) {
        0b1100_0000...0b1101_1111 => 2,
        0b1110_0000...0b1110_1111 => 3,
        0b1111_0000...0b1111_0111 => 4,
        else => return error.InvalidUtf8,
    };

    const read = try reader.read(buf[1..len]);

    if (read < len - 1) return error.InvalidUtf8;

    return switch (len) {
        2 => (@as(u21, (buf[0] & 0b00011111)) << 6) | (buf[1] & 0b00111111),

        3 => (((@as(u21, (buf[0] & 0b00001111)) << 6) |
            (buf[1] & 0b00111111)) << 6) |
            (buf[2] & 0b00111111),

        4 => (((((@as(u21, (buf[0] & 0b00000111)) << 6) |
            (buf[1] & 0b00111111)) << 6) |
            (buf[2] & 0b00111111)) << 6) |
            (buf[3] & 0b00111111),

        else => unreachable,
    };
}

test "readCodePoint" {
    var buf = "abé😹".*;
    var fis = std.io.fixedBufferStream(&buf);
    const reader = fis.reader();

    try std.testing.expectEqual(@as(u21, 'a'), (try readCodePoint(reader)).?);
    try std.testing.expectEqual(@as(u21, 'b'), (try readCodePoint(reader)).?);
    try std.testing.expectEqual(@as(u21, 'é'), (try readCodePoint(reader)).?);
    try std.testing.expectEqual(@as(u21, '😹'), (try readCodePoint(reader)).?);
    try std.testing.expectEqual(@as(?u21, null), try readCodePoint(reader));
}
