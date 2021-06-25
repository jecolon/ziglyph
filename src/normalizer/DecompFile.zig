const std = @import("std");
const mem = std.mem;
const fmt = std.fmt;
const unicode = std.unicode;
const testing = std.testing;

iter: usize,
entries: std.ArrayList(Entry),

const DecompFile = @This();

pub const Entry = struct {
    key: [4]u8,
    key_len: usize,
    value: Decomp,
};

/// Form is the normalization form.
/// * .canon : Canonical decomposition, which always results in two code points.
/// * .compat : Compatibility decomposition, which can result in at most 18 code points.
/// * .same : Default canonical decomposition to the code point itself.
pub const Form = enum(u2) {
    canon, // D
    compat, // KD
    same, // no more decomposition.
};

/// Decomp is the result of decomposing a code point to a normaliztion form.
pub const Decomp = struct {
    form: Form = .canon,
    len: usize = 2,
    seq: [18]u21 = [_]u21{0} ** 18,
};

pub fn deinit(self: *DecompFile) void {
    self.entries.deinit();
}

pub fn next(self: *DecompFile) ?Entry {
    if (self.iter >= self.entries.items.len) return null;
    const entry = self.entries.items[self.iter];
    self.iter += 1;
    return entry;
}

pub fn parseFile(allocator: *mem.Allocator, filename: []const u8) !DecompFile {
    var in_file = try std.fs.cwd().openFile(filename, .{});
    defer in_file.close();
    return parse(allocator, in_file.reader());
}

pub fn parse(allocator: *mem.Allocator, reader: anytype) !DecompFile {
    var buf_reader = std.io.bufferedReader(reader);
    var input_stream = buf_reader.reader();
    var entries = std.ArrayList(Entry).init(allocator);

    // Iterate over lines.
    var buf: [640]u8 = undefined;
    while (try input_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        // Iterate over fields.
        var fields = mem.split(line, ";");
        var field_index: usize = 0;
        var code_point: []const u8 = undefined;
        var dc = Decomp{};

        while (fields.next()) |raw| : (field_index += 1) {
            if (field_index == 0) {
                // Code point.
                code_point = raw;
            } else if (field_index == 5 and raw.len != 0) {
                // Normalization.
                const parsed_cp = try fmt.parseInt(u21, code_point, 16);
                var _key_backing = std.mem.zeroes([4]u8);
                const key = blk: {
                    const len = try unicode.utf8Encode(parsed_cp, &_key_backing);
                    break :blk _key_backing[0..len];
                };

                var is_compat = false;
                var cp_list: [18][]const u8 = [_][]const u8{""} ** 18;

                var cp_iter = mem.split(raw, " ");
                var i: usize = 0;
                while (cp_iter.next()) |cp| {
                    if (mem.startsWith(u8, cp, "<")) {
                        is_compat = true;
                        continue;
                    }
                    cp_list[i] = cp;
                    i += 1;
                }

                if (!is_compat and i == 1) {
                    // Singleton
                    dc.len = 1;
                    dc.seq[0] = try fmt.parseInt(u21, cp_list[0], 16);
                    try entries.append(Entry{ .key = _key_backing, .key_len = key.len, .value = dc });
                } else if (!is_compat) {
                    // Canonical
                    std.debug.assert(i == 2);
                    dc.seq[0] = try fmt.parseInt(u21, cp_list[0], 16);
                    dc.seq[1] = try fmt.parseInt(u21, cp_list[1], 16);
                    try entries.append(Entry{ .key = _key_backing, .key_len = key.len, .value = dc });
                } else {
                    // Compatibility
                    std.debug.assert(i != 0 and i <= 18);
                    var j: usize = 0;

                    for (cp_list) |ccp| {
                        if (ccp.len == 0) break; // sentinel
                        dc.seq[j] = try fmt.parseInt(u21, ccp, 16);
                        j += 1;
                    }

                    dc.form = .compat;
                    dc.len = j;
                    try entries.append(Entry{ .key = _key_backing, .key_len = key.len, .value = dc });
                }
            } else {
                continue;
            }
        }
    }
    return DecompFile{ .iter = 0, .entries = entries };
}

pub fn compressToFile(self: *DecompFile, filename: []const u8) !void {
    var out_file = try std.fs.cwd().createFile(filename, .{});
    defer out_file.close();
    return self.compressTo(out_file.writer());
}

pub fn compressTo(self: *DecompFile, writer: anytype) !void {
    var buf_writer = std.io.bufferedWriter(writer);
    var out = std.io.bitWriter(.Little, buf_writer.writer());
    try out.writeBits(@intCast(u16, self.entries.items.len), 16);
    while (self.next()) |entry| {
        try out.writeBits(entry.key_len, 3);
        _ = try out.write(entry.key[0..entry.key_len]);
        try out.writeBits(@enumToInt(entry.value.form), @bitSizeOf(Form));
        try out.writeBits(entry.value.len, 5);
        for (entry.value.seq[0..entry.value.len]) |s| try out.writeBits(s, 21);
    }
    try out.flushBits();
    try buf_writer.flush();
}

pub fn decompressFile(allocator: *mem.Allocator, filename: []const u8) !DecompFile {
    var in_file = try std.fs.cwd().openFile(filename, .{});
    defer in_file.close();
    return decompress(allocator, in_file.reader());
}

pub fn decompress(allocator: *mem.Allocator, reader: anytype) !DecompFile {
    var buf_reader = std.io.bufferedReader(reader);
    var in = std.io.bitReader(.Little, buf_reader.reader());
    var entries = std.ArrayList(Entry).init(allocator);
    var num_entries = try in.readBitsNoEof(usize, 16);
    var i: usize = 0;
    while (i < num_entries) : (i += 1) {
        var entry: Entry = std.mem.zeroes(Entry);
        entry.key_len = try in.readBitsNoEof(usize, 3);
        _ = try in.read(entry.key[0..entry.key_len]);
        entry.value.form = @intToEnum(Form, try in.readBitsNoEof(std.meta.Tag(Form), @bitSizeOf(Form)));
        entry.value.len = try in.readBitsNoEof(usize, 5);
        var j: usize = 0;
        while (j < entry.value.len) : (j += 1) entry.value.seq[j] = try in.readBitsNoEof(u21, 21);
        try entries.append(entry);
    }
    return DecompFile{ .iter = 0, .entries = entries };
}

test "parse" {
    const allocator = testing.allocator;
    var file = try parseFile(allocator, "src/data/ucd/UnicodeData.txt");
    defer file.deinit();
    while (file.next()) |entry| {
        _ = entry;
    }
}

test "compression_is_lossless" {
    const allocator = testing.allocator;

    // Compress UnicodeData.txt -> Decompositions.bin
    var file = try parseFile(allocator, "src/data/ucd/UnicodeData.txt");
    defer file.deinit();
    try file.compressToFile("src/data/ucd/Decompositions.bin");

    // Reset the raw file iterator.
    file.iter = 0;

    // Decompress the file.
    var decompressed = try decompressFile(allocator, "src/data/ucd/Decompositions.bin");
    defer decompressed.deinit();
    while (file.next()) |expected| {
        var actual = decompressed.next().?;
        try testing.expectEqual(expected, actual);
    }
}