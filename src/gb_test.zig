const std = @import("std");
const ArrayList = std.ArrayList;
const expect = std.testing.expect;
const expectEqual = std.testing.expectEqual;
const expectEqualSlices = std.testing.expectEqualSlices;
const io = std.io;
const fmt = std.fmt;
const mem = std.mem;
const unicode = std.unicode;

const CccMap = @import("/components/autogen/DerivedCombiningClass/CccMap.zig");
const Control = @import("components/autogen/GraphemeBreakProperty/Control.zig");
const Extend = @import("components/autogen/GraphemeBreakProperty/Extend.zig");
const ExtPic = @import("components/autogen/emoji-data/ExtendedPictographic.zig");
const Prepend = @import("components/autogen/GraphemeBreakProperty/Prepend.zig");
const Regional = @import("components/autogen/GraphemeBreakProperty/RegionalIndicator.zig");
const SpacingMark = @import("components/autogen/GraphemeBreakProperty/SpacingMark.zig");
const HangulMap = @import("components/autogen/HangulSyllableType/HangulMap.zig");
const Zigchar = @import("zigchar/Zigchar.zig");

test "grapheme break" {
    std.debug.print("\n", .{});
    var allocator = std.testing.allocator;
    var file = try std.fs.cwd().openFile("src/data/ucd/auxiliary/GraphemeBreakTest.txt", .{});
    defer file.close();
    var buf_reader = io.bufferedReader(file.reader());
    var input_stream = buf_reader.reader();

    var control = try Control.init(allocator);
    defer control.deinit();
    var ccc_map = try CccMap.init(allocator);
    defer ccc_map.deinit();
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

    var buf: [640]u8 = undefined;
    var line_no: usize = 1;
    while (try input_stream.readUntilDelimiterOrEof(&buf, '\n')) |raw| : (line_no += 1) {
        // Skip comments or empty lines.
        if (raw.len == 0 or raw[0] == '#' or raw[0] == '@') continue;
        // Clean up.
        var line = mem.trimLeft(u8, raw, "÷ ");
        if (mem.indexOf(u8, line, " ÷\t#")) |octo| {
            line = line[0..octo];
        }

        // Iterate over fields.
        var fields = mem.split(line, " ÷ ");
        var want = ArrayList(Zigchar).init(allocator);
        defer {
            for (want.items) |*char| {
                char.deinit();
            }
            want.deinit();
        }
        var all_code_points = ArrayList(u21).init(allocator);
        defer all_code_points.deinit();
        while (fields.next()) |field| {
            var code_points = ArrayList(u21).init(allocator);
            defer code_points.deinit();
            var sub_fields = mem.split(field, " ");
            while (sub_fields.next()) |sub_field| {
                if (mem.eql(u8, sub_field, "×")) continue;
                const cp: u21 = try fmt.parseInt(u21, sub_field, 16);
                try all_code_points.append(cp);
                try code_points.append(cp);
            }
            try want.append(try Zigchar.fromCodePoints(allocator, code_points.items));
        }

        ///////////////////////////////////////
        // Break graphemes.
        var got = ArrayList(Zigchar).init(allocator);
        defer {
            for (got.items) |*char| {
                char.deinit();
            }
            got.deinit();
        }
        const items = all_code_points.items;
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
            std.debug.print("line {d} i_at_top: {d}\n", .{ line_no, i_at_top });
            const cp = items[i];
            const next: ?u21 = if (i < len - 1) items[i + 1] else null;
            const prev: ?u21 = if (i > 0) items[i - 1] else null;

            // Apply rules.
            // GB3
            if (cp == CR) {
                if (next) |ncp| {
                    if (ncp == LF) {
                        i += 2;
                        std.debug.print("line {d} CRLF: {d} {d}\n", .{ line_no, i, char_start });
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
                                    std.debug.print("line {d} .L: {d} {d}\n", .{ line_no, i, char_start });
                                    continue;
                                }
                            },
                            .LV, .V => {
                                if (nhst == .V or nhst == .T) {
                                    i += 2;
                                    std.debug.print("line {d} .LV, .V: {d} {d}\n", .{ line_no, i, char_start });
                                    continue;
                                }
                            },
                            .LVT, .T => {
                                if (nhst == .T) {
                                    i += 2;
                                    std.debug.print("line {d} .LVT, .T: {d} {d}\n", .{ line_no, i, char_start });
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
                std.debug.print("line {d} Post-Extend: {d} {d}\n", .{ line_no, i, char_start });
                continue;
            }
            if (spacing.isSpacingMark(cp)) {
                i += lexRun(items[i..], spacing, SpacingMark.isSpacingMark);
                std.debug.print("line {d} Post-Spacing: {d} {d}\n", .{ line_no, i, char_start });
                continue;
            }
            if (cp == ZWJ) {
                if (prev != null) {
                    i += 1;
                    std.debug.print("line {d} Post-ZWJ: {d} {d}\n", .{ line_no, i, char_start });
                    continue;
                }
            }

            // GB9.2
            if (prepend.isPrepend(cp)) {
                if (next) |ncp| {
                    if (ncp != CR and ncp != LF and !control.isControl(ncp)) {
                        i += 2;
                        std.debug.print("line {d} Prepend: {d} {d}\n", .{ line_no, i, char_start });
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
                            std.debug.print("line {d} Emoji-ZWJ: {d} {d}\n", .{ line_no, i, char_start });
                            emoji_seen = false;
                            continue;
                        }
                    }
                } else {
                    // Emoji marks new cluster.
                    if (prev != null and char_start < i_at_top) {
                        try got.append(try Zigchar.fromCodePoints(allocator, items[char_start..i_at_top]));
                        char_start = i_at_top;
                    }
                    emoji_seen = true;
                    std.debug.print("line {d} Emoji-not-seen: {d} {d}\n", .{ line_no, i, char_start });
                    continue;
                }
            }

            // GB12
            if (regional.isRegionalIndicator(cp)) {
                if (next) |ncp| {
                    if (regional.isRegionalIndicator(ncp)) {
                        // Only 2 code points in RI sequences.
                        if (prev != null and char_start < i_at_top) {
                            try got.append(try Zigchar.fromCodePoints(allocator, items[char_start..i_at_top]));
                            char_start = i_at_top;
                        }
                        i += 2;
                        std.debug.print("line {d} RI: {d} {d}\n", .{ line_no, i, char_start });
                        continue;
                    }
                }
            }

            // GB9 continued.
            if (cp != CR and cp != LF and !control.isControl(cp)) {
                if (next) |ncp| {
                    if (extend.isExtend(ncp) or spacing.isSpacingMark(ncp) or ncp == ZWJ) {
                        i += 1;
                        std.debug.print("line {d} Skip append: {d} {d}\n", .{ line_no, i, char_start });
                        continue;
                    }
                }
            }

            // GB999
            // Add any pending char.
            if (prev != null and char_start < i) {
                try got.append(try Zigchar.fromCodePoints(allocator, items[char_start..i]));
                char_start = i;
            }

            try got.append(try Zigchar.fromCodePoints(allocator, items[char_start .. i + 1]));
            i += 1;
            std.debug.print("line {d} Bottom: {d} {d}\n", .{ line_no, i, char_start });
            char_start = i;
        }

        // Any left over?
        if (char_start < i) {
            try got.append(try Zigchar.fromCodePoints(allocator, items[char_start..]));
        }
        /////////////////////////////////////////

        // Chaeck.
        for (want.items) |char, j| {
            expectEqualSlices(u8, char.bytes, got.items[j].bytes);
        }
    }
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
