const std = @import("std");

// A line in a Unicode data file.
const Record = union(enum) {
    single: u21,
    range: struct { hi: u21, lo: u21 },

    fn parse(field: []const u8) !Record {
        if (std.mem.indexOf(u8, field, "..")) |dots| {
            // Ranges.
            const r_lo = try std.fmt.parseInt(u21, field[0..dots], 16);
            const r_hi = try std.fmt.parseInt(u21, field[dots + 2 ..], 16);
            return Record{ .range = .{ .hi = r_hi, .lo = r_lo } };
        } else {
            // Single code point.
            const code_point = try std.fmt.parseInt(u21, field, 16);
            return Record{ .single = code_point };
        }
    }
};

// A collection of Records.
const Collection = struct {
    hi: u21,
    lo: u21,
    name: []const u8,
    records: []Record,
};

// Files with the code point type in field index 1.
fn processF1(input_path: []const u8, output_path: []const u8) !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    std.log.info("Processing {s} -> {s} ...", .{ input_path, output_path });

    var cwd = std.fs.cwd();

    // Skip if output already exists.
    if (cwd.access(output_path, .{})) {
        std.log.debug("\tSkipping existing file: {s}", .{output_path});
        return;
    } else |_| {}

    // Prepare input.
    var file = try cwd.openFile(input_path, .{});
    defer file.close();
    var buf_reader = std.io.bufferedReader(file.reader());
    const reader = buf_reader.reader();

    // Prepare data structures.
    var collections = std.ArrayList(Collection).init(allocator);
    var records = std.ArrayList(Record).init(allocator);

    // Iter state
    var kind: ?[]const u8 = null;
    var buf: [4096]u8 = undefined;

    // Iterate over lines.
    while (try reader.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        // Skip comments or empty lines.
        if (line.len == 0 or line[0] == '#') continue;

        // Iterate over fields.
        var fields_iter = std.mem.splitScalar(u8, line, ';');
        var field_index: usize = 0;

        while (fields_iter.next()) |orig_field| : (field_index += 1) {
            var trimmed_field = std.mem.trim(u8, orig_field, " ");

            if (field_index == 0) {
                // Add new record.
                try records.append(try Record.parse(trimmed_field));
            } else if (field_index == 1) {
                // Record kind.
                // Possible comment at end.
                if (std.mem.indexOf(u8, trimmed_field, "#")) |octo|
                    trimmed_field = std.mem.trimRight(u8, trimmed_field[0..octo], " ");

                // Check if at new collection start.
                if (kind) |k| {
                    if (!std.mem.eql(u8, k, trimmed_field)) {
                        // New collection for new record kind.
                        // Last record belongs to new collection.
                        const one_past = records.pop();
                        const bounds = calcBounds(records.items);

                        // Add new collection.
                        try collections.append(.{
                            .hi = bounds[1],
                            .lo = bounds[0],
                            .name = k,
                            .records = try records.toOwnedSlice(),
                        });

                        // Update kind.
                        kind = try allocator.dupe(u8, trimmed_field);
                        // Add first record of new collection.
                        try records.append(one_past);
                    }
                } else {
                    // kind is null, initialize it.
                    kind = try allocator.dupe(u8, trimmed_field);
                }
            } else {
                // Ignore other fields.
                continue;
            }
        }
    }

    // Last collection.
    if (kind) |k| {
        // Calculate lo/hi.
        const bounds = calcBounds(records.items);

        try collections.append(.{
            .hi = bounds[1],
            .lo = bounds[0],
            .name = k,
            .records = try records.toOwnedSlice(),
        });
    }

    try writeFile(collections.items, output_path);
}

fn cleanName(name: []const u8, buf: []u8) []const u8 {
    var written: usize = 0;
    var should_upper = true;

    for (name) |byte| {
        if (' ' == byte or '_' == byte or '-' == byte) {
            should_upper = true;
            continue;
        }

        if (should_upper) {
            buf[written] = if (byte >= 'a' and byte <= 'z') byte ^ 32 else byte;
            should_upper = false;
        } else {
            buf[written] = if (byte >= 'A' and byte <= 'Z') byte ^ 32 else byte;
        }

        written += 1;
    }

    return buf[0..written];
}

fn calcBounds(records: []const Record) [2]u21 {
    // Calculate lo/hi.
    var lo: u21 = 0x10FFFF;
    var hi: u21 = 0;

    for (records) |rec| {
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

    return .{ lo, hi };
}

fn writeFile(collections: []Collection, filepath: []const u8) !void {
    var out_file = try std.fs.cwd().createFile(filepath, .{});
    defer out_file.close();
    var buf_writer = std.io.bufferedWriter(out_file.writer());
    const writer = buf_writer.writer();

    try writer.writeAll("// Autogenerated from https://www.unicode.org/Public/15.0.0/ucd/\n");
    var fn_name_buf: [256]u8 = undefined;

    for (collections) |collection| {
        // Prepare function name.
        const fn_name = cleanName(collection.name, &fn_name_buf);

        // Write data.
        if (collection.lo == collection.hi) {
            _ = try writer.print("\npub fn is{s}(cp: u21) bool {{\n", .{fn_name});
            _ = try writer.print("return cp == 0x{x};\n", .{collection.lo});
            try writer.writeAll("}\n");
        } else {
            _ = try writer.print(
                \\
                \\pub fn is{s}(cp: u21) bool {{
                \\
            , .{fn_name});

            if (collection.lo == 0) {
                _ = try writer.print("if (cp > 0x{x}) return false;\n", .{collection.hi});
            } else {
                _ = try writer.print("if (cp < 0x{x} or cp > 0x{x}) return false;\n", .{ collection.lo, collection.hi });
            }

            try writer.writeAll(
                \\
                \\    return switch (cp) {
                \\
            );

            for (collection.records) |record| {
                switch (record) {
                    .single => |cp| {
                        _ = try writer.print("0x{x} => true,\n", .{cp});
                    },
                    .range => |range| {
                        _ = try writer.print("0x{x}...0x{x} => true,\n", .{ range.lo, range.hi });
                    },
                }
            }

            try writer.writeAll("else => false,\n};\n}\n");
        }

        try buf_writer.flush();
    }
}

// Trim leading zeroes
fn tlz(s: []const u8) []const u8 {
    return std.mem.trimLeft(u8, s, "0");
}

// UnicodeData.txt
fn processUcd() !void {
    std.log.info("Processing zig-cache/_ziglyph-data/ucd/UnicodeData.txt -> various files...", .{});

    const cwd = std.fs.cwd();

    // Prepare input.
    var file = try cwd.openFile("zig-cache/_ziglyph-data/ucd/UnicodeData.txt", .{});
    defer file.close();
    var buf_reader = std.io.bufferedReader(file.reader());
    const reader = buf_reader.reader();

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    // Setup output.
    // Canonical compositions
    const compressor = std.compress.deflate.compressor;
    var nfc_file = try cwd.createFile("src/autogen/canonical_compositions.txt.deflate", .{});
    defer nfc_file.close();
    var nfc_comp = try compressor(arena.allocator(), nfc_file.writer(), .{ .level = .best_compression });
    defer nfc_comp.deinit();
    const nfc_writer = nfc_comp.writer();

    // Canonical decompositions
    var nfd_file = try cwd.createFile("src/autogen/canonical_decompositions.txt.deflate", .{});
    defer nfd_file.close();
    var nfd_comp = try compressor(arena.allocator(), nfd_file.writer(), .{ .level = .best_compression });
    defer nfd_comp.deinit();
    const nfd_writer = nfd_comp.writer();

    // Compatibility decompositions
    var nfkd_file = try cwd.createFile("src/autogen/compatibility_decompositions.txt.deflate", .{});
    defer nfkd_file.close();
    var nfkd_comp = try compressor(arena.allocator(), nfkd_file.writer(), .{ .level = .best_compression });
    defer nfkd_comp.deinit();
    const nfkd_writer = nfkd_comp.writer();

    // Lowercase map
    var l_file = try cwd.createFile("src/autogen/lower_map.zig", .{});
    defer l_file.close();
    var l_buf = std.io.bufferedWriter(l_file.writer());
    const l_writer = l_buf.writer();

    // Titlecase map
    var t_file = try cwd.createFile("src/autogen/title_map.zig", .{});
    defer t_file.close();
    var t_buf = std.io.bufferedWriter(t_file.writer());
    const t_writer = t_buf.writer();

    // Uppercase map
    var u_file = try cwd.createFile("src/autogen/upper_map.zig", .{});
    defer u_file.close();
    var u_buf = std.io.bufferedWriter(u_file.writer());
    const u_writer = u_buf.writer();

    // Headers.
    const map_header =
        \\// Autogenerated from https://www.unicode.org/Public/15.0.0/ucd/
        \\
        \\pub fn to{s}(cp: u21) u21 {{
        \\    return switch (cp) {{
        \\
    ;
    _ = try l_writer.print(map_header, .{"Lower"});
    _ = try t_writer.print(map_header, .{"Title"});
    _ = try u_writer.print(map_header, .{"Upper"});

    var buf: [4096]u8 = undefined;

    // Iterate over lines.
    while (try reader.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        // Iterate over fields.
        var fields_iter = std.mem.splitScalar(u8, line, ';');
        var field_index: usize = 0;
        var code_point: []const u8 = undefined;

        while (fields_iter.next()) |orig_field| : (field_index += 1) {
            if (field_index == 0) {
                // Code point.
                code_point = orig_field;
            } else if (field_index == 5 and orig_field.len != 0) {
                // Canonical compositions / decompositions
                const is_nfd = orig_field[0] != '<';

                var cp_iter = std.mem.splitScalar(u8, orig_field, ' ');
                if (!is_nfd) _ = cp_iter.next(); // <compat>

                var code_points: [18][]const u8 = .{""} ** 18;
                var i: usize = 0;

                while (cp_iter.next()) |cp| : (i += 1) {
                    code_points[i] = cp;
                }

                if (is_nfd) {
                    if (i == 1) {
                        // Canonical decomposition
                        _ = try nfd_writer.print("{s};{s};0\n", .{ tlz(code_point), tlz(code_points[0]) });
                    } else if (i == 2) {
                        // Canonical Composition
                        _ = try nfc_writer.print("{s};{s};{s}\n", .{
                            tlz(code_points[0]),
                            tlz(code_points[1]),
                            tlz(code_point),
                        });

                        // Canonical decomposition
                        _ = try nfd_writer.print("{s};{s};{s}\n", .{
                            tlz(code_point),
                            tlz(code_points[0]),
                            tlz(code_points[1]),
                        });
                    }
                } else {
                    // Compatibility decomposition
                    _ = try nfkd_writer.print("{s};", .{tlz(code_point)});

                    for (code_points, 0..) |cp, j| {
                        if (cp.len == 0) break;
                        if (j != 0) try nfkd_writer.writeByte(';');
                        _ = try nfkd_writer.print("{s}", .{tlz(cp)});
                    }

                    try nfkd_writer.writeAll("\n");
                }
            } else if (field_index == 12 and orig_field.len != 0) {
                // Uppercase mapping.
                _ = try u_writer.print("0x{s} => 0x{s},\n", .{ tlz(code_point), tlz(orig_field) });
            } else if (field_index == 13 and orig_field.len != 0) {
                // Lowercase mapping.
                _ = try l_writer.print("0x{s} => 0x{s},\n", .{ tlz(code_point), tlz(orig_field) });
            } else if (field_index == 14 and orig_field.len != 0) {
                // Titlecase mapping.
                _ = try t_writer.print("0x{s} => 0x{s},\n", .{ tlz(code_point), tlz(orig_field) });
            } else {
                continue;
            }
        }
    }

    // Finish writing.
    try l_writer.writeAll("else => cp,\n};\n}");
    try t_writer.writeAll("else => cp,\n};\n}");
    try u_writer.writeAll("else => cp,\n};\n}");

    // Flush buffers.
    try l_buf.flush();
    try t_buf.flush();
    try u_buf.flush();
    try nfc_comp.flush();
    try nfd_comp.flush();
    try nfkd_comp.flush();

    // Close compressors
    try nfc_comp.close();
    try nfd_comp.close();
    try nfkd_comp.close();
}

// DerivedNormalizationProps.txt
fn processNormProps() !void {
    const in_path = "zig-cache/_ziglyph-data/ucd/DerivedNormalizationProps.txt";
    const out_path = "src/autogen/derived_normalization_props.zig";

    std.log.info("Processing {s} -> {s}", .{ in_path, out_path });

    var cwd = std.fs.cwd();

    // Skip if output already exists.
    if (cwd.access(out_path, .{})) {
        std.log.debug("\tSkipping existing file: {s}", .{out_path});
        return;
    } else |_| {}

    // Fetch file.
    var file = try cwd.openFile(in_path, .{});
    defer file.close();
    var buf_reader = std.io.bufferedReader(file.reader());
    const reader = buf_reader.reader();

    // Setup output.
    var out_file = try cwd.createFile(out_path, .{});
    defer out_file.close();
    var buf_writer = std.io.bufferedWriter(out_file.writer());
    const writer = buf_writer.writer();

    try writer.writeAll("// Autogenerated from https://www.unicode.org/Public/15.0.0/ucd/\n");

    const Prop = struct {
        name: []const u8,
        func_head: []const u8,
        func_tail: []const u8,
    };

    const fcx = Prop{
        .name = "Full_Composition_Exclusion",
        .func_head =
        \\
        \\/// `isFcx` returns true if `cp` has Full Composition Exclusion.
        \\pub fn isFcx(cp: u21) bool {
        \\    return switch(cp) {
        \\
        ,
        .func_tail =
        \\        else => false,
        \\    };
        \\}
        \\
        ,
    };
    const nfd_qc = Prop{
        .name = "NFD_QC",
        .func_head =
        \\
        \\/// `isNfd` returns true if `cp` is in Canoical Decomposed Normalization Form.
        \\pub fn isNfd(cp: u21) bool {
        \\    return switch(cp) {
        \\
        ,
        .func_tail =
        \\        else => true,
        \\    };
        \\}
        \\
        ,
    };
    const nfc_qc = Prop{
        .name = "NFC_QC",
        .func_head =
        \\
        \\/// `isNfc` returns true if `cp` is in Canoical Composed Normalization Form.
        \\pub fn isNfc(cp: u21) bool {
        \\    return switch(cp) {
        \\
        ,
        .func_tail =
        \\        else => true,
        \\    };
        \\}
        \\
        ,
    };
    const nfkd_qc = Prop{
        .name = "NFKD_QC",
        .func_head =
        \\
        \\/// `isNfkd` returns true if `cp` is in Compatibility Decomposition Normalization Form.
        \\pub fn isNfkd(cp: u21) bool {
        \\    return switch(cp) {
        \\
        ,
        .func_tail =
        \\        else => true,
        \\    };
        \\}
        \\
        ,
    };
    const nfkc_qc = Prop{
        .name = "NFKC_QC",
        .func_head =
        \\
        \\/// `isNfkc` returns true if `cp` is in Compatibility Composition Normalization Form.
        \\pub fn isNFKC(cp: u21) bool {
        \\    return switch(cp) {
        \\
        ,
        .func_tail =
        \\        else => true,
        \\    };
        \\}
        \\
        ,
    };
    const nfkc_cf = Prop{
        .name = "NFKC_CF",
        .func_head =
        \\
        \\/// `toNfkcCaseFold` returns the Compatibility Decomposed, Case Folded mapping for `cp`.
        \\/// Returns null if `cp` maps to nothing. Otherwise an 8 element array of code points 
        \\/// where the first element with value zero (0) marks the end of the mapping sequence.
        \\pub fn toNfkcCaseFold(cp: u21) ?[18]u21 {
        \\    const slice: ?[]const u21 = switch(cp) {
        \\
        ,
        .func_tail =
        \\        else => &.{cp},
        \\    };
        \\
        \\    if (slice) |s| {
        \\        var array = [_]u21{0} ** 18;
        \\        @memcpy(array[0..s.len], s);
        \\
        \\        return array;
        \\    }
        \\
        \\    return null;
        \\}
        \\
        ,
    };
    const cw_nfkc_cf = Prop{
        .name = "Changes_When_NFKC_Casefolded",
        .func_head =
        \\
        \\/// `changesWhenNfkcCaseFold` returns true if `toNfkcCaseFold` for `cp` does not return `cp` itself.
        \\pub fn changesWhenNfkcCaseFold(cp: u21) bool {
        \\    return switch(cp) {
        \\
        ,
        .func_tail =
        \\        else => false,
        \\    };
        \\}
        \\
        ,
    };

    var inRun: ?Prop = null;
    var nfc_done: bool = false;
    var nfkc_done: bool = false;

    const wanted_props = [_]Prop{
        fcx,
        nfd_qc,
        nfc_qc,
        nfkd_qc,
        nfkc_qc,
        nfkc_cf,
        cw_nfkc_cf,
    };

    var buf: [4096]u8 = undefined;

    // Iterate over lines.
    lines: while (try reader.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        // Skip comments or empty lines.
        if (line.len != 0 and line[0] == '#') continue;

        // Close functions at empty line after run of entries.
        if (line.len == 0) {
            if (inRun) |prop| {
                try writer.writeAll(prop.func_tail);
                inRun = null;
            }

            continue;
        }

        var fields_iter = std.mem.splitScalar(u8, line, ';');
        var field_index: usize = 0;
        var r_lo: ?[]const u8 = null;
        var r_hi: ?[]const u8 = null;
        var code_point: ?[]const u8 = null;

        // Iterate over fields.
        while (fields_iter.next()) |orig_field| : (field_index += 1) {
            var trimmed_field = std.mem.trim(u8, orig_field, " ");

            if (field_index == 0) {
                if (std.mem.indexOf(u8, trimmed_field, "..")) |dots| {
                    // Ranges.
                    r_lo = trimmed_field[0..dots];
                    r_hi = trimmed_field[dots + 2 ..];
                } else {
                    code_point = trimmed_field;
                }
            } else if (field_index == 1) {
                // Possible comment at end.
                if (std.mem.indexOf(u8, trimmed_field, "#")) |octo| {
                    trimmed_field = std.mem.trimRight(u8, trimmed_field[0..octo], " ");
                }

                if (inRun == null) {
                    // Check for wanted properties.
                    for (wanted_props) |prop| {
                        if (std.mem.eql(u8, trimmed_field, prop.name)) {
                            // Special cases...
                            if (std.mem.eql(u8, "NFC_QC", prop.name)) {
                                if (nfc_done) continue :lines;
                                nfc_done = true;
                            }

                            if (std.mem.eql(u8, "NFKC_QC", prop.name)) {
                                if (nfkc_done) continue :lines;
                                nfkc_done = true;
                            }

                            // Write function header.
                            try writer.writeAll(prop.func_head);
                            // Flag we're in run.
                            inRun = prop;
                            break;
                        }
                    }

                    // Skip unwanted.
                    if (inRun == null) continue :lines;
                }

                // We must be in a run of entries.
                const prop = inRun.?;

                if (std.mem.eql(u8, "Full_Composition_Exclusion", prop.name) or
                    std.mem.eql(u8, "Changes_When_NFKC_Casefolded", prop.name))
                {
                    if (code_point) |cp| {
                        // Single
                        _ = try writer.print("0x{s} => true,\n", .{tlz(cp)});
                    } else {
                        // Range
                        _ = try writer.print("0x{s}...0x{s} => true,\n", .{ tlz(r_lo.?), tlz(r_hi.?) });
                    }

                    continue :lines;
                }

                if (std.mem.eql(u8, "NFD_QC", prop.name) or std.mem.eql(u8, "NFKD_QC", prop.name)) {
                    if (code_point) |cp| {
                        // Single
                        _ = try writer.print("0x{s} => false,\n", .{tlz(cp)});
                    } else {
                        // Range
                        _ = try writer.print("0x{s}...0x{s} => false,\n", .{ tlz(r_lo.?), tlz(r_hi.?) });
                    }

                    continue :lines;
                }
            } else if (field_index == 2) {
                if (inRun) |prop| {
                    // Possible comment at end.
                    if (std.mem.indexOf(u8, trimmed_field, "#")) |octo| {
                        trimmed_field = std.mem.trimRight(u8, trimmed_field[0..octo], " ");
                    }

                    if (std.mem.eql(u8, "NFC_QC", prop.name) or std.mem.eql(u8, "NFKC_QC", prop.name)) {
                        if (std.mem.eql(u8, "N", trimmed_field)) {
                            if (code_point) |cp| {
                                // Single
                                _ = try writer.print("0x{s} => false,\n", .{tlz(cp)});
                            } else {
                                // Range
                                _ = try writer.print("0x{s}...0x{s} => false,\n", .{ tlz(r_lo.?), tlz(r_hi.?) });
                            }
                        }

                        continue :lines;
                    }

                    if (std.mem.eql(u8, "NFKC_CF", prop.name)) {
                        // Mapping.
                        if (trimmed_field.len == 0) {
                            // Map to nothing.
                            if (code_point) |cp| {
                                // Single
                                _ = try writer.print("0x{s} => null,\n", .{tlz(cp)});
                            } else {
                                // Range
                                _ = try writer.print("0x{s}...0x{s} => null,\n", .{ tlz(r_lo.?), tlz(r_hi.?) });
                            }

                            continue :lines;
                        }

                        // Field not empty, parse code points.
                        var cp_iter = std.mem.splitScalar(u8, trimmed_field, ' ');

                        if (code_point) |cp| {
                            // Single
                            _ = try writer.print("0x{s} => &.{{", .{tlz(cp)});
                        } else {
                            // Range
                            _ = try writer.print("0x{s}...0x{s} => &.{{", .{ tlz(r_lo.?), tlz(r_hi.?) });
                        }

                        var i: usize = 0;
                        while (cp_iter.next()) |cp| : (i += 1) {
                            if (i != 0) try writer.writeByte(',');
                            _ = try writer.print("0x{s}", .{tlz(cp)});
                        }

                        try writer.writeAll("},\n");

                        continue :lines;
                    }
                }
            } else {
                // Ignored field.
                continue;
            }
        }
    }

    // Finish writing.
    try buf_writer.flush();
}

// CaseFolding.txt
fn processCaseFold() !void {
    const in_path = "zig-cache/_ziglyph-data/ucd/CaseFolding.txt";
    const out_path = "src/autogen/case_folding.zig";

    std.log.info("Processing {s} -> {s}", .{ in_path, out_path });

    var cwd = std.fs.cwd();

    // Skip if output already exists.
    if (cwd.access(out_path, .{})) {
        std.log.debug("\tSkipping existing file: {s}", .{out_path});
        return;
    } else |_| {}

    // Prepare input.
    var file = try cwd.openFile(in_path, .{});
    defer file.close();
    var buf_reader = std.io.bufferedReader(file.reader());
    const reader = buf_reader.reader();

    // Setup output.
    var out_file = try cwd.createFile(out_path, .{});
    defer out_file.close();
    var buf_writer = std.io.bufferedWriter(out_file.writer());
    const writer = buf_writer.writer();

    const case_folding_header = @embedFile("case_folding_header.tpl");
    try writer.writeAll(case_folding_header);
    var buf: [4096]u8 = undefined;

    // Iterate over lines.
    while (try reader.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        // Skip comments or empty lines.
        if (line.len == 0 or line[0] == '#') continue;

        // Iterate over fields.
        var fields_iter = std.mem.splitScalar(u8, line, ';');
        var field_index: usize = 0;
        var code_point: []const u8 = undefined;
        var select = false;

        while (fields_iter.next()) |orig_field| : (field_index += 1) {
            if (field_index == 0) {
                // Code point.
                code_point = orig_field;
            } else if (field_index == 1) {
                // Flag desired records.
                if (std.mem.endsWith(u8, orig_field, " C") or std.mem.endsWith(u8, orig_field, " F")) select = true;
            } else if (field_index == 2) {
                if (select) {
                    // Mapping.
                    var trimmed_field = std.mem.trim(u8, orig_field, " ");
                    var cp_iter = std.mem.splitScalar(u8, trimmed_field, ' ');
                    _ = try writer.print("0x{s} => &.{{ ", .{tlz(code_point)});
                    var i: usize = 0;

                    while (cp_iter.next()) |cp| : (i += 1) {
                        if (i != 0) try writer.writeByte(',');
                        _ = try writer.print("0x{s}", .{tlz(cp)});
                    }

                    try writer.writeAll("},\n");
                    select = false;
                }
            } else {
                continue;
            }
        }
    }

    // Finish writing.
    try writer.writeAll("else => &.{cp},\n");
    try writer.writeAll(
        \\    };
        \\
        \\    var array = [_]u21{0} ** 3;
        \\    @memcpy(array[0..slice.len], slice);
        \\
        \\    return array;
        \\}
    );

    try buf_writer.flush();
}

// extracted/DerivedCombiningClass.txt
fn processCombiningClass() !void {
    const in_path = "zig-cache/_ziglyph-data/ucd/extracted/DerivedCombiningClass.txt";
    const out_path = "src/autogen/derived_combining_class.zig";

    std.log.info("Processing {s} -> {s}", .{ in_path, out_path });

    var cwd = std.fs.cwd();

    // Skip if output already exists.
    if (cwd.access(out_path, .{})) {
        std.log.debug("\tSkipping existing file: {s}", .{out_path});
        return;
    } else |_| {}

    // Prepare input.
    var file = try cwd.openFile(in_path, .{});
    defer file.close();
    var buf_reader = std.io.bufferedReader(file.reader());
    const reader = buf_reader.reader();

    // Setup output.
    var out_file = try cwd.createFile(out_path, .{});
    defer out_file.close();
    var buf_writer = std.io.bufferedWriter(out_file.writer());
    const writer = buf_writer.writer();

    const header =
        \\// Autogenerated from https://www.unicode.org/Public/15.0.0/ucd/
        \\
        \\// `combiningClass` maps the code point to its combining class value.
        \\pub fn combiningClass(cp: u21) u8 {
        \\    return switch (cp) {
        \\
    ;
    try writer.writeAll(header);

    var buf: [4096]u8 = undefined;

    // Iterate over lines.
    while (try reader.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        // Skip comments or empty lines.
        if (line.len == 0 or line[0] == '#') continue;

        // Iterate over fields.
        var fields_iter = std.mem.splitScalar(u8, line, ';');
        var field_index: usize = 0;
        var r_lo: ?[]const u8 = null;
        var r_hi: ?[]const u8 = null;
        var code_point: ?[]const u8 = null;

        while (fields_iter.next()) |orig_field| : (field_index += 1) {
            var trimmed_field = std.mem.trim(u8, orig_field, " ");

            if (field_index == 0) {
                if (std.mem.indexOf(u8, trimmed_field, "..")) |dots| {
                    // Ranges.
                    r_lo = trimmed_field[0..dots];
                    r_hi = trimmed_field[dots + 2 ..];
                } else {
                    // Single
                    code_point = trimmed_field;
                }

                continue;
            } else if (field_index == 1) {
                // CCC value.
                // Possible comment at end.
                if (std.mem.indexOf(u8, trimmed_field, "#")) |octo| {
                    trimmed_field = std.mem.trimRight(u8, trimmed_field[0..octo], " ");
                }

                if (!std.mem.eql(u8, trimmed_field, "0")) {
                    if (code_point) |cp| {
                        _ = try writer.print("0x{s} => {s},\n", .{ tlz(cp), trimmed_field });
                    } else {
                        _ = try writer.print("0x{s}...0x{s} => {s},\n", .{ tlz(r_lo.?), tlz(r_hi.?), trimmed_field });
                    }
                }
            }

            // Reset state.
            r_lo = null;
            r_hi = null;
            code_point = null;
        }
    }

    // Finish writing.
    _ = try writer.write("else => 0,\n    };\n}");

    try buf_writer.flush();
}

// /extracted/DerivedGeneralCategory.txt
fn processGenCat() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const in_path = "zig-cache/_ziglyph-data/ucd/extracted/DerivedGeneralCategory.txt";
    const out_path = "src/autogen/derived_general_category.zig";

    std.log.info("Processing {s} -> {s}", .{ in_path, out_path });

    var cwd = std.fs.cwd();

    // Skip if output already exists.
    if (cwd.access(out_path, .{})) {
        std.log.debug("\tSkipping existing file: {s}", .{out_path});
        return;
    } else |_| {}

    // Prepare input.
    var file = try cwd.openFile(in_path, .{});
    defer file.close();
    var buf_reader = std.io.bufferedReader(file.reader());
    const reader = buf_reader.reader();

    // Setup data structures.
    var collections = std.ArrayList(Collection).init(allocator);
    var records = std.ArrayList(Record).init(allocator);

    var kind: ?[]const u8 = null;
    var buf: [4096]u8 = undefined;

    // Iterate over lines.
    while (try reader.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        // Skip empty lines.
        if (line.len == 0) continue;

        if (std.mem.indexOf(u8, line, "General_Category=")) |_| {
            // Record kind.
            const equals = std.mem.indexOf(u8, line, "=").?;
            const current_kind = std.mem.trim(u8, line[equals + 1 ..], " ");

            // Check if new collection started.
            if (kind) |k| {
                // New collection for new record kind.
                if (!std.mem.eql(u8, k, current_kind)) {
                    // Calculate lo/hi.
                    const bounds = calcBounds(records.items);

                    try collections.append(.{
                        .hi = bounds[1],
                        .lo = bounds[0],
                        .name = k,
                        .records = try records.toOwnedSlice(),
                    });

                    // Update kind.
                    kind = try allocator.dupe(u8, current_kind);
                }
            } else {
                // kind is null, initialize it.
                kind = try allocator.dupe(u8, current_kind);
            }

            continue;
        } else if (line[0] == '#') continue;

        // Iterate over fields.
        var fields_iter = std.mem.splitScalar(u8, line, ';');
        var field_index: usize = 0;

        while (fields_iter.next()) |orig_field| : (field_index += 1) {
            var trimmed_field = std.mem.trim(u8, orig_field, " ");

            if (field_index == 0) {
                // Add new record.
                try records.append(try Record.parse(trimmed_field));
            }
        }
    }

    // Last collection.
    if (kind) |k| {
        // Calculate lo/hi.
        const bounds = calcBounds(records.items);

        try collections.append(.{
            .hi = bounds[1],
            .lo = bounds[0],
            .name = k,
            .records = try records.toOwnedSlice(),
        });
    }

    try writeFile(collections.items, out_path);
}

// HangulSyllableType.txt
fn processHangul() !void {
    const in_path = "zig-cache/_ziglyph-data/ucd/HangulSyllableType.txt";
    const out_path = "src/autogen/hangul_syllable_type.zig";

    std.log.info("Processing {s} -> {s}", .{ in_path, out_path });

    var cwd = std.fs.cwd();

    // Skip if output already exists.
    if (cwd.access(out_path, .{})) {
        std.log.debug("\tSkipping existing file: {s}", .{out_path});
        return;
    } else |_| {}

    // Prepare input.
    var file = try cwd.openFile(in_path, .{});
    defer file.close();
    var buf_reader = std.io.bufferedReader(file.reader());
    const reader = buf_reader.reader();

    // Setup output.
    var out_file = try cwd.createFile(out_path, .{});
    defer out_file.close();
    var buf_writer = std.io.bufferedWriter(out_file.writer());
    const writer = buf_writer.writer();

    // Header
    const header =
        \\// Autogenerated from https://www.unicode.org/Public/15.0.0/ucd/
        \\
        \\pub const Kind = enum {
        \\    L,
        \\    LV,
        \\    LVT,
        \\    T,
        \\    V,
        \\};
        \\
        \\/// `syllableType` maps the code point to its Hangul Syllable Type.
        \\pub fn syllableType(cp: u21) ?Kind {
        \\    return switch (cp) {
        \\
    ;
    try writer.writeAll(header);

    var buf: [4096]u8 = undefined;

    // Iterate over lines.
    while (try reader.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        // Skip comments or empty lines.
        if (line.len == 0 or line[0] == '#') continue;

        // Iterate over fields.
        var fields_iter = std.mem.splitScalar(u8, line, ';');
        var field_index: usize = 0;
        var r_lo: ?[]const u8 = null;
        var r_hi: ?[]const u8 = null;
        var code_point: ?[]const u8 = null;

        while (fields_iter.next()) |orig_field| : (field_index += 1) {
            var trimmed_field = std.mem.trim(u8, orig_field, " ");

            if (field_index == 0) {
                if (std.mem.indexOf(u8, trimmed_field, "..")) |dots| {
                    // Ranges.
                    r_lo = trimmed_field[0..dots];
                    r_hi = trimmed_field[dots + 2 ..];
                } else {
                    // Single
                    code_point = trimmed_field;
                }

                continue;
            } else if (field_index == 1) {
                // Syllable type.
                // Possible comment at end.
                if (std.mem.indexOf(u8, trimmed_field, "#")) |octo| {
                    trimmed_field = std.mem.trimRight(u8, trimmed_field[0..octo], " ");
                }

                if (code_point) |cp| {
                    _ = try writer.print("0x{s} => .{s},\n", .{ tlz(cp), trimmed_field });
                } else {
                    _ = try writer.print("0x{s}...0x{s} => .{s},\n", .{ tlz(r_lo.?), tlz(r_hi.?), trimmed_field });
                }
            }

            // Reset state.
            r_lo = null;
            r_hi = null;
            code_point = null;
            continue;
        }
    }

    // Finish writing.
    _ = try writer.write("else => null,\n    };\n}");

    try buf_writer.flush();
}

// extracted/DerivedEastAsianWidth.txt
fn processAsianWidth() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const in_path = "zig-cache/_ziglyph-data/ucd/extracted/DerivedEastAsianWidth.txt";
    const out_path = "src/autogen/derived_east_asian_width.zig";

    std.log.info("Processing {s} -> {s}", .{ in_path, out_path });

    var cwd = std.fs.cwd();

    // Skip if output already exists.
    if (cwd.access(out_path, .{})) {
        std.log.debug("\tSkipping existing file: {s}", .{out_path});
        return;
    } else |_| {}

    // Prepare input.
    var file = try cwd.openFile(in_path, .{});
    defer file.close();
    var buf_reader = std.io.bufferedReader(file.reader());
    const reader = buf_reader.reader();

    // Setup data structures.
    var collections = std.ArrayList(Collection).init(allocator);
    var records = std.ArrayList(Record).init(allocator);

    var kind: ?[]const u8 = null;
    var buf: [4096]u8 = undefined;

    // Iterate over lines.
    while (try reader.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        // Skip empty lines.
        if (line.len == 0) continue;

        if (std.mem.indexOf(u8, line, "East_Asian_Width=")) |_| {
            // Record kind.
            const equals = std.mem.indexOf(u8, line, "=").?;
            const current_kind = std.mem.trim(u8, line[equals + 1 ..], " ");

            // Check if new collection started.
            if (kind) |k| {
                // New collection for new record kind.
                if (!std.mem.eql(u8, k, current_kind)) {
                    // Calculate lo/hi.
                    const bounds = calcBounds(records.items);

                    try collections.append(.{
                        .hi = bounds[1],
                        .lo = bounds[0],
                        .name = k,
                        .records = try records.toOwnedSlice(),
                    });

                    // Update kind.
                    kind = try allocator.dupe(u8, current_kind);
                }
            } else {
                // kind is null, initialize it.
                kind = try allocator.dupe(u8, current_kind);
            }

            continue;
        } else if (line[0] == '#') continue;

        // Iterate over fields.
        var fields_iter = std.mem.splitScalar(u8, line, ';');
        var field_index: usize = 0;

        while (fields_iter.next()) |orig_field| : (field_index += 1) {
            var trimmed_field = std.mem.trim(u8, orig_field, " ");

            if (field_index == 0) {
                // Add new record.
                try records.append(try Record.parse(trimmed_field));
            }
        }
    }

    // Last collection.
    if (kind) |k| {
        // Calculate lo/hi.
        const bounds = calcBounds(records.items);

        try collections.append(.{
            .hi = bounds[1],
            .lo = bounds[0],
            .name = k,
            .records = try records.toOwnedSlice(),
        });
    }

    try writeFile(collections.items, out_path);
}

// Compress allkeys.txt
fn akds() !void {
    const norm_props = @import("autogen/derived_normalization_props.zig");
    const compressor = std.compress.deflate.compressor;

    std.log.info("Generating Unicode Collation allkeys.txt files..", .{});

    var in_file = try std.fs.cwd().openFile("zig-cache/_ziglyph-data/uca/allkeys.txt", .{});
    defer in_file.close();
    var in_buf_read = std.io.bufferedReader(in_file.reader());
    const in_reader = in_buf_read.reader();

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    var out_file = try std.fs.cwd().createFile("src/data/allkeys-diffs.txt.deflate", .{});
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
}

fn autogen() !void {
    try std.fs.cwd().makePath("src/autogen");

    const in_out_paths = [_][2][]const u8{
        .{ "zig-cache/_ziglyph-data/ucd/Blocks.txt", "src/autogen/blocks.zig" },
        .{ "zig-cache/_ziglyph-data/ucd/DerivedCoreProperties.txt", "src/autogen/derived_core_properties.zig" },
        .{ "zig-cache/_ziglyph-data/ucd/PropList.txt", "src/autogen/prop_list.zig" },
        .{ "zig-cache/_ziglyph-data/ucd/auxiliary/GraphemeBreakProperty.txt", "src/autogen/grapheme_break_property.zig" },
        .{ "zig-cache/_ziglyph-data/ucd/auxiliary/SentenceBreakProperty.txt", "src/autogen/sentence_break_property.zig" },
        .{ "zig-cache/_ziglyph-data/ucd/auxiliary/WordBreakProperty.txt", "src/autogen/word_break_property.zig" },
        .{ "zig-cache/_ziglyph-data/ucd/emoji/emoji-data.txt", "src/autogen/emoji_data.zig" },
        .{ "zig-cache/_ziglyph-data/ucd/extracted/DerivedNumericType.txt", "src/autogen/derived_numeric_type.zig" },
    };

    var handles: [in_out_paths.len + 7]std.Thread = undefined;

    std.log.info("Autogenerating Zig code from Unicode data files...", .{});

    var timer = std.time.Timer.start() catch unreachable;

    for (in_out_paths, 0..) |entry, i| {
        handles[i] = try std.Thread.spawn(.{}, processF1, .{ entry[0], entry[1] });
    }

    handles[handles.len - 7] = try std.Thread.spawn(.{}, processUcd, .{});
    handles[handles.len - 6] = try std.Thread.spawn(.{}, processNormProps, .{});
    handles[handles.len - 5] = try std.Thread.spawn(.{}, processCaseFold, .{});
    handles[handles.len - 4] = try std.Thread.spawn(.{}, processCombiningClass, .{});
    handles[handles.len - 3] = try std.Thread.spawn(.{}, processGenCat, .{});
    handles[handles.len - 2] = try std.Thread.spawn(.{}, processHangul, .{});
    handles[handles.len - 1] = try std.Thread.spawn(.{}, processAsianWidth, .{});

    for (handles) |handle| handle.join();

    // This depends on the previous steps.
    try akds();

    const took: f64 = @floatFromInt(timer.read());
    std.log.info("Done!\nProcessing took: {d:.6}ms.", .{took / 1e6});
}

pub fn main() !void {
    try autogen();
}
