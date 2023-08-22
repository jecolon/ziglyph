const std = @import("std");

const norm_props = @import("autogen/derived_normalization_props.zig");
const compressor = std.compress.deflate.compressor;

pub fn main() !void {
    const in_path = "src/data/tailor/allkeys.txt";
    const out_path = "src/data/tailor/allkeys-diffs.txt.deflate";

    const stdout = std.io.getStdOut().writer();
    try stdout.print("\nCompressing {s} into {s}\n", .{ in_path, out_path });
    try stdout.writeAll("To use with Ziglyph's Collator, place the resulting ");
    try stdout.print("{s} file in the src/data directory.\n", .{out_path});

    var cwd = std.fs.cwd();

    var in_file = try cwd.openFile(in_path, .{});
    defer in_file.close();
    var in_buf_read = std.io.bufferedReader(in_file.reader());
    const in_reader = in_buf_read.reader();

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    var out_file = try cwd.createFile(out_path, .{});
    defer out_file.close();
    var comp = try compressor(arena.allocator(), out_file.writer(), .{ .level = .best_compression });
    defer comp.deinit();
    const writer = comp.writer();

    var line_buf: [4096]u8 = undefined;
    var prev_cp: isize = 0;
    var prev_l1: isize = 0;

    lines: while (try in_reader.readUntilDelimiterOrEof(&line_buf, '\n')) |raw| {
        // Skip empty, version or comment lines.
        if (raw.len == 0 or raw[0] == '#') continue;
        if (std.mem.startsWith(u8, raw, "@version")) continue;

        // Remove trailing comments.
        var line = raw;
        if (std.mem.indexOf(u8, raw, " #")) |octo_index| {
            line = raw[0..octo_index];
        }

        // Handle implicit weights.
        if (std.mem.startsWith(u8, line, "@implicitweights")) {
            try writer.writeAll(line[17..22]); // Start
            try writer.writeByte(';');
            try writer.writeAll(line[24..29]); // End
            try writer.writeByte(';');
            try writer.writeAll(line[31..35]); // Base
            try writer.writeByte('\n');

            continue;
        }

        // Normal lines = code points ; elements
        var halves = std.mem.split(u8, line, ";");
        var cps_str = std.mem.trim(u8, halves.next().?, " ");

        // Code points
        var cps_str_iter = std.mem.split(u8, cps_str, " ");

        var i: usize = 0;
        while (cps_str_iter.next()) |cp_str| : (i += 1) {
            const cp = try std.fmt.parseInt(isize, cp_str, 16);

            if (i == 0) {
                if (!norm_props.isNfd(@intCast(cp))) continue :lines;
            } else {
                try writer.writeByte(' ');
            }

            try writer.print("{X}", .{cp - prev_cp});
            prev_cp = cp;
        }

        try writer.writeByte(';');

        //// Elements
        const elements_str = std.mem.trim(u8, halves.next().?, " [].* ");
        var element_str_iter = std.mem.split(u8, elements_str, "][");
        i = 0;
        while (element_str_iter.next()) |element_str| : (i += 1) {
            if (i != 0) try writer.writeByte(';');

            //if (std.mem.eql(u8, element_str, "0000.0000.0000")) {
            //    try writer.writeAll(")");
            //    continue;
            //}

            const trimmed_estr = if (std.mem.startsWith(u8, element_str, "0000."))
                element_str[3..]
            else if (std.mem.startsWith(u8, element_str, ".0000."))
                element_str[4..]
            else
                std.mem.trimLeft(u8, element_str, "*.0 ");

            var l1: isize = undefined;
            var l2: u16 = undefined;
            var l3: u8 = undefined;

            var weight_str_iter = std.mem.split(u8, trimmed_estr, ".");
            var j: usize = 0;
            while (weight_str_iter.next()) |weight_str| : (j += 1) {
                var trimmed_wstr = std.mem.trimLeft(u8, weight_str, "*.0");
                if (trimmed_wstr.len == 0) trimmed_wstr = "0";

                switch (j) {
                    0 => l1 = try std.fmt.parseInt(isize, trimmed_wstr, 16),
                    1 => l2 = try std.fmt.parseInt(u16, trimmed_wstr, 16),
                    2 => l3 = try std.fmt.parseInt(u8, trimmed_wstr, 16),
                    else => unreachable,
                }
            }

            try writer.print("{X}", .{l1 - prev_l1});
            prev_l1 = l1;

            if (l2 == 0x20 and l3 == 0x2) {
                continue;
            }

            if (l2 == 0x20) {
                try writer.print(".@{x}", .{l3});
                continue;
            }

            if (l2 == 0 and l3 == 0) {
                try writer.writeAll(".)");
                continue;
            }

            try writer.print(".{X}.{X}", .{ l2, l3 });
        }

        try writer.writeByte('\n');
    }

    try comp.flush();
    try comp.close();

    try stdout.writeAll("Done!\n");
}
