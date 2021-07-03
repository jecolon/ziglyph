//! This module extracts the subset of allkeys.txt data that are canonically decomposed, and
//! handles compression/decompression of that subset using Unicode Data Differential Compression
//! (UDDC).
//!
//! See ../normalizer/DecompFile.zig for details on what Unicode Data Differential Compression
//! (UDDC) is and how it works.
//!
//! Note that only the entries which are canonically decomposed are encoded, since the collation
//! algorithm's first step requires you to decompose the string's code points to canonical NFD
//! form, and hence some ~2,000 non-NFD entries in the file are unused by the algorithm.

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

    // Calculates the difference of each optional integral value in this entry.
    pub fn diff(self: Entry, other: Entry) Entry {
        // Determine difference in key values.
        var d: Entry = undefined;
        d.key.len = self.key.len -% other.key.len;
        for (self.key.items) |k, i| {
            d.key.items[i] = k -% other.key.items[i];
        }

        // Determine difference in element values.
        for (self.value.items) |e, i| {
            d.value.len = self.value.len -% other.value.len;
            d.value.items[i] = Element{
                .l1 = e.l1 -% other.value.items[i].l1,
                .l2 = e.l2 -% other.value.items[i].l2,
                .l3 = e.l3 -% other.value.items[i].l3,
            };
        }
        return d;
    }
};

pub const Element = struct {
    l1: u16,
    l2: u16,
    l3: u16,
};

pub const Elements = struct {
    len: u5,
    items: [18]Element,
};
pub const Key = struct {
    len: u2,
    items: [3]u21,
};

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
        var key: Key = std.mem.zeroes(Key);
        while (cp_strs_iter.next()) |cp_str| {
            const cp = try fmt.parseInt(u21, cp_str, 16);
            if (!NFDCheck.isNFD(cp)) continue :lines; // Skip non-NFD.
            key.items[key.len] = cp;
            key.len += 1;
        }

        const ce_strs = mem.trim(u8, raw[semi + 1 ..], " ");
        var ce_strs_iter = mem.split(ce_strs[1 .. ce_strs.len - 1], "]["); // no ^[. or ^[* or ]$

        var elements: Elements = std.mem.zeroes(Elements);
        while (ce_strs_iter.next()) |ce_str| {
            const just_levels = ce_str[1..];
            var w_strs_iter = mem.split(just_levels, ".");

            elements.items[elements.len] = Element{
                .l1 = try fmt.parseInt(u16, w_strs_iter.next().?, 16),
                .l2 = try fmt.parseInt(u16, w_strs_iter.next().?, 16),
                .l3 = try fmt.parseInt(u16, w_strs_iter.next().?, 16),
            };
            elements.len += 1;
        }

        try entries.append(Entry{ .key = key, .value = elements });
    }

    return AllKeysFile{ .iter = 0, .entries = entries, .implicits = implicits };
}

// A UDDC opcode for an allkeys file.
const Opcode = enum(u4) {
    // Sets an incrementor for the key, incrementing the key by this much on each emission.
    // 10690 instances
    inc_key,

    // Sets the value register.
    // 31001 instances
    set_value,

    // Emits a single value.
    // 31001 instances
    emit,

    // Denotes the end of the opcode stream. This is so that we don't need to encode the total
    // number of opcodes in the stream up front (note also the file is bit packed: there may be
    // a few remaining zero bits at the end as padding so we need an EOF opcode rather than say
    // catching the actual file read EOF.)
    eof,
};

pub fn compressToFile(self: *AllKeysFile, filename: []const u8) !void {
    var out_file = try std.fs.cwd().createFile(filename, .{});
    defer out_file.close();
    return self.compressTo(out_file.writer());
}

pub fn compressTo(self: *AllKeysFile, writer: anytype) !void {
    var buf_writer = std.io.bufferedWriter(writer);
    var out = std.io.bitWriter(.Little, buf_writer.writer());

    // Implicits
    std.debug.assert(self.implicits.items.len == 4); // we don't encode a length for implicits.
    for (self.implicits.items) |implicit| {
        try out.writeBits(implicit.base, @bitSizeOf(@TypeOf(implicit.base)));
        try out.writeBits(implicit.start, @bitSizeOf(@TypeOf(implicit.start)));
        try out.writeBits(implicit.end, @bitSizeOf(@TypeOf(implicit.end)));
    }

    // For the UDDC registers, we want one register to represent each possible value in a single
    // entry; we will emit opcodes to modify these registers into the desired form to produce a
    // real entry.
    var registers = std.mem.zeroes(Entry);
    var incrementor = std.mem.zeroes(Entry);
    while (self.next()) |entry| {
        // Determine what has changed between this entry and the current registers' state.
        const diff = entry.diff(registers);

        // If you want to analyze the difference between entries, uncomment the following:
        //std.debug.print("diff.key={any: <7}\n", .{diff.key});
        //std.debug.print("diff.value={any: <5}\n", .{diff.value});
        //registers = entry;
        //continue;

        if (diff.key.len != 0 or !std.mem.eql(u21, diff.key.items[0..], incrementor.key.items[0..])) {
            try out.writeBits(@enumToInt(Opcode.inc_key), @bitSizeOf(Opcode));
            try out.writeBits(entry.key.len, 2);
            var diff_key_len: u2 = 0;
            for (diff.key.items) |kv, i| {
                if (kv != 0) diff_key_len = @intCast(u2, i + 1);
            }
            try out.writeBits(diff_key_len, 2);
            for (diff.key.items[0..diff_key_len]) |kv| try out.writeBits(kv, 21);
            incrementor.key = diff.key;
        }

        try out.writeBits(@enumToInt(Opcode.set_value), @bitSizeOf(Opcode));
        try out.writeBits(entry.value.len, 5);
        for (entry.value.items[0..entry.value.len]) |ev| {
            try out.writeBits(ev.l1, 16);
            try out.writeBits(ev.l2, 16);
            try out.writeBits(ev.l3, 16);
        }

        try out.writeBits(@enumToInt(Opcode.emit), @bitSizeOf(Opcode));

        registers = entry;
    }
    try out.writeBits(@enumToInt(Opcode.eof), @bitSizeOf(Opcode));
    try out.flushBits();
    try buf_writer.flush();
}

pub fn decompressFile(allocator: *mem.Allocator, filename: []const u8) !AllKeysFile {
    var in_file = try std.fs.cwd().openFile(filename, .{});
    defer in_file.close();
    return decompress(allocator, in_file.reader());
}

pub fn decompress(allocator: *mem.Allocator, reader: anytype) !AllKeysFile {
    var buf_reader = std.io.bufferedReader(reader);
    var in = std.io.bitReader(.Little, buf_reader.reader());
    var entries = std.ArrayList(Entry).init(allocator);
    var implicits = std.ArrayList(Implicit).init(allocator);

    // Implicits
    {
        var i: usize = 0;
        while (i < 4) : (i += 1) {
            var implicit: Implicit = undefined;
            implicit.base = try in.readBitsNoEof(u21, 21);
            implicit.start = try in.readBitsNoEof(u21, 21);
            implicit.end = try in.readBitsNoEof(u21, 21);
            try implicits.append(implicit);
        }
    }

    // For the UDDC registers, we want one register to represent each possible value in a single
    // entry; each opcode we read will modify these registers so we can emit a value.
    var registers = std.mem.zeroes(Entry);
    var incrementor = std.mem.zeroes(Entry);

    while (true) {
        // Read a single operation.
        var op = @intToEnum(Opcode, try in.readBitsNoEof(std.meta.Tag(Opcode), @bitSizeOf(Opcode)));

        // If you want to inspect the # of different ops in a stream, uncomment this:
        //std.debug.print("{}\n", .{op});

        switch (op) {
            .inc_key => {
                registers.key.len = try in.readBitsNoEof(u2, 2);
                var inc_key_len = try in.readBitsNoEof(u2, 2);
                var j: usize = 0;
                while (j < inc_key_len) : (j += 1) {
                    incrementor.key.items[j] = try in.readBitsNoEof(u21, 21);
                }
                while (j < 3) : (j += 1) incrementor.key.items[j] = 0;
            },
            .set_value => {
                registers.value.len = try in.readBitsNoEof(u5, 5);
                var j: usize = 0;
                while (j < registers.value.len) : (j += 1) {
                    var ev: Element = undefined;
                    ev.l1 = try in.readBitsNoEof(u16, 16);
                    ev.l2 = try in.readBitsNoEof(u16, 16);
                    ev.l3 = try in.readBitsNoEof(u16, 16);
                    registers.value.items[j] = ev;
                }
                while (j < registers.value.items.len) : (j += 1) {
                    registers.value.items[j] = std.mem.zeroes(Element);
                }
            },
            .emit => {
                for (incrementor.key.items) |k, i| registers.key.items[i] +%= k;
                try entries.append(registers);
            },
            .eof => break,
        }
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

test "compression_is_lossless" {
    const allocator = testing.allocator;

    // Compress allkeys.txt -> allkeys.bin
    var file = try parseFile(allocator, "src/data/uca/allkeys.txt");
    defer file.deinit();
    try file.compressToFile("src/data/uca/allkeys.bin");

    // Reset the raw file iterator.
    file.iter = 0;

    // Decompress the file.
    var decompressed = try decompressFile(allocator, "src/data/uca/allkeys.bin");
    defer decompressed.deinit();
    try testing.expectEqualSlices(Implicit, file.implicits.items, decompressed.implicits.items);
    while (file.next()) |expected| {
        var actual = decompressed.next().?;
        // std.debug.print("{}\n{}\n\n", .{expected, actual});
        try testing.expectEqual(expected, actual);
    }
}
