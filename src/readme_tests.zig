const std = @import("std");
const expect = std.testing.expect;
const expectEqual = std.testing.expectEqual;
const expectEqualSlices = std.testing.expectEqualSlices;

// Import structs.
const Collator = @import("zigstr/Collator.zig");
const GraphemeIterator = @import("ziglyph.zig").GraphemeIterator;
const Letter = @import("components/aggregate/Letter.zig");
const Lower = @import("components/autogen/DerivedCoreProperties/Lowercase.zig");
const Normalizer = @import("components.zig").Normalizer;
const Punct = @import("components/aggregate/Punct.zig");
const Upper = @import("components/autogen/DerivedCoreProperties/Uppercase.zig");
const UpperMap = @import("components/autogen/UnicodeData/UpperMap.zig");
const Width = @import("components/aggregate/Width.zig");
const Ziglyph = @import("ziglyph.zig").Ziglyph;

test "Ziglyph struct" {
    var ziglyph = Ziglyph.new();

    const z = 'z';
    expect(ziglyph.isLetter(z));
    expect(ziglyph.isAlphaNum(z));
    expect(ziglyph.isPrint(z));
    expect(!ziglyph.isUpper(z));
    const uz = ziglyph.toUpper(z);
    expect(ziglyph.isUpper(uz));
    expectEqual(uz, 'Z');
}

test "Aggregate struct" {
    var letter = Letter.new();
    var punct = Punct.new();

    const z = 'z';
    expect(letter.isLetter(z));
    expect(!letter.isUpper(z));
    expect(!punct.isPunct(z));
    expect(punct.isPunct('!'));
    const uz = letter.toUpper(z);
    expect(letter.isUpper(uz));
    expectEqual(uz, 'Z');
}

test "Component structs" {
    var lower = Lower{};
    var upper = Upper{};
    var upper_map = UpperMap{};

    const z = 'z';
    expect(lower.isLowercase(z));
    expect(!upper.isUppercase(z));
    const uz = upper_map.toUpper(z);
    expect(upper.isUppercase(uz));
    expectEqual(uz, 'Z');
}

test "decomposeTo" {
    var allocator = std.testing.allocator;
    var normalizer = try Normalizer.init(allocator, "src/data/ucd/UnicodeData.txt");
    defer normalizer.deinit();

    const Decomposed = Normalizer.Decomposed;

    // CD: ox03D3 -> 0x03D2, 0x0301
    var src = [1]Decomposed{.{ .src = '\u{03D3}' }};
    var result = try normalizer.decomposeTo(allocator, .D, &src);
    defer allocator.free(result);
    expectEqual(result.len, 2);
    expectEqual(result[0].same, 0x03D2);
    expectEqual(result[1].same, 0x0301);
    allocator.free(result);

    // KD: ox03D3 -> 0x03D2, 0x0301 -> 0x03A5, 0x0301
    src = [1]Decomposed{.{ .src = '\u{03D3}' }};
    result = try normalizer.decomposeTo(allocator, .KD, &src);
    expectEqual(result.len, 2);
    expect(result[0] == .same);
    expectEqual(result[0].same, 0x03A5);
    expect(result[1] == .same);
    expectEqual(result[1].same, 0x0301);
}

test "normalizeTo" {
    var allocator = std.testing.allocator;
    var normalizer = try Normalizer.init(allocator, "src/data/ucd/UnicodeData.txt");
    defer normalizer.deinit();

    // Canonical (NFD)
    var input = "Complex char: \u{03D3}";
    var want = "Complex char: \u{03D2}\u{0301}";
    var got = try normalizer.normalizeTo(allocator, .D, input);
    defer allocator.free(got);
    expectEqualSlices(u8, want, got);
    allocator.free(got);

    // Compatibility (NFKD)
    input = "Complex char: \u{03D3}";
    want = "Complex char: \u{03A5}\u{0301}";
    got = try normalizer.normalizeTo(allocator, .KD, input);
    expectEqualSlices(u8, want, got);
}

test "GraphemeIterator" {
    var giter = try GraphemeIterator.new("H\u{0065}\u{0301}llo");

    const want = &[_][]const u8{ "H", "\u{0065}\u{0301}", "l", "l", "o" };

    var i: usize = 0;
    while (giter.next()) |gc| : (i += 1) {
        expect(gc.eql(want[i]));
    }
}

test "Code point / string widths" {
    var width = Width.new();

    expectEqual(width.codePointWidth('é', .half), 1);
    expectEqual(width.codePointWidth('😊', .half), 2);
    expectEqual(width.codePointWidth('统', .half), 2);
    expectEqual(try width.strWidth("Hello\r\n", .half), 5);
    expectEqual(try width.strWidth("\u{1F476}\u{1F3FF}\u{0308}\u{200D}\u{1F476}\u{1F3FF}", .half), 2);
    expectEqual(try width.strWidth("Héllo 🇪🇸", .half), 8);
    expectEqual(try width.strWidth("\u{26A1}\u{FE0E}", .half), 1); // Text sequence
    expectEqual(try width.strWidth("\u{26A1}\u{FE0F}", .half), 2); // Presentation sequence

    var allocator = std.testing.allocator;

    // padLeft, center, padRight
    const right_aligned = try width.padLeft(allocator, "w😊w", 10, "-");
    defer allocator.free(right_aligned);
    expectEqualSlices(u8, "------w😊w", right_aligned);

    const centered = try width.center(allocator, "w😊w", 10, "-");
    defer allocator.free(centered);
    expectEqualSlices(u8, "---w😊w---", centered);

    const left_aligned = try width.padRight(allocator, "w😊w", 10, "-");
    defer allocator.free(left_aligned);
    expectEqualSlices(u8, "w😊w------", left_aligned);
}

test "Collation" {
    var allocator = std.testing.allocator;
    var normalizer = try Normalizer.init(allocator, "src/data/ucd/UnicodeData.txt");
    defer normalizer.deinit();
    var collator = try Collator.init(allocator, "src/data/uca/allkeys.txt", &normalizer);
    defer collator.deinit();

    expect(try collator.lessThan("abc", "def"));
    var strings: [3][]const u8 = .{ "xyz", "def", "abc" };
    collator.sort(&strings);
    expectEqual(strings[0], "abc");
    expectEqual(strings[1], "def");
    expectEqual(strings[2], "xyz");
}
