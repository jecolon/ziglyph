//! `Grapheme` represents a Unicode grapheme cluster with related functionality.

const std = @import("std");
const debug = std.debug;
const mem = std.mem;
const testing = std.testing;
const unicode = std.unicode;

const CodePoint = @import("CodePoint.zig");
const CodePointIterator = CodePoint.CodePointIterator;
const readCodePoint = CodePoint.readCodePoint;
const emoji = @import("../ziglyph.zig").emoji_data;
const gbp = @import("../ziglyph.zig").grapheme_break_property;

pub const Grapheme = @This();

bytes: []const u8,
offset: usize,

/// `eql` comparse `str` with the bytes of this grapheme cluster for equality.
pub fn eql(self: Grapheme, str: []const u8) bool {
    return mem.eql(u8, self.bytes, str);
}

/// `GraphemeIterator` iterates a sting one grapheme cluster at-a-time.
pub const GraphemeIterator = struct {
    buf: [2]?CodePoint = [_]?CodePoint{ null, null },
    cp_iter: CodePointIterator,

    const Self = @This();

    pub fn init(str: []const u8) !Self {
        if (!unicode.utf8ValidateSlice(str)) return error.InvalidUtf8;
        var self = Self{ .cp_iter = CodePointIterator{ .bytes = str } };
        self.buf[1] = self.cp_iter.next();

        return self;
    }

    pub fn next(self: *Self) ?Grapheme {
        const cp = self.advance() orelse return null;
        const start = cp.offset;
        var end = cp.end();

        if (cp.scalar == '\x0d') {
            if (self.peek()) |pcp| {
                if (pcp.scalar == '\x0a') {
                    end = pcp.end();
                    _ = self.advance();
                }
            }

            return Grapheme{
                .bytes = self.cp_iter.bytes[start..end],
                .offset = start,
            };
        }

        if (cp.scalar == '\x0a' or gbp.isControl(cp.scalar)) {
            return Grapheme{
                .bytes = self.cp_iter.bytes[start..end],
                .offset = start,
            };
        }

        if (gbp.isPrepend(cp.scalar)) {
            if (self.peek()) |pcp| {
                if (!cpIsBreaker(pcp.scalar)) {
                    end = pcp.end();
                    _ = self.advance();
                }
            }
        }

        if (gbp.isRegionalIndicator(cp.scalar)) {
            if (self.peek()) |pcp| {
                if (gbp.isRegionalIndicator(pcp.scalar)) {
                    end = pcp.end();
                    _ = self.advance();
                }
            }
        }

        if (gbp.isL(cp.scalar)) {
            if (self.peek()) |pcp| {
                if (gbp.isL(pcp.scalar) or gbp.isV(pcp.scalar) or gbp.isLv(pcp.scalar) or gbp.isLvt(pcp.scalar)) {
                    end = pcp.end();
                    _ = self.advance();
                }
            }
        }

        if (gbp.isLv(cp.scalar) or gbp.isV(cp.scalar)) {
            if (self.peek()) |pcp| {
                if (gbp.isV(pcp.scalar) or gbp.isT(pcp.scalar)) {
                    end = pcp.end();
                    _ = self.advance();
                }
            }
        }

        if (gbp.isLvt(cp.scalar) or gbp.isT(cp.scalar)) {
            if (self.peek()) |pcp| {
                if (gbp.isT(pcp.scalar)) {
                    end = pcp.end();
                    _ = self.advance();
                }
            }
        }

        const after_emoji = emoji.isExtendedPictographic(cp.scalar);
        var after_zwj = false;

        while (self.peek()) |pcp| {
            if (cpIsIgnorable(pcp.scalar) or (after_emoji and after_zwj and emoji.isExtendedPictographic(pcp.scalar))) {
                end = pcp.end();
                _ = self.advance();
                if (pcp.scalar == '\u{200d}') after_zwj = true;
            } else {
                break;
            }
        }

        return Grapheme{
            .bytes = self.cp_iter.bytes[start..end],
            .offset = start,
        };
    }

    fn advance(self: *Self) ?CodePoint {
        self.buf[0] = self.buf[1];
        self.buf[1] = self.cp_iter.next();

        return self.buf[0];
    }

    fn peek(self: Self) ?CodePoint {
        return self.buf[1];
    }
};

/// `StreamingGraphemeIterator` iterates a `std.io.Reader` one grapheme cluster at-a-time.
/// Note that, given the steaming context, the `offset` field of the returned `Grapheme`s is always 0.
pub fn StreamingGraphemeIterator(comptime T: type) type {
    return struct {
        allocator: std.mem.Allocator,
        buf: [2]?u21 = [_]?u21{ null, null },
        reader: T,

        const Self = @This();

        pub fn init(allocator: std.mem.Allocator, reader: anytype) !Self {
            var self = Self{ .allocator = allocator, .reader = reader };
            self.buf[1] = try readCodePoint(self.reader);

            return self;
        }

        pub fn next(self: *Self) !?Grapheme {
            const cp = (try self.advance()) orelse return null;

            var all_bytes = std.ArrayList(u8).init(self.allocator);
            try encode_and_append(cp, &all_bytes);

            if (cp == '\x0d') {
                if (self.peek()) |pcp| {
                    if (pcp == '\x0a') {
                        try encode_and_append(pcp, &all_bytes);
                        _ = self.advance() catch unreachable;
                    }
                }

                return Grapheme{
                    .bytes = all_bytes.toOwnedSlice(),
                    .offset = 0,
                };
            }

            if (cp == '\x0a' or gbp.isControl(cp)) {
                return Grapheme{
                    .bytes = all_bytes.toOwnedSlice(),
                    .offset = 0,
                };
            }

            if (gbp.isPrepend(cp)) {
                if (self.peek()) |pcp| {
                    if (!cpIsBreaker(pcp)) {
                        try encode_and_append(pcp, &all_bytes);
                        _ = self.advance() catch unreachable;
                    }
                }
            }

            if (gbp.isRegionalIndicator(cp)) {
                if (self.peek()) |pcp| {
                    if (gbp.isRegionalIndicator(pcp)) {
                        try encode_and_append(pcp, &all_bytes);
                        _ = self.advance() catch unreachable;
                    }
                }
            }

            if (gbp.isL(cp)) {
                if (self.peek()) |pcp| {
                    if (gbp.isL(pcp) or gbp.isV(pcp) or gbp.isLv(pcp) or gbp.isLvt(pcp)) {
                        try encode_and_append(pcp, &all_bytes);
                        _ = self.advance() catch unreachable;
                    }
                }
            }

            if (gbp.isLv(cp) or gbp.isV(cp)) {
                if (self.peek()) |pcp| {
                    if (gbp.isV(pcp) or gbp.isT(pcp)) {
                        try encode_and_append(pcp, &all_bytes);
                        _ = self.advance() catch unreachable;
                    }
                }
            }

            if (gbp.isLvt(cp) or gbp.isT(cp)) {
                if (self.peek()) |pcp| {
                    if (gbp.isT(pcp)) {
                        try encode_and_append(pcp, &all_bytes);
                        _ = self.advance() catch unreachable;
                    }
                }
            }

            const after_emoji = emoji.isExtendedPictographic(cp);
            var after_zwj = false;

            while (self.peek()) |pcp| {
                if (cpIsIgnorable(pcp) or (after_emoji and after_zwj and emoji.isExtendedPictographic(pcp))) {
                    try encode_and_append(pcp, &all_bytes);
                    _ = self.advance() catch unreachable;
                    if (pcp == '\u{200d}') after_zwj = true;
                } else {
                    break;
                }
            }

            return Grapheme{
                .bytes = all_bytes.toOwnedSlice(),
                .offset = 0,
            };
        }

        fn advance(self: *Self) !?u21 {
            self.buf[0] = self.buf[1];
            self.buf[1] = try readCodePoint(self.reader);

            return self.buf[0];
        }

        fn peek(self: Self) ?u21 {
            return self.buf[1];
        }

        fn encode_and_append(cp: u21, list: *std.ArrayList(u8)) !void {
            var tmp: [4]u8 = undefined;
            const len = try unicode.utf8Encode(cp, &tmp);
            try list.appendSlice(tmp[0..len]);
        }
    };
}

// Predicates
const CodePointPredicate = fn (u21) bool;

fn cpIsBreaker(cp: u21) bool {
    return cp == '\x0d' or cp == '\x0a' or gbp.isControl(cp);
}

fn cpIsIgnorable(cp: u21) bool {
    return gbp.isExtend(cp) or gbp.isSpacingmark(cp) or cp == '\u{200d}';
}

test "Segmentation GraphemeIterator" {
    var path_buf: [1024]u8 = undefined;
    var path = try std.fs.cwd().realpath(".", &path_buf);
    // Check if testing in this library path.
    if (!mem.endsWith(u8, path, "ziglyph")) return;

    var allocator = std.testing.allocator;
    var file = try std.fs.cwd().openFile("src/data/ucd/GraphemeBreakTest.txt", .{});
    defer file.close();
    var buf_reader = std.io.bufferedReader(file.reader());
    var input_stream = buf_reader.reader();

    var buf: [4096]u8 = undefined;
    var line_no: usize = 1;

    while (try input_stream.readUntilDelimiterOrEof(&buf, '\n')) |raw| : (line_no += 1) {
        // Skip comments or empty lines.
        if (raw.len == 0 or raw[0] == '#' or raw[0] == '@') continue;

        // Clean up.
        var line = mem.trimLeft(u8, raw, "÷ ");
        if (mem.indexOf(u8, line, " ÷\t#")) |octo| {
            line = line[0..octo];
        }
        //debug.print("\nline {}: {s}\n", .{ line_no, line });

        // Iterate over fields.
        var want = std.ArrayList(Grapheme).init(allocator);
        defer {
            for (want.items) |snt| {
                allocator.free(snt.bytes);
            }
            want.deinit();
        }

        var all_bytes = std.ArrayList(u8).init(allocator);
        defer all_bytes.deinit();

        var sentences = mem.split(u8, line, " ÷ ");
        var bytes_index: usize = 0;

        while (sentences.next()) |field| {
            var code_points = mem.split(u8, field, " ");
            var cp_buf: [4]u8 = undefined;
            var cp_index: usize = 0;
            var first: u21 = undefined;
            var cp_bytes = std.ArrayList(u8).init(allocator);
            defer cp_bytes.deinit();

            while (code_points.next()) |code_point| {
                if (mem.eql(u8, code_point, "×")) continue;
                const cp: u21 = try std.fmt.parseInt(u21, code_point, 16);
                if (cp_index == 0) first = cp;
                const len = try unicode.utf8Encode(cp, &cp_buf);
                try all_bytes.appendSlice(cp_buf[0..len]);
                try cp_bytes.appendSlice(cp_buf[0..len]);
                cp_index += len;
            }

            try want.append(Grapheme{
                .bytes = cp_bytes.toOwnedSlice(),
                .offset = bytes_index,
            });

            bytes_index += cp_index;
        }

        //debug.print("\nline {}: {s}\n", .{ line_no, all_bytes.items });
        var iter = try GraphemeIterator.init(all_bytes.items);

        // Chaeck.
        for (want.items) |w| {
            const g = (iter.next()).?;
            //debug.print("\n", .{});
            //for (w.bytes) |b| {
            //    debug.print("line {}: w:({x})\n", .{ line_no, b });
            //}
            //for (g.bytes) |b| {
            //    debug.print("line {}: g:({x})\n", .{ line_no, b });
            //}
            //debug.print("line {}: w:({s}), g:({s})\n", .{ line_no, w.bytes, g.bytes });
            try testing.expectEqualStrings(w.bytes, g.bytes);
            try testing.expectEqual(w.offset, g.offset);
        }
    }
}

test "Segmentation comptime GraphemeIterator" {
    const want = [_][]const u8{ "H", "é", "l", "l", "o" };

    comptime {
        var ct_iter = try GraphemeIterator.init("Héllo");
        var i = 0;
        while (ct_iter.next()) |grapheme| : (i += 1) {
            try testing.expect(grapheme.eql(want[i]));
        }
    }
}

test "Segmentation StreamingGraphemeIterator" {
    var path_buf: [1024]u8 = undefined;
    var path = try std.fs.cwd().realpath(".", &path_buf);
    // Check if testing in this library path.
    if (!mem.endsWith(u8, path, "ziglyph")) return;

    var allocator = std.testing.allocator;
    var file = try std.fs.cwd().openFile("src/data/ucd/GraphemeBreakTest.txt", .{});
    defer file.close();
    var buf_reader = std.io.bufferedReader(file.reader());
    var input_stream = buf_reader.reader();

    var buf: [4096]u8 = undefined;
    var line_no: usize = 1;

    while (try input_stream.readUntilDelimiterOrEof(&buf, '\n')) |raw| : (line_no += 1) {
        // Skip comments or empty lines.
        if (raw.len == 0 or raw[0] == '#' or raw[0] == '@') continue;

        // Clean up.
        var line = mem.trimLeft(u8, raw, "÷ ");
        if (mem.indexOf(u8, line, " ÷\t#")) |octo| {
            line = line[0..octo];
        }
        //debug.print("\nline {}: {s}\n", .{ line_no, line });

        // Iterate over fields.
        var want = std.ArrayList(Grapheme).init(allocator);
        defer {
            for (want.items) |snt| {
                allocator.free(snt.bytes);
            }
            want.deinit();
        }

        var all_bytes = std.ArrayList(u8).init(allocator);
        defer all_bytes.deinit();

        var sentences = mem.split(u8, line, " ÷ ");
        var bytes_index: usize = 0;

        while (sentences.next()) |field| {
            var code_points = mem.split(u8, field, " ");
            var cp_buf: [4]u8 = undefined;
            var cp_index: usize = 0;
            var first: u21 = undefined;
            var cp_bytes = std.ArrayList(u8).init(allocator);
            defer cp_bytes.deinit();

            while (code_points.next()) |code_point| {
                if (mem.eql(u8, code_point, "×")) continue;
                const cp: u21 = try std.fmt.parseInt(u21, code_point, 16);
                if (cp_index == 0) first = cp;
                const len = try unicode.utf8Encode(cp, &cp_buf);
                try all_bytes.appendSlice(cp_buf[0..len]);
                try cp_bytes.appendSlice(cp_buf[0..len]);
                cp_index += len;
            }

            try want.append(Grapheme{
                .bytes = cp_bytes.toOwnedSlice(),
                .offset = bytes_index,
            });

            bytes_index += cp_index;
        }

        //debug.print("\nline {}: {s}\n", .{ line_no, all_bytes.items });

        var fis = std.io.fixedBufferStream(all_bytes.items);
        const reader = fis.reader();
        var iter = try StreamingGraphemeIterator(@TypeOf(reader)).init(std.testing.allocator, reader);

        // Chaeck.
        for (want.items) |w| {
            const g = (try iter.next()).?;
            defer std.testing.allocator.free(g.bytes);
            //debug.print("\n", .{});
            //for (w.bytes) |b| {
            //    debug.print("line {}: w:({x})\n", .{ line_no, b });
            //}
            //for (g.bytes) |b| {
            //    debug.print("line {}: g:({x})\n", .{ line_no, b });
            //}
            //debug.print("line {}: w:({s}), g:({s})\n", .{ line_no, w.bytes, g.bytes });
            try testing.expectEqualStrings(w.bytes, g.bytes);
        }
    }
}

test "Simple StreamingGraphemeIterator" {
    var buf = "abe\u{301}😹".*;
    var fis = std.io.fixedBufferStream(&buf);
    const reader = fis.reader();
    var iter = try StreamingGraphemeIterator(@TypeOf(reader)).init(std.testing.allocator, reader);
    const want = [_][]const u8{ "a", "b", "e\u{301}", "😹" };

    for (want) |str| {
        const gc = (try iter.next()).?;
        defer std.testing.allocator.free(gc.bytes);
        try std.testing.expect(gc.eql(str));
    }

    try std.testing.expectEqual(@as(?@This(), null), try iter.next());
}
