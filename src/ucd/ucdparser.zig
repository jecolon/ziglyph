const std = @import("std");

const AutoHashMap = std.AutoHashMap;
const ascii = std.ascii;
const fs = std.fs;
const fmt = std.fmt;
const io = std.io;
const mem = std.mem;
const print = std.io.getStdOut().writer().print;
const expect = std.testing.expect;
const expectEqual = std.testing.expectEqual;
const expectEqualSlices = std.testing.expectEqualSlices;
const unicode = std.unicode;

const Ziglyph = struct {
    allocator: *mem.Allocator,

    u8_control_map: AutoHashMap(u8, void),
    u16_control_map: AutoHashMap(u16, void),
    u21_control_map: AutoHashMap(u21, void),

    u8_letter_map: AutoHashMap(u8, void),
    u16_letter_map: AutoHashMap(u16, void),
    u21_letter_map: AutoHashMap(u21, void),

    u8_lower_map: AutoHashMap(u8, void),
    u16_lower_map: AutoHashMap(u16, void),
    u21_lower_map: AutoHashMap(u21, void),

    u8_mark_map: AutoHashMap(u8, void),
    u16_mark_map: AutoHashMap(u16, void),
    u21_mark_map: AutoHashMap(u21, void),

    u8_number_map: AutoHashMap(u8, void),
    u16_number_map: AutoHashMap(u16, void),
    u21_number_map: AutoHashMap(u21, void),

    u8_punct_map: AutoHashMap(u8, void),
    u16_punct_map: AutoHashMap(u16, void),
    u21_punct_map: AutoHashMap(u21, void),

    u8_space_map: AutoHashMap(u8, void),
    u16_space_map: AutoHashMap(u16, void),
    u21_space_map: AutoHashMap(u21, void),

    u8_symbol_map: AutoHashMap(u8, void),
    u16_symbol_map: AutoHashMap(u16, void),
    u21_symbol_map: AutoHashMap(u21, void),

    u8_title_map: AutoHashMap(u8, void),
    u16_title_map: AutoHashMap(u16, void),
    u21_title_map: AutoHashMap(u21, void),

    u8_upper_map: AutoHashMap(u8, void),
    u16_upper_map: AutoHashMap(u16, void),
    u21_upper_map: AutoHashMap(u21, void),

    u8_2l_map: AutoHashMap(u8, u21),
    u16_2l_map: AutoHashMap(u16, u21),
    u21_2l_map: AutoHashMap(u21, u21),

    u8_2u_map: AutoHashMap(u8, u21),
    u16_2u_map: AutoHashMap(u16, u21),
    u21_2u_map: AutoHashMap(u21, u21),

    u8_2t_map: AutoHashMap(u8, u21),
    u16_2t_map: AutoHashMap(u16, u21),
    u21_2t_map: AutoHashMap(u21, u21),

    u8_decomp_map: AutoHashMap(u8, []const u21),
    u16_decomp_map: AutoHashMap(u16, []const u21),
    u21_decomp_map: AutoHashMap(u21, []const u21),

    pub fn init(allocator: *mem.Allocator) !Ziglyph {
        const file = try fs.cwd().openFile("UnicodeData.txt", .{});
        defer file.close();
        var buf_reader = io.bufferedReader(file.reader());
        const stream = buf_reader.reader();

        var z = Ziglyph{
            .allocator = allocator,

            .u8_control_map = AutoHashMap(u8, void).init(allocator),
            .u16_control_map = AutoHashMap(u16, void).init(allocator),
            .u21_control_map = AutoHashMap(u21, void).init(allocator),

            .u8_letter_map = AutoHashMap(u8, void).init(allocator),
            .u16_letter_map = AutoHashMap(u16, void).init(allocator),
            .u21_letter_map = AutoHashMap(u21, void).init(allocator),

            .u8_lower_map = AutoHashMap(u8, void).init(allocator),
            .u16_lower_map = AutoHashMap(u16, void).init(allocator),
            .u21_lower_map = AutoHashMap(u21, void).init(allocator),

            .u8_mark_map = AutoHashMap(u8, void).init(allocator),
            .u16_mark_map = AutoHashMap(u16, void).init(allocator),
            .u21_mark_map = AutoHashMap(u21, void).init(allocator),

            .u8_number_map = AutoHashMap(u8, void).init(allocator),
            .u16_number_map = AutoHashMap(u16, void).init(allocator),
            .u21_number_map = AutoHashMap(u21, void).init(allocator),

            .u8_punct_map = AutoHashMap(u8, void).init(allocator),
            .u16_punct_map = AutoHashMap(u16, void).init(allocator),
            .u21_punct_map = AutoHashMap(u21, void).init(allocator),

            .u8_space_map = AutoHashMap(u8, void).init(allocator),
            .u16_space_map = AutoHashMap(u16, void).init(allocator),
            .u21_space_map = AutoHashMap(u21, void).init(allocator),

            .u8_symbol_map = AutoHashMap(u8, void).init(allocator),
            .u16_symbol_map = AutoHashMap(u16, void).init(allocator),
            .u21_symbol_map = AutoHashMap(u21, void).init(allocator),

            .u8_title_map = AutoHashMap(u8, void).init(allocator),
            .u16_title_map = AutoHashMap(u16, void).init(allocator),
            .u21_title_map = AutoHashMap(u21, void).init(allocator),

            .u8_upper_map = AutoHashMap(u8, void).init(allocator),
            .u16_upper_map = AutoHashMap(u16, void).init(allocator),
            .u21_upper_map = AutoHashMap(u21, void).init(allocator),

            .u8_2l_map = AutoHashMap(u8, u21).init(allocator),
            .u16_2l_map = AutoHashMap(u16, u21).init(allocator),
            .u21_2l_map = AutoHashMap(u21, u21).init(allocator),

            .u8_2u_map = AutoHashMap(u8, u21).init(allocator),
            .u16_2u_map = AutoHashMap(u16, u21).init(allocator),
            .u21_2u_map = AutoHashMap(u21, u21).init(allocator),

            .u8_2t_map = AutoHashMap(u8, u21).init(allocator),
            .u16_2t_map = AutoHashMap(u16, u21).init(allocator),
            .u21_2t_map = AutoHashMap(u21, u21).init(allocator),

            .u8_decomp_map = AutoHashMap(u8, []const u21).init(allocator),
            .u16_decomp_map = AutoHashMap(u16, []const u21).init(allocator),
            .u21_decomp_map = AutoHashMap(u21, []const u21).init(allocator),
        };

        var buf: [256]u8 = undefined;
        while (try stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
            var fields = mem.split(line, ";");
            var i: usize = 0;
            var code_point: u21 = undefined;
            while (fields.next()) |field| : (i += 1) {
                // Major categories.
                if (i == 2 and field.len != 0) {
                    switch (field[0]) {
                        'C' => {
                            if (code_point < 256) {
                                try z.u8_control_map.put(@intCast(u8, code_point), {});
                            } else if (code_point < 65536) {
                                try z.u16_control_map.put(@intCast(u16, code_point), {});
                            } else {
                                try z.u21_control_map.put(code_point, {});
                            }
                        },
                        'L' => {
                            if (code_point < 256) {
                                try z.u8_letter_map.put(@intCast(u8, code_point), {});
                            } else if (code_point < 65536) {
                                try z.u16_letter_map.put(@intCast(u16, code_point), {});
                            } else {
                                try z.u21_letter_map.put(code_point, {});
                            }
                        },
                        'N' => {
                            if (code_point < 256) {
                                try z.u8_number_map.put(@intCast(u8, code_point), {});
                            } else if (code_point < 65536) {
                                try z.u16_number_map.put(@intCast(u16, code_point), {});
                            } else {
                                try z.u21_number_map.put(code_point, {});
                            }
                        },
                        'P' => {
                            if (code_point < 256) {
                                try z.u8_punct_map.put(@intCast(u8, code_point), {});
                            } else if (code_point < 65536) {
                                try z.u16_punct_map.put(@intCast(u16, code_point), {});
                            } else {
                                try z.u21_punct_map.put(code_point, {});
                            }
                        },
                        'S' => {
                            if (code_point < 256) {
                                try z.u8_symbol_map.put(@intCast(u8, code_point), {});
                            } else if (code_point < 65536) {
                                try z.u16_symbol_map.put(@intCast(u16, code_point), {});
                            } else {
                                try z.u21_symbol_map.put(code_point, {});
                            }
                        },
                        else => if (mem.eql(u8, field, "Zs")) {
                            if (code_point < 256) {
                                try z.u8_space_map.put(@intCast(u8, code_point), {});
                            } else if (code_point < 65536) {
                                try z.u16_space_map.put(@intCast(u16, code_point), {});
                            } else {
                                try z.u21_space_map.put(code_point, {});
                            }
                        },
                    }
                }
                if (i == 0) {
                    // Parse code point.
                    code_point = try fmt.parseInt(u21, field, 16);
                } else if (i == 2 and mem.eql(u8, field, "Ll")) {
                    // Lowercase.
                    if (code_point < 256) {
                        try z.u8_lower_map.put(@intCast(u8, code_point), {});
                    } else if (code_point < 65536) {
                        try z.u16_lower_map.put(@intCast(u16, code_point), {});
                    } else {
                        try z.u21_lower_map.put(code_point, {});
                    }
                } else if (i == 2 and mem.eql(u8, field, "Lu")) {
                    // Uppercase.
                    if (code_point < 256) {
                        try z.u8_upper_map.put(@intCast(u8, code_point), {});
                    } else if (code_point < 65536) {
                        try z.u16_upper_map.put(@intCast(u16, code_point), {});
                    } else {
                        try z.u21_upper_map.put(code_point, {});
                    }
                } else if (i == 2 and mem.eql(u8, field, "Lt")) {
                    // Titlecase.
                    if (code_point < 256) {
                        try z.u8_title_map.put(@intCast(u8, code_point), {});
                    } else if (code_point < 65536) {
                        try z.u16_title_map.put(@intCast(u16, code_point), {});
                    } else {
                        try z.u21_title_map.put(code_point, {});
                    }
                } else if (i == 2 and field.len != 0 and field[0] == 'M') {
                    // Mark.
                    if (code_point < 256) {
                        try z.u8_mark_map.put(@intCast(u8, code_point), {});
                    } else if (code_point < 65536) {
                        try z.u16_mark_map.put(@intCast(u16, code_point), {});
                    } else {
                        try z.u21_mark_map.put(code_point, {});
                    }
                } else if (i == 5 and field.len != 0) {
                    // Decomposition.
                    var seq = mem.split(field, " ");
                    var cp_list = try allocator.alloc(u21, 18);
                    var j: usize = 0;
                    while (seq.next()) |scp| {
                        if (scp.len == 0 or scp[0] == '<') continue;
                        const ncp: u21 = try fmt.parseInt(u21, scp, 16);
                        cp_list[j] = ncp;
                        j += 1;
                    }
                    if (code_point < 256) {
                        try z.u8_decomp_map.put(@intCast(u8, code_point), cp_list[0..j]);
                    } else if (code_point < 65536) {
                        try z.u16_decomp_map.put(@intCast(u16, code_point), cp_list[0..j]);
                    } else {
                        try z.u21_decomp_map.put(code_point, cp_list[0..j]);
                    }
                } else if (i == 12 and field.len != 0) {
                    // Map to uppercase.
                    const ucp: u21 = try fmt.parseInt(u21, field, 16);
                    if (code_point < 256) {
                        try z.u8_2u_map.put(@intCast(u8, code_point), ucp);
                    } else if (code_point < 65536) {
                        try z.u16_2u_map.put(@intCast(u16, code_point), ucp);
                    } else {
                        try z.u21_2u_map.put(code_point, ucp);
                    }
                } else if (i == 13 and field.len != 0) {
                    // Map to lowercase.
                    const lcp: u21 = try fmt.parseInt(u21, field, 16);
                    if (code_point < 256) {
                        try z.u8_2l_map.put(@intCast(u8, code_point), lcp);
                    } else if (code_point < 65536) {
                        try z.u16_2l_map.put(@intCast(u16, code_point), lcp);
                    } else {
                        try z.u21_2l_map.put(code_point, lcp);
                    }
                } else if (i == 14 and field.len != 0) {
                    // Map to titlecase.
                    const tcp: u21 = try fmt.parseInt(u21, field, 16);
                    if (code_point < 256) {
                        try z.u8_2t_map.put(@intCast(u8, code_point), tcp);
                    } else if (code_point < 65536) {
                        try z.u16_2t_map.put(@intCast(u16, code_point), tcp);
                    } else {
                        try z.u21_2t_map.put(code_point, tcp);
                    }
                } else {
                    continue;
                }
            }
        }

        return z;
    }

    const Self = @This();

    pub fn deinit(self: *Self) void {
        self.u8_control_map.deinit();
        self.u16_control_map.deinit();
        self.u21_control_map.deinit();

        self.u8_letter_map.deinit();
        self.u16_letter_map.deinit();
        self.u21_letter_map.deinit();

        self.u8_lower_map.deinit();
        self.u16_lower_map.deinit();
        self.u21_lower_map.deinit();

        self.u8_mark_map.deinit();
        self.u16_mark_map.deinit();
        self.u21_mark_map.deinit();

        self.u8_number_map.deinit();
        self.u16_number_map.deinit();
        self.u21_number_map.deinit();

        self.u8_punct_map.deinit();
        self.u16_punct_map.deinit();
        self.u21_punct_map.deinit();

        self.u8_space_map.deinit();
        self.u16_space_map.deinit();
        self.u21_space_map.deinit();

        self.u8_symbol_map.deinit();
        self.u16_symbol_map.deinit();
        self.u21_symbol_map.deinit();

        self.u8_title_map.deinit();
        self.u16_title_map.deinit();
        self.u21_title_map.deinit();

        self.u8_upper_map.deinit();
        self.u16_upper_map.deinit();
        self.u21_upper_map.deinit();

        self.u8_2l_map.deinit();
        self.u16_2l_map.deinit();
        self.u21_2l_map.deinit();

        self.u8_2u_map.deinit();
        self.u16_2u_map.deinit();
        self.u21_2u_map.deinit();

        self.u8_2t_map.deinit();
        self.u16_2t_map.deinit();
        self.u21_2t_map.deinit();

        var u8_iter = self.u8_decomp_map.iterator();
        while (u8_iter.next()) |entry| {
            self.allocator.free(entry.value);
        }
        self.u8_decomp_map.deinit();
        var u16_iter = self.u16_decomp_map.iterator();
        while (u16_iter.next()) |entry| {
            self.allocator.free(entry.value);
        }
        self.u16_decomp_map.deinit();
        var u21_iter = self.u21_decomp_map.iterator();
        while (u21_iter.next()) |entry| {
            self.allocator.free(entry.value);
        }
        self.u21_decomp_map.deinit();
    }

    pub fn decompose(self: Self, cp: u21) ?[]const u21 {
        if (cp < 256) {
            return self.u8_decomp_map.get(@intCast(u8, cp));
        } else if (cp < 65536) {
            return self.u16_decomp_map.get(@intCast(u16, cp));
        } else {
            return self.u21_decomp_map.get(cp);
        }
    }

    pub fn isAlphaNum(self: Self, cp: u21) bool {
        return self.isLetter(cp) or self.isNumber(cp);
    }

    pub fn isControl(self: Self, cp: u21) bool {
        if (cp < 256) {
            return self.u8_control_map.get(@intCast(u8, cp)) != null;
        } else if (cp < 65536) {
            return self.u16_control_map.get(@intCast(u16, cp)) != null;
        } else {
            return self.u21_control_map.get(cp) != null;
        }
    }

    pub fn isGraphic(self: Self, cp: u21) bool {
        return self.isPrint(cp) or self.isSpace(cp);
    }

    pub fn isLetter(self: Self, cp: u21) bool {
        if (cp < 256) {
            return self.u8_letter_map.get(@intCast(u8, cp)) != null;
        } else if (cp < 65536) {
            return self.u16_letter_map.get(@intCast(u16, cp)) != null;
        } else {
            return self.u21_letter_map.get(cp) != null;
        }
    }

    pub fn isLower(self: Self, cp: u21) bool {
        if (cp < 256) {
            return self.u8_lower_map.get(@intCast(u8, cp)) != null;
        } else if (cp < 65536) {
            return self.u16_lower_map.get(@intCast(u16, cp)) != null;
        } else {
            return self.u21_lower_map.get(cp) != null;
        }
    }

    pub fn isMark(self: Self, cp: u21) bool {
        if (cp < 256) {
            return self.u8_mark_map.get(@intCast(u8, cp)) != null;
        } else if (cp < 65536) {
            return self.u16_mark_map.get(@intCast(u16, cp)) != null;
        } else {
            return self.u21_mark_map.get(cp) != null;
        }
    }

    pub fn isNumber(self: Self, cp: u21) bool {
        if (cp < 256) {
            return self.u8_number_map.get(@intCast(u8, cp)) != null;
        } else if (cp < 65536) {
            return self.u16_number_map.get(@intCast(u16, cp)) != null;
        } else {
            return self.u21_number_map.get(cp) != null;
        }
    }

    pub fn isPrint(self: Self, cp: u21) bool {
        return self.isAlphaNum(cp) or self.isMark(cp) or self.isPunct(cp) or self.isSymbol(cp);
    }

    pub fn isPunct(self: Self, cp: u21) bool {
        if (cp < 256) {
            return self.u8_punct_map.get(@intCast(u8, cp)) != null;
        } else if (cp < 65536) {
            return self.u16_punct_map.get(@intCast(u16, cp)) != null;
        } else {
            return self.u21_punct_map.get(cp) != null;
        }
    }

    pub fn isSpace(self: Self, cp: u21) bool {
        if (cp < 256) {
            if (self.u8_space_map.get(@intCast(u8, cp)) != null) {
                return true;
            } else {
                for (ascii.spaces) |s| {
                    if (cp == s) return true;
                }
                return false;
            }
        } else if (cp < 65536) {
            return self.u16_space_map.get(@intCast(u16, cp)) != null;
        } else {
            return self.u21_space_map.get(cp) != null;
        }
    }

    pub fn isSymbol(self: Self, cp: u21) bool {
        if (cp < 256) {
            return self.u8_symbol_map.get(@intCast(u8, cp)) != null;
        } else if (cp < 65536) {
            return self.u16_symbol_map.get(@intCast(u16, cp)) != null;
        } else {
            return self.u21_symbol_map.get(cp) != null;
        }
    }

    pub fn isTitle(self: Self, cp: u21) bool {
        if (cp < 256) {
            return self.u8_title_map.get(@intCast(u8, cp)) != null;
        } else if (cp < 65536) {
            return self.u16_title_map.get(@intCast(u16, cp)) != null;
        } else {
            return self.u21_title_map.get(cp) != null;
        }
    }

    pub fn isUpper(self: Self, cp: u21) bool {
        if (cp < 256) {
            return self.u8_upper_map.get(@intCast(u8, cp)) != null;
        } else if (cp < 65536) {
            return self.u16_upper_map.get(@intCast(u16, cp)) != null;
        } else {
            return self.u21_upper_map.get(cp) != null;
        }
    }

    // Caller must free memory.
    pub fn normalize(self: Self, str: []const u8) ![]const u8 {
        var code_points = try self.allocator.alloc(u21, str.len);
        defer self.allocator.free(code_points);
        var index: usize = 0;
        var utf8 = (try unicode.Utf8View.init(str)).iterator();
        while (utf8.nextCodepoint()) |code_point| : (index += 1) {
            code_points[index] = code_point;
        }
        const len_old_points = index;

        var new_points = try self.allocator.alloc(u21, (len_old_points + 1) * 18); // Max composition code points = 18
        defer self.allocator.free(new_points);
        index = 0;
        var index_new_points: usize = 0;
        while (index < len_old_points) : (index += 1) {
            const cp = code_points[index];
            if (cp < 256) {
                if (self.u8_decomp_map.get(@intCast(u8, cp))) |seq| {
                    for (seq) |scp| {
                        new_points[index_new_points] = scp;
                        index_new_points += 1;
                    }
                } else {
                    new_points[index_new_points] = cp;
                    index_new_points += 1;
                }
            } else if (cp < 65536) {
                if (self.u16_decomp_map.get(@intCast(u16, cp))) |seq| {
                    for (seq) |scp| {
                        new_points[index_new_points] = scp;
                        index_new_points += 1;
                    }
                } else {
                    new_points[index_new_points] = cp;
                    index_new_points += 1;
                }
            } else {
                if (self.u21_decomp_map.get(cp)) |seq| {
                    for (seq) |scp| {
                        new_points[index_new_points] = scp;
                        index_new_points += 1;
                    }
                } else {
                    new_points[index_new_points] = cp;
                    index_new_points += 1;
                }
            }
        }
        const len_new_points = index_new_points;

        var result = try self.allocator.alloc(u8, @divFloor(len_new_points * 21, 8) + 1);
        index = 0;
        var index_result: usize = 0;
        while (index < len_new_points) : (index += 1) {
            const bytes_written = try unicode.utf8Encode(new_points[index], result[index_result..]);
            index_result += bytes_written;
        }
        const len_result = index_result;

        result = self.allocator.shrink(result, len_result);
        return result[0..];
    }

    pub fn toLower(self: Self, cp: u21) u21 {
        if (cp < 256) {
            if (self.u8_2l_map.get(@intCast(u8, cp))) |lcp| {
                return lcp;
            } else {
                return cp;
            }
        }

        if (cp < 65536) {
            if (self.u16_2l_map.get(@intCast(u16, cp))) |lcp| {
                return lcp;
            } else {
                return cp;
            }
        }

        if (self.u16_2l_map.get(@intCast(u16, cp))) |lcp| {
            return lcp;
        } else {
            return cp;
        }
    }

    pub fn toTitle(self: Self, cp: u21) u21 {
        if (cp < 256) {
            if (self.u8_2t_map.get(@intCast(u8, cp))) |lcp| {
                return lcp;
            } else {
                return cp;
            }
        }

        if (cp < 65536) {
            if (self.u16_2t_map.get(@intCast(u16, cp))) |lcp| {
                return lcp;
            } else {
                return cp;
            }
        }

        if (self.u16_2t_map.get(@intCast(u16, cp))) |lcp| {
            return lcp;
        } else {
            return cp;
        }
    }

    pub fn toUpper(self: Self, cp: u21) u21 {
        if (cp < 256) {
            if (self.u8_2u_map.get(@intCast(u8, cp))) |lcp| {
                return lcp;
            } else {
                return cp;
            }
        }

        if (cp < 65536) {
            if (self.u16_2u_map.get(@intCast(u16, cp))) |lcp| {
                return lcp;
            } else {
                return cp;
            }
        }

        if (self.u16_2u_map.get(@intCast(u16, cp))) |lcp| {
            return lcp;
        } else {
            return cp;
        }
    }
};

test "isLower" {
    var z = try Ziglyph.init(std.testing.allocator);
    defer z.deinit();

    expect(z.isLower('a'));
    expect(z.isLower('é'));
    expect(z.isLower('i'));
    expect(!z.isLower('A'));
    expect(!z.isLower('É'));
    expect(!z.isLower('İ'));
}

test "toLower" {
    var z = try Ziglyph.init(std.testing.allocator);
    defer z.deinit();

    expectEqual(z.toLower('a'), 'a');
    expectEqual(z.toLower('A'), 'a');
    expectEqual(z.toLower('İ'), 'i');
    expectEqual(z.toLower('É'), 'é');
    expectEqual(z.toLower(0x80), 0x80);
    expectEqual(z.toLower(0x80), 0x80);
    expectEqual(z.toLower('Å'), 'å');
    expectEqual(z.toLower('å'), 'å');
    expectEqual(z.toLower('\u{212A}'), 'k');
}

test "isUpper" {
    var z = try Ziglyph.init(std.testing.allocator);
    defer z.deinit();

    expect(!z.isUpper('a'));
    expect(!z.isUpper('é'));
    expect(!z.isUpper('i'));
    expect(z.isUpper('A'));
    expect(z.isUpper('É'));
    expect(z.isUpper('İ'));
}

test "toUpper" {
    var z = try Ziglyph.init(std.testing.allocator);
    defer z.deinit();

    expectEqual(z.toUpper('a'), 'A');
    expectEqual(z.toUpper('A'), 'A');
    expectEqual(z.toUpper('i'), 'I');
    expectEqual(z.toUpper('é'), 'É');
    expectEqual(z.toUpper(0x80), 0x80);
    expectEqual(z.toUpper('Å'), 'Å');
    expectEqual(z.toUpper('å'), 'Å');
}

test "isTitle" {
    var z = try Ziglyph.init(std.testing.allocator);
    defer z.deinit();

    expect(!z.isTitle('a'));
    expect(!z.isTitle('é'));
    expect(!z.isTitle('i'));
    expect(z.isTitle('\u{1FBC}'));
    expect(z.isTitle('\u{1FCC}'));
    expect(z.isTitle('ǈ'));
}

test "toTitle" {
    var z = try Ziglyph.init(std.testing.allocator);
    defer z.deinit();

    expectEqual(z.toTitle('a'), 'A');
    expectEqual(z.toTitle('A'), 'A');
    expectEqual(z.toTitle('i'), 'I');
    expectEqual(z.toTitle('é'), 'É');
}

test "isControl" {
    var z = try Ziglyph.init(std.testing.allocator);
    defer z.deinit();

    expect(z.isControl('\u{0003}'));
    expect(z.isControl('\u{0012}'));
    expect(!z.isControl('A'));
}

test "isGraphic" {
    var z = try Ziglyph.init(std.testing.allocator);
    defer z.deinit();

    expect(z.isGraphic('A'));
    expect(z.isGraphic('\u{20E4}'));
    expect(z.isGraphic('1'));
    expect(z.isGraphic('?'));
    expect(z.isGraphic(' '));
    expect(z.isGraphic('='));
    expect(!z.isGraphic('\u{0003}'));
}

test "isPrint" {
    var z = try Ziglyph.init(std.testing.allocator);
    defer z.deinit();

    expect(z.isPrint('A'));
    expect(z.isPrint('\u{20E4}'));
    expect(z.isPrint('1'));
    expect(z.isPrint('?'));
    expect(z.isPrint('='));
    expect(!z.isPrint(' '));
    expect(!z.isPrint('\t'));
    expect(!z.isPrint('\u{0003}'));
}

test "isLetter" {
    var z = try Ziglyph.init(std.testing.allocator);
    defer z.deinit();

    expect(z.isLetter('A'));
    expect(z.isLetter('É'));
    expect(!z.isLetter('\u{0003}'));
}

test "isMark" {
    var z = try Ziglyph.init(std.testing.allocator);
    defer z.deinit();

    expect(z.isMark('\u{20E4}'));
    expect(!z.isMark('='));
}

test "isNumber" {
    var z = try Ziglyph.init(std.testing.allocator);
    defer z.deinit();

    expect(z.isNumber('1'));
    expect(z.isNumber('0'));
    expect(!z.isNumber('\u{0003}'));
    expect(!z.isNumber('A'));
}

test "isPunct" {
    var z = try Ziglyph.init(std.testing.allocator);
    defer z.deinit();

    expect(z.isPunct('!'));
    expect(z.isPunct('?'));
    expect(!z.isPunct('\u{0003}'));
}

test "isSpace" {
    var z = try Ziglyph.init(std.testing.allocator);
    defer z.deinit();

    expect(z.isSpace(' '));
    expect(z.isSpace('\t'));
    expect(!z.isSpace('\u{0003}'));
}

test "isSymbol" {
    var z = try Ziglyph.init(std.testing.allocator);
    defer z.deinit();

    expect(z.isSymbol('>'));
    expect(z.isSymbol('='));
    expect(!z.isSymbol('A'));
    expect(!z.isSymbol('?'));
}

test "isAlphaNum" {
    var z = try Ziglyph.init(std.testing.allocator);
    defer z.deinit();

    expect(z.isAlphaNum('1'));
    expect(z.isAlphaNum('A'));
    expect(!z.isAlphaNum('='));
}

test "decompose" {
    var z = try Ziglyph.init(std.testing.allocator);
    defer z.deinit();

    expectEqualSlices(u21, z.decompose('\u{00E9}').?, &[_]u21{ '\u{0065}', '\u{0301}' });
}

test "normalize" {
    var z = try Ziglyph.init(std.testing.allocator);
    defer z.deinit();

    const input = "H\u{00E9}llo";
    const want = "H\u{0065}\u{0301}llo";
    const got = try z.normalize(input);
    defer std.testing.allocator.free(got);
    expectEqualSlices(u8, want, got);
}
