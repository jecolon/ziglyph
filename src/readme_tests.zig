const std = @import("std");
const expect = std.testing.expect;
const expectEqual = std.testing.expectEqual;
const expectEqualSlices = std.testing.expectEqualSlices;

// Import structs.
const Context = @import("Context.zig");
const GraphemeIterator = @import("ziglyph.zig").GraphemeIterator;
const Letter = @import("components/aggregate/Letter.zig");
const Punct = @import("components/aggregate/Punct.zig");
const Width = @import("components/aggregate/Width.zig");
const Ziglyph = @import("ziglyph.zig").Ziglyph;

test "Ziglyph struct" {
    var ctx = Context.init(std.testing.allocator);
    defer ctx.deinit();

    var ziglyph = try Ziglyph.new(&ctx);

    const z = 'z';
    expect(try ziglyph.isLetter(z));
    expect(try ziglyph.isAlphaNum(z));
    expect(try ziglyph.isPrint(z));
    expect(!try ziglyph.isUpper(z));
    const uz = try ziglyph.toUpper(z);
    expect(try ziglyph.isUpper(uz));
    expectEqual(uz, 'Z');
}

test "Aggregate struct" {
    var ctx = Context.init(std.testing.allocator);
    defer ctx.deinit();

    var letter = Letter.new(&ctx);
    var punct = Punct.new(&ctx);

    const z = 'z';
    expect(try letter.isLetter(z));
    expect(!try letter.isUpper(z));
    expect(!try punct.isPunct(z));
    expect(try punct.isPunct('!'));
    const uz = try letter.toUpper(z);
    expect(try letter.isUpper(uz));
    expectEqual(uz, 'Z');
}

test "Component structs" {
    var ctx = Context.init(std.testing.allocator);
    defer ctx.deinit();

    const lower = try ctx.getLower();
    const upper = try ctx.getUpper();
    const upper_map = try ctx.getUpperMap();

    const z = 'z';
    expect(lower.isLowercaseLetter(z));
    expect(!upper.isUppercaseLetter(z));
    const uz = upper_map.toUpper(z);
    expect(upper.isUppercaseLetter(uz));
    expectEqual(uz, 'Z');
}

test "decomposeTo" {
    var allocator = std.testing.allocator;
    var ctx = Context.init(allocator);
    defer ctx.deinit();

    const Decomposed = Context.DecomposeMap.Decomposed;
    const decomp_map = try ctx.getDecomposeMap();

    // CD: ox03D3 -> 0x03D2, 0x0301
    var src = [1]Decomposed{.{ .src = '\u{03D3}' }};
    var result = try decomp_map.decomposeTo(allocator, .D, &src);
    defer allocator.free(result);
    expectEqual(result.len, 2);
    expectEqual(result[0].same, 0x03D2);
    expectEqual(result[1].same, 0x0301);
    allocator.free(result);

    // KD: ox03D3 -> 0x03D2, 0x0301 -> 0x03A5, 0x0301
    src = [1]Decomposed{.{ .src = '\u{03D3}' }};
    result = try decomp_map.decomposeTo(allocator, .KD, &src);
    expectEqual(result.len, 2);
    expect(result[0] == .same);
    expectEqual(result[0].same, 0x03A5);
    expect(result[1] == .same);
    expectEqual(result[1].same, 0x0301);
}

test "normalizeTo" {
    var allocator = std.testing.allocator;
    var ctx = Context.init(allocator);
    defer ctx.deinit();

    const decomp_map = try ctx.getDecomposeMap();

    // Canonical (NFD)
    var input = "Complex char: \u{03D3}";
    var want = "Complex char: \u{03D2}\u{0301}";
    var got = try decomp_map.normalizeTo(allocator, .D, input);
    defer allocator.free(got);
    expectEqualSlices(u8, want, got);
    allocator.free(got);

    // Compatibility (NFKD)
    input = "Complex char: \u{03D3}";
    want = "Complex char: \u{03A5}\u{0301}";
    got = try decomp_map.normalizeTo(allocator, .KD, input);
    expectEqualSlices(u8, want, got);
}

test "GraphemeIterator" {
    var ctx = Context.init(std.testing.allocator);
    defer ctx.deinit();

    var iter = try GraphemeIterator.new(&ctx, "H\u{0065}\u{0301}llo");

    const want = &[_][]const u8{ "H", "\u{0065}\u{0301}", "l", "l", "o" };

    var i: usize = 0;
    while (try iter.next()) |gc| : (i += 1) {
        expect(gc.eql(want[i]));
    }
}

test "Code point / string widths" {
    var ctx = Context.init(std.testing.allocator);
    defer ctx.deinit();

    var width = try Width.new(&ctx);

    expectEqual(try width.codePointWidth('é'), 1);
    expectEqual(try width.codePointWidth('😊'), 2);
    expectEqual(try width.codePointWidth('统'), 2);
    expectEqual(try width.strWidth("Hello\r\n"), 5);
    expectEqual(try width.strWidth("\u{1F476}\u{1F3FF}\u{0308}\u{200D}\u{1F476}\u{1F3FF}"), 2);
    expectEqual(try width.strWidth("Héllo 🇪🇸"), 8);
    expectEqual(try width.strWidth("\u{26A1}\u{FE0E}"), 1); // Text sequence
    expectEqual(try width.strWidth("\u{26A1}\u{FE0F}"), 2); // Presentation sequence
}
