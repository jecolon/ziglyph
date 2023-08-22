const std = @import("std");

const Collator = @import("collator/Collator.zig");
const Normalizer = @import("normalizer/Normalizer.zig");

test "UCD tests" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    var allocator = arena.allocator();

    var n = try Normalizer.init(allocator);
    defer n.deinit();

    var file = try std.fs.cwd().openFile("zig-cache/_ziglyph-data/ucd/NormalizationTest.txt", .{});
    defer file.close();
    var buf_reader = std.io.bufferedReader(file.reader());
    const input_stream = buf_reader.reader();

    var line_no: usize = 0;
    var buf: [4096]u8 = undefined;
    var cp_buf: [4]u8 = undefined;

    while (try input_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        line_no += 1;
        // Skip comments or empty lines.
        if (line.len == 0 or line[0] == '#' or line[0] == '@') continue;
        // Iterate over fields.
        var fields = std.mem.split(u8, line, ";");
        var field_index: usize = 0;
        var input: []u8 = undefined;
        defer allocator.free(input);

        while (fields.next()) |field| : (field_index += 1) {
            if (field_index == 0) {
                var i_buf = std.ArrayList(u8).init(allocator);
                defer i_buf.deinit();

                var i_fields = std.mem.split(u8, field, " ");
                while (i_fields.next()) |s| {
                    const icp = try std.fmt.parseInt(u21, s, 16);
                    const len = try std.unicode.utf8Encode(icp, &cp_buf);
                    try i_buf.appendSlice(cp_buf[0..len]);
                }

                input = try i_buf.toOwnedSlice();
            } else if (field_index == 1) {
                //std.debug.print("\n*** {s} ***\n", .{line});
                // NFC, time to test.
                var w_buf = std.ArrayList(u8).init(allocator);
                defer w_buf.deinit();

                var w_fields = std.mem.split(u8, field, " ");
                while (w_fields.next()) |s| {
                    const wcp = try std.fmt.parseInt(u21, s, 16);
                    const len = try std.unicode.utf8Encode(wcp, &cp_buf);
                    try w_buf.appendSlice(cp_buf[0..len]);
                }

                const want = w_buf.items;
                var got = try n.nfc(allocator, input);
                defer got.deinit();

                try std.testing.expectEqualStrings(want, got.slice);
            } else if (field_index == 2) {
                // NFD, time to test.
                var w_buf = std.ArrayList(u8).init(allocator);
                defer w_buf.deinit();

                var w_fields = std.mem.split(u8, field, " ");
                while (w_fields.next()) |s| {
                    const wcp = try std.fmt.parseInt(u21, s, 16);
                    const len = try std.unicode.utf8Encode(wcp, &cp_buf);
                    try w_buf.appendSlice(cp_buf[0..len]);
                }

                const want = w_buf.items;
                var got = try n.nfd(allocator, input);
                defer got.deinit();

                try std.testing.expectEqualStrings(want, got.slice);
            } else if (field_index == 3) {
                // NFKC, time to test.
                var w_buf = std.ArrayList(u8).init(allocator);
                defer w_buf.deinit();

                var w_fields = std.mem.split(u8, field, " ");
                while (w_fields.next()) |s| {
                    const wcp = try std.fmt.parseInt(u21, s, 16);
                    const len = try std.unicode.utf8Encode(wcp, &cp_buf);
                    try w_buf.appendSlice(cp_buf[0..len]);
                }

                const want = w_buf.items;
                var got = try n.nfkc(allocator, input);
                defer got.deinit();

                try std.testing.expectEqualStrings(want, got.slice);
            } else if (field_index == 4) {
                // NFKD, time to test.
                var w_buf = std.ArrayList(u8).init(allocator);
                defer w_buf.deinit();

                var w_fields = std.mem.split(u8, field, " ");
                while (w_fields.next()) |s| {
                    const wcp = try std.fmt.parseInt(u21, s, 16);
                    const len = try std.unicode.utf8Encode(wcp, &cp_buf);
                    try w_buf.appendSlice(cp_buf[0..len]);
                }

                const want = w_buf.items;
                var got = try n.nfkd(allocator, input);
                defer got.deinit();

                try std.testing.expectEqualStrings(want, got.slice);
            } else {
                continue;
            }
        }
    }
}

test "UCA tests" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    var allocator = arena.allocator();

    var collator = try Collator.init(allocator);
    defer collator.deinit();

    const uca_gz_file = try std.fs.cwd().openFile("src/data/CollationTest_NON_IGNORABLE_SHORT.txt.gz", .{});
    defer uca_gz_file.close();
    var uca_gzip_stream = try std.compress.gzip.decompress(allocator, uca_gz_file.reader());
    defer uca_gzip_stream.deinit();

    var uca_br = std.io.bufferedReader(uca_gzip_stream.reader());
    const uca_reader = uca_br.reader();

    // Skip header.
    var line_num: usize = 1;
    var buf: [4096]u8 = undefined;
    while (try uca_reader.readUntilDelimiterOrEof(&buf, '\n')) |line| : (line_num += 1) {
        if (line.len == 0) {
            line_num += 1;
            break;
        }
    }

    var prev_key: []const u16 = try allocator.alloc(u16, 1);
    var prev_nfd: Normalizer.Result = undefined;
    defer prev_nfd.deinit();
    var cp_buf: [4]u8 = undefined;

    lines: while (try uca_reader.readUntilDelimiterOrEof(&buf, '\n')) |raw| : (line_num += 1) {
        if (raw.len == 0 or raw[0] == '#') continue;

        var line = raw;

        if (std.mem.indexOf(u8, raw, ";")) |semi_index| {
            line = raw[0..semi_index];
        }

        //std.debug.print("line {d}: {s}\n", .{ line_no, line });
        var bytes = std.ArrayList(u8).init(allocator);
        defer bytes.deinit();

        var cp_strs = std.mem.split(u8, line, " ");

        while (cp_strs.next()) |cp_str| {
            const cp = try std.fmt.parseInt(u21, cp_str, 16);
            const len = std.unicode.utf8Encode(cp, &cp_buf) catch continue :lines; // Ignore surrogate errors in tests.
            try bytes.appendSlice(cp_buf[0..len]);
        }

        const current_key = try collator.sortKey(allocator, bytes.items);
        defer allocator.free(current_key);
        var current_nfd = try collator.normalizer.nfd(allocator, bytes.items);
        errdefer current_nfd.deinit();

        if (prev_key.len == 1) {
            allocator.free(prev_key);
            prev_key = try allocator.dupe(u16, current_key);
            prev_nfd = .{
                .allocator = allocator,
                .slice = try allocator.dupe(u8, current_nfd.slice),
            };
            continue;
        }

        const order = Collator.tertiaryOrder(prev_key, current_key);

        if (order == .gt) return error.PrevKeyGreater;

        // Identical sorting
        if (order == .eq) {
            const len = if (prev_nfd.slice.len > current_nfd.slice.len) current_nfd.slice.len else prev_nfd.slice.len;

            const tie_breaker = for (prev_nfd.slice[0..len], 0..) |prev_cp, i| {
                const cp_order = std.math.order(prev_cp, current_nfd.slice[i]);
                if (cp_order != .eq) break cp_order;
            } else .eq;

            if (tie_breaker == .gt) return error.PrevNfdGreater;

            if (tie_breaker == .eq and prev_nfd.slice.len > current_nfd.slice.len) return error.PrevNfdLonger;
        }

        allocator.free(prev_key);
        prev_key = try allocator.dupe(u16, current_key);
        prev_nfd.deinit();
        prev_nfd = .{
            .allocator = allocator,
            .slice = try allocator.dupe(u8, current_nfd.slice),
        };
    }
}
