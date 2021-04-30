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

/// AmbiguousWidth determines the width of ambiguous characters according to the context. In an 
/// East Asian context, the width of ambiguous code points should be 2 (full), and 1 (half) 
/// in non-East Asian contexts. The most common use case is `half`.
pub const AmbiguousWidth = enum(u2) {
    half = 1,
    full = 2,
};

/// codePointWidth returns how many cells (or columns) wide `cp` should be when rendered in a
/// fixed-width font.
pub fn codePointWidth(self: Self, cp: u21, am_width: AmbiguousWidth) i8 {
    if (cp == 0x000 or cp == 0x0005 or cp == 0x0007 or (cp >= 0x000A and cp <= 0x000F)) {
        // Control.
        return 0;
    } else if (cp == 0x0008) {
        // backspace
        return -1;
    } else if (cp == 0x00AD) {
        // soft-hyphen
        return 1;
    } else if (cp == 0x2E3A) {
        // two-em dash
        return 2;
    } else if (cp == 0x2E3B) {
        // three-em dash
        return 3;
    } else if (self.context.enclosing.isEnclosingMark(cp) or self.context.nonspacing.isNonspacingMark(cp)) {
        // Combining Marks.
        return 0;
    } else if (self.context.format.isFormat(cp) and (!(cp >= 0x0600 and cp <= 0x0605) and cp != 0x061C and
        cp != 0x06DD and cp != 0x08E2))
    {
        // Format except Arabic.
        return 0;
    } else if ((cp >= 0x1160 and cp <= 0x11FF) or (cp >= 0x2060 and cp <= 0x206F) or
        (cp >= 0xFFF0 and cp <= 0xFFF8) or (cp >= 0xE0000 and cp <= 0xE0FFF))
    {
        // Hangul syllable and ignorable.
        return 0;
    } else if ((cp >= 0x3400 and cp <= 0x4DBF) or (cp >= 0x4E00 and cp <= 0x9FFF) or
        (cp >= 0xF900 and cp <= 0xFAFF) or (cp >= 0x20000 and cp <= 0x2FFFD) or
        (cp >= 0x30000 and cp <= 0x3FFFD))
    {
        return 2;
    } else if (self.context.wide.isWide(cp) or self.context.fullwidth.isFullwidth(cp)) {
        return 2;
    } else if (self.context.regional.isRegionalIndicator(cp)) {
        return 2;
    } else if (self.context.ambiguous.isAmbiguous(cp)) {
        return @enumToInt(am_width);
    } else {
        return 1;
    }
}

/// strWidth returns how many cells (or columns) wide `str` should be when rendered in a
/// fixed-width font.
pub fn strWidth(self: *Self, str: []const u8, am_width: AmbiguousWidth) !usize {
    var total: isize = 0;

    if (self.giter == null) {
        self.giter = try GraphemeIterator.new(self.context, str);
    } else {
        try self.giter.?.reinit(str);
    }

    var giter = self.giter.?;

    while (giter.next()) |gc| {
        var cp_iter = (try unicode.Utf8View.init(gc.bytes)).iterator();

        while (cp_iter.nextCodepoint()) |cp| {
            var w = self.codePointWidth(cp, am_width);

            if (w != 0) {
                if (self.context.extpic.isExtendedPictographic(cp)) {
                    if (cp_iter.nextCodepoint()) |ncp| {
                        if (ncp == 0xFE0E) w = 1; // Emoji text sequence.
                    }
                }
                total += w;
                break;
            }
        }
    }

    return if (total > 0) @intCast(usize, total) else 0;
}

const expectEqual = std.testing.expectEqual;

test "Grapheme Width" {
    var ctx = try Context.init(std.testing.allocator);
    defer ctx.deinit();

    var width = try new(&ctx);

    expectEqual(@as(i8, -1), width.codePointWidth(0x0008, .half)); // \b DEL
    expectEqual(@as(i8, 0), width.codePointWidth(0x0000, .half)); // null
    expectEqual(@as(i8, 0), width.codePointWidth(0x0005, .half)); // Cf
    expectEqual(@as(i8, 0), width.codePointWidth(0x0007, .half)); // \a BEL
    expectEqual(@as(i8, 0), width.codePointWidth(0x000A, .half)); // \n LF
    expectEqual(@as(i8, 0), width.codePointWidth(0x000B, .half)); // \v VT
    expectEqual(@as(i8, 0), width.codePointWidth(0x000C, .half)); // \f FF
    expectEqual(@as(i8, 0), width.codePointWidth(0x000D, .half)); // \r CR
    expectEqual(@as(i8, 0), width.codePointWidth(0x000E, .half)); // SQ
    expectEqual(@as(i8, 0), width.codePointWidth(0x000F, .half)); // SI

    expectEqual(@as(i8, 0), width.codePointWidth(0x070F, .half)); // Cf
    expectEqual(@as(i8, 1), width.codePointWidth(0x0603, .half)); // Cf Arabic

    expectEqual(@as(i8, 1), width.codePointWidth(0x00AD, .half)); // soft-hyphen
    expectEqual(@as(i8, 2), width.codePointWidth(0x2E3A, .half)); // two-em dash
    expectEqual(@as(i8, 3), width.codePointWidth(0x2E3B, .half)); // three-em dash

    expectEqual(@as(i8, 1), width.codePointWidth(0x00BD, .half)); // ambiguous halfwidth
    expectEqual(@as(i8, 2), width.codePointWidth(0x00BD, .full)); // ambiguous fullwidth

    expectEqual(@as(i8, 1), width.codePointWidth('é', .half));
    expectEqual(@as(i8, 2), width.codePointWidth('😊', .half));
    expectEqual(@as(i8, 2), width.codePointWidth('统', .half));

    expectEqual(@as(usize, 5), try width.strWidth("Hello\r\n", .half));
    expectEqual(@as(usize, 1), try width.strWidth("\u{0065}\u{0301}", .half));
    expectEqual(@as(usize, 2), try width.strWidth("\u{1F476}\u{1F3FF}\u{0308}\u{200D}\u{1F476}\u{1F3FF}", .half));
    expectEqual(@as(usize, 8), try width.strWidth("Hello 😊", .half));
    expectEqual(@as(usize, 8), try width.strWidth("Héllo 😊", .half));
    expectEqual(@as(usize, 8), try width.strWidth("Héllo :)", .half));
    expectEqual(@as(usize, 8), try width.strWidth("Héllo 🇪🇸", .half));
    expectEqual(@as(usize, 2), try width.strWidth("\u{26A1}", .half)); // Lone emoji
    expectEqual(@as(usize, 1), try width.strWidth("\u{26A1}\u{FE0E}", .half)); // Text sequence
    expectEqual(@as(usize, 2), try width.strWidth("\u{26A1}\u{FE0F}", .half)); // Presentation sequence
}
