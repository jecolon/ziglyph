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
        const CGJ: u21 = 0x034F;
        const CR: u21 = 0x000D;
        const LF: u21 = 0x000A;

        var char_start: usize = 0;
        var i: usize = 0;
        while (i < len) : (i += 1) {
            const cp = items[i];
            const next: ?u21 = if (i < len - 1) items[i + 1] else null;
            const prev: ?u21 = if (i > 0) items[i - 1] else null;

            // Apply rules.
            if (extpic.isExtendedPictographic(cp)) {
                // GB11
                if (prev) |pcp| {
                    // GB9b
                    if (!prepend.isPrepend(pcp) and char_start < i) {
                        // Add previous.
                        try got.append(try Zigchar.fromCodePoints(allocator, items[char_start..i]));
                        char_start = i;
                    }
                }

                if (next) |ncp| {
                    var has_extend = false;
                    if (ncp == ZWJ) {
                        var j = i + 2;
                        if (j < len and extpic.isExtendedPictographic(items[j])) {
                            // Extpic + ZWJ + Extpic
                            i += 2;
                            var k = i + 1;
                            if (k < len and (extend.isExtend(items[k]) or spacing.isSpacingMark(items[k]))) {
                                // Possible run?
                                var l = k + 1;
                                while (l < len and (extend.isExtend(items[l]) or spacing.isSpacingMark(items[l]))) : (l += 1) {}
                                if (l > k + 1) i = l - 1 else i = k; // backup
                            }
                        } else {
                            // Extpic + ZWJ
                            i += 1;
                        }
                    } else if (extend.isExtend(ncp) or spacing.isSpacingMark(ncp)) {
                        // Possible run?
                        i += 1;
                        var j = i + 1; // known
                        while (j < len and (extend.isExtend(items[j]) or spacing.isSpacingMark(items[j]))) : (j += 1) {}
                        if (j > i + 1) i = j - 1; // backup
                        has_extend = true;
                    }

                    if (has_extend) {
                        var j = i + 1;
                        if (j < len and items[j] == ZWJ) {
                            // Maybe Extpic + Extend + ZWJ + Extpic?
                            j += 1;
                            if (j < len and extpic.isExtendedPictographic(items[j])) {
                                // Yes!
                                i += 2;
                                var k = i + 1;
                                if (k < len and (extend.isExtend(items[k]) or spacing.isSpacingMark(items[k]))) {
                                    // Possible run?
                                    var l = k + 1;
                                    while (l < len and (extend.isExtend(items[l]) or spacing.isSpacingMark(items[l]))) : (l += 1) {}
                                    if (l > k + 1) i = l - 1 else i = k; // backup
                                }
                            } else {
                                // No, Extpic + Extend + ZWJ only.
                                i += 1;
                            }
                        }
                    }
                }

                try got.append(try Zigchar.fromCodePoints(allocator, items[char_start .. i + 1]));
                char_start = i + 1;
                continue;
            }

            if (regional.isRegionalIndicator(cp)) {
                // GB12, GB13
                if (prev) |pcp| {
                    // GB9b
                    if (!prepend.isPrepend(pcp) and char_start < i) {
                        // Add previous.
                        try got.append(try Zigchar.fromCodePoints(allocator, items[char_start..i]));
                        char_start = i;
                    }
                }

                if (next) |ncp| {
                    // GB3
                    if (regional.isRegionalIndicator(ncp)) {
                        i += 1;
                        var j = i + 1; // i is known
                        if (j < len and (extend.isExtend(items[j]) or items[j] == ZWJ or spacing.isSpacingMark(items[j]))) {
                            // Possible run of extenders.
                            j += 1;
                            while (j < len and (extend.isExtend(items[j]) or items[j] == ZWJ or spacing.isSpacingMark(items[j]))) : (j += 1) {}
                            if (j > i + 1) i = j - 1; // backup
                        }
                    } else if (extend.isExtend(ncp) or ncp == ZWJ or spacing.isSpacingMark(ncp)) {
                        // Possible run of extenders.
                        i += 1;
                        var j = i + 1; // known
                        while (j < len and (extend.isExtend(items[j]) or items[j] == ZWJ or spacing.isSpacingMark(items[j]))) : (j += 1) {}
                        if (j > i + 1) i = j - 1; // backup
                    }
                }

                try got.append(try Zigchar.fromCodePoints(allocator, items[char_start .. i + 1]));
                char_start = i + 1;
                continue;
            }

            if (cp == CR or cp == LF) {
                // GB3, GB4, GB5
                if (char_start < i) {
                    // Add previous.
                    try got.append(try Zigchar.fromCodePoints(allocator, items[char_start..i]));
                }
                char_start = i;
                if (next) |ncp| {
                    // GB3
                    if (cp == CR and ncp == LF) i += 1;
                }
                try got.append(try Zigchar.fromCodePoints(allocator, items[char_start .. i + 1]));
                char_start = i + 1;
                continue;
            }

            if (control.isControl(cp)) {
                // GB4, GB5
                if (char_start < i) {
                    // Add previous.
                    try got.append(try Zigchar.fromCodePoints(allocator, items[char_start..i]));
                }
                char_start = i;
                try got.append(try Zigchar.fromCodePoints(allocator, items[char_start .. i + 1]));
                char_start = i + 1;
                continue;
            }

            if (han_map.syllableType(cp)) |hst| {
                // GB6, GB7, GB8
                if (prev) |pcp| {
                    // GB9b
                    if (!prepend.isPrepend(pcp) and char_start < i) {
                        // Add previous.
                        try got.append(try Zigchar.fromCodePoints(allocator, items[char_start..i]));
                        char_start = i;
                    }
                }

                if (next) |ncp| {
                    const ncp_hst = han_map.syllableType(ncp);
                    if (ncp_hst) |nhst| {
                        switch (hst) {
                            .L => {
                                if (nhst == .L or nhst == .V or nhst == .LV or nhst == .LVT) i += 1;
                            },
                            .LV, .V => {
                                if (nhst == .V or nhst == .T) i += 1;
                            },
                            .LVT, .T => {
                                if (nhst == .T) i += 1;
                            },
                        }
                    }
                }
            }

            if (next) |ncp| {
                // GB9, GB9a
                if (extend.isExtend(ncp) or ncp == ZWJ or spacing.isSpacingMark(ncp)) {
                    i += 1;
                    continue;
                }
            }

            if (prev != null) {
                // GB9, GB9a
                if (extend.isExtend(cp) or cp == ZWJ or spacing.isSpacingMark(cp)) {
                    continue;
                }
            }

            if (prepend.isPrepend(cp)) {
                // GB9b
                if (prev) |pcp| {
                    if (!prepend.isPrepend(pcp)) {
                        if (char_start < i) {
                            // Add previous.
                            try got.append(try Zigchar.fromCodePoints(allocator, items[char_start..i]));
                            char_start = i;
                        }
                    } else {
                        // Possible run?
                        i += 1; // known
                        while (i < len and prepend.isPrepend(items[i])) : (i += 1) {}
                        i -= 1; // backup
                    }
                }
                continue;
            }

            //if (regional.isRegionalIndicator(cp)) {
            //    // GB12, GB13
            //    if (prev) |pcp| {
            //        // GB9b
            //        if (!prepend.isPrepend(pcp) and !regional.isRegionalIndicator(pcp) and char_start < i) {
            //            // Add previous.
            //            try got.append(try Zigchar.fromCodePoints(allocator, items[char_start..i]));
            //            char_start = i;
            //        }
            //    }

            //    if (next) |ncp| {
            //        // GB9, GB9a
            //        if (regional.isRegionalIndicator(ncp)) {
            //            if (prev) |pcp| {
            //                if (regional.isRegionalIndicator(pcp)) {
            //                    // GB12, GB13
            //                    var ri_count: usize = 0;
            //                    var j = i - 1; // known
            //                    while (regional.isRegionalIndicator(items[j])) : (j -= 1) {
            //                        ri_count += 1;
            //                        if (j == 0) break;
            //                    }
            //                    // GB13
            //                    if (ri_count % 2 != 0) continue;
            //                } else {
            //                    // GB13 non-RI at sot.
            //                    continue;
            //                }
            //            } else {
            //                // GB12 at sot.
            //                continue;
            //            }
            //        }
            //    }

            //    //try got.append(try Zigchar.fromCodePoints(allocator, items[char_start .. i + 1]));
            //    //char_start = i + 1;
            //    //continue;
            //}

            // GB 999
            if (prev) |pcp| {
                // GB9b
                if (!prepend.isPrepend(pcp) and !regional.isRegionalIndicator(pcp) and char_start < i) {
                    // Add previous.
                    try got.append(try Zigchar.fromCodePoints(allocator, items[char_start..i]));
                    char_start = i;
                }
            }

            try got.append(try Zigchar.fromCodePoints(allocator, items[char_start .. i + 1]));
            char_start = i + 1;
        }

        // Add last one.
        if (char_start < i) {
            try got.append(try Zigchar.fromCodePoints(allocator, items[char_start..i]));
        }
        /////////////////////////////////////////

        // Chaeck.
        for (want.items) |char, j| {
            std.debug.print("line {d}: ({s}) -> ({s})\n", .{ line_no, char.bytes, got.items[j].bytes });
            expectEqualSlices(u8, char.bytes, got.items[j].bytes);
        }
    }
}
