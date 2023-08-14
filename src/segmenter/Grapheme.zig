//! `Grapheme` represents a Unicode grapheme cluster with related functionality.

const std = @import("std");
const debug = std.debug;
const mem = std.mem;
const testing = std.testing;
const unicode = std.unicode;

const CodePoint = @import("CodePoint.zig");
const CodePointIterator = CodePoint.CodePointIterator;
const readCodePoint = CodePoint.readCodePoint;
const emoji = @import("../autogen/emoji_data.zig");
const gbp = @import("../autogen/grapheme_break_property.zig");

pub const Grapheme = @This();

len: usize,
offset: usize,

/// `eql` comparse `str` with the bytes of this grapheme cluster for equality.
pub fn eql(self: Grapheme, src: []const u8, other: []const u8) bool {
    return mem.eql(u8, src[self.offset .. self.offset + self.len], other);
}

/// `GraphemeIterator` iterates a sting one grapheme cluster at-a-time.
pub const GraphemeIterator = struct {
    buf: [2]?CodePoint = [_]?CodePoint{ null, null },
    cp_iter: CodePointIterator,

    const Self = @This();

    /// Assumes `src` is valid UTF-8.
    pub fn init(str: []const u8) Self {
        var self = Self{ .cp_iter = CodePointIterator{ .bytes = str } };
        self.buf[1] = self.cp_iter.next();

        return self;
    }

    fn advance(self: *Self) void {
        self.buf[0] = self.buf[1];
        self.buf[1] = self.cp_iter.next();
    }

    pub fn next(self: *Self) ?Grapheme {
        self.advance();
        const cp = self.buf[0] orelse return null;

        // If at end
        if (self.buf[1] == null) return Grapheme{ .len = cp.len, .offset = cp.offset };

        const code = cp.code;
        const gc_start = cp.offset;
        var gc_len: usize = cp.len;

        // Instant breakers
        // CR
        if (code == '\x0d') {
            if (self.buf[1].?.code == '\x0a') {
                // CRLF
                gc_len += 1;
                self.advance();
            }

            return Grapheme{ .len = gc_len, .offset = gc_start };
        }
        // LF
        if (code == '\x0a') return Grapheme{ .len = gc_len, .offset = gc_start };
        // Control
        if (gbp.isControl(code)) return Grapheme{ .len = gc_len, .offset = gc_start };

        // Common chars
        if (code < 0xa9) {
            // Extend / ignorables loop
            while (self.buf[1]) |next_cp| {
                const next_code = next_cp.code;

                if (next_code >= 0x300 and isIgnorable(next_code)) {
                    gc_len += next_cp.len;
                    self.advance();
                } else {
                    break;
                }
            }

            return Grapheme{ .len = gc_len, .offset = gc_start };
        }

        // Emoji
        if (emoji.isExtendedPictographic(code)) {
            var after_zwj = false;

            // Extend / ignorables loop
            while (self.buf[1]) |next_cp| {
                const next_code = next_cp.code;

                if (next_code >= 0x300 and
                    after_zwj and
                    emoji.isExtendedPictographic(next_code))
                {
                    gc_len += next_cp.len;
                    self.advance();
                    after_zwj = false;
                } else if (next_code >= 0x300 and isIgnorable(next_code)) {
                    gc_len += next_cp.len;
                    self.advance();
                    if (next_code == '\u{200d}') after_zwj = true;
                } else {
                    break;
                }
            }

            return Grapheme{ .len = gc_len, .offset = gc_start };
        }

        // Han
        if (0x1100 <= code and code <= 0xd7c6) {
            const next_cp = self.buf[1].?;
            const next_code = next_cp.code;

            if (gbp.isL(code)) {
                if (next_code >= 0x1100 and
                    (gbp.isL(next_code) or
                    gbp.isV(next_code) or
                    gbp.isLv(next_code) or
                    gbp.isLvt(next_code)))
                {
                    gc_len += next_cp.len;
                    self.advance();
                }
            } else if (gbp.isLv(code) or gbp.isV(code)) {
                if (next_code >= 0x1100 and
                    (gbp.isV(next_code) or
                    gbp.isT(next_code)))
                {
                    gc_len += next_cp.len;
                    self.advance();
                }
            } else if (gbp.isLvt(code) or gbp.isT(code)) {
                if (next_code >= 0x1100 and gbp.isT(next_cp.code)) {
                    gc_len += next_cp.len;
                    self.advance();
                }
            }
        } else if (0x600 <= code and code <= 0x11f02) {
            if (gbp.isPrepend(code)) {
                const next_cp = self.buf[1].?;

                if (isBreaker(next_cp.code)) {
                    return Grapheme{ .len = gc_len, .offset = gc_start };
                } else {
                    gc_len += next_cp.len;
                    self.advance();
                }
            }
        } else if (0x1f1e6 <= code and code <= 0x1f1ff) {
            if (gbp.isRegionalIndicator(code)) {
                const next_cp = self.buf[1].?;
                const next_code = next_cp.code;

                if (next_code >= 0x1f1e6 and gbp.isRegionalIndicator(next_cp.code)) {
                    gc_len += next_cp.len;
                    self.advance();
                }
            }
        }

        // Extend / ignorables loop
        while (self.buf[1]) |next_cp| {
            const next_code = next_cp.code;

            if (next_code >= 0x300 and isIgnorable(next_code)) {
                gc_len += next_cp.len;
                self.advance();
            } else {
                break;
            }
        }

        return Grapheme{ .len = gc_len, .offset = gc_start };
    }
};

/// `StreamingGraphemeIterator` iterates a `std.io.Reader` one grapheme cluster at-a-time.
/// Note that, given the steaming context, each grapheme cluster is returned as a slice of bytes.
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

        /// Caller must free returned bytes with `allocator` passed to `init`.
        pub fn next(self: *Self) !?[]u8 {
            const code = (try self.advance()) orelse return null;

            var all_bytes = std.ArrayList(u8).init(self.allocator);
            errdefer all_bytes.deinit();

            try encode_and_append(code, &all_bytes);

            // If at end
            if (self.buf[1] == null) return try all_bytes.toOwnedSlice();

            // Instant breakers
            // CR
            if (code == '\x0d') {
                if (self.buf[1].? == '\x0a') {
                    // CRLF
                    try encode_and_append(self.buf[1].?, &all_bytes);
                    _ = self.advance() catch unreachable;
                }

                return try all_bytes.toOwnedSlice();
            }
            // LF
            if (code == '\x0a') return try all_bytes.toOwnedSlice();
            // Control
            if (gbp.isControl(code)) return try all_bytes.toOwnedSlice();

            // Common chars
            if (code < 0xa9) {
                // Extend / ignorables loop
                while (self.buf[1]) |next_cp| {
                    if (next_cp >= 0x300 and isIgnorable(next_cp)) {
                        try encode_and_append(next_cp, &all_bytes);
                        _ = self.advance() catch unreachable;
                    } else {
                        break;
                    }
                }

                return try all_bytes.toOwnedSlice();
            }

            if (emoji.isExtendedPictographic(code)) {
                var after_zwj = false;

                // Extend / ignorables loop
                while (self.buf[1]) |next_cp| {
                    if (next_cp >= 0x300 and
                        after_zwj and
                        emoji.isExtendedPictographic(next_cp))
                    {
                        try encode_and_append(next_cp, &all_bytes);
                        _ = self.advance() catch unreachable;
                        after_zwj = false;
                    } else if (next_cp >= 0x300 and isIgnorable(next_cp)) {
                        try encode_and_append(next_cp, &all_bytes);
                        _ = self.advance() catch unreachable;
                        if (next_cp == '\u{200d}') after_zwj = true;
                    } else {
                        break;
                    }
                }

                return try all_bytes.toOwnedSlice();
            }

            if (0x1100 <= code and code <= 0xd7c6) {
                const next_cp = self.buf[1].?;

                if (gbp.isL(code)) {
                    if (next_cp >= 0x1100 and
                        (gbp.isL(next_cp) or
                        gbp.isV(next_cp) or
                        gbp.isLv(next_cp) or
                        gbp.isLvt(next_cp)))
                    {
                        try encode_and_append(next_cp, &all_bytes);
                        _ = self.advance() catch unreachable;
                    }
                } else if (gbp.isLv(code) or gbp.isV(code)) {
                    if (next_cp >= 0x1100 and
                        (gbp.isV(next_cp) or
                        gbp.isT(next_cp)))
                    {
                        try encode_and_append(next_cp, &all_bytes);
                        _ = self.advance() catch unreachable;
                    }
                } else if (gbp.isLvt(code) or gbp.isT(code)) {
                    if (next_cp >= 0x1100 and gbp.isT(next_cp)) {
                        try encode_and_append(next_cp, &all_bytes);
                        _ = self.advance() catch unreachable;
                    }
                }
            } else if (0x600 <= code and code <= 0x11f02) {
                if (gbp.isPrepend(code)) {
                    const next_cp = self.buf[1].?;

                    if (isBreaker(next_cp)) {
                        return try all_bytes.toOwnedSlice();
                    } else {
                        try encode_and_append(next_cp, &all_bytes);
                        _ = self.advance() catch unreachable;
                    }
                }
            } else if (0x1f1e6 <= code and code <= 0x1f1ff) {
                if (gbp.isRegionalIndicator(code)) {
                    const next_cp = self.buf[1].?;

                    if (next_cp >= 0x1f1e6 and gbp.isRegionalIndicator(next_cp)) {
                        try encode_and_append(next_cp, &all_bytes);
                        _ = self.advance() catch unreachable;
                    }
                }
            }

            // Extend / ignorables loop
            while (self.buf[1]) |next_cp| {
                if (next_cp >= 0x300 and isIgnorable(next_cp)) {
                    try encode_and_append(next_cp, &all_bytes);
                    _ = self.advance() catch unreachable;
                } else {
                    break;
                }
            }

            return try all_bytes.toOwnedSlice();
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
fn isBreaker(cp: u21) bool {
    return cp == '\x0d' or cp == '\x0a' or gbp.isControl(cp);
}

fn isIgnorable(cp: u21) bool {
    return gbp.isExtend(cp) or gbp.isSpacingmark(cp) or cp == '\u{200d}';
}

test "Segmentation GraphemeIterator" {
    var path_buf: [1024]u8 = undefined;
    var path = try std.fs.cwd().realpath(".", &path_buf);
    // Check if testing in this library path.
    if (!mem.endsWith(u8, path, "zg2")) return;

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
        defer want.deinit();

        var all_bytes = std.ArrayList(u8).init(allocator);
        defer all_bytes.deinit();

        var graphemes = mem.split(u8, line, " ÷ ");
        var bytes_index: usize = 0;

        while (graphemes.next()) |field| {
            var code_points = mem.split(u8, field, " ");
            var cp_buf: [4]u8 = undefined;
            var cp_index: usize = 0;
            var gc_len: usize = 0;

            while (code_points.next()) |code_point| {
                if (mem.eql(u8, code_point, "×")) continue;
                const cp: u21 = try std.fmt.parseInt(u21, code_point, 16);
                const len = try unicode.utf8Encode(cp, &cp_buf);
                try all_bytes.appendSlice(cp_buf[0..len]);
                cp_index += len;
                gc_len += len;
            }

            try want.append(Grapheme{ .len = gc_len, .offset = bytes_index });
            bytes_index += cp_index;
        }

        //debug.print("\nline {}: {s}\n", .{ line_no, all_bytes.items });
        var iter = GraphemeIterator.init(all_bytes.items);

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
            try testing.expect(w.eql(all_bytes.items, all_bytes.items[g.offset .. g.offset + g.len]));
        }
    }
}

test "Segmentation comptime GraphemeIterator" {
    const want = [_][]const u8{ "H", "é", "l", "l", "o" };

    comptime {
        const src = "Héllo";
        var ct_iter = GraphemeIterator.init(src);
        var i = 0;
        while (ct_iter.next()) |grapheme| : (i += 1) {
            try testing.expect(grapheme.eql(src, want[i]));
        }
    }
}

test "Segmentation StreamingGraphemeIterator" {
    var path_buf: [1024]u8 = undefined;
    var path = try std.fs.cwd().realpath(".", &path_buf);
    // Check if testing in this library path.
    if (!mem.endsWith(u8, path, "zg2")) return;

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
        var want = std.ArrayList([]const u8).init(allocator);
        defer {
            for (want.items) |snt| {
                allocator.free(snt);
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
            var cp_bytes = std.ArrayList(u8).init(allocator);
            errdefer cp_bytes.deinit();

            while (code_points.next()) |code_point| {
                if (mem.eql(u8, code_point, "×")) continue;
                const cp: u21 = try std.fmt.parseInt(u21, code_point, 16);
                const len = try unicode.utf8Encode(cp, &cp_buf);
                try all_bytes.appendSlice(cp_buf[0..len]);
                try cp_bytes.appendSlice(cp_buf[0..len]);
                cp_index += len;
            }

            try want.append(try cp_bytes.toOwnedSlice());
            bytes_index += cp_index;
        }

        //debug.print("\nline {}: {s}\n", .{ line_no, all_bytes.items });

        var fis = std.io.fixedBufferStream(all_bytes.items);
        const reader = fis.reader();
        var iter = try StreamingGraphemeIterator(@TypeOf(reader)).init(std.testing.allocator, reader);

        // Chaeck.
        for (want.items) |wstr| {
            const gstr = (try iter.next()).?;
            defer std.testing.allocator.free(gstr);
            //debug.print("\n", .{});
            //for (w.bytes) |b| {
            //    debug.print("line {}: w:({x})\n", .{ line_no, b });
            //}
            //for (g.bytes) |b| {
            //    debug.print("line {}: g:({x})\n", .{ line_no, b });
            //}
            //debug.print("line {}: w:({s}), g:({s})\n", .{ line_no, w.bytes, g.bytes });
            try testing.expectEqualStrings(wstr, gstr);
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
        defer std.testing.allocator.free(gc);
        try std.testing.expectEqualStrings(gc, str);
    }

    try std.testing.expectEqual(@as(?[]u8, null), try iter.next());
}

test "Segmentation ZWJ and ZWSP emoji sequences" {
    const seq_1 = "\u{1F43B}\u{200D}\u{2744}\u{FE0F}";
    const seq_2 = "\u{1F43B}\u{200D}\u{2744}\u{FE0F}";
    const with_zwj = seq_1 ++ "\u{200D}" ++ seq_2;
    const with_zwsp = seq_1 ++ "\u{200B}" ++ seq_2;
    const no_joiner = seq_1 ++ seq_2;

    var ct_iter = GraphemeIterator.init(with_zwj);
    var i: usize = 0;
    while (ct_iter.next()) |_| : (i += 1) {}
    try testing.expectEqual(@as(usize, 1), i);

    ct_iter = GraphemeIterator.init(with_zwsp);
    i = 0;
    while (ct_iter.next()) |_| : (i += 1) {}
    try testing.expectEqual(@as(usize, 3), i);

    ct_iter = GraphemeIterator.init(no_joiner);
    i = 0;
    while (ct_iter.next()) |_| : (i += 1) {}
    try testing.expectEqual(@as(usize, 2), i);
}
