const std = @import("std");
const unicode = std.unicode;

const Ziglyph = @import("ziglyph.zig").Ziglyph;

pub fn main() !void {
    const corpus = "src/data/lang_mix.txt";
    var file = try std.fs.cwd().openFile(corpus, .{});
    defer file.close();
    var buf_reader = std.io.bufferedReader(file.reader()).reader();

    var ziglyph = Ziglyph.init(std.heap.page_allocator);
    defer ziglyph.deinit();
    var buf: [1024]u8 = undefined;
    var count: usize = 0;

    while (try buf_reader.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        const s = try unicode.Utf8View.init(line);
        var iter = s.iterator();
        while (iter.nextCodepoint()) |cp| {
            _ = try ziglyph.toUpper(cp);
            count += 1;
        }
    }

    try std.io.getStdOut().writer().print("Count: {d}\n", .{count});
}
