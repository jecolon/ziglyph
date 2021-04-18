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
const Zigchar = @import("../zigchar/Zigchar.zig");

allocator: *mem.Allocator,
bytes: []u8,
chars: []Zigchar,
code_points: []u21,

const Self = @This();
pub fn init(allocator: *mem.Allocator, str: []const u8) !Self {
    var control = try Control.init(allocator);
    defer control.deinit();
    var extend = try Extend.init(allocator);
    defer extend.deinit();
    var extpic = try ExtPic.init(allocator);
    defer extpic.deinit();
    var han_map = try HangulMap.init(allocator);
    defer han_map.deinit();
    var prepend = try Prepend.init(allocator);
    defer prepend.deinit();
    var regional = try Regional.init(allocator);
    defer regional.deinit();
    var spacing = try SpacingMark.init(allocator);
    defer spacing.deinit();

    // Gather code points.
    var code_points = std.ArrayList(u21).init(allocator);
    defer code_points.deinit();
    var iter = (try unicode.Utf8View.init(str)).iterator();
    while (iter.nextCodepoint()) |cp| {
        try code_points.append(cp);
    }

    // Gather Zigchars.
    var chars = std.ArrayList(Zigchar).init(allocator);
    defer {
        for (chars.items) |*char| {
            char.deinit();
        }
        chars.deinit();
    }
    const items = code_points.items;
    const len = items.len;

    // Special code points.
    const ZWJ: u21 = 0x200D;
    const CR: u21 = 0x000D;
    const LF: u21 = 0x000A;

    var char_start: usize = 0;
    var emoji_seen = false;
    var i: usize = 0;
    while (i < len) {
        const i_at_top = i;
        const cp = items[i];
        const next: ?u21 = if (i < len - 1) items[i + 1] else null;
        const prev: ?u21 = if (i > 0) items[i - 1] else null;

        // Apply rules.
        // GB3
        if (cp == CR) {
            if (next) |ncp| {
                if (ncp == LF) {
                    i += 2;
                    continue;
                }
            }
        }

        // GB6, GB7, GB8
        if (han_map.syllableType(cp)) |hst| {
            if (next) |ncp| {
                const ncp_hst = han_map.syllableType(ncp);

                if (ncp_hst) |nhst| {
                    switch (hst) {
                        .L => {
                            if (nhst == .L or nhst == .V or nhst == .LV or nhst == .LVT) {
                                i += 2;
                                continue;
                            }
                        },
                        .LV, .V => {
                            if (nhst == .V or nhst == .T) {
                                i += 2;
                                continue;
                            }
                        },
                        .LVT, .T => {
                            if (nhst == .T) {
                                i += 2;
                                continue;
                            }
                        },
                    }
                }
            }
        }

        // GB9
        if (extend.isExtend(cp)) {
            i += lexRun(items[i..], extend, Extend.isExtend);
            continue;
        }
        if (spacing.isSpacingMark(cp)) {
            i += lexRun(items[i..], spacing, SpacingMark.isSpacingMark);
            continue;
        }
        if (cp == ZWJ) {
            if (prev != null) {
                i += 1;
                continue;
            }
        }

        // GB9.2
        if (prepend.isPrepend(cp)) {
            if (next) |ncp| {
                if (ncp != CR and ncp != LF and !control.isControl(ncp)) {
                    i += 2;
                    continue;
                }
            }
        }

        // GB11
        if (extpic.isExtendedPictographic(cp)) {
            if (emoji_seen) {
                if (prev) |pcp| {
                    if (pcp == ZWJ) {
                        i += 1;
                        emoji_seen = false;
                        continue;
                    }
                }
            } else {
                // Emoji marks new cluster.
                if (prev != null and char_start < i_at_top) {
                    try chars.append(try Zigchar.fromCodePoints(allocator, items[char_start..i_at_top]));
                    char_start = i_at_top;
                }
                emoji_seen = true;
                continue;
            }
        }

        // GB12
        if (regional.isRegionalIndicator(cp)) {
            if (next) |ncp| {
                if (regional.isRegionalIndicator(ncp)) {
                    // Only 2 code points in RI sequences.
                    if (prev != null and char_start < i_at_top) {
                        try chars.append(try Zigchar.fromCodePoints(allocator, items[char_start..i_at_top]));
                        char_start = i_at_top;
                    }
                    i += 2;
                    continue;
                }
            }
        }

        // GB9 continued.
        if (cp != CR and cp != LF and !control.isControl(cp)) {
            if (next) |ncp| {
                if (extend.isExtend(ncp) or spacing.isSpacingMark(ncp) or ncp == ZWJ) {
                    i += 1;
                    continue;
                }
            }
        }

        // GB999
        // Add any pending char.
        if (prev != null and char_start < i) {
            try chars.append(try Zigchar.fromCodePoints(allocator, items[char_start..i]));
            char_start = i;
        }

        try chars.append(try Zigchar.fromCodePoints(allocator, items[char_start .. i + 1]));
        i += 1;
        char_start = i;
    }

    // Any left over?
    if (char_start < i) {
        try chars.append(try Zigchar.fromCodePoints(allocator, items[char_start..]));
    }

    return Self{
        .allocator = allocator,
        .bytes = blk: {
            const b = try allocator.alloc(u8, str.len);
            mem.copy(u8, b, str);
            break :blk b;
        },
        .chars = chars.toOwnedSlice(),
        .code_points = code_points.toOwnedSlice(),
    };
}

pub fn deinit(self: *Self) void {
    self.allocator.free(self.bytes);
    for (self.chars) |*char| {
        char.deinit();
    }
    self.allocator.free(self.chars);
    self.allocator.free(self.code_points);
}

fn lexRun(
    list: []const u21,
    ctx: anytype,
    comptime predicate: fn (ctx: @TypeOf(ctx), cp: u21) bool,
) usize {
    return for (list) |cp, i| {
        if (!predicate(ctx, cp)) break i;
    } else i;
}
