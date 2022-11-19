//! `CodePoint` represents a Unicode code point wit hrealted functionality.

const std = @import("std");
const unicode = std.unicode;

bytes: []const u8,
offset: usize,
scalar: u21,

const CodePoint = @This();

/// `end` returns the index of the byte after this code points last byte in the source string.
pub fn end(self: CodePoint) usize {
    return self.offset + self.bytes.len;
}

/// `CodePointIterator` iterates a string one code point at-a-time.
pub const CodePointIterator = struct {
    bytes: []const u8,
    i: usize = 0,

    pub fn next(it: *CodePointIterator) ?CodePoint {
        if (it.i >= it.bytes.len) {
            return null;
        }

        var cp = CodePoint{
            .bytes = undefined,
            .offset = it.i,
            .scalar = undefined,
        };

        const cp_len = unicode.utf8ByteSequenceLength(it.bytes[it.i]) catch unreachable;
        it.i += cp_len;
        cp.bytes = it.bytes[it.i - cp_len .. it.i];

        cp.scalar = switch (cp.bytes.len) {
            1 => @as(u21, cp.bytes[0]),
            2 => unicode.utf8Decode2(cp.bytes) catch unreachable,
            3 => unicode.utf8Decode3(cp.bytes) catch unreachable,
            4 => unicode.utf8Decode4(cp.bytes) catch unreachable,
            else => unreachable,
        };

        return cp;
    }
};

/// `readCodePoint` returns the next code point in the given reader, or null at end-of-stream.
pub fn readCodePoint(reader: anytype) !?u21 {
    var buf: [4]u8 = undefined;

    buf[0] = reader.readByte() catch |err| switch (err) {
        error.EndOfStream => return null,
        else => return err,
    };

    if (buf[0] < 128) return @as(u21, buf[0]);

    const len = try unicode.utf8ByteSequenceLength(buf[0]);
    const read = try reader.read(buf[1..len]);

    if (read < len - 1) return error.InvalidUtf8;

    return switch (len) {
        2 => try unicode.utf8Decode2(buf[0..len]),
        3 => try unicode.utf8Decode3(buf[0..len]),
        4 => try unicode.utf8Decode4(buf[0..len]),
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
