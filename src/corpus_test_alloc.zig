const std = @import("std");
const unicode = std.unicode;

const ControlAlloc = @import("ziglyph.zig").ControlAlloc;
const LetterAlloc = @import("ziglyph.zig").LetterAlloc;
const LowerAlloc = @import("ziglyph.zig").LowerAlloc;
const MarkAlloc = @import("ziglyph.zig").MarkAlloc;
const NumberAlloc = @import("ziglyph.zig").NumberAlloc;
const PunctAlloc = @import("ziglyph.zig").PunctAlloc;
const SpaceAlloc = @import("ziglyph.zig").SpaceAlloc;
const SymbolAlloc = @import("ziglyph.zig").SymbolAlloc;
const TitleAlloc = @import("ziglyph.zig").TitleAlloc;
const UpperAlloc = @import("ziglyph.zig").UpperAlloc;

const LowerMapAlloc = @import("ziglyph.zig").LowerMapAlloc;
const TitleMapAlloc = @import("ziglyph.zig").TitleMapAlloc;
const UpperMapAlloc = @import("ziglyph.zig").UpperMapAlloc;

pub fn main() !void {
    const corpus = "src/data/lang_mix.txt";
    var file = try std.fs.cwd().openFile(corpus, .{});
    defer file.close();
    var buf_reader = std.io.bufferedReader(file.reader()).reader();

    //var allocator = std.testing.allocator;
    var allocator = std.heap.page_allocator;
    var control = try ControlAlloc.init(allocator);
    defer control.deinit();
    var letter = try LetterAlloc.init(allocator);
    defer letter.deinit();
    var lower = try LowerAlloc.init(allocator);
    defer lower.deinit();
    var mark = try MarkAlloc.init(allocator);
    defer mark.deinit();
    var number = try NumberAlloc.init(allocator);
    defer number.deinit();
    var punct = try PunctAlloc.init(allocator);
    defer punct.deinit();
    var space = try SpaceAlloc.init(allocator);
    defer space.deinit();
    var symbol = try SymbolAlloc.init(allocator);
    defer symbol.deinit();
    var title = try TitleAlloc.init(allocator);
    defer title.deinit();
    var upper = try UpperAlloc.init(allocator);
    defer upper.deinit();

    var lower_map = try LowerMapAlloc.init(allocator);
    defer lower_map.deinit();
    var title_map = try TitleMapAlloc.init(allocator);
    defer title_map.deinit();
    var upper_map = try UpperMapAlloc.init(allocator);
    defer upper_map.deinit();

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
