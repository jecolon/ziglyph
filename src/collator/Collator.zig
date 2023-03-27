const std = @import("std");

const ccc_map = @import("../ziglyph.zig").combining_map;
const Normalizer = @import("../ziglyph.zig").Normalizer;
const props = @import("../ziglyph.zig").prop_list;

const Element = struct {
    l1: u16 = 0,
    l2: u16 = 0,
    l3: u8 = 0,
};

const Implicit = struct {
    start: u21,
    end: u21,
    base: u16,
};

const Self = @This();

ducet: std.AutoHashMap([3]u21, [18]?Element),
implicits: [4]Implicit,
normalizer: Normalizer,

pub fn init(allocator: std.mem.Allocator) !Self {
    var self = Self{
        .ducet = std.AutoHashMap([3]u21, [18]?Element).init(allocator),
        .implicits = undefined,
        .normalizer = try Normalizer.init(allocator),
    };
    errdefer self.deinit();

    // allkeys-strip.txt file.
    const ak_gz_file = @embedFile("../data/uca/allkeys-diffs.txt.gz");
    var ak_in_stream = std.io.fixedBufferStream(ak_gz_file);
    var ak_gzip_stream = try std.compress.gzip.decompress(allocator, ak_in_stream.reader());
    defer ak_gzip_stream.deinit();

    var ak_br = std.io.bufferedReader(ak_gzip_stream.reader());
    const ak_reader = ak_br.reader();
    var buf: [256]u8 = undefined;
    var line_num: usize = 0;

    // Diff state
    var prev_cp: u21 = 0;
    var cp_diff: isize = 0;
    var prev_l1: u16 = 0;
    var l1_diff: isize = 0;

    while (try ak_reader.readUntilDelimiterOrEof(&buf, '\n')) |line| : (line_num += 1) {
        var fields = std.mem.split(u8, line, ";");

        // Will the number of implicits change in a future version of Unicode?
        if (line_num < 4) {
            self.implicits[line_num] = Implicit{
                .start = try std.fmt.parseInt(u21, fields.next().?, 16),
                .end = try std.fmt.parseInt(u21, fields.next().?, 16),
                .base = try std.fmt.parseInt(u16, fields.next().?, 16),
            };

            continue;
        }

        var i: usize = 0;
        var cps = [_]u21{0} ** 3;
        var cp_diff_strs = std.mem.split(u8, fields.next().?, " ");

        while (cp_diff_strs.next()) |cp_diff_str| : (i += 1) {
            cp_diff = try std.fmt.parseInt(isize, cp_diff_str, 16);
            prev_cp = @intCast(u21, @as(isize, prev_cp) + cp_diff);
            cps[i] = prev_cp;
        }

        i = 0;
        var elements = [_]?Element{null} ** 18;

        while (fields.next()) |element_diff_str| : (i += 1) {
            // i.e. 3D3;-42
            if (std.mem.indexOf(u8, element_diff_str, ".") == null) {
                l1_diff = try std.fmt.parseInt(isize, element_diff_str, 16);
                prev_l1 = @intCast(u16, @as(isize, prev_l1) + l1_diff);

                elements[i] = Element{
                    .l1 = prev_l1,
                    .l2 = 0x20,
                    .l3 = 0x2,
                };

                continue;
            }

            var weight_strs = std.mem.split(u8, element_diff_str, ".");
            l1_diff = try std.fmt.parseInt(isize, weight_strs.next().?, 16);
            prev_l1 = @intCast(u16, @as(isize, prev_l1) + l1_diff);
            elements[i] = Element{ .l1 = prev_l1 };

            var j: usize = 0;
            while (weight_strs.next()) |weight_str| : (j += 1) {
                if (weight_str.len == 1 and weight_str[0] == ')') {
                    elements[i].?.l2 = 0;
                    elements[i].?.l3 = 0;
                    break;
                }

                if (weight_str[0] == '@') {
                    elements[i].?.l2 = 0x20;
                    elements[i].?.l3 = try std.fmt.parseInt(u8, weight_str[1..], 16);
                    break;
                }

                switch (j) {
                    0 => elements[i].?.l2 = try std.fmt.parseInt(u16, weight_str, 16),
                    1 => elements[i].?.l3 = try std.fmt.parseInt(u8, weight_str, 16),
                    else => unreachable,
                }
            }
        }

        try self.ducet.put(cps, elements);
    }

    return self;
}

pub fn deinit(self: *Self) void {
    self.ducet.deinit();
    self.normalizer.deinit();
}

test "init / deinit" {
    var c = try init(std.testing.allocator);
    defer c.deinit();

    try std.testing.expectEqual(@as(u16, 0xfb00), c.implicits[0].base);
    //try std.testing.expectEqual(@as(usize, 34193), c.ducet.count()); // All
    try std.testing.expectEqual(@as(usize, 32130), c.ducet.count()); // NFD only
}

fn implicitWeight(self: Self, cp: u21) [18]?Element {
    var base: u16 = 0;
    var aaaa: u16 = 0;
    var bbbb: u16 = 0;

    if (props.isUnifiedIdeograph(cp) and ((0x4E00 <= cp and cp <= 0x9FFF) or (0xF900 <= cp and cp <= 0xFAFF))) {
        base = 0xFB40;
        aaaa = base + @intCast(u16, (cp >> 15));
        bbbb = @intCast(u16, (cp & 0x7FFF)) | 0x8000;
    } else if (props.isUnifiedIdeograph(cp) and !((0x4E00 <= cp and cp <= 0x9FFF) or (0xF900 <= cp and cp <= 0xFAFF))) {
        base = 0xFB80;
        aaaa = base + @intCast(u16, (cp >> 15));
        bbbb = @intCast(u16, (cp & 0x7FFF)) | 0x8000;
    } else {
        for (self.implicits) |implicit| {
            if (implicit.start <= cp and cp <= implicit.end) {
                aaaa = implicit.base;

                if (0x18D00 <= cp and cp <= 0x18D8F) {
                    bbbb = @truncate(u16, (cp - 17000)) | 0x8000;
                } else {
                    bbbb = @intCast(u16, (cp - implicit.start)) | 0x8000;
                }

                break;
            }
        }

        if (aaaa == 0) {
            base = 0xFBC0;
            aaaa = base + @intCast(u16, (cp >> 15));
            bbbb = @intCast(u16, (cp & 0x7FFF)) | 0x8000;
        }
    }

    var elements = [_]?Element{null} ** 18;
    elements[0] = Element{ .l1 = aaaa, .l2 = 0x0020, .l3 = 0x0002 };
    elements[1] = Element{ .l1 = bbbb, .l2 = 0x0000, .l3 = 0x0000 };

    return elements;
}

fn getElements(self: Self, allocator: std.mem.Allocator, str: []const u8) ![]const Element {
    std.debug.assert(str.len > 0);

    var normalized = try self.normalizer.nfd(allocator, str);
    defer normalized.deinit();

    var cp_list = try std.ArrayList(u21).initCapacity(allocator, normalized.slice.len);
    defer cp_list.deinit();
    const view = try std.unicode.Utf8View.init(normalized.slice);
    var cp_iter = view.iterator();
    while (cp_iter.nextCodepoint()) |cp| cp_list.appendAssumeCapacity(cp);

    var all_elements = std.ArrayList(Element).init(allocator);
    defer all_elements.deinit();

    var cp_index: usize = 0;

    while (cp_index < cp_list.items.len) {
        var S: [3]u21 = undefined;
        var s_len: usize = 3;
        var elements: ?[18]?Element = null;

        if (cp_list.items.len > cp_index + 2) {
            S[0] = cp_list.items[cp_index];
            S[1] = cp_list.items[cp_index + 1];
            S[2] = cp_list.items[cp_index + 2];
            elements = self.ducet.get(S);
        }

        if (elements == null and cp_list.items.len > cp_index + 1) {
            S[0] = cp_list.items[cp_index];
            S[1] = cp_list.items[cp_index + 1];
            S[2] = 0;
            s_len = 2;
            elements = self.ducet.get(S);
        }

        if (elements == null) {
            S[0] = cp_list.items[cp_index];
            S[1] = 0;
            S[2] = 0;
            s_len = 1;
            elements = self.ducet.get(S);
        }

        if (elements != null and s_len < 3) {
            // Handle non-starters
            var prev_ccc: ?u8 = null;
            const tail_start = cp_index + s_len; // 1 past S
            var tail_index = tail_start;

            // Advance to last combining C.
            while (tail_index < cp_list.items.len) : (tail_index += 1) {
                const ccc = ccc_map.combiningClass(cp_list.items[tail_index]);
                if (ccc == 0 or (prev_ccc != null and prev_ccc.? >= ccc)) break;
                prev_ccc = ccc;
            }

            if (tail_start != tail_index) { // We have combining characters
                S[s_len] = cp_list.items[tail_index - 1]; // S + C
                s_len += 1;

                if (self.ducet.get(S)) |sc_elements| {
                    // S + C has an entry; Rotate C to be just after S.
                    var segment = cp_list.items[tail_start..tail_index];
                    std.mem.rotate(u21, segment, segment.len - 1);

                    // Add S + C elements to final collection.
                    for (sc_elements) |element_opt| {
                        if (element_opt) |element| {
                            try all_elements.append(element);
                        } else {
                            break;
                        }
                    }

                    cp_index += s_len; // 1 past S + C

                    continue;
                }

                if (s_len < 3) S[s_len] = 0; // back up to just S
                s_len -= 1;
            }
        }

        if (elements == null) {
            // Not in DUCET; derive the elements.
            elements = self.implicitWeight(cp_list.items[cp_index]);
        }

        // Add elements to final collection.
        for (elements.?) |element_opt| {
            if (element_opt) |element| {
                try all_elements.append(element);
            } else {
                break;
            }
        }

        cp_index += s_len; // 1 past S
    }

    return all_elements.toOwnedSlice();
}

test "getElements" {
    var c = try init(std.testing.allocator);
    defer c.deinit();

    const elements_1 = try c.getElements(std.testing.allocator, "ca\u{301}b");
    defer std.testing.allocator.free(elements_1);

    try std.testing.expectEqual(@as(usize, 4), elements_1.len);
    try std.testing.expectEqual(@as(u16, 0x20e7), elements_1[0].l1);
    try std.testing.expectEqual(@as(u16, 0x20b3), elements_1[1].l1);
    try std.testing.expectEqual(@as(u16, 0x0024), elements_1[2].l2);
    try std.testing.expectEqual(@as(u16, 0x20cd), elements_1[3].l1);

    const elements_2 = try c.getElements(std.testing.allocator, "\u{0CC6}\u{0CC2}\u{0CD5}");
    defer std.testing.allocator.free(elements_2);

    try std.testing.expectEqual(@as(usize, 1), elements_2.len);
    try std.testing.expectEqual(@as(u16, 0x2D59), elements_2[0].l1);
    try std.testing.expectEqual(@as(u16, 0x0020), elements_2[0].l2);
    try std.testing.expectEqual(@as(u16, 0x0002), elements_2[0].l3);
}

/// A sort key is a slice of `u16`s that can be compared efficiently.
pub fn sortKey(self: Self, allocator: std.mem.Allocator, str: []const u8) ![]const u16 {
    const elements = try self.getElements(allocator, str);
    defer allocator.free(elements);

    var sort_key = std.ArrayList(u16).init(allocator);
    defer sort_key.deinit();

    var level: usize = 0;
    while (level < 3) : (level += 1) {
        if (level != 0) try sort_key.append(0); // level separator

        for (elements) |element| {
            switch (level) {
                0 => if (element.l1 != 0) try sort_key.append(element.l1),
                1 => if (element.l2 != 0) try sort_key.append(element.l2),
                2 => if (element.l3 != 0) try sort_key.append(element.l3),
                else => unreachable,
            }
        }
    }

    return sort_key.toOwnedSlice();
}

/// Orders strings `a` and `b` based only on the base characters; case and combining marks are ignored.
pub fn primaryOrder(a: []const u16, b: []const u16) std.math.Order {
    return for (a) |weight, i| {
        if (weight == 0) break .eq; // End of level
        const order = std.math.order(weight, b[i]);
        if (order != .eq) break order;
    } else .eq;
}

/// Orders strings `a` and `b` based on base characters and combining marks; case is ignored.
pub fn secondaryOrder(a: []const u16, b: []const u16) std.math.Order {
    var last_level = false;

    return for (a) |weight, i| {
        if (weight == 0) {
            if (last_level) break .eq else last_level = true;
            continue;
        }

        const order = std.math.order(weight, b[i]);
        if (order != .eq) break order;
    } else .eq;
}

/// Orders strings `a` and `b` based on base characters, combining marks, and letter case.
pub fn tertiaryOrder(a: []const u16, b: []const u16) std.math.Order {
    return for (a) |weight, i| {
        const order = std.math.order(weight, b[i]);
        if (order != .eq) break order;
    } else .eq;
}

test "key order" {
    var c = try init(std.testing.allocator);
    defer c.deinit();

    const key_a = try c.sortKey(std.testing.allocator, "cab");
    defer std.testing.allocator.free(key_a);
    const key_b = try c.sortKey(std.testing.allocator, "Cab");
    defer std.testing.allocator.free(key_b);

    try std.testing.expectEqual(std.math.Order.eq, primaryOrder(key_a, key_b));
    try std.testing.expectEqual(std.math.Order.eq, secondaryOrder(key_a, key_b));
    try std.testing.expectEqual(std.math.Order.lt, tertiaryOrder(key_a, key_b));
}

test "key order with combining" {
    var c = try init(std.testing.allocator);
    defer c.deinit();

    const key_a = try c.sortKey(std.testing.allocator, "ca\u{301}b");
    defer std.testing.allocator.free(key_a);
    const key_b = try c.sortKey(std.testing.allocator, "Cab");
    defer std.testing.allocator.free(key_b);

    try std.testing.expectEqual(std.math.Order.eq, primaryOrder(key_a, key_b));
    try std.testing.expectEqual(std.math.Order.gt, secondaryOrder(key_a, key_b));
    try std.testing.expectEqual(std.math.Order.gt, tertiaryOrder(key_a, key_b));
}

/// An ascending sort for strings that works with `std.sort.sort`. Because the API requires this function to be
/// infallible, it just returns `false` on errors.
pub fn ascending(self: Self, a: []const u8, b: []const u8) bool {
    const key_a = self.sortKey(self.ducet.allocator, a) catch return false;
    defer self.ducet.allocator.free(key_a);
    const key_b = self.sortKey(self.ducet.allocator, b) catch return false;
    defer self.ducet.allocator.free(key_b);

    return tertiaryOrder(key_a, key_b) == .lt;
}

/// A descending sort for strings that works with `std.sort.sort`. Because the API requires this function to be
/// infallible, it just returns `false` on errors.
pub fn descending(self: Self, a: []const u8, b: []const u8) bool {
    const key_a = self.sortKey(self.ducet.allocator, a) catch return false;
    defer self.ducet.allocator.free(key_a);
    const key_b = self.sortKey(self.ducet.allocator, b) catch return false;
    defer self.ducet.allocator.free(key_b);

    return tertiaryOrder(key_a, key_b) == .gt;
}

test "sort functions" {
    var c = try init(std.testing.allocator);
    defer c.deinit();

    var strings = [_][]const u8{ "def", "xyz", "abc" };
    var want = [_][]const u8{ "abc", "def", "xyz" };

    std.sort.sort([]const u8, &strings, c, ascending);
    try std.testing.expectEqualSlices([]const u8, &want, &strings);

    want = [_][]const u8{ "xyz", "def", "abc" };
    std.sort.sort([]const u8, &strings, c, descending);
    try std.testing.expectEqualSlices([]const u8, &want, &strings);
}

/// A caseless ascending sort for strings that works with `std.sort.sort`. Because the API requires this function to be
/// infallible, it just returns `false` on errors.
pub fn ascendingCaseless(self: Self, a: []const u8, b: []const u8) bool {
    const key_a = self.sortKey(self.ducet.allocator, a) catch return false;
    defer self.ducet.allocator.free(key_a);
    const key_b = self.sortKey(self.ducet.allocator, b) catch return false;
    defer self.ducet.allocator.free(key_b);

    return secondaryOrder(key_a, key_b) == .lt;
}

/// A caseless descending sort for strings that works with `std.sort.sort`. Because the API requires this function to be
/// infallible, it just returns `false` on errors.
pub fn descendingCaseless(self: Self, a: []const u8, b: []const u8) bool {
    const key_a = self.sortKey(self.ducet.allocator, a) catch return false;
    defer self.ducet.allocator.free(key_a);
    const key_b = self.sortKey(self.ducet.allocator, b) catch return false;
    defer self.ducet.allocator.free(key_b);

    return secondaryOrder(key_a, key_b) == .gt;
}

test "caseless sort functions" {
    var c = try init(std.testing.allocator);
    defer c.deinit();

    var strings = [_][]const u8{ "def", "Abc", "abc" };
    var want = [_][]const u8{ "Abc", "abc", "def" };

    std.sort.sort([]const u8, &strings, c, ascendingCaseless);
    try std.testing.expectEqualSlices([]const u8, &want, &strings);

    want = [_][]const u8{ "def", "Abc", "abc" };
    std.sort.sort([]const u8, &strings, c, descendingCaseless);
    try std.testing.expectEqualSlices([]const u8, &want, &strings);
}

test "caseless / markless sort functions" {
    var c = try init(std.testing.allocator);
    defer c.deinit();

    var strings = [_][]const u8{ "ábc", "Abc", "abc" };
    const want = [_][]const u8{ "ábc", "Abc", "abc" };

    std.sort.sort([]const u8, &strings, c, ascendingBase);
    try std.testing.expectEqualSlices([]const u8, &want, &strings);

    std.sort.sort([]const u8, &strings, c, descendingBase);
    try std.testing.expectEqualSlices([]const u8, &want, &strings);
}

/// An ascending sort for strings that works with `std.sort.sort`. This ignores case and any combining marks like
/// accents.  Because the API requires this function to be infallible, it just returns `false` on errors.
pub fn ascendingBase(self: Self, a: []const u8, b: []const u8) bool {
    const key_a = self.sortKey(self.ducet.allocator, a) catch return false;
    defer self.ducet.allocator.free(key_a);
    const key_b = self.sortKey(self.ducet.allocator, b) catch return false;
    defer self.ducet.allocator.free(key_b);

    return primaryOrder(key_a, key_b) == .lt;
}

/// A descending sort for strings that works with `std.sort.sort`. This ignores case and any combining marks like
/// accents.  Because the API requires this function to be infallible, it just returns `false` on errors.
pub fn descendingBase(self: Self, a: []const u8, b: []const u8) bool {
    const key_a = self.sortKey(self.ducet.allocator, a) catch return false;
    defer self.ducet.allocator.free(key_a);
    const key_b = self.sortKey(self.ducet.allocator, b) catch return false;
    defer self.ducet.allocator.free(key_b);

    return primaryOrder(key_a, key_b) == .gt;
}

test "UCA tests" {
    var path_buf: [1024]u8 = undefined;
    var path = try std.fs.cwd().realpath(".", &path_buf);
    // Check if testing in this library path.
    if (!std.mem.endsWith(u8, path, "ziglyph")) return;

    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    var allocator = arena.allocator();

    var collator = try init(allocator);
    defer collator.deinit();

    const uca_gz_file = try std.fs.cwd().openFile("src/data/uca/CollationTest_NON_IGNORABLE_SHORT.txt.gz", .{});
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

        //std.debug.print("\n{}: {s}\nkey: p: {any} c: {any}\nnfd: p: {any} c: {any}\n", .{
        //    line_num,
        //    raw,
        //    prev_key,
        //    current_key,
        //    prev_nfd.slice,
        //    current_nfd.slice,
        //});

        const order = tertiaryOrder(prev_key, current_key);

        if (order == .gt) return error.PrevKeyGreater;

        // Identical sorting
        if (order == .eq) {
            const len = if (prev_nfd.slice.len > current_nfd.slice.len) current_nfd.slice.len else prev_nfd.slice.len;

            const tie_breaker = for (prev_nfd.slice[0..len]) |prev_cp, i| {
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
