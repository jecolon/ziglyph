# Zigstr
A UTF-8 string type.

## What? No Characters?
Zigstr tries to emphasize the clear distinction between bytes (`u8`), code points (`u21`), and
grapheme clusters (`[]const u8`) as per the Unicode standard. Note that the term *character* is glaringly
missing here, as it tends to produce more confusion than clarity, and in fact Unicode has no concrete 
*character* concept, only abstract characters are broadly mentioned. The closes concept resembling
a human-perceivable *character in Unicode* is the Grapheme Cluster, represented here as the `Grapheme` 
type returned from each call to the `next` method on a `GraphemeIterator` (see sample code below).

## Ownership
There are two possibilities when creating a new Zigstr, either with bytes or code points:

* You own the bytes or code points, requiring the `deinit` method to free them.
* You don't own the bytes or code points, so `deinit` will not free them.

To create a Zigstr with bytes or code points that you don't own:

```zig
// For bytes.
var str = try Zigstr.fromBytes(allocator, "Hello");
defer str.deinit(); // still need `deinit` to free other resources, but not the passed-in bytes.

// For code points.
var str = try Zigstr.fromCodePoints(allocator, &[_]u21{ 0x68, 0x65, 0x6C, 0x6C, 0x6F });
defer str.deinit(); // still need `deinit` to free other resources, but not the passed-in code points.
```

To create a Zigstr from bytes or code points you own:

```zig
// For bytes.
var str = try Zigstr.fromOwnedBytes(allocator, slice);
defer str.deinit(); // owned bytes will be freed.

// For code points.
var str = try Zigstr.fromOwnedCodePoints(allocator, slice);
defer str.deinit(); // owned code points will be freed.
```

## Comparison and Sorting (Collation)
Given the large amounts of data required for comparisons and sorting of Unicode strings, these operations
are not included in the `Zigstr` struct to keep it light and fast. Comparison and sorting of strings
can be found in the `Normalizer` and `Collator` structs. See the main `README` file for examples.

## Display Width
The `Width` struct contains methods to calculate the fixed-width cells a given code point or string 
occupies in a fixed-width context such as a terminal emulator. Since these calculations are required
for methods that *pad* the string in different alignments, operations like `padLeft`, `padRight`, and 
`center` are part of the `Width` struct and not Zigstr. See the main `README` for examples.

## Usage Examples
```zig
const Zigstr = @import("Ziglyph").Zigstr;

test "Zigstr README tests" {
    var allocator = std.testing.allocator;
    var str = try Zigstr.fromBytes(std.testing.allocator, "Héllo");
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

    const gc_want = [_][]const u8{ "H", "é", "l", "l", "o" };

    i = 0;
    while (giter.next()) |gc| : (i += 1) {
        expect(gc.eql(gc_want[i]));
    }

    // Collect all grapheme clusters at once.
    expectEqual(@as(usize, 5), try str.graphemeCount());
    const gcs = try str.graphemes();
    for (gcs) |gc, j| {
        expect(gc.eql(gc_want[j]));
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
    try str.reset("foo"); // re-initialize a Zigstr.

    expect(str.eql("foo")); // exact
    expect(!str.eql("fooo")); // lengths
    expect(!str.eql("foó")); // combining marks
    expect(!str.eql("Foo")); // letter case

    // Trimming.
    try str.reset("   Hello");
    try str.trimLeft(" ");
    expect(str.eql("Hello"));

    try str.reset("Hello   ");
    try str.trimRight(" ");
    expect(str.eql("Hello"));

    try str.reset("   Hello   ");
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
    try str.reset(" Hello World ");

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

    // Convenience methods for splitting on newline '\n'.
    try str.reset("Hello\nWorld");
    var iter = str.lineIter(); // line iterator
    expectEqualStrings(iter.next().?, "Hello");
    expectEqualStrings(iter.next().?, "World");

    var lines_array = try str.lines(); // array of lines without ending \n.
    defer allocator.free(lines_array);
    expectEqualStrings(lines_array[0], "Hello");
    expectEqualStrings(lines_array[1], "World");

    // startsWith / endsWith
    try str.reset("Hello World");
    expect(str.startsWith("Hell"));
    expect(!str.startsWith("Zig"));
    expect(str.endsWith("World"));
    expect(!str.endsWith("Zig"));

    // Concatenation
    try str.reset("Hello");
    try str.concat(" World");
    expect(str.eql("Hello World"));
    var others = [_][]const u8{ " is", " the", " tradition!" };
    try str.concatAll(&others);
    expect(str.eql("Hello World is the tradition!"));

    // replace
    try str.reset("Hello");
    var replacements = try str.replace("l", "z");
    expectEqual(@as(usize, 2), replacements);
    expect(str.eql("Hezzo"));

    replacements = try str.replace("z", "");
    expectEqual(@as(usize, 2), replacements);
    expect(str.eql("Heo"));

    // Append a code point or many.
    try str.reset("Hell");
    try str.append('o');
    expectEqual(@as(usize, 5), str.bytes.len);
    expect(str.eql("Hello"));
    try str.appendAll(&[_]u21{ ' ', 'W', 'o', 'r', 'l', 'd' });
    expect(str.eql("Hello World"));

    // Test for empty string.
    expect(!str.isEmpty());

    // Test for whitespace only (blank) strings.
    try str.reset("  \t  ");
    expect(try str.isBlank());
    expect(!str.isEmpty());

    // Remove grapheme clusters (characters) from strings.
    try str.reset("Hello World");
    try str.dropLeft(6);
    expect(str.eql("World"));
    try str.reset("Hello World");
    try str.dropRight(6);
    expect(str.eql("Hello"));

    // Repeat a string's content.
    try str.reset("*");
    try str.repeat(10);
    expect(str.eql("**********"));
    try str.repeat(1);
    expect(str.eql("**********"));
    try str.repeat(0);
    expect(str.eql(""));

    // Reverse a string. Note correct handling of Unicode code point ordering.
    try str.reset("Héllo 😊");
    try str.reverse();
    expect(str.eql("😊 olléH"));

    // You can also construct a Zigstr from coce points.
    const cp_array = [_]u21{ 0x68, 0x65, 0x6C, 0x6C, 0x6F }; // "hello"
    str.deinit();
    str = try Zigstr.fromCodePoints(allocator, &cp_array);
    expect(str.eql("hello"));
    expectEqual(str.codePointCount(), 5);

    // Chomp line breaks.
    try str.reset("Hello\n");
    try str.chomp();
    expectEqual(@as(usize, 5), str.bytes.len);
    expect(str.eql("Hello"));

    try str.reset("Hello\r");
    try str.chomp();
    expectEqual(@as(usize, 5), str.bytes.len);
    expect(str.eql("Hello"));

    try str.reset("Hello\r\n");
    try str.chomp();
    expectEqual(@as(usize, 5), str.bytes.len);
    expect(str.eql("Hello"));

    // byteSlice, codePointSlice, graphemeSlice, substr
    try str.reset("H\u{0065}\u{0301}llo"); // Héllo
    expectEqualSlices(u8, try str.byteSlice(1, 4), "\u{0065}\u{0301}");
    expectEqualSlices(u21, try str.codePointSlice(1, 3), &[_]u21{ '\u{0065}', '\u{0301}' });
    const gc1 = try str.graphemeSlice(1, 2);
    expect(gc1[0].eql("\u{0065}\u{0301}"));

    // Substrings
    var str3 = try str.substr(1, 2);
    expectEqualStrings("\u{0065}\u{0301}", str3);
    expectEqualStrings(try str.byteSlice(1, 4), str3);

    // Letter case detection.
    try str.reset("hello! 123");
    expect(try str.isLower());
    expect(!try str.isUpper());
    try str.reset("HELLO! 123");
    expect(try str.isUpper());
    expect(!try str.isLower());

    // Letter case conversion.
    try str.reset("Héllo! 123");
    try str.toLower();
    expect(str.eql("héllo! 123"));
    try str.toUpper();
    expect(str.eql("HÉLLO! 123"));

    // Zigstr implements the std.fmt.format interface.
    std.debug.print("Zigstr: {}\n", .{str});
}
```
