const std = @import("std");
const mem = std.mem;
const unicode = std.unicode;

const Ziglyph = @import("../../ziglyph.zig").Ziglyph;
const Fullwidth = @import("../autogen/DerivedEastAsianWidth/Fullwidth.zig");
const GraphemeIterator = @import("../../zigstr/GraphemeIterator.zig");
const Narrow = @import("../autogen/DerivedEastAsianWidth/Narrow.zig");
const Wide = @import("../autogen/DerivedEastAsianWidth/Wide.zig");

const Self = @This();

allocator: *mem.Allocator,
fullwidth: Fullwidth,
giter: GraphemeIterator,
narrow: Narrow,
wide: Wide,
ziglyph: Ziglyph,

pub fn init(allocator: *mem.Allocator) !Self {
    return Self{
        .allocator = allocator,
        .fullwidth = try Fullwidth.init(allocator),
        .giter = try GraphemeIterator.init(allocator, ""),
        .narrow = try Narrow.init(allocator),
        .wide = try Wide.init(allocator),
        .ziglyph = try Ziglyph.init(allocator),
    };
}

pub fn deinit(self: *Self) void {
    self.fullwidth.deinit();
    self.giter.deinit();
    self.narrow.deinit();
    self.wide.deinit();
    self.ziglyph.deinit();
}

/// codePointWidth returns how many cells (or columns) wide `cp` should be when rendered in a
/// fixed-width font.
pub fn codePointWidth(self: Self, cp: u21) usize {
    if (self.wide.isWide(cp) or self.fullwidth.isFullwidth(cp)) {
        return 2;
    } else if (self.ziglyph.isControl(cp) or !self.ziglyph.isPrint(cp)) {
        return 0;
    } else if (self.giter.regional.isRegionalIndicator(cp)) {
        return 2;
    } else {
        return 1;
    }
    //if (cp > 0x10FFFF) {
    //    return 0;
    //} else if ((cp >= 0x7F and cp <= 0x9F) or cp == 0xAD) {
    //    return 0;
    //} else if (cp < 0x300) {
    //    return 1;
    //} else if (self.narrow.isNarrow(cp)) {
    //    return 1;
    //} else if (!self.ziglyph.isPrint(cp) or (self.ccc_map.combiningClass(cp) != 0)) {
    //    return 0;
    //} else if (self.regional.isRegionalIndicator(cp)) {
    //    return 2;
    //} else if (self.wide.isWide(cp) or self.fullwidth.isFullwidth(cp)) {
    //    return 2;
    //} else {
    //    return 1;
    //}
}

/// strWidth returns how many cells (or columns) wide `str` should be when rendered in a
/// fixed-width font.
pub fn strWidth(self: *Self, str: []const u8) !usize {
    var total: usize = 0;
    try self.giter.reinit(str);

    while (self.giter.next()) |gc| {
        var cp_iter = (try unicode.Utf8View.init(gc.bytes)).iterator();

        while (cp_iter.nextCodepoint()) |cp| {
            var w = self.codePointWidth(cp);

            if (w != 0) {
                if (self.giter.extpic.isExtendedPictographic(cp)) {
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

test "Grapheme Width" {
    const expectEqual = std.testing.expectEqual;
    var z = try init(std.testing.allocator);
    defer z.deinit();

    expectEqual(z.codePointWidth('\n'), 0);
    expectEqual(z.codePointWidth('\r'), 0);
    expectEqual(z.codePointWidth('é'), 1);
    expectEqual(z.codePointWidth('😊'), 2);
    expectEqual(z.codePointWidth('统'), 2);
    expectEqual(try z.strWidth("Hello\r\n"), 5);
    expectEqual(try z.strWidth("\u{0065}\u{0301}"), 1);
    expectEqual(try z.strWidth("\u{1F476}\u{1F3FF}\u{0308}\u{200D}\u{1F476}\u{1F3FF}"), 2);
    expectEqual(try z.strWidth("Hello 😊"), 8);
    expectEqual(try z.strWidth("Héllo 😊"), 8);
    expectEqual(try z.strWidth("Héllo :)"), 8);
    expectEqual(try z.strWidth("Héllo 🇪🇸"), 8);
    expectEqual(try z.strWidth("\u{26A1}"), 2); // Lone emoji
    expectEqual(try z.strWidth("\u{26A1}\u{FE0E}"), 1); // Text sequence
    expectEqual(try z.strWidth("\u{26A1}\u{FE0F}"), 2); // Presentation sequence
}
