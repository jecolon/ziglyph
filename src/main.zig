const std = @import("std");
const Ziglyph = @import("ziglyph.zig").Ziglyph;

test "runeIs" {
    var z = try Ziglyph.init(std.testing.allocator, "src/UnicodeData.txt");
    defer z.deinit();

    const mixed = [_]u21{ '5', 'o', '9', '!', ' ', '℃', 'ᾭ', 'G' };
    for (mixed) |r| {
        std.debug.print("\nFor {u}:\n", .{r});
        if ((z.isControl(r))) {
            std.debug.print("\tis control\n", .{});
        }
        if ((z.isNumber(r))) {
            std.debug.print("\tis number\n", .{});
        }
        if ((z.isGraphic(r))) {
            std.debug.print("\tis graphic\n", .{});
        }
        if ((z.isLetter(r))) {
            std.debug.print("\tis letter\n", .{});
        }
        if ((z.isLower(r))) {
            std.debug.print("\tis lower case\n", .{});
        }
        if ((z.isMark(r))) {
            std.debug.print("\tis mark\n", .{});
        }
        if ((z.isPrint(r))) {
            std.debug.print("\tis printable\n", .{});
        }
        if ((!z.isPrint(r))) {
            std.debug.print("\tis not printable\n", .{});
        }
        if ((z.isPunct(r))) {
            std.debug.print("\tis punct\n", .{});
        }
        if ((z.isSpace(r))) {
            std.debug.print("\tis space\n", .{});
        }
        if ((z.isSymbol(r))) {
            std.debug.print("\tis symbol\n", .{});
        }
        if ((z.isTitle(r))) {
            std.debug.print("\tis title case\n", .{});
        }
        if ((z.isUpper(r))) {
            std.debug.print("\tis upper case\n", .{});
        }
    }
}
