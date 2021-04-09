const std = @import("std");

const ArrayList = std.ArrayList;
const fmt = std.fmt;
const io = std.io;
const mem = std.mem;

const Collection = @import("Collection.zig");
const Record = @import("record.zig").Record;
const ascii = @import("ascii.zig");

const UcdGenerator = struct {
    allocator: *mem.Allocator,

    pub fn new(allocator: *mem.Allocator) UcdGenerator {
        return UcdGenerator{
            .allocator = allocator,
        };
    }

    const Self = @This();

    // Files with the code point type in field index 1.
    fn processF1(self: *Self, path: []const u8) !void {
        // Setup input.
        var file = try std.fs.cwd().openFile(path, .{});
        defer file.close();
        var buf_reader = io.bufferedReader(file.reader());
        var input_stream = buf_reader.reader();

        // Iterate over lines.
        var buf: [640]u8 = undefined;
        var collections = ArrayList(Collection).init(self.allocator);
        defer {
            for (collections.items) |*collection| {
                collection.deinit();
            }
            collections.deinit();
        }
        var records = ArrayList(Record).init(self.allocator);
        defer records.deinit();
        var kind = ArrayList(u8).init(self.allocator);
        defer kind.deinit();
        while (try input_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
            // Skip comments or empty lines.
            if (line.len == 0 or line[0] == '#') continue;
            // Iterate over fields.
            var fields = mem.split(line, ";");
            var field_index: usize = 0;
            var record: Record = undefined;
            while (fields.next()) |raw| : (field_index += 1) {
                var field = mem.trim(u8, raw, " ");
                // Skip empty or comment fields.
                if (field.len == 0 or field[0] == '#') continue;
                // Construct record.
                if (field_index == 0) {
                    if (mem.indexOf(u8, field, "..")) |dots| {
                        // Ranges.
                        const r_lo = try fmt.parseInt(u21, field[0..dots], 16);
                        const r_hi = try fmt.parseInt(u21, field[dots + 2 ..], 16);
                        record = .{ .range = .{ .lo = r_lo, .hi = r_hi } };
                    } else {
                        const code_point = try fmt.parseInt(u21, field, 16);
                        record = .{ .single = code_point };
                    }
                    // Add this record.
                    try records.append(record);
                } else if (field_index == 1) {
                    // Record kind.
                    // Possible comment at end.
                    if (mem.indexOf(u8, field, "#")) |octo| {
                        field = mem.trimRight(u8, field[0..octo], " ");
                    }
                    // Check if new collection started.
                    if (kind.items.len != 0) {
                        if (!mem.eql(u8, kind.items, field)) {
                            // New collection for new record kind.
                            // Last record belongs to next collection.
                            const one_past = records.pop();
                            // Calculate lo/hi.
                            var lo: u21 = 0x10FFFF;
                            var hi: u21 = 0;
                            for (records.items) |rec| {
                                switch (rec) {
                                    .single => |cp| {
                                        if (cp < lo) lo = cp;
                                        if (cp > hi) hi = cp;
                                    },
                                    .range => |range| {
                                        if (range.lo < lo) lo = range.lo;
                                        if (range.hi > hi) hi = range.hi;
                                    },
                                }
                            }
                            try collections.append(try Collection.init(
                                self.allocator,
                                kind.toOwnedSlice(),
                                lo,
                                hi,
                                records.toOwnedSlice(),
                            ));
                            // Update kind.
                            try kind.appendSlice(field);
                            // Add first record of new collection.
                            try records.append(one_past);
                        }
                    } else {
                        // Initialize kind.
                        try kind.appendSlice(field);
                    }
                } else {
                    continue;
                }
            }
        }

        // Write out files.
        var dir = std.fs.path.basename(path);
        const dot = mem.lastIndexOf(u8, dir, ".");
        if (dot) |d| dir = dir[0..d];
        for (collections.items) |*collection| {
            try collection.writeFile(dir);
        }
    }

    // data/ucd/extracted/DerivedGeneralCategory.txt
    fn processGenCat(self: *Self) !void {
        // Setup input.
        var file = try std.fs.cwd().openFile("data/ucd/extracted/DerivedGeneralCategory.txt", .{});
        defer file.close();
        var buf_reader = io.bufferedReader(file.reader());
        var input_stream = buf_reader.reader();

        // Iterate over lines.
        var buf: [640]u8 = undefined;
        var collections = ArrayList(Collection).init(self.allocator);
        defer {
            for (collections.items) |*collection| {
                collection.deinit();
            }
            collections.deinit();
        }
        var records = ArrayList(Record).init(self.allocator);
        defer records.deinit();
        var kind = ArrayList(u8).init(self.allocator);
        defer kind.deinit();
        var lo: u21 = 0x10FFFF;
        var hi: u21 = 0;
        while (try input_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
            // Skip empty lines.
            if (line.len == 0) continue;

            if (mem.indexOf(u8, line, "General_Category=")) |_| {
                // Record kind.
                const equals = mem.indexOf(u8, line, "=").?;
                const current_kind = mem.trim(u8, line[equals + 1 ..], " ");
                // Check if new collection started.
                if (kind.items.len != 0) {
                    // New collection for new record kind.
                    if (!mem.eql(u8, kind.items, current_kind)) {
                        try collections.append(try Collection.init(
                            self.allocator,
                            kind.toOwnedSlice(),
                            lo,
                            hi,
                            records.toOwnedSlice(),
                        ));
                        // Reset extremes.
                        lo = 0x10FFFF;
                        hi = 0;
                        // Update kind.
                        try kind.appendSlice(current_kind);
                    }
                } else {
                    // Initialize kind.
                    try kind.appendSlice(current_kind);
                }
            }
            // Iterate over fields.
            var fields = mem.split(line, ";");
            var field_index: usize = 0;
            var record: Record = undefined;
            while (fields.next()) |raw| : (field_index += 1) {
                var field = mem.trim(u8, raw, " ");
                // Skip empty or comment fields.
                if (field.len == 0 or field[0] == '#') continue;
                // Construct record.
                if (field_index == 0) {
                    // Ranges.
                    if (mem.indexOf(u8, field, "..")) |dots| {
                        const r_lo = try fmt.parseInt(u21, field[0..dots], 16);
                        if (r_lo < lo) lo = r_lo;
                        const r_hi = try fmt.parseInt(u21, field[dots + 2 ..], 16);
                        if (r_hi > hi) hi = r_hi;
                        record = .{ .range = .{ .lo = r_lo, .hi = r_hi } };
                    } else {
                        const code_point = try fmt.parseInt(u21, field, 16);
                        if (code_point < lo) lo = code_point;
                        if (code_point > hi) hi = code_point;
                        record = .{ .single = code_point };
                    }
                    // Add this record.
                    try records.append(record);
                } else {
                    continue;
                }
            }
        }

        // Write out files.
        for (collections.items) |*collection| {
            try collection.writeFile("DerivedGeneralCategory");
        }
    }

    // data/ucd/CaseFolding.txt
    fn processCaseFold(self: *Self) !void {
        // Setup input.
        var in_file = try std.fs.cwd().openFile("data/ucd/CaseFolding.txt", .{});
        defer in_file.close();
        var buf_reader = io.bufferedReader(in_file.reader());
        var input_stream = buf_reader.reader();
        // Setup output.
        const header_tpl = @embedFile("parts/fold_map_header_tpl.txt");
        const trailer_tpl = @embedFile("parts/fold_map_trailer_tpl.txt");
        var cwd = std.fs.cwd();
        cwd.makeDir("components/CaseFolding") catch |err| switch (err) {
            error.PathAlreadyExists => {},
            else => return err,
        };
        var out_file = try cwd.createFile("components/CaseFolding/CaseFoldMap.zig", .{});
        defer out_file.close();
        var buf_writer = io.bufferedWriter(out_file.writer());
        const writer = buf_writer.writer();
        _ = try writer.print(header_tpl, .{});

        // Iterate over lines.
        var buf: [640]u8 = undefined;
        while (try input_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
            // Skip comments or empty lines.
            if (line.len == 0 or line[0] == '#') continue;
            // Iterate over fields.
            var fields = mem.split(line, ";");
            var field_index: usize = 0;
            var code_point: []const u8 = undefined;
            var select = false;
            while (fields.next()) |raw| : (field_index += 1) {
                if (field_index == 0) {
                    // Code point.
                    code_point = raw;
                } else if (field_index == 1) {
                    if (mem.endsWith(u8, raw, " C") or mem.endsWith(u8, raw, " F")) select = true;
                } else if (field_index == 2) {
                    if (select) {
                        // Mapping.
                        var field = mem.trim(u8, raw, " ");
                        var cp_iter = mem.split(field, " ");
                        _ = try writer.print("    try instance.map.put(0x{s}, &[_]u21{{\n", .{code_point});
                        while (cp_iter.next()) |cp| {
                            _ = try writer.print("        0x{s},\n", .{cp});
                        }
                        _ = try writer.write("    });\n");
                        select = false;
                    }
                } else {
                    continue;
                }
            }
        }

        // Finish writing.
        _ = try writer.print(trailer_tpl, .{});
        try buf_writer.flush();
    }

    // data/ucd/UnicodeData.txt
    fn processUcd(self: *Self) !void {
        // Setup input.
        var in_file = try std.fs.cwd().openFile("data/ucd/UnicodeData.txt", .{});
        defer in_file.close();
        var buf_reader = io.bufferedReader(in_file.reader());
        var input_stream = buf_reader.reader();
        // Output directory.
        var cwd = std.fs.cwd();
        cwd.makeDir("components/UnicodeData") catch |err| switch (err) {
            error.PathAlreadyExists => {},
            else => return err,
        };
        // Templates.
        const decomp_header_tpl = @embedFile("parts/decomp_map_header_tpl.txt");
        const decomp_trailer_tpl = @embedFile("parts/decomp_map_trailer_tpl.txt");
        const map_header_tpl = @embedFile("parts/map_header_tpl.txt");
        const map_trailer_tpl = @embedFile("parts/map_trailer_tpl.txt");
        // Setup output.
        var d_file = try cwd.createFile("components/UnicodeData/DecomposeMap.zig", .{});
        defer d_file.close();
        var d_buf = io.bufferedWriter(d_file.writer());
        const d_writer = d_buf.writer();
        var l_file = try cwd.createFile("components/UnicodeData/LowerMap.zig", .{});
        defer l_file.close();
        var l_buf = io.bufferedWriter(l_file.writer());
        const l_writer = l_buf.writer();
        var t_file = try cwd.createFile("components/UnicodeData/TitleMap.zig", .{});
        defer t_file.close();
        var t_buf = io.bufferedWriter(t_file.writer());
        const t_writer = t_buf.writer();
        var u_file = try cwd.createFile("components/UnicodeData/UpperMap.zig", .{});
        defer u_file.close();
        var u_buf = io.bufferedWriter(u_file.writer());
        const u_writer = u_buf.writer();

        // Headers.
        _ = try d_writer.print(decomp_header_tpl, .{});
        _ = try l_writer.print(map_header_tpl, .{"LowerMap"});
        _ = try t_writer.print(map_header_tpl, .{"TitleMap"});
        _ = try u_writer.print(map_header_tpl, .{"UpperMap"});

        // Iterate over lines.
        var buf: [640]u8 = undefined;
        while (try input_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
            // Iterate over fields.
            var fields = mem.split(line, ";");
            var field_index: usize = 0;
            var code_point: []const u8 = undefined;
            while (fields.next()) |raw| : (field_index += 1) {
                if (field_index == 0) {
                    // Code point.
                    code_point = raw;
                } else if (field_index == 5 and raw.len != 0) {
                    // Decomposition.
                    var cp_iter = mem.split(raw, " ");
                    _ = try d_writer.print("    try instance.map.put(0x{s}, &[_]u21{{\n", .{code_point});
                    while (cp_iter.next()) |cp| {
                        if (mem.startsWith(u8, cp, "<")) continue;
                        _ = try d_writer.print("        0x{s},\n", .{cp});
                    }
                    _ = try d_writer.write("    });\n");
                } else if (field_index == 12 and raw.len != 0) {
                    // Uppercase mapping.
                    _ = try u_writer.print("    try instance.map.put(0x{s}, 0x{s});\n", .{ code_point, raw });
                } else if (field_index == 13 and raw.len != 0) {
                    // Lowercase mapping.
                    _ = try l_writer.print("    try instance.map.put(0x{s}, 0x{s});\n", .{ code_point, raw });
                } else if (field_index == 14 and raw.len != 0) {
                    // Titlecase mapping.
                    _ = try t_writer.print("    try instance.map.put(0x{s}, 0x{s});\n", .{ code_point, raw });
                } else {
                    continue;
                }
            }
        }

        // Finish writing.
        _ = try d_writer.print(decomp_trailer_tpl, .{});
        _ = try l_writer.print(map_trailer_tpl, .{ "Lower", "LowerMap" });
        _ = try t_writer.print(map_trailer_tpl, .{ "Title", "TitleMap" });
        _ = try u_writer.print(map_trailer_tpl, .{ "Upper", "UpperMap" });
        try d_buf.flush();
        try l_buf.flush();
        try t_buf.flush();
        try u_buf.flush();
    }

    // data/ucd/SpecialCassing.txt
    fn processSpecialCasing(self: *Self) !void {
        // Setup input.
        var in_file = try std.fs.cwd().openFile("data/ucd/SpecialCasing.txt", .{});
        defer in_file.close();
        var buf_reader = io.bufferedReader(in_file.reader());
        var input_stream = buf_reader.reader();
        // Setup output.
        const header_tpl = @embedFile("parts/special_case_header_tpl.txt");
        const trailer_tpl = @embedFile("parts/special_case_trailer_tpl.txt");
        var cwd = std.fs.cwd();
        cwd.makeDir("components/SpecialCasing") catch |err| switch (err) {
            error.PathAlreadyExists => {},
            else => return err,
        };
        var out_file = try cwd.createFile("components/SpecialCasing/SpecialCaseMap.zig", .{});
        defer out_file.close();
        var buf_writer = io.bufferedWriter(out_file.writer());
        const writer = buf_writer.writer();
        _ = try writer.print(header_tpl, .{});

        // Iterate over lines.
        var buf: [640]u8 = undefined;
        while (try input_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
            // Skip comments or empty lines.
            if (line.len == 0 or line[0] == '#') continue;
            // Iterate over fields.
            var fields = mem.split(line, ";");
            var field_index: usize = 0;
            var code_point: []const u8 = undefined;
            var mappings: [3][][]const u8 = undefined;
            while (fields.next()) |raw| : (field_index += 1) {
                var field = mem.trim(u8, raw, " ");
                if (field_index == 0) {
                    // Code point.
                    code_point = field;
                } else if (field_index == 1) {
                    // Lowercase.
                    var cp_iter = mem.split(field, " ");
                    var cp_list = ArrayList([]const u8).init(self.allocator);
                    while (cp_iter.next()) |cp| {
                        try cp_list.append(cp);
                    }
                    mappings[0] = cp_list.toOwnedSlice();
                } else if (field_index == 2) {
                    // Titlecase.
                    var cp_iter = mem.split(field, " ");
                    var cp_list = ArrayList([]const u8).init(self.allocator);
                    while (cp_iter.next()) |cp| {
                        try cp_list.append(cp);
                    }
                    mappings[1] = cp_list.toOwnedSlice();
                } else if (field_index == 3) {
                    // Uppercase.
                    var cp_iter = mem.split(field, " ");
                    var cp_list = ArrayList([]const u8).init(self.allocator);
                    while (cp_iter.next()) |cp| {
                        try cp_list.append(cp);
                    }
                    mappings[2] = cp_list.toOwnedSlice();
                } else if (field_index == 4) {
                    _ = try writer.print("    try instance.map.put(0x{s}, .{{\n", .{code_point});
                    if (field.len == 0 or field[0] == '#') {
                        // No countries or conditions.
                        _ = try writer.write("        .countries = &[0][]u8{},\n");
                        _ = try writer.write("        .conditions = &[0][]u8{},\n");
                    } else {
                        // Countries and/or conditions.
                        var countries_started = false;
                        var conditions_started = false;
                        var coco_iter = mem.split(field, " ");
                        while (coco_iter.next()) |cc| {
                            if (ascii.isLower(cc[0])) {
                                // Country code.
                                if (!countries_started) {
                                    _ = try writer.write("        .countries = &[_][]u8{\n");
                                    countries_started = true;
                                }
                                _ = try writer.print("            \"{s}\",\n", .{cc});
                            } else {
                                // Conditions.
                                if (countries_started) {
                                    _ = try writer.write("        },\n");
                                    countries_started = false;
                                }
                                if (!conditions_started) {
                                    _ = try writer.write("        .conditions = &[_][]u8{\n");
                                    conditions_started = true;
                                }
                                _ = try writer.print("            \"{s}\",\n", .{cc});
                            }
                        }
                        if (countries_started) {
                            _ = try writer.write("        },\n");
                        }
                        if (conditions_started) {
                            _ = try writer.write("        },\n");
                        }
                    }
                    // Mappings.
                    _ = try writer.write("        .mappings = [3][]u8{\n");
                    for (mappings) |cmaps| {
                        if (cmaps.len == 0) {
                            // No mapping.
                            _ = try writer.write("            &[0]u8{},\n");
                        } else {
                            _ = try writer.write("            &[_]u8{ ");
                            for (cmaps) |mcp, i| {
                                if (mcp.len == 0) continue;
                                if (i != 0) {
                                    _ = try writer.write(", ");
                                }
                                _ = try writer.print("0x{s}", .{mcp});
                            }
                            _ = try writer.write(" },\n");
                        }
                    }
                    _ = try writer.write("        },\n    });\n");
                } else {
                    continue;
                }
            }
        }

        // Finish writing.
        _ = try writer.print(trailer_tpl, .{});
        try buf_writer.flush();
    }
};

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    var allocator = &arena.allocator;
    // var allocator = std.testing.allocator;
    var ugen = UcdGenerator.new(allocator);
    try ugen.processF1("data/ucd/Blocks.txt");
    try ugen.processF1("data/ucd/PropList.txt");
    try ugen.processF1("data/ucd/Scripts.txt");
    try ugen.processF1("data/ucd/auxiliary/GraphemeBreakProperty.txt");
    try ugen.processF1("data/ucd/DerivedCoreProperties.txt");
    try ugen.processF1("data/ucd/extracted/DerivedDecompositionType.txt");
    try ugen.processF1("data/ucd/extracted/DerivedNumericType.txt");
    try ugen.processGenCat();
    try ugen.processCaseFold();
    try ugen.processUcd();
    try ugen.processSpecialCasing();
}
