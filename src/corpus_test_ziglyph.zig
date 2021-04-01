const std = @import("std");
const unicode = std.unicode;

const Ziglyph = @import("ziglyph.zig").Ziglyph;

pub fn main() !void {
    const corpus = "src/data/lang_mix.txt";
    var file = try std.fs.cwd().openFile(corpus, .{});
    defer file.close();
    var buf_reader = std.io.bufferedReader(file.reader()).reader();

    //var allocator = std.testing.allocator;
    var allocator = std.heap.page_allocator;
    var ziglyph = try Ziglyph.init(allocator);
    defer ziglyph.deinit();

    var c_count: usize = 0;
    var l_count: usize = 0;
    var ll_count: usize = 0;
    var lt_count: usize = 0;
    var lu_count: usize = 0;
    var m_count: usize = 0;
    var n_count: usize = 0;
    var p_count: usize = 0;
    var z_count: usize = 0;
    var s_count: usize = 0;

    var buf: [1024]u8 = undefined;
    while (try buf_reader.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        const s = try unicode.Utf8View.init(line);
        var iter = s.iterator();
        while (iter.nextCodepoint()) |cp| {
            if (try ziglyph.isControl(cp)) {
                c_count += 1;
            } else if (try ziglyph.isLetter(cp)) {
                l_count += 1;
                if (try ziglyph.isLower(cp)) {
                    ll_count += 1;
                    _ = try ziglyph.toTitle(cp);
                } else if (try ziglyph.isTitle(cp)) {
                    lt_count += 1;
                    _ = try ziglyph.toUpper(cp);
                } else if (try ziglyph.isUpper(cp)) {
                    lu_count += 1;
                    _ = try ziglyph.toLower(cp);
                }
            } else if (try ziglyph.isMark(cp)) {
                m_count += 1;
            } else if (try ziglyph.isNumber(cp)) {
                n_count += 1;
            } else if (try ziglyph.isPunct(cp)) {
                p_count += 1;
            } else if (try ziglyph.isSpace(cp)) {
                z_count += 1;
            } else if (try ziglyph.isSymbol(cp)) {
                s_count += 1;
            }
        }
    }

    try std.io.getStdOut().writer().print(
        "c: {d}, l: {d}, ll: {d}, lt: {d}, lu: {d}, m: {d}, n: {d}, p: {d}, z: {d}, s: {d}\n",
        .{
            c_count,  l_count, ll_count, lt_count,
            lu_count, m_count, n_count,  p_count,
            z_count,  s_count,
        },
    );
}
