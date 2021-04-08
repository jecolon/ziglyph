const std = @import("std");
const io = std.io;
const mem = std.mem;

const Range = @import("record.zig").Range;
const Record = @import("record.zig").Record;
const Collection = @This();

const comp_path = "components";

allocator: *mem.Allocator,
kind: []const u8,
lo: u21,
hi: u21,
records: []Record,

pub fn init(allocator: *mem.Allocator, kind: []const u8, lo: u21, hi: u21, records: []Record) !Collection {
    return Collection{
        .allocator = allocator,
        .kind = kind,
        .lo = lo,
        .hi = hi,
        .records = records,
    };
}

pub fn deinit(self: *Collection) void {
    self.allocator.free(self.kind);
}

pub fn writeFile(self: Collection, dir: []const u8) !void {
    const header_tpl = @embedFile("parts/collection_header_tpl.txt");
    const trailer_tpl = @embedFile("parts/collection_trailer_tpl.txt");

    // Prepare output files.
    var name = try self.allocator.alloc(u8, mem.replacementSize(u8, self.kind, "_", ""));
    defer self.allocator.free(name);
    _ = mem.replace(u8, self.kind, "_", "", name);
    var dir_name = try mem.concat(self.allocator, u8, &[_][]const u8{
        comp_path,
        "/",
        dir,
    });
    defer self.allocator.free(dir_name);
    var cwd = std.fs.cwd();
    cwd.makeDir(dir_name) catch |err| switch (err) {
        error.PathAlreadyExists => {},
        else => return err,
    };
    var file_name = try mem.concat(self.allocator, u8, &[_][]const u8{ dir_name, "/", name, ".zig" });
    defer self.allocator.free(file_name);
    var file = try cwd.createFile(file_name, .{});
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
