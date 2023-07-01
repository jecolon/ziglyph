const std = @import("std");

const norm_props = @import("ziglyph.zig").derived_normalization_props;

fn makeStripped() !void {
    var in_file = try std.fs.cwd().openFile("allkeys.txt", .{});
    defer in_file.close();
    var in_buf_read = std.io.bufferedReader(in_file.reader());
    const in_reader = in_buf_read.reader();

    var out_file = try std.fs.cwd().createFile("allkeys-strip.txt", .{});
    defer out_file.close();
    var bw = std.io.bufferedWriter(out_file.writer());
    defer bw.flush() catch unreachable;
    const writer = bw.writer();

    var line_buf: [4096]u8 = undefined;

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
            const cp = try std.fmt.parseInt(u21, cp_str, 16);

            if (i == 0) {
                if (!norm_props.isNfd(cp)) continue :lines;
            } else {
                try writer.writeByte(' ');
            }

            try writer.print("{X}", .{cp});
        }

        try writer.writeByte(';');

        //// Elements
        const elements_str = std.mem.trim(u8, halves.next().?, " [].* ");
        var element_str_iter = std.mem.split(u8, elements_str, "][");
        i = 0;
        while (element_str_iter.next()) |element_str| : (i += 1) {
            if (i != 0) try writer.writeByte(';');

            if (std.mem.eql(u8, element_str, "0000.0000.0000")) {
                try writer.writeAll("0.0.0");
                continue;
            }

            const trimmed_estr = if (std.mem.startsWith(u8, element_str, "0000."))
                element_str[3..]
            else if (std.mem.startsWith(u8, element_str, ".0000."))
                element_str[4..]
            else
                std.mem.trimLeft(u8, element_str, "*.0 ");

            var weight_str_iter = std.mem.split(u8, trimmed_estr, ".");
            var j: usize = 0;
            while (weight_str_iter.next()) |weight_str| : (j += 1) {
                if (j != 0) try writer.writeByte('.');
                var trimmed_wstr = std.mem.trimLeft(u8, weight_str, "*.0");
                if (trimmed_wstr.len == 0) trimmed_wstr = "0";
                try writer.writeAll(trimmed_wstr);
            }
        }

        try writer.writeByte('\n');
    }
}

fn makeDiffs() !void {
    var in_file = try std.fs.cwd().openFile("allkeys.txt", .{});
    defer in_file.close();
    var in_buf_read = std.io.bufferedReader(in_file.reader());
    const in_reader = in_buf_read.reader();

    var out_file = try std.fs.cwd().createFile("allkeys-diffs.txt", .{});
    defer out_file.close();
    var bw = std.io.bufferedWriter(out_file.writer());
    defer bw.flush() catch unreachable;
    const writer = bw.writer();

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
                if (!norm_props.isNfd(@as(u21, @intCast(cp)))) continue :lines;
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
}

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    try stdout.writeAll("Processing allkeys.txt into allkeys-strip.txt and allkeys-diffs.txt\n");
    try stdout.writeAll("To use with Ziglyph's Collator, compress allkeys-diffs.txt with:\n");
    try stdout.writeAll("$ gzip -9 allkeys-diffs.txt\n");
    try stdout.writeAll("Then put the resulting allkeys-diffs.txt.gz file in:\n");
    try stdout.writeAll("/<path to ziglyph source>/src/data/uca/\n");

    try makeStripped();
    try makeDiffs();
}
