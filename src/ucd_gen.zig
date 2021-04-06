const std = @import("std");

const ArrayList = std.ArrayList;
const AutoHashMap = std.AutoHashMap;
const HashMap = std.HashMap;
const Range = @import("Range.zig");
const fmt = std.fmt;
const io = std.io;
const mem = std.mem;

const CaseKind = enum {
    Lower,
    Title,
    Upper,
};

const List = struct {
    name: []const u8,
    filename: []const u8,
    ascii_opt: []const u8,
    items: []u21,
    ranges: ?[]Range = null,
};

const Consolidated = struct {
    code_points: []u21,
    ranges: []Range,
    lo: u21,
    hi: u21,
};

const UcdGenerator = struct {
    allocator: *mem.Allocator,

    alpha: ArrayList(u21),
    alpha_ranges: ArrayList(Range),
    cased: ArrayList(u21),
    cased_ranges: ArrayList(Range),
    control: ArrayList(u21),
    control_ranges: ArrayList(Range),
    decimal: ArrayList(u21),
    decimal_ranges: ArrayList(Range),
    digit: ArrayList(u21),
    digit_ranges: ArrayList(Range),
    letter: ArrayList(u21),
    letter_ranges: ArrayList(Range),
    lower: ArrayList(u21),
    lower_ranges: ArrayList(Range),
    mark: ArrayList(u21),
    number: ArrayList(u21),
    punct: ArrayList(u21),
    space: ArrayList(u21),
    symbol: ArrayList(u21),
    title: ArrayList(u21),
    upper: ArrayList(u21),
    upper_ranges: ArrayList(Range),

    decomp_map: AutoHashMap(u21, []const u21),
    fold_map: AutoHashMap(u21, []const u21),
    to_lower_map: AutoHashMap(u21, u21),
    to_upper_map: AutoHashMap(u21, u21),
    to_title_map: AutoHashMap(u21, u21),

    pub fn init(allocator: *mem.Allocator) !UcdGenerator {
        return UcdGenerator{
            .allocator = allocator,

            .alpha = ArrayList(u21).init(allocator),
            .alpha_ranges = ArrayList(Range).init(allocator),
            .cased = ArrayList(u21).init(allocator),
            .cased_ranges = ArrayList(Range).init(allocator),
            .control = ArrayList(u21).init(allocator),
            .control_ranges = ArrayList(Range).init(allocator),
            .decimal = ArrayList(u21).init(allocator),
            .decimal_ranges = ArrayList(Range).init(allocator),
            .digit = ArrayList(u21).init(allocator),
            .digit_ranges = ArrayList(Range).init(allocator),
            .letter = ArrayList(u21).init(allocator),
            .letter_ranges = ArrayList(Range).init(allocator),
            .lower = ArrayList(u21).init(allocator),
            .lower_ranges = ArrayList(Range).init(allocator),
            .mark = ArrayList(u21).init(allocator),
            .number = ArrayList(u21).init(allocator),
            .punct = ArrayList(u21).init(allocator),
            .space = ArrayList(u21).init(allocator),
            .symbol = ArrayList(u21).init(allocator),
            .title = ArrayList(u21).init(allocator),
            .upper = ArrayList(u21).init(allocator),
            .upper_ranges = ArrayList(Range).init(allocator),

            .decomp_map = AutoHashMap(u21, []const u21).init(allocator),
            .fold_map = AutoHashMap(u21, []const u21).init(allocator),
            .to_lower_map = AutoHashMap(u21, u21).init(allocator),
            .to_upper_map = AutoHashMap(u21, u21).init(allocator),
            .to_title_map = AutoHashMap(u21, u21).init(allocator),
        };
    }

    const Self = @This();

    pub fn deinit(self: *Self) void {
        self.alpha.deinit();
        self.alpha_ranges.deinit();
        self.cased.deinit();
        self.cased_ranges.deinit();
        self.control.deinit();
        self.control_ranges.deinit();
        self.decimal.deinit();
        self.decimal_ranges.deinit();
        self.digit.deinit();
        self.digit_ranges.deinit();
        self.letter.deinit();
        self.letter_ranges.deinit();
        self.lower.deinit();
        self.mark.deinit();
        self.number.deinit();
        self.punct.deinit();
        self.space.deinit();
        self.symbol.deinit();
        self.title.deinit();
        self.upper.deinit();
        self.to_lower_map.deinit();
        self.to_title_map.deinit();
        self.to_upper_map.deinit();

        var decomp_iter = self.decomp_map.iterator();
        while (decomp_iter.next()) |entry| {
            self.allocator.free(entry.value);
        }
        self.decomp_map.deinit();

        var fold_iter = self.fold_map.iterator();
        while (fold_iter.next()) |entry| {
            self.allocator.free(entry.value);
        }
        self.fold_map.deinit();
    }

    fn gen(self: *Self) !void {
        try self.process_stream();
        try self.write_files();
    }

    fn process_stream(self: *Self) !void {
        try self.process_case_folding();
        try self.process_core_props();
        try self.process_numeric();
        try self.process_ucd();
    }

    // UnicodeData.txt
    fn process_ucd(self: *Self) !void {
        const ucd_filepath = "data/ucd/UnicodeData.txt";
        var buf: [1024]u8 = undefined;
        var ucd_file = try std.fs.cwd().openFile(ucd_filepath, .{});
        defer ucd_file.close();
        var buf_reader = io.bufferedReader(ucd_file.reader());
        const ucd_stream = buf_reader.reader();
        var range_start: ?u21 = null;
        while (try ucd_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
            if (line.len == 0 or line[0] == '#') continue;
            if (range_start) |rscp| {
                var iter = mem.split(line, ";");
                var fields: [3][]const u8 = undefined;
                var i: usize = 0;
                while (iter.next()) |field| : (i += 1) {
                    if (i < 3) fields[i] = field else break;
                }
                if (!mem.endsWith(u8, fields[1], "Last>")) return error.UnclosedRange;

                const range_end = try fmt.parseInt(u21, fields[0], 16);
                if (mem.eql(u8, fields[2], "Cc")) {
                    try self.control_ranges.append(.{ .start = rscp, .end = range_end });
                } else if (fields[2][0] == 'L') {
                    try self.letter_ranges.append(.{ .start = rscp, .end = range_end });
                } else {
                    return error.UnexpectedRangeCategory;
                }

                range_start = null;
                continue;
            }

            var fields = mem.split(line, ";");
            var i: usize = 0;
            var code_point: u21 = undefined;
            while (fields.next()) |field| : (i += 1) {
                if (i == 0) {
                    // Parse code point.
                    code_point = try fmt.parseInt(u21, field, 16);
                } else if (i == 1 and mem.endsWith(u8, field, "First>")) {
                    // Ranges to avoid.
                    if (mem.endsWith(u8, field, "Surrogate, First>")) continue;
                    if (mem.endsWith(u8, field, "Private Use, First>")) continue;
                    if (mem.startsWith(u8, field, "Private Use")) continue;
                    range_start = code_point;
                } else if (i == 2 and field.len != 0) {
                    // Major categories.
                    if (mem.eql(u8, field, "Cc") and !contains(self.control.items, code_point)) {
                        try self.control.append(code_point);
                    }
                    switch (field[0]) {
                        'L' => {
                            if (!contains(self.letter.items, code_point)) {
                                try self.letter.append(code_point);
                            }
                            if (mem.eql(u8, field, "Ll")) {
                                if (!contains(self.lower.items, code_point)) {
                                    try self.lower.append(code_point);
                                }
                            } else if (mem.eql(u8, field, "Lt")) {
                                if (!contains(self.title.items, code_point)) {
                                    try self.title.append(code_point);
                                }
                            } else if (mem.eql(u8, field, "Lu")) {
                                if (!contains(self.upper.items, code_point)) {
                                    try self.upper.append(code_point);
                                }
                            }
                        },
                        'M' => if (!contains(self.mark.items, code_point)) {
                            try self.mark.append(code_point);
                        },
                        'N' => if (!contains(self.number.items, code_point)) {
                            try self.number.append(code_point);
                        },
                        'P' => if (!contains(self.punct.items, code_point)) {
                            try self.punct.append(code_point);
                        },
                        'S' => if (!contains(self.symbol.items, code_point)) {
                            try self.symbol.append(code_point);
                        },
                        else => {
                            if (mem.eql(u8, field, "Zs")) {
                                if (!contains(self.space.items, code_point)) {
                                    try self.space.append(code_point);
                                }
                            } else {
                                continue;
                            }
                        },
                    }
                } else if (i == 5 and field.len != 0) {
                    // Decomposition.
                    try self.decompMapAdd(code_point, field);
                } else if (i == 12 and field.len != 0) {
                    // Map to uppercase.
                    try self.caseMapAdd(.Upper, code_point, field);
                } else if (i == 13 and field.len != 0) {
                    // Map to lowercase.
                    try self.caseMapAdd(.Lower, code_point, field);
                } else if (i == 14 and field.len != 0) {
                    // Map to titlecase.
                    try self.caseMapAdd(.Title, code_point, field);
                } else {
                    continue;
                }
            }
        }
    }

    // CaseFolding.txt
    fn process_case_folding(self: *Self) !void {
        const fold_filepath = "data/ucd/CaseFolding.txt";
        var buf: [1024]u8 = undefined;
        var fold_file = try std.fs.cwd().openFile(fold_filepath, .{});
        defer fold_file.close();
        var fold_buf = io.bufferedReader(fold_file.reader());
        const fold_stream = fold_buf.reader();
        var code_point: u21 = undefined;
        while (try fold_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
            if (line.len == 0 or mem.startsWith(u8, line, "#")) continue;
            var fields = mem.split(line, ";");
            var index: usize = 0;
            while (fields.next()) |field| : (index += 1) {
                if (index == 0) {
                    code_point = try fmt.parseInt(u21, field, 16);
                } else if (index == 1 and (mem.endsWith(u8, field, " F") or mem.endsWith(u8, field, " C"))) {
                    try self.foldMapAdd(code_point, fields.next().?);
                    break;
                }
            }
        }
    }

    // DerivedCoreProperties.txt
    fn process_core_props(self: *Self) !void {
        const core_props_filepath = "data/ucd/DerivedCoreProperties.txt";
        var buf: [1024]u8 = undefined;
        var core_props_file = try std.fs.cwd().openFile(core_props_filepath, .{});
        defer core_props_file.close();
        var core_props_buf = io.bufferedReader(core_props_file.reader());
        const core_props_stream = core_props_buf.reader();
        while (try core_props_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
            if (line.len == 0 or line[0] == '#') continue;
            var fields = mem.split(line, ";");
            var i: usize = 0;
            const Item = union(enum) {
                cp: u21,
                range: Range,
            };
            const Property = enum {
                Alphabetic,
                Cased,
                Lowercase,
                Uppercase,
            };
            var it: Item = undefined;
            var prop: ?Property = null;
            while (fields.next()) |field| : (i += 1) {
                if (field.len == 0 or field[0] == '#') continue;
                if (i == 0) {
                    if (mem.indexOf(u8, field, "..")) |dots| {
                        const start = try fmt.parseInt(u21, field[0..dots], 16);
                        const clean = mem.trimRight(u8, field[dots + 2 ..], " ");
                        const end = try fmt.parseInt(u21, clean, 16);
                        it = .{ .range = .{ .start = start, .end = end } };
                    } else {
                        const clean = mem.trimRight(u8, field, " ");
                        const code_point = try fmt.parseInt(u21, clean, 16);
                        it = .{ .cp = code_point };
                    }
                } else if (i == 1 and field.len != 0) {
                    if (mem.startsWith(u8, field, " Alphabetic")) {
                        prop = .Alphabetic;
                    } else if (mem.startsWith(u8, field, " Cased")) {
                        prop = .Cased;
                    } else if (mem.startsWith(u8, field, " Lowercase")) {
                        prop = .Lowercase;
                    } else if (mem.startsWith(u8, field, " Uppercase")) {
                        prop = .Uppercase;
                    }

                    if (prop) |p| {
                        switch (it) {
                            .cp => |cp| {
                                switch (p) {
                                    .Alphabetic => try self.alpha.append(cp),
                                    .Cased => try self.cased.append(cp),
                                    .Lowercase => try self.lower.append(cp),
                                    .Uppercase => try self.upper.append(cp),
                                }
                            },
                            .range => |range| {
                                switch (p) {
                                    .Alphabetic => try self.alpha_ranges.append(range),
                                    .Cased => try self.cased_ranges.append(range),
                                    .Lowercase => try self.lower_ranges.append(range),
                                    .Uppercase => try self.upper_ranges.append(range),
                                }
                            },
                        }
                    }
                } else {
                    continue;
                }
            }
        }
    }

    // DerivedNumericType.txt
    fn process_numeric(self: *Self) !void {
        const numeric_filepath = "data/ucd/extracted/DerivedNumericType.txt";
        var buf: [1024]u8 = undefined;
        var numeric_file = try std.fs.cwd().openFile(numeric_filepath, .{});
        defer numeric_file.close();
        var numeric_buf = io.bufferedReader(numeric_file.reader());
        const numeric_stream = numeric_buf.reader();
        while (try numeric_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
            if (line.len == 0 or line[0] == '#') continue;
            var fields = mem.split(line, ";");
            var i: usize = 0;
            const Item = union(enum) {
                cp: u21,
                range: Range,
            };
            const Property = enum {
                Decimal,
                Digit,
            };
            var it: Item = undefined;
            var prop: ?Property = null;
            while (fields.next()) |field| : (i += 1) {
                if (field.len == 0 or field[0] == '#') continue;
                if (i == 0) {
                    if (mem.indexOf(u8, field, "..")) |dots| {
                        const start = try fmt.parseInt(u21, field[0..dots], 16);
                        const clean = mem.trimRight(u8, field[dots + 2 ..], " ");
                        const end = try fmt.parseInt(u21, clean, 16);
                        it = .{ .range = .{ .start = start, .end = end } };
                    } else {
                        const clean = mem.trimRight(u8, field, " ");
                        const code_point = try fmt.parseInt(u21, clean, 16);
                        it = .{ .cp = code_point };
                    }
                } else if (i == 1 and field.len != 0) {
                    if (mem.startsWith(u8, field, " Decimal")) {
                        prop = .Decimal;
                    } else if (mem.startsWith(u8, field, " Digit")) {
                        prop = .Digit;
                    }

                    if (prop) |p| {
                        switch (it) {
                            .cp => |cp| {
                                switch (p) {
                                    .Decimal => try self.decimal.append(cp),
                                    .Digit => try self.digit.append(cp),
                                }
                            },
                            .range => |range| {
                                switch (p) {
                                    .Decimal => try self.decimal_ranges.append(range),
                                    .Digit => try self.digit_ranges.append(range),
                                }
                            },
                        }
                    }
                } else {
                    continue;
                }
            }
        }
    }
    fn write_files(self: *Self) !void {
        // Write out.
        const lists = [_]List{
            .{
                .name = "Alpha",
                .filename = "components/Alpha.zig",
                .ascii_opt = "return ascii.isAlpha(@intCast(u8, cp));",
                .items = self.alpha.items,
                .ranges = self.alpha_ranges.items,
            },
            .{
                .name = "Cased",
                .filename = "components/Cased.zig",
                .ascii_opt = "return null;",
                .items = self.cased.items,
                .ranges = self.cased_ranges.items,
            },
            .{
                .name = "Control",
                .filename = "components/Control.zig",
                .ascii_opt = "return ascii.isCntrl(@intCast(u8, cp));",
                .items = self.control.items,
                .ranges = self.control_ranges.items,
            },
            .{
                .name = "Decimal",
                .filename = "components/Decimal.zig",
                .ascii_opt = "return null;",
                .items = self.decimal.items,
                .ranges = self.decimal_ranges.items,
            },
            .{
                .name = "Digit",
                .filename = "components/Digit.zig",
                .ascii_opt = "return ascii.isDigit(@intCast(u8, cp));",
                .items = self.digit.items,
                .ranges = self.digit_ranges.items,
            },
            .{
                .name = "Letter",
                .filename = "components/Letter.zig",
                .items = self.letter.items,
                .ascii_opt = "return ascii.isAlpha(@intCast(u8, cp));",
                .ranges = self.letter_ranges.items,
            },
            .{
                .name = "Lower",
                .filename = "components/Lower.zig",
                .ascii_opt = "return ascii.isLower(@intCast(u8, cp));",
                .items = self.lower.items,
                .ranges = self.lower_ranges.items,
            },
            .{
                .name = "Mark",
                .filename = "components/Mark.zig",
                .ascii_opt = "return null;",
                .items = self.mark.items,
            },
            .{
                .name = "Number",
                .filename = "components/Number.zig",
                .ascii_opt = "return ascii.isDigit(@intCast(u8, cp));",
                .items = self.number.items,
            },
            .{
                .name = "Punct",
                .filename = "components/Punct.zig",
                .ascii_opt = "return ascii.isPunct(@intCast(u8, cp));",
                .items = self.punct.items,
            },
            .{
                .name = "Space",
                .filename = "components/Space.zig",
                .ascii_opt = "return ascii.isSpace(@intCast(u8, cp));",
                .items = self.space.items,
            },
            .{
                .name = "Symbol",
                .filename = "components/Symbol.zig",
                .ascii_opt = "return ascii.isSymbol(@intCast(u8, cp));",
                .items = self.symbol.items,
            },
            .{
                .name = "Title",
                .filename = "components/Title.zig",
                .ascii_opt = "return null;",
                .items = self.title.items,
            },
            .{
                .name = "Upper",
                .filename = "components/Upper.zig",
                .ascii_opt = "return ascii.isUpper(@intCast(u8, cp));",
                .items = self.upper.items,
                .ranges = self.upper_ranges.items,
            },
        };

        const header_tpl = @embedFile("parts/array_header_tpl.txt");
        const trailer_tpl = @embedFile("parts/array_trailer_tpl.txt");

        for (lists) |list| {
            // Prepare output files.
            var file = try std.fs.cwd().createFile(list.filename, .{});
            defer file.close();
            var buf_writer = io.bufferedWriter(file.writer());
            const writer = buf_writer.writer();

            // Write data.
            const consolidated = try self.consolidate(list);
            defer self.allocator.free(consolidated.code_points);
            defer self.allocator.free(consolidated.ranges);
            const array_length = consolidated.hi - consolidated.lo + 1;
            _ = try writer.print(header_tpl, .{ list.name, array_length, consolidated.lo, consolidated.hi });

            for (consolidated.code_points) |cp| {
                _ = try writer.print("    instance.array[{d}] = true;\n", .{cp - consolidated.lo});
            }

            _ = try writer.write("\n    var index: u21 = 0;\n");

            for (consolidated.ranges) |range| {
                _ = try writer.print("    index = {d};\n", .{range.start - consolidated.lo});
                _ = try writer.print("    while (index <= {d}) : (index += 1) {{\n", .{range.end - consolidated.lo});
                _ = try writer.write("        instance.array[index] = true;\n");
                _ = try writer.write("    }\n");
            }

            _ = try writer.print(trailer_tpl, .{ list.name, list.ascii_opt });
            try buf_writer.flush();
        }

        const CaseMap = struct {
            name: []const u8,
            comment: []const u8,
            filename: []const u8,
            map: AutoHashMap(u21, u21),
            method: []const u8,
            ascii_opt: []const u8,
        };

        const case_maps = [_]CaseMap{
            .{
                .name = "LowerMap",
                .comment = "Unicode letter mappings to lowercase.",
                .filename = "components/LowerMap.zig",
                .map = self.to_lower_map,
                .method = "Lower",
                .ascii_opt = "return ascii.toLower(@intCast(u8, cp));\n",
            },
            .{
                .name = "TitleMap",
                .comment = "Unicode letter mappings to titlecase.",
                .filename = "components/TitleMap.zig",
                .map = self.to_title_map,
                .method = "Title",
                .ascii_opt = "return null;",
            },
            .{
                .name = "UpperMap",
                .comment = "Unicode letter mappings to uppercase.",
                .filename = "components/UpperMap.zig",
                .map = self.to_upper_map,
                .method = "Upper",
                .ascii_opt = "return ascii.toUpper(@intCast(u8, cp));\n",
            },
        };

        const map_header_tpl = @embedFile("parts/map_header_tpl.txt");
        const map_trailer_tpl = @embedFile("parts/map_trailer_tpl.txt");

        for (case_maps) |cm| {
            var file = try std.fs.cwd().createFile(cm.filename, .{});
            defer file.close();
            var buf_writer = io.bufferedWriter(file.writer());
            const writer = buf_writer.writer();

            var lo: u21 = 0x10FFFF;
            var hi: u21 = 0;
            var iter = cm.map.iterator();
            while (iter.next()) |entry| {
                if (entry.key < lo) lo = entry.key;
                if (entry.key > hi) hi = entry.key;
            }

            const array_length = hi - lo + 1;
            _ = try writer.print(map_header_tpl, .{ cm.comment, cm.name, array_length, lo, hi });

            iter = cm.map.iterator();
            while (iter.next()) |entry| {
                _ = try writer.print("    instance.array[{d}] = 0x{X};\n", .{ entry.key - lo, entry.value });
            }

            _ = try writer.print(map_trailer_tpl, .{ cm.method, cm.name, cm.ascii_opt });
            try buf_writer.flush();
        }

        // Decomposition map.
        const decomp_header_tpl = @embedFile("parts/decomp_map_header_tpl.txt");
        const decomp_trailer_tpl = @embedFile("parts/decomp_map_trailer_tpl.txt");

        var decompf = try std.fs.cwd().createFile("components/DecomposeMap.zig", .{});
        defer decompf.close();
        var decompf_buf = io.bufferedWriter(decompf.writer());
        const decompf_writer = decompf_buf.writer();

        _ = try decompf_writer.print(decomp_header_tpl, .{});

        var decomp_iter = self.decomp_map.iterator();
        while (decomp_iter.next()) |entry| {
            _ = try decompf_writer.print("    try instance.map.put(0x{X}, &[{d}]u21{{\n", .{ entry.key, entry.value.len });
            for (entry.value) |cp| {
                _ = try decompf_writer.print("        0x{X},\n", .{cp});
            }
            _ = try decompf_writer.write("    });\n");
        }

        _ = try decompf_writer.print(decomp_trailer_tpl, .{});
        try decompf_buf.flush();

        // Case folding map.
        const fold_header_tpl = @embedFile("parts/fold_map_header_tpl.txt");
        const fold_trailer_tpl = @embedFile("parts/fold_map_trailer_tpl.txt");

        var fold_file = try std.fs.cwd().createFile("components/CaseFoldMap.zig", .{});
        defer fold_file.close();
        var fold_buf = io.bufferedWriter(fold_file.writer());
        const fold_writer = fold_buf.writer();

        _ = try fold_writer.print(fold_header_tpl, .{});

        var fold_iter = self.fold_map.iterator();
        while (fold_iter.next()) |entry| {
            _ = try fold_writer.print("    try instance.map.put(0x{X}, &[{d}]u21{{\n", .{ entry.key, entry.value.len });
            for (entry.value) |cp| {
                _ = try fold_writer.print("        0x{X},\n", .{cp});
            }
            _ = try fold_writer.write("    });\n");
        }

        _ = try fold_writer.print(fold_trailer_tpl, .{});
        try fold_buf.flush();
    }

    fn decompMapAdd(self: *Self, code_point: u21, field: []const u8) !void {
        var seq = mem.split(field, " ");
        var cp_list = try self.allocator.alloc(u21, 18); // Max decomp code points = 18
        errdefer self.allocator.free(cp_list);
        var i: usize = 0;
        while (seq.next()) |scp| {
            if (scp.len == 0 or scp[0] == '<') continue;
            const ncp: u21 = try fmt.parseInt(u21, scp, 16);
            cp_list[i] = ncp;
            i += 1;
        }
        cp_list = self.allocator.shrink(cp_list, i);
        try self.decomp_map.put(code_point, cp_list);
    }

    fn caseMapAdd(self: *Self, case_map: CaseKind, code_point: u21, field: []const u8) !void {
        const ccp: u21 = try fmt.parseInt(u21, field, 16);
        switch (case_map) {
            .Lower => try self.to_lower_map.put(code_point, ccp),
            .Title => try self.to_title_map.put(code_point, ccp),
            .Upper => try self.to_upper_map.put(code_point, ccp),
        }
    }

    // Caller must free .code_points and .ranges fields.
    fn consolidate(self: Self, list: List) !Consolidated {
        var lo: u21 = 0x10FFFF;
        var hi: u21 = 0;
        var cp_list = std.ArrayList(u21).init(self.allocator);
        defer cp_list.deinit();
        var range_list = std.ArrayList(Range).init(self.allocator);
        defer range_list.deinit();

        if (list.items.len > 0) {
            hi = mem.max(u21, list.items);
            lo = mem.min(u21, list.items);
            var array = try self.allocator.alloc(bool, hi + 1);
            defer self.allocator.free(array);
            var indices = std.ArrayList(u21).init(self.allocator);
            defer indices.deinit();

            var index: u21 = 0;
            var latest: u21 = 0;
            var true_run = false;
            while (index < array.len) : (index += 1) {
                if (contains(list.items, index)) {
                    if (!true_run) {
                        try indices.append(index);
                        true_run = true;
                    }
                    array[index] = true;
                    latest = index;
                } else {
                    if (true_run) {
                        try indices.append(latest);
                        true_run = false;
                    }
                    array[index] = false;
                }
            }

            index = 0;
            while (index < indices.items.len) {
                var start = indices.items[index];
                index += 1;
                if (index >= indices.items.len) {
                    // End of list, add last one.
                    try cp_list.append(start);
                    break;
                }

                var end = indices.items[index];
                if (end - start == 0) {
                    // Single code point.
                    try cp_list.append(start);
                } else {
                    // Range
                    if (start < lo) lo = start;
                    if (end > hi) hi = end;
                    try range_list.append(.{ .start = start, .end = end });
                }

                index += 1;
            }
        }

        // Add other ranges.
        if (list.ranges) |ranges| {
            for (ranges) |range| {
                if (range.start < lo) lo = range.start;
                if (range.end > hi) hi = range.end;
                try range_list.append(range);
            }
        }

        return Consolidated{
            .code_points = cp_list.toOwnedSlice(),
            .ranges = range_list.toOwnedSlice(),
            .lo = lo,
            .hi = hi,
        };
    }

    fn foldMapAdd(self: *Self, code_point: u21, field: []const u8) !void {
        var clean = mem.trim(u8, field, " ");
        var seq = mem.split(clean, " ");
        var cp_list = try self.allocator.alloc(u21, 4);
        errdefer self.allocator.free(cp_list);
        var i: usize = 0;
        while (seq.next()) |scp| {
            if (scp.len == 0) continue;
            const ncp: u21 = try fmt.parseInt(u21, scp, 16);
            cp_list[i] = ncp;
            i += 1;
        }
        cp_list = self.allocator.shrink(cp_list, i);
        try self.fold_map.put(code_point, cp_list);
    }
};

fn contains(slice: []u21, cp: u21) bool {
    for (slice) |item| {
        if (item == cp) return true;
    }
    return false;
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    var allocator = &arena.allocator;
    //var allocator = std.testing.allocator;
    var ugen = try UcdGenerator.init(allocator);
    defer ugen.deinit();
    try ugen.gen();
}
