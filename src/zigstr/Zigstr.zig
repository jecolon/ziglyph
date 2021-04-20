const std = @import("std");
const mem = std.mem;
const unicode = std.unicode;

const Control = @import("../components/autogen/GraphemeBreakProperty/Control.zig");
const Extend = @import("../components/autogen/GraphemeBreakProperty/Extend.zig");
const ExtPic = @import("../components/autogen/emoji-data/ExtendedPictographic.zig");
const Prepend = @import("../components/autogen/GraphemeBreakProperty/Prepend.zig");
const Regional = @import("../components/autogen/GraphemeBreakProperty/RegionalIndicator.zig");
const SpacingMark = @import("../components/autogen/GraphemeBreakProperty/SpacingMark.zig");
const HangulMap = @import("../components/autogen/HangulSyllableType/HangulMap.zig");

pub const CodePointIterator = struct {
    bytes: []const u8,
    current: ?u21,
    i: usize,
    prev: ?u21,
    prev_i: usize,

    pub fn init(str: []const u8) !CodePointIterator {
        if (!unicode.utf8ValidateSlice(str)) {
            return error.InvalidUtf8;
        }

        return CodePointIterator{
            .bytes = str,
            .current = null,
            .i = 0,
            .prev = null,
            .prev_i = 0,
        };
    }

    pub fn nextCodepointSlice(it: *CodePointIterator) ?[]const u8 {
        if (it.i >= it.bytes.len) {
            return null;
        }

        const cp_len = unicode.utf8ByteSequenceLength(it.bytes[it.i]) catch unreachable;
        it.prev_i = it.i;
        it.i += cp_len;
        return it.bytes[it.i - cp_len .. it.i];
    }

    pub fn nextCodepoint(it: *CodePointIterator) ?u21 {
        const slice = it.nextCodepointSlice() orelse return null;
        it.prev = it.current;

        switch (slice.len) {
            1 => it.current = @as(u21, slice[0]),
            2 => it.current = unicode.utf8Decode2(slice) catch unreachable,
            3 => it.current = unicode.utf8Decode3(slice) catch unreachable,
            4 => it.current = unicode.utf8Decode4(slice) catch unreachable,
            else => unreachable,
        }

        return it.current;
    }

    /// Look ahead at the next n codepoints without advancing the iterator.
    /// If fewer than n codepoints are available, then return the remainder of the string.
    pub fn peekN(it: *CodePointIterator, n: usize) []const u8 {
        const original_i = it.i;
        defer it.i = original_i;

        var end_ix = original_i;
        var found: usize = 0;
        while (found < n) : (found += 1) {
            const next_codepoint = it.nextCodepointSlice() orelse return it.bytes[original_i..];
            end_ix += next_codepoint.len;
        }

        return it.bytes[original_i..end_ix];
    }

    /// Look ahead at the next codepoint without advancing the iterator.
    pub fn peek(it: *CodePointIterator) ?u21 {
        const original_i = it.i;
        const original_prev_i = it.prev_i;
        const original_prev = it.prev;
        defer {
            it.i = original_i;
            it.prev_i = original_prev_i;
            it.prev = original_prev;
        }
        return it.nextCodepoint();
    }
};

pub const GraphemeIterator = struct {
    allocator: *mem.Allocator,
    control: Control,
    cp_iter: CodePointIterator,
    extend: Extend,
    extpic: ExtPic,
    han_map: HangulMap,
    prepend: Prepend,
    regional: Regional,
    spacing: SpacingMark,

    pub fn init(allocator: *mem.Allocator, str: []const u8) !GraphemeIterator {
        return GraphemeIterator{
            .allocator = allocator,
            .control = try Control.init(allocator),
            .cp_iter = try CodePointIterator.init(str),
            .extend = try Extend.init(allocator),
            .extpic = try ExtPic.init(allocator),
            .han_map = try HangulMap.init(allocator),
            .prepend = try Prepend.init(allocator),
            .regional = try Regional.init(allocator),
            .spacing = try SpacingMark.init(allocator),
        };
    }

    pub fn deinit(it: *GraphemeIterator) void {
        it.control.deinit();
        it.extend.deinit();
        it.extpic.deinit();
        it.han_map.deinit();
        it.prepend.deinit();
        it.regional.deinit();
        it.spacing.deinit();
    }

    pub fn reinit(it: *GraphemeIterator, str: []const u8) !void {
        it.cp_iter = try CodePointIterator.init(str);
    }

    // Special code points.
    const ZWJ: u21 = 0x200D;
    const CR: u21 = 0x000D;
    const LF: u21 = 0x000A;

    const Slice = struct {
        start: usize,
        end: usize,
    };

    pub fn next(it: *GraphemeIterator) ?[]const u8 {
        var cpo = it.cp_iter.nextCodepoint();
        if (cpo == null) return null;
        const cp = cpo.?;
        const cp_end = it.cp_iter.i;
        const cp_start = it.cp_iter.prev_i;
        const next_cp = it.cp_iter.peek();

        // GB9.2
        if (it.prepend.isPrepend(cp)) {
            if (next_cp) |ncp| {
                if (ncp == CR or ncp == LF or it.control.isControl(ncp)) {
                    return it.cp_iter.bytes[cp_start..cp_end];
                }

                const pncp = it.cp_iter.nextCodepoint().?; // We know there's a next.
                const pncp_end = it.cp_iter.i;
                const pncp_start = it.cp_iter.prev_i;
                const pncp_next_cp = it.cp_iter.peek();
                const s = it.processNonPrepend(pncp, pncp_start, pncp_end, pncp_next_cp);
                return it.cp_iter.bytes[cp_start..s.end];
            }

            return it.cp_iter.bytes[cp_start..cp_end];
        }

        const s = it.processNonPrepend(cp, cp_start, cp_end, next_cp);
        return it.cp_iter.bytes[s.start..s.end];
    }

    fn processNonPrepend(
        it: *GraphemeIterator,
        cp: u21,
        cp_start: usize,
        cp_end: usize,
        next_cp: ?u21,
    ) Slice {
        // GB3, GB4, GB5
        if (cp == CR) {
            if (next_cp) |ncp| {
                if (ncp == LF) {
                    _ = it.cp_iter.nextCodepoint(); // Advance past LF.
                    return .{ .start = cp_start, .end = it.cp_iter.i };
                }
            }
            return .{ .start = cp_start, .end = cp_end };
        }

        if (cp == LF) {
            return .{ .start = cp_start, .end = cp_end };
        }

        if (it.control.isControl(cp)) {
            return .{ .start = cp_start, .end = cp_end };
        }

        // GB6, GB7, GB8
        if (it.han_map.syllableType(cp)) |hst| {
            if (next_cp) |ncp| {
                const ncp_hst = it.han_map.syllableType(ncp);

                if (ncp_hst) |nhst| {
                    switch (hst) {
                        .L => {
                            if (nhst == .L or nhst == .V or nhst == .LV or nhst == .LVT) {
                                _ = it.cp_iter.nextCodepoint(); // Advance past next syllable.
                            }
                        },
                        .LV, .V => {
                            if (nhst == .V or nhst == .T) {
                                _ = it.cp_iter.nextCodepoint(); // Advance past next syllable.
                            }
                        },
                        .LVT, .T => {
                            if (nhst == .T) {
                                _ = it.cp_iter.nextCodepoint(); // Advance past next syllable.
                            }
                        },
                    }
                }
            }

            // GB9
            it.fullAdvance();
            return .{ .start = cp_start, .end = it.cp_iter.i };
        }

        // GB11
        if (it.extpic.isExtendedPictographic(cp)) {
            it.fullAdvance();
            if (it.cp_iter.prev) |pcp| {
                if (pcp == ZWJ) {
                    if (it.cp_iter.peek()) |ncp| {
                        if (it.extpic.isExtendedPictographic(ncp)) {
                            _ = it.cp_iter.nextCodepoint(); // Advance past end emoji.
                            // GB9
                            it.fullAdvance();
                        }
                    }
                }
            }

            return .{ .start = cp_start, .end = it.cp_iter.i };
        }

        // GB12
        if (it.regional.isRegionalIndicator(cp)) {
            if (next_cp) |ncp| {
                if (it.regional.isRegionalIndicator(ncp)) {
                    _ = it.cp_iter.nextCodepoint(); // Advance past 2nd RI.
                }
            }

            it.fullAdvance();
            return .{ .start = cp_start, .end = it.cp_iter.i };
        }

        // GB999
        it.fullAdvance();
        return .{ .start = cp_start, .end = it.cp_iter.i };
    }

    fn lexRun(
        it: *GraphemeIterator,
        ctx: anytype,
        comptime predicate: fn (ctx: @TypeOf(ctx), cp: u21) bool,
    ) void {
        while (it.cp_iter.peek()) |ncp| {
            if (!predicate(ctx, ncp)) break;
            _ = it.cp_iter.nextCodepoint();
        }
    }

    fn fullAdvance(it: *GraphemeIterator) void {
        const next_cp = it.cp_iter.peek();
        // Base case.
        if (next_cp) |ncp| {
            if (ncp != ZWJ and !it.extend.isExtend(ncp) and !it.spacing.isSpacingMark(ncp)) return;
        } else {
            return;
        }

        // Recurse.
        const ncp = next_cp.?; // We now we have next.

        if (ncp == ZWJ) {
            _ = it.cp_iter.nextCodepoint();
            it.fullAdvance();
        } else if (it.extend.isExtend(ncp)) {
            it.lexRun(it.extend, Extend.isExtend);
            it.fullAdvance();
        } else if (it.spacing.isSpacingMark(ncp)) {
            it.lexRun(it.spacing, SpacingMark.isSpacingMark);
            it.fullAdvance();
        }
    }
};
