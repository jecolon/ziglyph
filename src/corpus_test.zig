const std = @import("std");
const unicode = std.unicode;

const Space = @import("ziglyph.zig").Space;
const Number = @import("ziglyph.zig").Number;
const Letter = @import("ziglyph.zig").Letter;

const corpus = @embedFile("data/lang_mix.txt");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    var allocator = &arena.allocator;
    var ziglyph = try Letter.init(allocator);
    defer ziglyph.deinit();

    const s = try unicode.Utf8View.init(corpus);
    var iter = s.iterator();
    var count: usize = 0;
    while (iter.nextCodepoint()) |cp| {
        if (ziglyph.isLetter(cp)) count += 1;
    }

    try std.io.getStdOut().writer().print("Count: {d}\n", .{count});
}
