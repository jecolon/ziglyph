const std = @import("std");
const expect = std.testing.expect;
const expectEqual = std.testing.expectEqual;
const expectEqualStrings = std.testing.expectEqualStrings;
const expectEqualSlices = std.testing.expectEqualSlices;

usingnamespace @import("zigstr/Zigstr.zig");

test "README tests" {
    var allocator = std.testing.allocator;
    var str = try init(allocator, "Héllo");
    defer str.deinit();

    // Byte count.
    expectEqual(@as(usize, 6), str.byteCount());

    // Code point iteration.
    var cp_iter = try str.codePointIter();
    var want = [_]u21{ 'H', 0x00E9, 'l', 'l', 'o' };

    var i: usize = 0;
    while (cp_iter.next()) |cp| : (i += 1) {
        expectEqual(want[i], cp);
    }

    // Code point count.
    expectEqual(@as(usize, 5), str.codePointCount());

    // Collect all code points at once.
    expectEqualSlices(u21, &want, try str.codePoints());

    // Grapheme cluster iteration.
    var giter = try str.graphemeIter();
    defer giter.deinit();

    const gc_want = [_][]const u8{ "H", "é", "l", "l", "o" };

    i = 0;
    while (giter.next()) |gc| : (i += 1) {
        expectEqualStrings(gc_want[i], gc);
    }

    // Collect all grapheme clusters at once.
    expectEqual(@as(usize, 5), try str.graphemeCount());
    const gcs = try str.graphemes();
    for (gcs) |gc, j| {
        expectEqualStrings(gc_want[j], gc);
    }

    // Grapheme count.
    expectEqual(@as(usize, 5), try str.graphemeCount());

    // Copy
    var str2 = try str.copy();
    defer str2.deinit();
    expect(str.eql(str2.bytes));
    expect(str2.eql("Héllo"));
    expect(str.sameAs(str2));

    // Equality
    try str.reinit("foo"); // re-initialize a Zigstr.

    expect(str.eql("foo")); // exact
    expect(!str.eql("fooo")); // lengths
    expect(!str.eql("foó")); // combining marks
    expect(!str.eql("Foo")); // letter case

    expect(try str.eqlBy("Foo", .ignore_case));

    try str.reinit("foé");
    expect(try str.eqlBy("foe\u{0301}", .normalize));

    try str.reinit("foϓ");
    expect(try str.eqlBy("foΥ\u{0301}", .normalize));

    try str.reinit("Foϓ");
    expect(try str.eqlBy("foΥ\u{0301}", .norm_ignore));

    try str.reinit("FOÉ");
    expect(try str.eqlBy("foe\u{0301}", .norm_ignore)); // foÉ == foé

    // Trimming.
    try str.reinit("   Hello");
    try str.trimLeft(" ");
    expect(str.eql("Hello"));

    try str.reinit("Hello   ");
    try str.trimRight(" ");
    expect(str.eql("Hello"));

    try str.reinit("   Hello   ");
    try str.trim(" ");
    expect(str.eql("Hello"));

    // indexOf / contains / lastIndexOf
    expectEqual(str.indexOf("l"), 2);
    expectEqual(str.indexOf("z"), null);
    expect(str.contains("l"));
    expect(!str.contains("z"));
    expectEqual(str.lastIndexOf("l"), 3);
    expectEqual(str.lastIndexOf("z"), null);

    // count
    expectEqual(str.count("l"), 2);
    expectEqual(str.count("ll"), 1);
    expectEqual(str.count("z"), 0);

    // Tokenization
    try str.reinit(" Hello World ");

    // Token iteration.
    var tok_iter = str.tokenIter(" ");
    expectEqualStrings("Hello", tok_iter.next().?);
    expectEqualStrings("World", tok_iter.next().?);
    expect(tok_iter.next() == null);

    // Collect all tokens at once.
    var ts = try str.tokenize(" ");
    defer allocator.free(ts);
    expectEqual(@as(usize, 2), ts.len);
    expectEqualStrings("Hello", ts[0]);
    expectEqualStrings("World", ts[1]);

    // Split
    var split_iter = str.splitIter(" ");
    expectEqualStrings("", split_iter.next().?);
    expectEqualStrings("Hello", split_iter.next().?);
    expectEqualStrings("World", split_iter.next().?);
    expectEqualStrings("", split_iter.next().?);
    expect(split_iter.next() == null);

    // Collect all sub-strings at once.
    var ss = try str.split(" ");
    defer allocator.free(ss);
    expectEqual(@as(usize, 4), ss.len);
    expectEqualStrings("", ss[0]);
    expectEqualStrings("Hello", ss[1]);
    expectEqualStrings("World", ss[2]);
    expectEqualStrings("", ss[3]);

    // startsWith / endsWith
    try str.reinit("Hello World");
    expect(str.startsWith("Hell"));
    expect(!str.startsWith("Zig"));
    expect(str.endsWith("World"));
    expect(!str.endsWith("Zig"));

    // Concatenation
    try str.reinit("Hello");
    try str.concat(" World");
    expect(str.eql("Hello World"));
    var others = [_][]const u8{ " is", " the", " tradition!" };
    try str.concatAll(&others);
    expect(str.eql("Hello World is the tradition!"));

    // replace
    try str.reinit("Hello");
    var replacements = try str.replace("l", "z");
    expectEqual(@as(usize, 2), replacements);
    expect(str.eql("Hezzo"));

    replacements = try str.replace("z", "");
    expectEqual(@as(usize, 2), replacements);
    expect(str.eql("Heo"));

    // Append a code point or many.
    try str.reinit("Hell");
    try str.append('o');
    expectEqual(@as(usize, 5), str.bytes.len);
    expect(str.eql("Hello"));
    try str.appendAll(&[_]u21{ ' ', 'W', 'o', 'r', 'l', 'd' });
    expect(str.eql("Hello World"));

    // Test for empty string.
    expect(!str.empty());

    // Chomp line breaks.
    try str.reinit("Hello\n");
    try str.chomp();
    expectEqual(@as(usize, 5), str.bytes.len);
    expect(str.eql("Hello"));

    try str.reinit("Hello\r");
    try str.chomp();
    expectEqual(@as(usize, 5), str.bytes.len);
    expect(str.eql("Hello"));

    try str.reinit("Hello\r\n");
    try str.chomp();
    expectEqual(@as(usize, 5), str.bytes.len);
    expect(str.eql("Hello"));

    // byteSlice, codePointSlice, graphemeSlice, substr
    try str.reinit("H\u{0065}\u{0301}llo"); // Héllo
    expectEqualSlices(u8, try str.byteSlice(1, 4), "\u{0065}\u{0301}");
    expectEqualSlices(u21, try str.codePointSlice(1, 3), &[_]u21{ '\u{0065}', '\u{0301}' });
    const gc1 = try str.graphemeSlice(1, 2);
    expectEqualStrings(gc1[0], "\u{0065}\u{0301}");
    // Substrings
    var str3 = try str.substr(1, 2);
    defer str3.deinit();
    expect(str3.eql("\u{0065}\u{0301}"));
    expect(str3.eql(try str.byteSlice(1, 4)));
}
