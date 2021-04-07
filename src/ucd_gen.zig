const std = @import("std");

const ArrayList = std.ArrayList;
const AutoHashMap = std.AutoHashMap;
const fmt = std.fmt;
const io = std.io;
const mem = std.mem;

const Range = @import("record.zig").Range;
const Record = @import("record.zig").Record;

const comp_path = "components/";

const Collection = struct {
    allocator: *mem.Allocator,
    kind: []const u8,
    lo: u21,
    hi: u21,
    records: []Record,

    fn init(allocator: *mem.Allocator, kind: []const u8, lo: u21, hi: u21, records: []Record) !Collection {
        return Collection{
            .allocator = allocator,
            .kind = kind,
            .lo = lo,
            .hi = hi,
            .records = records,
        };
    }

    fn deinit(self: *Collection) void {
        self.allocator.free(self.kind);
    }

    fn writeFile(self: Collection) !void {
        const header_tpl = @embedFile("parts/collection_header_tpl.txt");
        const trailer_tpl = @embedFile("parts/collection_trailer_tpl.txt");

        // Prepare output files.
        var name = try self.allocator.alloc(u8, mem.replacementSize(u8, self.kind, "_", ""));
        defer self.allocator.free(name);
        _ = mem.replace(u8, self.kind, "_", "", name);
        var filename = try mem.concat(self.allocator, u8, &[_][]const u8{ comp_path, name, ".zig" });
        defer self.allocator.free(filename);
        var file = try std.fs.cwd().createFile(filename, .{});
        defer file.close();
        var buf_writer = io.bufferedWriter(file.writer());
        const writer = buf_writer.writer();

        // Write data.
        const array_len = self.hi - self.lo + 1;
        _ = try writer.print(header_tpl, .{ self.kind, name, array_len, self.lo, self.hi });
        _ = try writer.write("    var index: u21 = 0;\n");

        for (self.records) |record| {
            switch (record) {
                .single => |cp| {
                    _ = try writer.print("    instance.array[{d}] = true;\n", .{cp - self.lo});
                },
                .range => |range| {
                    _ = try writer.print("    index = {d};\n", .{range.lo - self.lo});
                    _ = try writer.print("    while (index <= {d}) : (index += 1) {{\n", .{range.hi - self.lo});
                    _ = try writer.write("        instance.array[index] = true;\n");
                    _ = try writer.write("    }\n");
                },
            }
        }

        _ = try writer.print(trailer_tpl, .{ name, self.kind });
        try buf_writer.flush();
    }
};

const UcdGenerator = struct {
    allocator: *mem.Allocator,

    pub fn new(allocator: *mem.Allocator) UcdGenerator {
        return UcdGenerator{
            .allocator = allocator,
        };
    }

    const Self = @This();

    // data/ucd/extracted/DerivedGeneralCategory.txt
    fn process_file(self: *Self, path: []const u8) !void {
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
        var lo: u21 = 0x10FFFF;
        var hi: u21 = 0;
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
                } else if (field_index == 1) {
                    // Record kind.
                    // Possible comment at end.
                    if (mem.indexOf(u8, field, "#")) |octo| {
                        field = mem.trimRight(u8, field[0..octo], " ");
                    }
                    // Check if new collection started.
                    if (kind.items.len != 0) {
                        // New collection for new record kind.
                        if (!mem.eql(u8, kind.items, field)) {
                            try collections.append(try Collection.init(
                                self.allocator,
                                kind.toOwnedSlice(),
                                lo,
                                hi,
                                records.toOwnedSlice(),
                            ));
                            // Reset extremes.
                            switch (record) {
                                .single => |cp| {
                                    lo = cp;
                                    hi = cp;
                                },
                                .range => |range| {
                                    lo = range.lo;
                                    hi = range.hi;
                                },
                            }
                            // Update kind.
                            try kind.appendSlice(field);
                        }
                    } else {
                        // Initialize kind.
                        try kind.appendSlice(field);
                    }
                    try records.append(record);
                } else {
                    continue;
                }
            }
        }

        // Write out files.
        for (collections.items) |collection| {
            try collection.writeFile();
        }
    }
};

pub fn main() !void {
    //var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    //defer arena.deinit();
    //var allocator = &arena.allocator;
    var allocator = std.testing.allocator;
    var ugen = UcdGenerator.new(allocator);
    try ugen.process_file("data/ucd/DerivedCoreProperties.txt");
}
