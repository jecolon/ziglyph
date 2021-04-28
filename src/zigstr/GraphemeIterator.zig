//! GraphemeIterator retrieves the grapheme clusters of a string, which may be composed of several 
//! code points each.

const std = @import("std");
const mem = std.mem;
const unicode = std.unicode;

const CodePointIterator = @import("CodePointIterator.zig");
const Context = @import("../Context.zig");

allocator: *mem.Allocator,
context: *Context,
cp_iter: CodePointIterator,

const Self = @This();

pub fn new(ctx: *Context, str: []const u8) !Self {
    return Self{
        .allocator = ctx.allocator,
        .context = ctx,
        .cp_iter = try CodePointIterator.init(str),
    };
}

/// reinit resets the iterator with a new string.
pub fn reinit(self: *Self, str: []const u8) !void {
    self.cp_iter = try CodePointIterator.init(str);
}

// Special code points.
const ZWJ: u21 = 0x200D;
const CR: u21 = 0x000D;
const LF: u21 = 0x000A;

const Slice = struct {
    start: usize,
    end: usize,
};

pub const Grapheme = struct {
    bytes: []const u8,

    pub fn eql(self: Grapheme, str: []const u8) bool {
        return mem.eql(u8, self.bytes, str);
    }
};

/// next retrieves the next grapheme cluster.
pub fn next(self: *Self) !?Grapheme {
    var cpo = self.cp_iter.next();
    if (cpo == null) return null;
    const cp = cpo.?;
    const cp_end = self.cp_iter.i;
    const cp_start = self.cp_iter.prev_i;
    const next_cp = self.cp_iter.peek();

    // GB9.2
    const prepend = try self.context.getPrepend();
    const control = try self.context.getControl();

    if (prepend.isPrepend(cp)) {
        if (next_cp) |ncp| {
            if (ncp == CR or ncp == LF or control.isControl(ncp)) {
                return Grapheme{
                    .bytes = self.cp_iter.bytes[cp_start..cp_end],
                };
            }

            const pncp = self.cp_iter.next().?; // We know there's a next.
            const pncp_end = self.cp_iter.i;
            const pncp_start = self.cp_iter.prev_i;
            const pncp_next_cp = self.cp_iter.peek();
            const s = try self.processNonPrepend(pncp, pncp_start, pncp_end, pncp_next_cp);
            return Grapheme{
                .bytes = self.cp_iter.bytes[cp_start..s.end],
            };
        }

        return Grapheme{
            .bytes = self.cp_iter.bytes[cp_start..cp_end],
        };
    }

    const s = try self.processNonPrepend(cp, cp_start, cp_end, next_cp);
    return Grapheme{
        .bytes = self.cp_iter.bytes[s.start..s.end],
    };
}

fn processNonPrepend(
    self: *Self,
    cp: u21,
    cp_start: usize,
    cp_end: usize,
    next_cp: ?u21,
) !Slice {
    // GB3, GB4, GB5
    if (cp == CR) {
        if (next_cp) |ncp| {
            if (ncp == LF) {
                _ = self.cp_iter.next(); // Advance past LF.
                return Slice{ .start = cp_start, .end = self.cp_iter.i };
            }
        }
        return Slice{ .start = cp_start, .end = cp_end };
    }

    if (cp == LF) {
        return Slice{ .start = cp_start, .end = cp_end };
    }

    const control = try self.context.getControl();
    if (control.isControl(cp)) {
        return Slice{ .start = cp_start, .end = cp_end };
    }

    // GB6, GB7, GB8
    const han_map = try self.context.getHangulMap();
    if (han_map.syllableType(cp)) |hst| {
        if (next_cp) |ncp| {
            const ncp_hst = han_map.syllableType(ncp);

            if (ncp_hst) |nhst| {
                switch (hst) {
                    .L => {
                        if (nhst == .L or nhst == .V or nhst == .LV or nhst == .LVT) {
                            _ = self.cp_iter.next(); // Advance past next syllable.
                        }
                    },
                    .LV, .V => {
                        if (nhst == .V or nhst == .T) {
                            _ = self.cp_iter.next(); // Advance past next syllable.
                        }
                    },
                    .LVT, .T => {
                        if (nhst == .T) {
                            _ = self.cp_iter.next(); // Advance past next syllable.
                        }
                    },
                }
            }
        }

        // GB9
        try self.fullAdvance();
        return Slice{ .start = cp_start, .end = self.cp_iter.i };
    }

    // GB11
    const extpic = try self.context.getExtPic();
    if (extpic.isExtendedPictographic(cp)) {
        try self.fullAdvance();
        if (self.cp_iter.prev) |pcp| {
            if (pcp == ZWJ) {
                if (self.cp_iter.peek()) |ncp| {
                    if (extpic.isExtendedPictographic(ncp)) {
                        _ = self.cp_iter.next(); // Advance past end emoji.
                        // GB9
                        try self.fullAdvance();
                    }
                }
            }
        }

        return Slice{ .start = cp_start, .end = self.cp_iter.i };
    }

    // GB12
    const regional = try self.context.getRegional();
    if (regional.isRegionalIndicator(cp)) {
        if (next_cp) |ncp| {
            if (regional.isRegionalIndicator(ncp)) {
                _ = self.cp_iter.next(); // Advance past 2nd RI.
            }
        }

        try self.fullAdvance();
        return Slice{ .start = cp_start, .end = self.cp_iter.i };
    }

    // GB999
    try self.fullAdvance();
    return Slice{ .start = cp_start, .end = self.cp_iter.i };
}

fn lexRun(
    self: *Self,
    ctx: anytype,
    comptime predicate: fn (ctx: @TypeOf(ctx), cp: u21) bool,
) void {
    while (self.cp_iter.peek()) |ncp| {
        if (!predicate(ctx, ncp)) break;
        _ = self.cp_iter.next();
    }
}

fn fullAdvance(self: *Self) anyerror!void {
    const next_cp = self.cp_iter.peek();
    // Base case.
    const extend = try self.context.getExtend();
    const spacing = try self.context.getSpacing();

    if (next_cp) |ncp| {
        if (ncp != ZWJ and !extend.isExtend(ncp) and !spacing.isSpacingMark(ncp)) return;
    } else {
        return;
    }

    // Recurse.
    const ncp = next_cp.?; // We now we have next.

    if (ncp == ZWJ) {
        _ = self.cp_iter.next();
        try self.fullAdvance();
    } else if (extend.isExtend(ncp)) {
        self.lexRun(extend.*, Context.Extend.isExtend);
        try self.fullAdvance();
    } else if (spacing.isSpacingMark(ncp)) {
        self.lexRun(spacing.*, Context.Spacing.isSpacingMark);
        try self.fullAdvance();
    }
}

test "Grapheme iterator" {
    var allocator = std.testing.allocator;
    var file = try std.fs.cwd().openFile("src/data/ucd/auxiliary/GraphemeBreakTest.txt", .{});
    defer file.close();
    var buf_reader = std.io.bufferedReader(file.reader());
    var input_stream = buf_reader.reader();

    var buf: [640]u8 = undefined;
    var line_no: usize = 1;

    var ctx = Context.init(allocator);
    defer ctx.deinit();
    var giter: ?Self = null;

    while (try input_stream.readUntilDelimiterOrEof(&buf, '\n')) |raw| : (line_no += 1) {
        // Skip comments or empty lines.
        if (raw.len == 0 or raw[0] == '#' or raw[0] == '@') continue;

        // Clean up.
        var line = mem.trimLeft(u8, raw, "÷ ");
        if (mem.indexOf(u8, line, " ÷\t#")) |octo| {
            line = line[0..octo];
        }

        // Iterate over fields.
        var want = std.ArrayList(Grapheme).init(allocator);
        defer {
            for (want.items) |gc| {
                allocator.free(gc.bytes);
            }
            want.deinit();
        }
        var all_bytes = std.ArrayList(u8).init(allocator);
        defer all_bytes.deinit();
        var graphemes = mem.split(line, " ÷ ");
        var bytes_index: usize = 0;

        while (graphemes.next()) |field| {
            var code_points = mem.split(field, " ");
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
            });

            bytes_index += cp_index;
        }

        if (giter) |*gi| {
            try gi.reinit(all_bytes.items);
        } else {
            giter = try new(&ctx, all_bytes.items);
        }

        // Chaeck.
        for (want.items) |w| {
            const g = (try giter.?.next()).?;
            //std.debug.print("line {d}: w:({s}), g:({s})\n", .{ line_no, w.bytes, g.bytes });
            std.testing.expectEqualStrings(w.bytes, g.bytes);
        }
    }
}

test "Grapheme width" {
    _ = @import("../components/aggregate/Width.zig");
}
