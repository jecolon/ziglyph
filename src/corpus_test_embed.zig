const std = @import("std");
const unicode = std.unicode;

const Letter = @import("ziglyph.zig").Letter;

const corpus = @embedFile("data/lang_mix.txt");

pub fn main() !void {
    var ziglyph = Letter.new();

    const s = try unicode.Utf8View.init(corpus);
    var iter = s.iterator();
    var count: usize = 0;
    while (iter.nextCodepoint()) |cp| {
        if (ziglyph.isLetter(cp)) count += 1;
    }

    try std.io.getStdOut().writer().print("Count: {d}\n", .{count});
}
