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
pub fn codePointWidth(self: Self, cp: u21, am_width: AmbiguousWidth) !isize {
    const ambiguous = try self.context.getAmbiguous();
    const enclosing = try self.context.getEnclosing();
    const format = try self.context.getFormat();
    const fullwidth = try self.context.getFullwidth();
    const nonspacing = try self.context.getNonspacing();
    const regional = try self.context.getRegional();
    const wide = try self.context.getWide();

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
    } else if (enclosing.isEnclosingMark(cp) or nonspacing.isNonspacingMark(cp)) {
        // Combining Marks.
        return 0;
    } else if (format.isFormat(cp) and (!(cp >= 0x0600 and cp <= 0x0605) and cp != 0x061C and
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
    } else if (wide.isWide(cp) or fullwidth.isFullwidth(cp)) {
        return 2;
    } else if (regional.isRegionalIndicator(cp)) {
        return 2;
    } else if (ambiguous.isAmbiguous(cp)) {
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
    const extpic = try self.context.getExtPic();

    while (try giter.next()) |gc| {
        var cp_iter = (try unicode.Utf8View.init(gc.bytes)).iterator();

        while (cp_iter.nextCodepoint()) |cp| {
            var w = try self.codePointWidth(cp, am_width);

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

    return if (total > 0) @intCast(usize, total) else 0;
}

const expectEqual = std.testing.expectEqual;

test "Grapheme Width" {
    var ctx = Context.init(std.testing.allocator);
    defer ctx.deinit();

    var width = try new(&ctx);

    expectEqual(@as(isize, -1), try width.codePointWidth(0x0008, .half)); // \b DEL
    expectEqual(@as(isize, 0), try width.codePointWidth(0x0000, .half)); // null
    expectEqual(@as(isize, 0), try width.codePointWidth(0x0005, .half)); // Cf
    expectEqual(@as(isize, 0), try width.codePointWidth(0x0007, .half)); // \a BEL
    expectEqual(@as(isize, 0), try width.codePointWidth(0x000A, .half)); // \n LF
    expectEqual(@as(isize, 0), try width.codePointWidth(0x000B, .half)); // \v VT
    expectEqual(@as(isize, 0), try width.codePointWidth(0x000C, .half)); // \f FF
    expectEqual(@as(isize, 0), try width.codePointWidth(0x000D, .half)); // \r CR
    expectEqual(@as(isize, 0), try width.codePointWidth(0x000E, .half)); // SQ
    expectEqual(@as(isize, 0), try width.codePointWidth(0x000F, .half)); // SI

    expectEqual(@as(isize, 0), try width.codePointWidth(0x070F, .half)); // Cf
    expectEqual(@as(isize, 1), try width.codePointWidth(0x0603, .half)); // Cf Arabic

    expectEqual(@as(isize, 1), try width.codePointWidth(0x00AD, .half)); // soft-hyphen
    expectEqual(@as(isize, 2), try width.codePointWidth(0x2E3A, .half)); // two-em dash
    expectEqual(@as(isize, 3), try width.codePointWidth(0x2E3B, .half)); // three-em dash

    expectEqual(@as(isize, 1), try width.codePointWidth(0x00BD, .half)); // ambiguous halfwidth
    expectEqual(@as(isize, 2), try width.codePointWidth(0x00BD, .full)); // ambiguous fullwidth

    expectEqual(try width.codePointWidth('é', .half), 1);
    expectEqual(try width.codePointWidth('😊', .half), 2);
    expectEqual(try width.codePointWidth('统', .half), 2);
    expectEqual(try width.strWidth("Hello\r\n", .half), 5);
    expectEqual(try width.strWidth("\u{0065}\u{0301}", .half), 1);
    expectEqual(try width.strWidth("\u{1F476}\u{1F3FF}\u{0308}\u{200D}\u{1F476}\u{1F3FF}", .half), 2);
    expectEqual(try width.strWidth("Hello 😊", .half), 8);
    expectEqual(try width.strWidth("Héllo 😊", .half), 8);
    expectEqual(try width.strWidth("Héllo :)", .half), 8);
    expectEqual(try width.strWidth("Héllo 🇪🇸", .half), 8);
    expectEqual(try width.strWidth("\u{26A1}", .half), 2); // Lone emoji
    expectEqual(try width.strWidth("\u{26A1}\u{FE0E}", .half), 1); // Text sequence
    expectEqual(try width.strWidth("\u{26A1}\u{FE0F}", .half), 2); // Presentation sequence
}
