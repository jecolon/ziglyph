const std = @import("std");
const fmt = std.fmt;
const io = std.io;
const mem = std.mem;
const sort = std.sort.sort;
const unicode = std.unicode;

const CccMap = @import("../components.zig").CccMap;
const Control = @import("../components.zig").Control;
const DecomposeMap = @import("../components.zig").DecomposeMap;
const Trie = @import("Trie.zig");
const UnifiedIdeo = @import("../components/autogen/PropList/UnifiedIdeograph.zig");

const Implicit = struct {
    base: u21,
    start: u21,
    end: u21,
};

const ImplicitList = std.ArrayList(Implicit);

allocator: *mem.Allocator,
ccc_map: CccMap,
control: Control,
decomp_map: DecomposeMap,
ideographs: UnifiedIdeo,
implicits: ImplicitList,
table: Trie,

const Self = @This();

pub fn init(allocator: *mem.Allocator, filename: []const u8) !Self {
    var self = Self{
        .allocator = allocator,
        .ccc_map = CccMap{},
        .control = Control{},
        .decomp_map = DecomposeMap.new(),
        .ideographs = UnifiedIdeo{},
        .implicits = ImplicitList.init(allocator),
        .table = try Trie.init(allocator),
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

pub fn sortKey(self: *Self, str: []const u8) ![]const u16 {
    var arena = std.heap.ArenaAllocator.init(self.allocator);
    defer arena.deinit();

    const normalized = try self.decomp_map.normalizeCodePointsTo(&arena.allocator, .D, str);
    const collation_elements = try self.collationElements(normalized);
    defer self.allocator.free(collation_elements);

    return self.sortKeyFromCollationElements(collation_elements);
}

pub fn implicitWeight(self: Self, cp: u21) Trie.Elements {
    var base: u21 = 0;
    var aaaa: ?u21 = null;
    var bbbb: u21 = 0;

    //if ((!self.control.isControl(cp) and ((cp >= 0x4E00 and cp <= 0x9FCC) or
    //    (cp >= 0x9FCD and cp <= 0x9FD5) or
    //    (cp >= 0x9FD6 and cp <= 0x9FEA) or
    //    for ([_]u21{
    //    0xFA0E, 0xFA0F, 0xFA11, 0xFA13, 0xFA14, 0xFA1F, 0xFA21, 0xFA23, 0xFA24,
    //    0xFA27, 0xFA28, 0xFA29,
    //}) |match| {
    //    if (cp == match) break true;
    //} else false))) {
    if (self.ideographs.isUnifiedIdeograph(cp) and ((cp >= 0x4E00 and cp <= 0x9FFF) or
        (cp >= 0xF900 and cp <= 0xFAFF)))
    {
        base = 0xFB40;
        aaaa = base + (cp >> 15);
        bbbb = (cp & 0x7FFF) | 0x8000;
        //} else if ((!self.control.isControl(cp) and ((cp >= 0x3400 and cp <= 0x4DB5) or
        //    (cp >= 0x20000 and cp <= 0x2A6D6) or
        //    (cp >= 0x2A700 and cp <= 0x2B734) or
        //    (cp >= 0x2B740 and cp <= 0x2B81D) or
        //    (cp >= 0x2B820 and cp <= 0x2CEAF) or
        //    (cp >= 0x2CEB0 and cp <= 0x2EBE0))))
        //{
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

const testing = std.testing;

test "Collator" {
    var allocator = std.testing.allocator;
    var collator = try init(allocator, "src/data/uca/allkeys.txt");
    defer collator.deinit();

    var key_a = try collator.sortKey("\u{0334}\u{0308}");
    defer allocator.free(key_a);
    var key_b = try collator.sortKey("\u{0308}\u{0301}\u{0334}");
    defer allocator.free(key_b);

    // Level 1.
    var total_a: u32 = 0;
    var ai: usize = 0;
    while (ai < key_a.len) : (ai += 1) {
        if (key_a[ai] == 0) break;
        total_a += key_a[ai];
    }

    var total_b: u32 = 0;
    var bi: usize = 0;
    while (bi < key_b.len) : (bi += 1) {
        if (key_b[bi] == 0) break;
        total_b += key_b[bi];
    }

    if (total_a != total_b) testing.expect(total_a < total_b);

    // Level 2.
    while (ai < key_a.len) : (ai += 1) {
        if (key_a[ai] == 0) break;
        total_a += key_a[ai];
    }

    while (bi < key_b.len) : (bi += 1) {
        if (key_b[bi] == 0) break;
        total_b += key_b[bi];
    }

    if (total_a != total_b) testing.expect(total_a < total_b);

    // Level 3.
    while (ai < key_a.len) : (ai += 1) {
        if (key_a[ai] == 0) break;
        total_a += key_a[ai];
    }

    while (bi < key_b.len) : (bi += 1) {
        if (key_b[bi] == 0) break;
        total_b += key_b[bi];
    }

    if (total_a != total_b) testing.expect(total_a < total_b);
}
