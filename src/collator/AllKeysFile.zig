//! This module extracts the subset of allkeys.txt data that are canonically decomposed (since the
//! collation algorithm's first step requires you to decompoe the string's code points to canonical
//! NFD form, and hence some ~2,000 non-NFD records in the file are unused by the algorithm.)

const std = @import("std");
const mem = std.mem;
const fmt = std.fmt;
const unicode = std.unicode;
const testing = std.testing;

const NFDCheck = @import("../components.zig").NFDCheck;

iter: usize,
entries: std.ArrayList(Entry),
implicits: std.ArrayList(Implicit),

const AllKeysFile = @This();

pub const Entry = struct {
    key: Key,
    value: Elements,
};

pub const Element = struct {
    l1: u16,
    l2: u16,
    l3: u16,
};

pub const Elements = [18]?Element;
pub const Key = [3]?u21;

pub const Implicit = struct {
    base: u21,
    start: u21,
    end: u21,
};

pub fn deinit(self: *AllKeysFile) void {
    self.entries.deinit();
    self.implicits.deinit();
}

pub fn next(self: *AllKeysFile) ?Entry {
    if (self.iter >= self.entries.items.len) return null;
    const entry = self.entries.items[self.iter];
    self.iter += 1;
    return entry;
}

pub fn parseFile(allocator: *mem.Allocator, filename: []const u8) !AllKeysFile {
    var in_file = try std.fs.cwd().openFile(filename, .{});
    defer in_file.close();
    return parse(allocator, in_file.reader());
}

pub fn parse(allocator: *mem.Allocator, reader: anytype) !AllKeysFile {
    var buf_reader = std.io.bufferedReader(reader);
    var input_stream = buf_reader.reader();
    var buf: [1024]u8 = undefined;

    var entries = std.ArrayList(Entry).init(allocator);
    var implicits = std.ArrayList(Implicit).init(allocator);

    lines: while (try input_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
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

            try implicits.append(.{
                .base = try fmt.parseInt(u21, base, 16),
                .start = try fmt.parseInt(u21, range_start, 16),
                .end = try fmt.parseInt(u21, range_end, 16),
            });

            continue; // next line.
        }

        const semi = mem.indexOf(u8, raw, ";").?;
        const cp_strs = mem.trim(u8, raw[0..semi], " ");
        var cp_strs_iter = mem.split(cp_strs, " ");
        var cp_list: [3]?u21 = [_]?u21{null} ** 3;
        var i: usize = 0;

        while (cp_strs_iter.next()) |cp_str| {
            const cp = try fmt.parseInt(u21, cp_str, 16);
            if (!NFDCheck.isNFD(cp)) continue :lines; // Skip non-NFD.
            cp_list[i] = cp;
            i += 1;
        }

        var coll_elements = std.ArrayList(Element).init(allocator);
        defer coll_elements.deinit();
        const ce_strs = mem.trim(u8, raw[semi + 1 ..], " ");
        var ce_strs_iter = mem.split(ce_strs[1 .. ce_strs.len - 1], "]["); // no ^[. or ^[* or ]$

        while (ce_strs_iter.next()) |ce_str| {
            const just_levels = ce_str[1..];
            var w_strs_iter = mem.split(just_levels, ".");

            try coll_elements.append(Element{
                .l1 = try fmt.parseInt(u16, w_strs_iter.next().?, 16),
                .l2 = try fmt.parseInt(u16, w_strs_iter.next().?, 16),
                .l3 = try fmt.parseInt(u16, w_strs_iter.next().?, 16),
            });
        }

        var elements = [_]?Element{null} ** 18;
        for (coll_elements.items) |element, j| {
            elements[j] = element;
        }

        try entries.append(Entry{ .key = cp_list, .value = elements });
    }

    return AllKeysFile{ .iter = 0, .entries = entries, .implicits = implicits };
}

test "parse" {
    const allocator = testing.allocator;
    var file = try parseFile(allocator, "src/data/uca/allkeys.txt");
    defer file.deinit();
    while (file.next()) |entry| {
        _ = entry;
    }
}
