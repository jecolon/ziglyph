const std = @import("std");
const debug = std.debug;
const testing = std.testing;

const Word = @import("../components.zig").Word;
const WordIterator = Word.WordIterator;
const Width = @import("../components.zig").Width;

/// Wraps a string approximately at the given number of colums per line. Threshold defines how far the last column of
/// the last word can be from the edge. Caller must free returned bytes.
pub fn wrap(allocator: *std.mem.Allocator, str: []const u8, columns: usize, threshold: usize) ![]u8 {
    var iter = try WordIterator.init(allocator, str);
    defer iter.deinit();
    var result = std.ArrayList(u8).init(allocator);
    defer result.deinit();
    var line_width: usize = 0;

    while (iter.next()) |word| {
        if (isLineBreak(word.bytes)) {
            try result.append(' ');
            continue;
        }
        try result.appendSlice(word.bytes);
        line_width += try Width.strWidth(allocator, word.bytes, .half);

        if (line_width > columns or columns - line_width <= threshold) {
            try result.append('\n');
            line_width = 0;
        }
    }

    return result.toOwnedSlice();
}

fn isLineBreak(str: []const u8) bool {
    if (std.mem.eql(u8, str, "\r\n")) {
        return true;
    } else if (std.mem.eql(u8, str, "\r")) {
        return true;
    } else if (std.mem.eql(u8, str, "\n")) {
        return true;
    } else {
        return false;
    }
}

test "Wrapper wrap" {
    var allocator = testing.allocator;
    var input = "The quick brown fox\r\njumped over the lazy dog!";
    var got = try wrap(allocator, input, 10, 3);
    defer allocator.free(got);
    var want = "The quick\n brown \nfox jumped\n over the\n lazy dog\n!";
    try testing.expectEqualStrings(want, got);
}
