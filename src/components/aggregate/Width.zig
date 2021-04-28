const std = @import("std");
const mem = std.mem;
const unicode = std.unicode;

const Context = @import("../../Context.zig");
const Ziglyph = @import("../../ziglyph.zig").Ziglyph;
const GraphemeIterator = @import("../../zigstr/GraphemeIterator.zig");

const Self = @This();

allocator: *mem.Allocator,
context: *Context,
giter: ?GraphemeIterator,
ziglyph: Ziglyph,

pub fn new(ctx: *Context) !Self {
    return Self{
        .allocator = ctx.allocator,
        .context = ctx,
        .giter = null,
        .ziglyph = try Ziglyph.new(ctx),
    };
}

/// codePointWidth returns how many cells (or columns) wide `cp` should be when rendered in a
/// fixed-width font.
pub fn codePointWidth(self: Self, cp: u21) !usize {
    const ccc_map = try self.context.getCccMap();
    const wide = try self.context.getWide();
    const fullwidth = try self.context.getFullwidth();
    const regional = try self.context.getRegional();

    if ((cp >= 0x7F and cp <= 0x9F) or cp == 0xAD or cp == '\n' or cp == '\r') {
        return 0;
    } else if (cp < 0x300) {
        return 1;
    } else if (ccc_map.combiningClass(cp) != 0 or (!try self.ziglyph.isPrint(cp))) {
        return 0;
    } else if (wide.isWide(cp) or fullwidth.isFullwidth(cp)) {
        return 2;
    } else if (regional.isRegionalIndicator(cp)) {
        return 2;
    } else {
        return 1;
    }
}

/// strWidth returns how many cells (or columns) wide `str` should be when rendered in a
/// fixed-width font.
pub fn strWidth(self: *Self, str: []const u8) !usize {
    var total: usize = 0;
    if (self.giter == null) {
        self.giter = try GraphemeIterator.new(self.context, str);
    } else {
        try self.giter.?.reinit(str);
    }

    var giter = self.giter.?;
    const extpic = try self.context.getExtPic();

    while (try giter.next()) |gc| {
        var cp_iter = (try unicode.Utf8View.init(gc.bytes)).iterator();

        while (cp_iter.nextCodepoint()) |cp| {
            var w = try self.codePointWidth(cp);

            if (w != 0) {
                if (extpic.isExtendedPictographic(cp)) {
                    if (cp_iter.nextCodepoint()) |ncp| {
                        if (ncp == 0xFE0E) w = 1; // Emoji text sequence.
                    }
                }
                total += w;
                break;
            }
        }
    }

    return total;
}

const expectEqual = std.testing.expectEqual;

test "Grapheme Width" {
    var ctx = Context.init(std.testing.allocator);
    defer ctx.deinit();

    var width = try new(&ctx);

    expectEqual(try width.codePointWidth('\n'), 0);
    expectEqual(try width.codePointWidth('\r'), 0);
    expectEqual(try width.codePointWidth('é'), 1);
    expectEqual(try width.codePointWidth('😊'), 2);
    expectEqual(try width.codePointWidth('统'), 2);
    expectEqual(try width.strWidth("Hello\r\n"), 5);
    expectEqual(try width.strWidth("\u{0065}\u{0301}"), 1);
    expectEqual(try width.strWidth("\u{1F476}\u{1F3FF}\u{0308}\u{200D}\u{1F476}\u{1F3FF}"), 2);
    expectEqual(try width.strWidth("Hello 😊"), 8);
    expectEqual(try width.strWidth("Héllo 😊"), 8);
    expectEqual(try width.strWidth("Héllo :)"), 8);
    expectEqual(try width.strWidth("Héllo 🇪🇸"), 8);
    expectEqual(try width.strWidth("\u{26A1}"), 2); // Lone emoji
    expectEqual(try width.strWidth("\u{26A1}\u{FE0E}"), 1); // Text sequence
    expectEqual(try width.strWidth("\u{26A1}\u{FE0F}"), 2); // Presentation sequence
}
