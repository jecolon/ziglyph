const std = @import("std");
const unicode = std.unicode;

const Control = @import("ziglyph.zig").Control;
const Letter = @import("ziglyph.zig").Letter;
const Lower = @import("ziglyph.zig").Lower;
const Mark = @import("ziglyph.zig").Mark;
const Number = @import("ziglyph.zig").Number;
const Punct = @import("ziglyph.zig").Punct;
const Space = @import("ziglyph.zig").Space;
const Symbol = @import("ziglyph.zig").Symbol;
const Title = @import("ziglyph.zig").Title;
const Upper = @import("ziglyph.zig").Upper;

const LowerMap = @import("ziglyph.zig").LowerMap;
const TitleMap = @import("ziglyph.zig").TitleMap;
const UpperMap = @import("ziglyph.zig").UpperMap;

pub fn main() !void {
    const corpus = "src/data/lang_mix.txt";
    var file = try std.fs.cwd().openFile(corpus, .{});
    defer file.close();
    var buf_reader = std.io.bufferedReader(file.reader()).reader();

    var control = Control.new();
    var letter = Letter.new();
    var lower = Lower.new();
    var mark = Mark.new();
    var number = Number.new();
    var punct = Punct.new();
    var space = Space.new();
    var symbol = Symbol.new();
    var title = Title.new();
    var upper = Upper.new();

    //var allocator = std.testing.allocator;
    var allocator = std.heap.page_allocator;
    var lower_map = LowerMap.new();
    var title_map = TitleMap.new();
    var upper_map = UpperMap.new();

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
            if (control.isControl(cp)) {
                c_count += 1;
            } else if (letter.isLetter(cp)) {
                l_count += 1;
                if (lower.isLower(cp)) {
                    ll_count += 1;
                    _ = title_map.toTitle(cp);
                } else if (title.isTitle(cp)) {
                    lt_count += 1;
                    _ = upper_map.toUpper(cp);
                } else if (upper.isUpper(cp)) {
                    lu_count += 1;
                    _ = lower_map.toLower(cp);
                }
            } else if (mark.isMark(cp)) {
                m_count += 1;
            } else if (number.isNumber(cp)) {
                n_count += 1;
            } else if (punct.isPunct(cp)) {
                p_count += 1;
            } else if (space.isSpace(cp)) {
                z_count += 1;
            } else if (symbol.isSymbol(cp)) {
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
