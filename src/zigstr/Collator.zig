const std = @import("std");
const atomic = std.atomic;
const fmt = std.fmt;
const io = std.io;
const mem = std.mem;
const zort = std.sort.sort;
const unicode = std.unicode;

const CccMap = @import("../components.zig").CccMap;
const isAsciiStr = @import("Zigstr.zig").isAsciiStr;
const Normalizer = @import("../components.zig").Normalizer;
const Trie = @import("CollatorTrie.zig");
const UnifiedIdeo = @import("../components/autogen/PropList/UnifiedIdeograph.zig");

const Implicit = struct {
    base: u21,
    start: u21,
    end: u21,
};

const ImplicitList = std.ArrayList(Implicit);

allocator: *mem.Allocator,
ccc_map: CccMap,
normalizer: Normalizer,
ideographs: UnifiedIdeo,
implicits: ImplicitList,
table: Trie,

const Self = @This();

pub fn init(allocator: *mem.Allocator, filename: []const u8) !Self {
    var self = Self{
        .allocator = allocator,
        .ccc_map = CccMap{},
        .normalizer = Normalizer.new(allocator),
        .ideographs = UnifiedIdeo{},
        .implicits = ImplicitList.init(allocator),
        .table = Trie.init(allocator),
    };

    try self.load(filename);

    return self;
}

pub fn deinit(self: *Self) void {
    self.table.deinit();
    self.implicits.deinit();
}

pub fn load(self: *Self, filename: []const u8) !void {
    var uca_file = try std.fs.cwd().openFile(filename, .{});
    defer uca_file.close();
    var uca_reader = io.bufferedReader(uca_file.reader());
    var uca_stream = uca_reader.reader();
    var buf: [1024]u8 = undefined;

    while (try uca_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        // Skip empty or comment.
        if (line.len == 0 or line[0] == '#' or mem.startsWith(u8, line, "@version")) continue;

        var raw = mem.trim(u8, line, " ");
        if (mem.indexOf(u8, line, "#")) |octo| {
            raw = mem.trimRight(u8, line[0..octo], " ");
        }

        if (mem.startsWith(u8, raw, "@implicitweights")) {
            raw = raw[17..]; // 17 == length of "@implicitweights "
            const semi = mem.indexOf(u8, raw, ";").?;
            const ch_range = raw[0..semi];
            const base = mem.trim(u8, raw[semi + 1 ..], " ");

            const dots = mem.indexOf(u8, ch_range, "..").?;
            const range_start = ch_range[0..dots];
            const range_end = ch_range[dots + 2 ..];

            try self.implicits.append(.{
                .base = try fmt.parseInt(u21, base, 16),
                .start = try fmt.parseInt(u21, range_start, 16),
                .end = try fmt.parseInt(u21, range_end, 16),
            });

            continue; // next line.
        }

        const semi = mem.indexOf(u8, raw, ";").?;
        const cp_strs = mem.trim(u8, raw[0..semi], " ");
        var cp_list = std.ArrayList(u21).init(self.allocator);
        defer cp_list.deinit();
        var cp_strs_iter = mem.split(cp_strs, " ");

        while (cp_strs_iter.next()) |cp_str| {
            try cp_list.append(try fmt.parseInt(u21, cp_str, 16));
        }

        var coll_elements = std.ArrayList(Trie.Element).init(self.allocator);
        defer coll_elements.deinit();
        const ce_strs = mem.trim(u8, raw[semi + 1 ..], " ");
        var ce_strs_iter = mem.split(ce_strs[1 .. ce_strs.len - 1], "]["); // no ^[. or ^[* or ]$

        while (ce_strs_iter.next()) |ce_str| {
            const just_levels = ce_str[1..];
            var w_strs_iter = mem.split(just_levels, ".");

            try coll_elements.append(Trie.Element{
                .l1 = try fmt.parseInt(u16, w_strs_iter.next().?, 16),
                .l2 = try fmt.parseInt(u16, w_strs_iter.next().?, 16),
                .l3 = try fmt.parseInt(u16, w_strs_iter.next().?, 16),
            });
        }

        var elements = [_]?Trie.Element{null} ** 18;
        for (coll_elements.items) |element, i| {
            elements[i] = element;
        }

        try self.table.add(cp_list.items, elements);
    }
}

pub fn collationElements(self: Self, normalized: []const u21) ![]Trie.Element {
    var all_elements = std.ArrayList(Trie.Element).init(self.allocator);
    defer all_elements.deinit();

    var code_points = normalized;
    var code_points_len = code_points.len;
    var need_to_free: bool = false;
    var cp_index: usize = 0;

    while (cp_index < code_points_len) {
        var lookup = self.table.find(code_points[cp_index..]);
        const S = code_points[0 .. cp_index + lookup.index + 1];
        var elements = lookup.value; // elements for S.

        // handle non-starters
        var last_class: ?u8 = null;
        const tail_start = cp_index + lookup.index + 1;
        var tail_index: usize = tail_start;

        // Advance to last combining C.
        while (tail_index < code_points_len) : (tail_index += 1) {
            const combining_class = self.ccc_map.combiningClass(code_points[tail_index]);
            if (combining_class == 0) {
                if (tail_index != tail_start) tail_index -= 1;
                break;
            }
            if (last_class) |last| {
                if (combining_class <= last) {
                    if (tail_index != tail_start) tail_index -= 1;
                    break;
                }
            }
            last_class = combining_class;
        }

        if (tail_index == code_points_len) tail_index -= 1;

        if (tail_index > tail_start) {
            const C = code_points[tail_index];
            var new_key = try self.allocator.alloc(u21, S.len + 1);
            defer self.allocator.free(new_key);
            mem.copy(u21, new_key, S);
            new_key[new_key.len - 1] = C;
            var new_lookup = self.table.find(new_key);

            if (new_lookup.index == (new_key.len - 1) and new_lookup.value != null) {
                cp_index = tail_start;
                // Splice
                var tmp = try self.allocator.alloc(u21, code_points_len - 1);
                need_to_free = true;
                mem.copy(u21, tmp, code_points[0..tail_index]);
                if (tail_index + 1 < code_points_len) {
                    mem.copy(u21, tmp[tail_index..], code_points[tail_index + 1 ..]);
                }
                code_points = tmp;
                code_points_len = code_points.len;
                // Add elements to final collection.
                for (new_lookup.value.?) |element| {
                    if (element) |e| try all_elements.append(e);
                }
                continue;
            }
        }

        if (elements == null) {
            elements = self.implicitWeight(code_points[0]);
        }

        // Add elements to final collection.
        for (elements.?) |element| {
            if (element) |e| try all_elements.append(e);
        }

        cp_index += lookup.index + 1;
    }

    if (need_to_free) self.allocator.free(code_points);

    return all_elements.toOwnedSlice();
}

pub fn sortKeyFromCollationElements(self: Self, collation_elements: []Trie.Element) ![]const u16 {
    var sort_key = std.ArrayList(u16).init(self.allocator);
    defer sort_key.deinit();

    var level: usize = 0;

    while (level < 3) : (level += 1) {
        if (level != 0) try sort_key.append(0); // level separator

        for (collation_elements) |e| {
            switch (level) {
                0 => if (e.l1 != 0) try sort_key.append(e.l1),
                1 => if (e.l2 != 0) try sort_key.append(e.l2),
                2 => if (e.l3 != 0) try sort_key.append(e.l3),
                else => unreachable,
            }
        }
    }

    return sort_key.toOwnedSlice();
}

pub fn sortKey(self: Self, str: []const u8) ![]const u16 {
    var arena = std.heap.ArenaAllocator.init(self.allocator);
    defer arena.deinit();

    const normalized = try self.normalizer.normalizeCodePointsTo(&arena.allocator, .D, str);
    const collation_elements = try self.collationElements(normalized);
    defer self.allocator.free(collation_elements);

    return self.sortKeyFromCollationElements(collation_elements);
}

pub fn implicitWeight(self: Self, cp: u21) Trie.Elements {
    var base: u21 = 0;
    var aaaa: ?u21 = null;
    var bbbb: u21 = 0;

    if (self.ideographs.isUnifiedIdeograph(cp) and ((cp >= 0x4E00 and cp <= 0x9FFF) or
        (cp >= 0xF900 and cp <= 0xFAFF)))
    {
        base = 0xFB40;
        aaaa = base + (cp >> 15);
        bbbb = (cp & 0x7FFF) | 0x8000;
    } else if (self.ideographs.isUnifiedIdeograph(cp) and !((cp >= 0x4E00 and cp <= 0x9FFF) or
        (cp >= 0xF900 and cp <= 0xFAFF)))
    {
        base = 0xFB80;
        aaaa = base + (cp >> 15);
        bbbb = (cp & 0x7FFF) | 0x8000;
    } else {
        for (self.implicits.items) |weights| {
            if (cp >= weights.start and cp <= weights.end) {
                aaaa = weights.base;
                if (cp >= 0x18D00 and cp <= 0x18D8F) {
                    bbbb = (cp - 17000) | 0x8000;
                } else {
                    bbbb = (cp - weights.start) | 0x8000;
                }
                break;
            }
        }

        if (aaaa == null) {
            base = 0xFBC0;
            aaaa = base + (cp >> 15);
            bbbb = (cp & 0x7FFF) | 0x8000;
        }
    }

    var elements = [_]?Trie.Element{null} ** 18;
    elements[0] = .{ .l1 = @truncate(u16, aaaa.?), .l2 = 0x0020, .l3 = 0x0002 };
    elements[1] = .{ .l1 = @truncate(u16, bbbb), .l2 = 0x0000, .l3 = 0x0000 };
    return elements;
}

/// keyEql returns true if key `a` is equal to key `b`.
pub fn keyEql(self: Self, a: []const u16, b: []const u16) bool {
    if (a.len != b.len) return false;
    return for (a) |aw, i| {
        if (aw != b[i]) break false;
    } else true;
}

/// keyLessThan returns true if key `a` is less than key `b`.
pub fn keyLessThan(self: Self, a: []const u16, b: []const u16) bool {
    // Compare
    var long_is_a = true;
    var long = a;
    var short = b;

    if (a.len < b.len) {
        long_is_a = false;
        long = b;
        short = a;
    }

    return for (short) |w, i| {
        if (w == long[i]) continue;

        if (w == 0) {
            // Short less than long.
            break if (long_is_a) false else true;
        }

        if (long[i] == 0) {
            // long less than short.
            break if (long_is_a) true else false;
        }

        break if (long_is_a) w > long[i] else w < long[i];
    } else false; // equal is not less than.
}

/// asciiLessThan returns true if `a` is less than `b` in binary order which works for ASCII.
pub fn asciiLessThan(a: []const u8, b: []const u8) bool {
    if (a.len == b.len) {
        for (a) |c, i| {
            if (b[i] < c) return false;
        }

        return if (mem.eql(u8, a, b)) false else true;
    }

    var long_is_a = true;
    var long = a;
    var short = b;

    if (a.len < b.len) {
        long_is_a = false;
        long = b;
        short = a;
    }

    for (short) |c, i| {
        if (long_is_a) {
            if (long[i] < c) return false;
        } else {
            if (c < long[i]) return false;
        }
    }

    return a.len < b.len;
}

test "Collator ASCII less" {
    testing.expect(asciiLessThan("abc", "def"));
    testing.expect(asciiLessThan("Abc", "abc"));
    testing.expect(asciiLessThan("abc", "abcd"));
    testing.expect(!asciiLessThan("abc", "abc"));
    testing.expect(!asciiLessThan("dbc", "abc"));
    testing.expect(!asciiLessThan("adc", "abc"));
    testing.expect(!asciiLessThan("abd", "abc"));
}

/// lessThan returns true if `a` is less than `b` according to the Unicode Collation Algorithm and 
/// the Default Unicode Collation Element Table (DUCET) found at 
/// http://www.unicode.org/Public/UCA/latest/allkeys.txt .
pub fn lessThan(self: Self, a: []const u8, b: []const u8) !bool {
    if ((try isAsciiStr(a)) and (try isAsciiStr(b))) return asciiLessThan(a, b);

    var key_a = try self.sortKey(a);
    defer self.allocator.free(key_a);
    var key_b = try self.sortKey(b);
    defer self.allocator.free(key_b);

    return self.keyLessThan(key_a, key_b);
}

fn lessThanNoFail(self: Self, a: []const u8, b: []const u8) bool {
    var a_ascii = isAsciiStr(a) catch |e| {
        std.debug.print("Collator.lessThanNoFail: {}\n", .{e});
        @panic("Collator.sort -> lessThanNoFail failed!");
    };
    var b_ascii = isAsciiStr(b) catch |e| {
        std.debug.print("Collator.lessThanNoFail: {}\n", .{e});
        @panic("Collator.sort -> lessThanNoFail failed!");
    };

    if (a_ascii and b_ascii) return asciiLessThan(a, b);

    return self.lessThan(a, b) catch |e| {
        std.debug.print("Collator.lessThanNoFail: {}\n", .{e});
        @panic("Collator.sort -> lessThanNoFail failed!");
    };
}

/// sort orders the strings in `strings` according to the Unicode Collation Algorithm.
pub fn sort(self: Self, strings: [][]const u8) void {
    zort([]const u8, strings, self, lessThanNoFail);
}

const testing = std.testing;

test "Collator sort" {
    var allocator = std.testing.allocator;
    var collator = try init(allocator, "src/data/uca/allkeys.txt");
    defer collator.deinit();

    testing.expect(try collator.lessThan("abc", "def"));
    var strings: [3][]const u8 = .{ "xyz", "def", "abc" };
    collator.sort(&strings);
    testing.expectEqual(strings[0], "abc");
    testing.expectEqual(strings[1], "def");
    testing.expectEqual(strings[2], "xyz");
}

test "Collator UCA" {
    const uca_tests = "/home/jecolon/dev/zig/corpus_tests/src/CollationTest/CollationTest_NON_IGNORABLE_SHORT.txt";
    var file = try std.fs.cwd().openFile(uca_tests, .{});
    defer file.close();
    var buf_reader = std.io.bufferedReader(file.reader()).reader();

    var allocator = std.testing.allocator;
    var buf: [1024]u8 = undefined;

    // Skip header.
    var line_no: usize = 1;
    while (try buf_reader.readUntilDelimiterOrEof(&buf, '\n')) |line| : (line_no += 1) {
        if (line.len == 0) {
            line_no += 1;
            break;
        }
    }

    var prev_key: []const u16 = &[_]u16{};
    defer allocator.free(prev_key);

    var collator = try init(allocator, "src/data/uca/allkeys.txt");
    defer collator.deinit();
    var cp_buf: [4]u8 = undefined;

    lines: while (try buf_reader.readUntilDelimiterOrEof(&buf, '\n')) |line| : (line_no += 1) {
        if (line.len == 0 or line[0] == '#') continue;

        //std.debug.print("line {d}: {s}\n", .{ line_no, line });
        var bytes = std.ArrayList(u8).init(allocator);
        defer bytes.deinit();

        var cp_strs = mem.split(line, " ");

        while (cp_strs.next()) |cp_str| {
            const cp = try fmt.parseInt(u21, cp_str, 16);
            const len = unicode.utf8Encode(cp, &cp_buf) catch |_| continue :lines;
            try bytes.appendSlice(cp_buf[0..len]);
        }

        const current_key = try collator.sortKey(bytes.items);

        if (prev_key.len == 0) {
            prev_key = current_key;
            continue;
        }

        testing.expect(collator.keyEql(prev_key, current_key) or collator.keyLessThan(prev_key, current_key));

        allocator.free(prev_key);
        prev_key = current_key;
    }
}
