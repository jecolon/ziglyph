const std = @import("std");
const mem = std.mem;
const unicode = std.unicode;

const ascii = @import("../ascii.zig");
const Control = @import("../components/autogen/GraphemeBreakProperty/Control.zig");
const DecomposeMap = @import("../ziglyph.zig").DecomposeMap;
const Extend = @import("../components/autogen/GraphemeBreakProperty/Extend.zig");
const ExtPic = @import("../components/autogen/emoji-data/ExtendedPictographic.zig");
const CaseFoldMap = @import("../components/autogen/CaseFolding/CaseFoldMap.zig");
const Prepend = @import("../components/autogen/GraphemeBreakProperty/Prepend.zig");
const Regional = @import("../components/autogen/GraphemeBreakProperty/RegionalIndicator.zig");
const SpacingMark = @import("../components/autogen/GraphemeBreakProperty/SpacingMark.zig");
const HangulMap = @import("../components/autogen/HangulSyllableType/HangulMap.zig");

/// CodePointIterator retrieves the code points of a string.
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

    const Self = @This();

    // nexCodePointSlice retrieves the next code point's bytes.
    pub fn nextCodePointSlice(self: *Self) ?[]const u8 {
        if (self.i >= self.bytes.len) {
            return null;
        }

        const cp_len = unicode.utf8ByteSequenceLength(self.bytes[self.i]) catch unreachable;
        self.prev_i = self.i;
        self.i += cp_len;
        return self.bytes[self.i - cp_len .. self.i];
    }

    /// nextCodePoint retrieves the next code point as a single u21.
    pub fn nextCodePoint(self: *Self) ?u21 {
        const slice = self.nextCodePointSlice() orelse return null;
        self.prev = self.current;

        switch (slice.len) {
            1 => self.current = @as(u21, slice[0]),
            2 => self.current = unicode.utf8Decode2(slice) catch unreachable,
            3 => self.current = unicode.utf8Decode3(slice) catch unreachable,
            4 => self.current = unicode.utf8Decode4(slice) catch unreachable,
            else => unreachable,
        }

        return self.current;
    }

    /// peekN looks ahead at the next n codepoints without advancing the iterator.
    /// If fewer than n codepoints are available, then return the remainder of the string.
    pub fn peekN(self: *Self) []const u8 {
        const original_i = self.i;
        defer self.i = original_i;

        var end_ix = original_i;
        var found: usize = 0;
        while (found < n) : (found += 1) {
            const next_codepoint = self.nextCodePointSlice() orelse return self.bytes[original_i..];
            end_ix += next_codepoint.len;
        }

        return self.bytes[original_i..end_ix];
    }

    /// peek looks ahead at the next codepoint without advancing the iterator.
    pub fn peek(self: *Self) ?u21 {
        const original_i = self.i;
        const original_prev_i = self.prev_i;
        const original_prev = self.prev;
        defer {
            self.i = original_i;
            self.prev_i = original_prev_i;
            self.prev = original_prev;
        }
        return self.nextCodePoint();
    }

    /// reset prepares the iterator to start over iteration.
    pub fn reset(self: *Self) void {
        self.current = null;
        self.i = 0;
        self.prev = null;
        self.prev_i = 0;
    }
};

/// GraphemeIterator retrieves the grapheme clusters of a string, which may be composed of several 
/// code points each.
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

    const Self = @This();

    pub fn deinit(self: *Self) void {
        self.control.deinit();
        self.extend.deinit();
        self.extpic.deinit();
        self.han_map.deinit();
        self.prepend.deinit();
        self.regional.deinit();
        self.spacing.deinit();
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

    /// next retrieves the next grapheme cluster.
    pub fn next(self: *Self) ?[]const u8 {
        var cpo = self.cp_iter.nextCodePoint();
        if (cpo == null) return null;
        const cp = cpo.?;
        const cp_end = self.cp_iter.i;
        const cp_start = self.cp_iter.prev_i;
        const next_cp = self.cp_iter.peek();

        // GB9.2
        if (self.prepend.isPrepend(cp)) {
            if (next_cp) |ncp| {
                if (ncp == CR or ncp == LF or self.control.isControl(ncp)) {
                    return self.cp_iter.bytes[cp_start..cp_end];
                }

                const pncp = self.cp_iter.nextCodePoint().?; // We know there's a next.
                const pncp_end = self.cp_iter.i;
                const pncp_start = self.cp_iter.prev_i;
                const pncp_next_cp = self.cp_iter.peek();
                const s = self.processNonPrepend(pncp, pncp_start, pncp_end, pncp_next_cp);
                return self.cp_iter.bytes[cp_start..s.end];
            }

            return self.cp_iter.bytes[cp_start..cp_end];
        }

        const s = self.processNonPrepend(cp, cp_start, cp_end, next_cp);
        return self.cp_iter.bytes[s.start..s.end];
    }

    fn processNonPrepend(
        self: *Self,
        cp: u21,
        cp_start: usize,
        cp_end: usize,
        next_cp: ?u21,
    ) Slice {
        // GB3, GB4, GB5
        if (cp == CR) {
            if (next_cp) |ncp| {
                if (ncp == LF) {
                    _ = self.cp_iter.nextCodePoint(); // Advance past LF.
                    return .{ .start = cp_start, .end = self.cp_iter.i };
                }
            }
            return .{ .start = cp_start, .end = cp_end };
        }

        if (cp == LF) {
            return .{ .start = cp_start, .end = cp_end };
        }

        if (self.control.isControl(cp)) {
            return .{ .start = cp_start, .end = cp_end };
        }

        // GB6, GB7, GB8
        if (self.han_map.syllableType(cp)) |hst| {
            if (next_cp) |ncp| {
                const ncp_hst = self.han_map.syllableType(ncp);

                if (ncp_hst) |nhst| {
                    switch (hst) {
                        .L => {
                            if (nhst == .L or nhst == .V or nhst == .LV or nhst == .LVT) {
                                _ = self.cp_iter.nextCodePoint(); // Advance past next syllable.
                            }
                        },
                        .LV, .V => {
                            if (nhst == .V or nhst == .T) {
                                _ = self.cp_iter.nextCodePoint(); // Advance past next syllable.
                            }
                        },
                        .LVT, .T => {
                            if (nhst == .T) {
                                _ = self.cp_iter.nextCodePoint(); // Advance past next syllable.
                            }
                        },
                    }
                }
            }

            // GB9
            self.fullAdvance();
            return .{ .start = cp_start, .end = self.cp_iter.i };
        }

        // GB11
        if (self.extpic.isExtendedPictographic(cp)) {
            self.fullAdvance();
            if (self.cp_iter.prev) |pcp| {
                if (pcp == ZWJ) {
                    if (self.cp_iter.peek()) |ncp| {
                        if (self.extpic.isExtendedPictographic(ncp)) {
                            _ = self.cp_iter.nextCodePoint(); // Advance past end emoji.
                            // GB9
                            self.fullAdvance();
                        }
                    }
                }
            }

            return .{ .start = cp_start, .end = self.cp_iter.i };
        }

        // GB12
        if (self.regional.isRegionalIndicator(cp)) {
            if (next_cp) |ncp| {
                if (self.regional.isRegionalIndicator(ncp)) {
                    _ = self.cp_iter.nextCodePoint(); // Advance past 2nd RI.
                }
            }

            self.fullAdvance();
            return .{ .start = cp_start, .end = self.cp_iter.i };
        }

        // GB999
        self.fullAdvance();
        return .{ .start = cp_start, .end = self.cp_iter.i };
    }

    fn lexRun(
        self: *Self,
        ctx: anytype,
        comptime predicate: fn (ctx: @TypeOf(ctx), cp: u21) bool,
    ) void {
        while (self.cp_iter.peek()) |ncp| {
            if (!predicate(ctx, ncp)) break;
            _ = self.cp_iter.nextCodePoint();
        }
    }

    fn fullAdvance(self: *Self) void {
        const next_cp = self.cp_iter.peek();
        // Base case.
        if (next_cp) |ncp| {
            if (ncp != ZWJ and !self.extend.isExtend(ncp) and !self.spacing.isSpacingMark(ncp)) return;
        } else {
            return;
        }

        // Recurse.
        const ncp = next_cp.?; // We now we have next.

        if (ncp == ZWJ) {
            _ = self.cp_iter.nextCodePoint();
            self.fullAdvance();
        } else if (self.extend.isExtend(ncp)) {
            self.lexRun(self.extend, Extend.isExtend);
            self.fullAdvance();
        } else if (self.spacing.isSpacingMark(ncp)) {
            self.lexRun(self.spacing, SpacingMark.isSpacingMark);
            self.fullAdvance();
        }
    }
};

/// isAscii checks a code point to see if it's an ASCII character.
pub fn isAscii(cp: u21) bool {
    return cp < 128;
}

/// isAsciiStr checks if a string (`[]const uu`) is composed solely of ASCII characters.
pub fn isAsciiStr(str: []const u8) !bool {
    var cp_iter = (try unicode.Utf8View.init(str)).iterator();
    while (cp_iter.nextCodepoint()) |cp| {
        if (!isAscii(cp)) return false;
    }
    return true;
}

/// isLatin1 checks a code point to see if it's a Latin-1 character.
pub fn isLatin1(cp: u21) bool {
    return cp < 256;
}

/// isLatin1Str checks if a string (`[]const uu`) is composed solely of Latin-1 characters.
pub fn isLatin1Str(str: []const u8) !bool {
    var cp_iter = (try unicode.Utf8View.init(str)).iterator();
    while (cp_iter.nextCodepoint()) |cp| {
        if (!isLatin1(cp)) return false;
    }
    return true;
}

pub const StrOpts = enum {
    exact,
    ignore_case,
    normalize,
    norm_ignore,
};

pub fn eql(allocator: *mem.Allocator, a: []const u8, b: []const u8, opts: StrOpts) !bool {
    var ascii_only = true;
    var bytes_eql = true;
    var inner: []const u8 = undefined;
    const len_a = a.len;
    const len_b = b.len;
    var len_eql = len_a == len_b;
    var outer: []const u8 = undefined;

    if (len_a <= len_b) {
        outer = a;
        inner = b;
    } else {
        outer = b;
        inner = a;
    }

    for (outer) |c, i| {
        if (c != inner[i]) bytes_eql = false;
        if (!isAscii(c) and !isAscii(inner[i])) ascii_only = false;
    }

    // Exact bytes match.
    if (opts == .exact and len_eql and bytes_eql) return true;

    if (opts == .ignore_case and len_eql) {
        if (ascii_only) {
            // ASCII case insensitive.
            for (a) |c, i| {
                if (ascii.toLower(c) != ascii.toLower(b[i])) return false;
            }
            return true;
        }

        // Non-ASCII case insensitive.
        return try ignoreCaseEql(allocator, a, b);
    }

    if (opts == .normalize) return try normalizeEql(allocator, a, b);

    if (opts == .norm_ignore) return try normIgnoreEql(allocator, a, b);

    return false;
}

fn ignoreCaseEql(allocator: *mem.Allocator, a: []const u8, b: []const u8) !bool {
    var fold_map = try CaseFoldMap.init(allocator);
    defer fold_map.deinit();

    const cf_a = try fold_map.caseFoldStr(allocator, a);
    const cf_b = try fold_map.caseFoldStr(allocator, b);

    return mem.eql(u8, cf_a, cf_b);
}

fn normalizeEql(allocator: *mem.Allocator, a: []const u8, b: []const u8) !bool {
    var dm = try DecomposeMap.init(allocator);
    defer dm.deinit();
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    var arena_allocator = &arena.allocator;

    const norm_a = try dm.normalizeTo(arena_allocator, .KD, a);
    const norm_b = try dm.normalizeTo(arena_allocator, .KD, b);
    return mem.eql(u8, norm_a, norm_b);
}

fn normIgnoreEql(allocator: *mem.Allocator, a: []const u8, b: []const u8) !bool {
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    var arena_allocator = &arena.allocator;

    var dm = try DecomposeMap.init(arena_allocator);
    var fold_map = try CaseFoldMap.init(arena_allocator);

    // The long winding road of normalized caseless matching...
    var norm_a = try dm.normalizeTo(arena_allocator, .D, a);
    var cf_a = try fold_map.caseFoldStr(arena_allocator, norm_a);
    norm_a = try dm.normalizeTo(arena_allocator, .KD, cf_a);
    cf_a = try fold_map.caseFoldStr(arena_allocator, norm_a);
    norm_a = try dm.normalizeTo(arena_allocator, .KD, cf_a);
    var norm_b = try dm.normalizeTo(arena_allocator, .D, b);
    var cf_b = try fold_map.caseFoldStr(arena_allocator, norm_b);
    norm_b = try dm.normalizeTo(arena_allocator, .KD, cf_b);
    cf_b = try fold_map.caseFoldStr(arena_allocator, norm_b);
    norm_b = try dm.normalizeTo(arena_allocator, .KD, cf_b);

    return mem.eql(u8, norm_a, norm_b);
}
