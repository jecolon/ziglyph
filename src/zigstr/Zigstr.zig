const std = @import("std");
const mem = std.mem;
const unicode = std.unicode;

const ascii = @import("../ascii.zig");
const DecomposeMap = @import("../ziglyph.zig").DecomposeMap;
const CaseFoldMap = @import("../components/autogen/CaseFolding/CaseFoldMap.zig");
pub const CodePointIterator = @import("CodePointIterator.zig");
pub const GraphemeIterator = @import("GraphemeIterator.zig");

allocator: *mem.Allocator,
bytes: []const u8,
code_points: ?[]u21,
cp_count: usize,
decomp_map: DecomposeMap,
fold_map: CaseFoldMap,
grapheme_clusters: ?[][]const u8,

const Self = @This();

pub fn init(allocator: *mem.Allocator, str: []const u8) !Self {
    // This not only gets the code point count, it validates str as UTF-8.
    const cp_count = try unicode.utf8CountCodepoints(str);

    return Self{
        .allocator = allocator,
        .bytes = blk: {
            var b = try allocator.alloc(u8, str.len);
            mem.copy(u8, b, str);
            break :blk b;
        },
        .code_points = null,
        .cp_count = cp_count,
        .decomp_map = try DecomposeMap.init(allocator),
        .fold_map = try CaseFoldMap.init(allocator),
        .grapheme_clusters = null,
    };
}

fn deinitContent(self: *Self) void {
    if (self.code_points) |code_points| {
        self.allocator.free(code_points);
    }

    if (self.grapheme_clusters) |gcs| {
        self.allocator.free(gcs);
    }

    self.code_points = null;
    self.cp_count = 0;
    self.grapheme_clusters = null;
    self.allocator.free(self.bytes);
    self.bytes = &[0]u8{};
}

pub fn deinit(self: *Self) void {
    self.decomp_map.deinit();
    self.fold_map.deinit();
    self.deinitContent();
}

pub fn reinit(self: *Self, str: []const u8) !void {
    // Get code point count and validate UTF-8.
    self.cp_count = try unicode.utf8CountCodepoints(str);
    // Copy befor deinit becasue maybe str is a slice of self.bytes.
    var bytes = try self.allocator.alloc(u8, str.len);
    mem.copy(u8, bytes, str);
    self.deinitContent();
    self.bytes = bytes;
}

/// byteCount returns the number of bytes, which can be different from the number of code points and the 
/// number of graphemes.
pub fn byteCount(self: Self) usize {
    return self.bytes.len;
}

/// codePointIter returns a code point iterator based on the bytes of this Zigstr.
pub fn codePointIter(self: Self) !CodePointIterator {
    return try CodePointIterator.init(self.bytes);
}

/// codePoints returns the code points that make up this Zigstr.
pub fn codePoints(self: *Self) ![]u21 {
    // Check for cached code points.
    if (self.code_points) |code_points| return code_points;

    // Cache miss, generate.
    var cp_iter = try self.codePointIter();
    var code_points = std.ArrayList(u21).init(self.allocator);
    defer code_points.deinit();

    while (cp_iter.next()) |cp| {
        try code_points.append(cp);
    }

    // Cache.
    self.code_points = code_points.toOwnedSlice();

    return self.code_points.?;
}

/// codePointCount returns the number of code points, which can be different from the number of bytes
/// and the number of graphemes.
pub fn codePointCount(self: *Self) usize {
    return self.cp_count;
}

test "Zigstr code points" {
    var str = try init(std.testing.allocator, "Héllo");
    defer str.deinit();

    var cp_iter = try str.codePointIter();
    var want = [_]u21{ 'H', 0x00E9, 'l', 'l', 'o' };
    var i: usize = 0;
    while (cp_iter.next()) |cp| : (i += 1) {
        std.testing.expectEqual(want[i], cp);
    }

    std.testing.expectEqual(@as(usize, 5), str.codePointCount());
    std.testing.expectEqualSlices(u21, &want, try str.codePoints());
    std.testing.expectEqual(@as(usize, 6), str.byteCount());
    std.testing.expectEqual(@as(usize, 5), str.codePointCount());
}

/// graphemeIter returns a grapheme cluster iterator based on the bytes of this Zigstr. Each grapheme
/// can be composed of multiple code points, so the next method returns a slice of bytes.
pub fn graphemeIter(self: Self) !GraphemeIterator {
    return GraphemeIterator.init(self.allocator, self.bytes);
}

/// graphemes returns the grapheme clusters that make up this Zigstr.
pub fn graphemes(self: *Self) ![][]const u8 {
    // Check for cached code points.
    if (self.grapheme_clusters) |gcs| return gcs;

    // Cache miss, generate.
    var giter = try self.graphemeIter();
    defer giter.deinit();
    var gcs = std.ArrayList([]const u8).init(self.allocator);
    defer gcs.deinit();

    while (giter.next()) |gc| {
        try gcs.append(gc);
    }

    // Cache.
    self.grapheme_clusters = gcs.toOwnedSlice();

    return self.grapheme_clusters.?;
}

/// graphemeCount returns the number of grapheme clusters, which can be different from the number of bytes
/// and the number of code points.
pub fn graphemeCount(self: *Self) !usize {
    if (self.grapheme_clusters) |gcs| {
        return gcs.len;
    } else {
        return (try self.graphemes()).len;
    }
}

test "Zigstr graphemes" {
    var str = try init(std.testing.allocator, "Héllo");
    defer str.deinit();

    var giter = try str.graphemeIter();
    defer giter.deinit();
    var want = [_][]const u8{ "H", "é", "l", "l", "o" };
    var i: usize = 0;
    while (giter.next()) |gc| : (i += 1) {
        std.testing.expectEqualStrings(want[i], gc);
    }

    std.testing.expectEqual(@as(usize, 5), try str.graphemeCount());
    const gcs = try str.graphemes();
    for (gcs) |gc, j| {
        std.testing.expectEqualStrings(want[j], gc);
    }
    std.testing.expectEqual(@as(usize, 6), str.byteCount());
    std.testing.expectEqual(@as(usize, 5), try str.graphemeCount());
}

/// copy a Zigstr to a new Zigstr.
pub fn copy(self: Self) !Self {
    return init(self.allocator, self.bytes);
}

/// sameAs convenience method to test exact byte equality of two Zigstrs.
pub fn sameAs(self: Self, other: Self) bool {
    return self.eql(other.bytes);
}

test "Zigstr copy" {
    var str1 = try init(std.testing.allocator, "Zig");
    defer str1.deinit();
    var str2 = try str1.copy();
    defer str2.deinit();

    std.testing.expect(str1.eql(str2.bytes));
    std.testing.expect(str2.eql("Zig"));
    std.testing.expect(str1.sameAs(str2));
}

/// isEmpty returns true if the Zigstr has no bytes.
pub fn isEmpty(self: Self) bool {
    return self.bytes.len == 0;
}

pub const CmpMode = enum {
    ignore_case,
    normalize,
    norm_ignore,
};

/// eql compares for exact byte per byte equality with `other`.
pub fn eql(self: Self, other: []const u8) bool {
    return mem.eql(u8, self.bytes, other);
}

/// eqlBy compares for equality with `other` according to the specified comparison mode.
pub fn eqlBy(self: *Self, other: []const u8, mode: CmpMode) !bool {
    var ascii_only = true;
    var bytes_eql = true;
    var inner: []const u8 = undefined;
    const len_a = self.bytes.len;
    const len_b = other.len;
    var len_eql = len_a == len_b;
    var outer: []const u8 = undefined;

    if (len_a <= len_b) {
        outer = self.bytes;
        inner = other;
    } else {
        outer = other;
        inner = self.bytes;
    }

    for (outer) |c, i| {
        if (c != inner[i]) bytes_eql = false;
        if (!isAscii(c) and !isAscii(inner[i])) ascii_only = false;
    }

    if (mode == .ignore_case and len_eql) {
        if (ascii_only) {
            // ASCII case insensitive.
            for (self.bytes) |c, i| {
                if (ascii.toLower(c) != ascii.toLower(other[i])) return false;
            }
            return true;
        }

        // Non-ASCII case insensitive.
        return try self.eqlIgnoreCase(other);
    }

    if (mode == .normalize) return try self.eqlNorm(other);
    if (mode == .norm_ignore) return try self.eqlNormIgnore(other);

    return false;
}

fn eqlIgnoreCase(self: *Self, other: []const u8) !bool {
    const cf_a = try self.fold_map.caseFoldStr(self.allocator, self.bytes);
    defer self.allocator.free(cf_a);
    const cf_b = try self.fold_map.caseFoldStr(self.allocator, other);
    defer self.allocator.free(cf_b);

    return mem.eql(u8, cf_a, cf_b);
}

fn eqlNorm(self: *Self, other: []const u8) !bool {
    var arena = std.heap.ArenaAllocator.init(self.allocator);
    defer arena.deinit();

    const norm_a = try self.decomp_map.normalizeTo(&arena.allocator, .KD, self.bytes);
    const norm_b = try self.decomp_map.normalizeTo(&arena.allocator, .KD, other);

    return mem.eql(u8, norm_a, norm_b);
}

fn eqlNormIgnore(self: *Self, other: []const u8) !bool {
    var arena = std.heap.ArenaAllocator.init(self.allocator);
    defer arena.deinit();

    // The long winding road of normalized caseless matching...
    // NFKD(CaseFold(NFKD(CaseFold(NFD(str)))))
    var norm_a = try self.decomp_map.normalizeTo(&arena.allocator, .D, self.bytes);
    var cf_a = try self.fold_map.caseFoldStr(&arena.allocator, norm_a);
    norm_a = try self.decomp_map.normalizeTo(&arena.allocator, .KD, cf_a);
    cf_a = try self.fold_map.caseFoldStr(&arena.allocator, norm_a);
    norm_a = try self.decomp_map.normalizeTo(&arena.allocator, .KD, cf_a);
    var norm_b = try self.decomp_map.normalizeTo(&arena.allocator, .D, other);
    var cf_b = try self.fold_map.caseFoldStr(&arena.allocator, norm_b);
    norm_b = try self.decomp_map.normalizeTo(&arena.allocator, .KD, cf_b);
    cf_b = try self.fold_map.caseFoldStr(&arena.allocator, norm_b);
    norm_b = try self.decomp_map.normalizeTo(&arena.allocator, .KD, cf_b);

    return mem.eql(u8, norm_a, norm_b);
}

test "Zigstr eql" {
    var str = try init(std.testing.allocator, "foo");
    defer str.deinit();

    std.testing.expect(str.eql("foo")); // exact
    std.testing.expect(!str.eql("fooo")); // lengths
    std.testing.expect(!str.eql("foó")); // combining
    std.testing.expect(!str.eql("Foo")); // letter case
    std.testing.expect(try str.eqlBy("Foo", .ignore_case));

    try str.reinit("foé");
    std.testing.expect(try str.eqlBy("foe\u{0301}", .normalize));

    try str.reinit("foϓ");
    std.testing.expect(try str.eqlBy("foΥ\u{0301}", .normalize));

    try str.reinit("Foϓ");
    std.testing.expect(try str.eqlBy("foΥ\u{0301}", .norm_ignore));

    try str.reinit("FOÉ");
    std.testing.expect(try str.eqlBy("foe\u{0301}", .norm_ignore)); // foÉ == foé
}

/// isAscii checks a code point to see if it's an ASCII character.
pub fn isAscii(cp: u21) bool {
    return cp < 128;
}

/// isAsciiStr checks if a string (`[]const uu`) is composed solely of ASCII characters.
pub fn isAsciiStr(str: []const u8) !bool {
    var cp_iter = (try unicode.Utf8View.init(str)).iterator();
    while (cp_iter.nextCodepoint()) |cp| {
        if (!isAscii(cp)) return false;
    }
    return true;
}

test "Zigstr isAsciiStr" {
    std.testing.expect(try isAsciiStr("Hello!"));
    std.testing.expect(!try isAsciiStr("Héllo!"));
}

/// isLatin1 checks a code point to see if it's a Latin-1 character.
pub fn isLatin1(cp: u21) bool {
    return cp < 256;
}

/// isLatin1Str checks if a string (`[]const uu`) is composed solely of Latin-1 characters.
pub fn isLatin1Str(str: []const u8) !bool {
    var cp_iter = (try unicode.Utf8View.init(str)).iterator();
    while (cp_iter.nextCodepoint()) |cp| {
        if (!isLatin1(cp)) return false;
    }
    return true;
}

test "Zigstr isLatin1Str" {
    std.testing.expect(try isLatin1Str("Hello!"));
    std.testing.expect(try isLatin1Str("Héllo!"));
    std.testing.expect(!try isLatin1Str("H\u{0065}\u{0301}llo!"));
    std.testing.expect(!try isLatin1Str("H😀llo!"));
}

/// trimLeft removes `str` from the left of this Zigstr, mutating it.
pub fn trimLeft(self: *Self, str: []const u8) !void {
    const trimmed = mem.trimLeft(u8, self.bytes, str);
    try self.reinit(trimmed);
}

test "Zigstr trimLeft" {
    var str = try init(std.testing.allocator, "   Hello");
    defer str.deinit();

    try str.trimLeft(" ");
    std.testing.expect(str.eql("Hello"));
}

/// trimRight removes `str` from the right of this Zigstr, mutating it.
pub fn trimRight(self: *Self, str: []const u8) !void {
    const trimmed = mem.trimRight(u8, self.bytes, str);
    try self.reinit(trimmed);
}

test "Zigstr trimRight" {
    var str = try init(std.testing.allocator, "Hello   ");
    defer str.deinit();

    try str.trimRight(" ");
    std.testing.expect(str.eql("Hello"));
}

/// trim removes `str` from both the left and right of this Zigstr, mutating it.
pub fn trim(self: *Self, str: []const u8) !void {
    const trimmed = mem.trim(u8, self.bytes, str);
    try self.reinit(trimmed);
}

test "Zigstr trim" {
    var str = try init(std.testing.allocator, "   Hello   ");
    defer str.deinit();

    try str.trim(" ");
    std.testing.expect(str.eql("Hello"));
}

/// indexOf returns the index of `needle` in this Zigstr or null if not found.
pub fn indexOf(self: Self, needle: []const u8) ?usize {
    return mem.indexOf(u8, self.bytes, needle);
}

/// containes ceonvenience method to check if `str` is a substring of this Zigstr.
pub fn contains(self: Self, str: []const u8) bool {
    return self.indexOf(str) != null;
}

test "Zigstr indexOf" {
    var str = try init(std.testing.allocator, "Hello");
    defer str.deinit();

    std.testing.expectEqual(str.indexOf("l"), 2);
    std.testing.expectEqual(str.indexOf("z"), null);
    std.testing.expect(str.contains("l"));
    std.testing.expect(!str.contains("z"));
}

/// lastIndexOf returns the index of `needle` in this Zigstr starting from the end, or null if not found.
pub fn lastIndexOf(self: Self, needle: []const u8) ?usize {
    return mem.lastIndexOf(u8, self.bytes, needle);
}

test "Zigstr lastIndexOf" {
    var str = try init(std.testing.allocator, "Hello");
    defer str.deinit();

    std.testing.expectEqual(str.lastIndexOf("l"), 3);
    std.testing.expectEqual(str.lastIndexOf("z"), null);
}

/// count returns the number of `needle`s in this Zigstr.
pub fn count(self: Self, needle: []const u8) usize {
    return mem.count(u8, self.bytes, needle);
}

test "Zigstr count" {
    var str = try init(std.testing.allocator, "Hello");
    defer str.deinit();

    std.testing.expectEqual(str.count("l"), 2);
    std.testing.expectEqual(str.count("ll"), 1);
    std.testing.expectEqual(str.count("z"), 0);
}

/// tokenIter returns an iterator on tokens resulting from splitting this Zigstr at every `delim`.
/// Semantics are that of `std.mem.tokenize`.
pub fn tokenIter(self: Self, delim: []const u8) mem.TokenIterator {
    return mem.tokenize(self.bytes, delim);
}

/// tokenize returns a slice of tokens resulting from splitting this Zigstr at every `delim`.
/// Caller must free returned slice.
pub fn tokenize(self: Self, delim: []const u8) ![][]const u8 {
    var ts = std.ArrayList([]const u8).init(self.allocator);
    defer ts.deinit();

    var iter = self.tokenIter(delim);
    while (iter.next()) |t| {
        try ts.append(t);
    }

    return ts.toOwnedSlice();
}

test "Zigstr tokenize" {
    var allocator = std.testing.allocator;
    var str = try init(allocator, " Hello World ");
    defer str.deinit();

    var iter = str.tokenIter(" ");
    std.testing.expectEqualStrings("Hello", iter.next().?);
    std.testing.expectEqualStrings("World", iter.next().?);
    std.testing.expect(iter.next() == null);

    var ts = try str.tokenize(" ");
    defer allocator.free(ts);
    std.testing.expectEqual(@as(usize, 2), ts.len);
    std.testing.expectEqualStrings("Hello", ts[0]);
    std.testing.expectEqualStrings("World", ts[1]);
}

/// splitIter returns an iterator on substrings resulting from splitting this Zigstr at every `delim`.
/// Semantics are that of `std.mem.split`.
pub fn splitIter(self: Self, delim: []const u8) mem.SplitIterator {
    return mem.split(self.bytes, delim);
}

/// split returns a slice of substrings resulting from splitting this Zigstr at every `delim`.
/// Caller must free returned slice.
pub fn split(self: Self, delim: []const u8) ![][]const u8 {
    var ss = std.ArrayList([]const u8).init(self.allocator);
    defer ss.deinit();

    var iter = self.splitIter(delim);
    while (iter.next()) |s| {
        try ss.append(s);
    }

    return ss.toOwnedSlice();
}

test "Zigstr split" {
    var allocator = std.testing.allocator;
    var str = try init(allocator, " Hello World ");
    defer str.deinit();

    var iter = str.splitIter(" ");
    std.testing.expectEqualStrings("", iter.next().?);
    std.testing.expectEqualStrings("Hello", iter.next().?);
    std.testing.expectEqualStrings("World", iter.next().?);
    std.testing.expectEqualStrings("", iter.next().?);
    std.testing.expect(iter.next() == null);

    var ss = try str.split(" ");
    defer allocator.free(ss);
    std.testing.expectEqual(@as(usize, 4), ss.len);
    std.testing.expectEqualStrings("", ss[0]);
    std.testing.expectEqualStrings("Hello", ss[1]);
    std.testing.expectEqualStrings("World", ss[2]);
    std.testing.expectEqualStrings("", ss[3]);
}

/// startsWith returns true if this Zigstr starts with `str`.
pub fn startsWith(self: Self, str: []const u8) bool {
    return mem.startsWith(u8, self.bytes, str);
}

test "Zigstr startsWith" {
    var allocator = std.testing.allocator;
    var str = try init(allocator, "Hello World ");
    defer str.deinit();

    std.testing.expect(str.startsWith("Hell"));
    std.testing.expect(!str.startsWith("Zig"));
}

/// endsWith returns true if this Zigstr ends with `str`.
pub fn endsWith(self: Self, str: []const u8) bool {
    return mem.endsWith(u8, self.bytes, str);
}

test "Zigstr endsWith" {
    var allocator = std.testing.allocator;
    var str = try init(allocator, "Hello World");
    defer str.deinit();

    std.testing.expect(str.endsWith("World"));
    std.testing.expect(!str.endsWith("Zig"));
}

/// Refer to the docs for `std.mem.join`.
pub const join = mem.join;

test "Zigstr join" {
    var allocator = std.testing.allocator;
    const result = try join(allocator, "/", &[_][]const u8{ "this", "is", "a", "path" });
    defer allocator.free(result);
    std.testing.expectEqualSlices(u8, "this/is/a/path", result);
}

/// concatAll appends each string in `others` to this Zigstr, mutating it.
pub fn concatAll(self: *Self, others: [][]const u8) !void {
    if (others.len == 0) return;

    const total_len = blk: {
        var sum: usize = 0;
        for (others) |slice| {
            sum += slice.len;
        }
        sum += self.bytes.len;
        break :blk sum;
    };

    const buf = try self.allocator.alloc(u8, total_len);
    mem.copy(u8, buf, self.bytes);

    var buf_index: usize = self.bytes.len;
    for (others) |slice| {
        mem.copy(u8, buf[buf_index..], slice);
        buf_index += slice.len;
    }

    // No need for shrink since buf is exactly the correct size.
    self.deinitContent();
    // Get new code point count and validate UTF-8.
    self.cp_count = try unicode.utf8CountCodepoints(buf);
    self.bytes = buf;
}

/// concat appends `other` to this Zigstr, mutating it.
pub fn concat(self: *Self, other: []const u8) !void {
    try self.concatAll(&[1][]const u8{other});
}

test "Zigstr concat" {
    var allocator = std.testing.allocator;
    var str = try init(allocator, "Hello");
    defer str.deinit();

    try str.concat(" World");
    std.testing.expectEqualStrings("Hello World", str.bytes);
    var others = [_][]const u8{ " is", " the", " tradition!" };
    try str.concatAll(&others);
    std.testing.expectEqualStrings("Hello World is the tradition!", str.bytes);
}

/// replace all occurrences of `needle` with `replacement`, mutating this Zigstr. Returns the total
/// replacements made.
pub fn replace(self: *Self, needle: []const u8, replacement: []const u8) !usize {
    const len = mem.replacementSize(u8, self.bytes, needle, replacement);
    var buf = try self.allocator.alloc(u8, len);
    const replacements = mem.replace(u8, self.bytes, needle, replacement, buf);
    if (replacement.len == 0) buf = self.allocator.shrink(buf, (len + 1) - needle.len * replacements);
    self.deinitContent();
    // Get new code point count and validate UTF-8.
    self.cp_count = try unicode.utf8CountCodepoints(buf);
    self.bytes = buf;

    return replacements;
}

test "Zigstr replace" {
    var allocator = std.testing.allocator;
    var str = try init(allocator, "Hello");
    defer str.deinit();

    var replacements = try str.replace("l", "z");
    std.testing.expectEqual(@as(usize, 2), replacements);
    std.testing.expect(str.eql("Hezzo"));

    replacements = try str.replace("z", "");
    std.testing.expectEqual(@as(usize, 2), replacements);
    std.testing.expect(str.eql("Heo"));
}

/// append adds `cp` to the end of this Zigstr, mutating it.
pub fn append(self: *Self, cp: u21) !void {
    var buf: [4]u8 = undefined;
    const len = try unicode.utf8Encode(cp, &buf);
    try self.concat(buf[0..len]);
}

/// append adds `cp` to the end of this Zigstr, mutating it.
pub fn appendAll(self: *Self, cp_list: []const u21) !void {
    var cp_bytes = std.ArrayList(u8).init(self.allocator);
    defer cp_bytes.deinit();

    for (cp_list) |cp| {
        var buf: [4]u8 = undefined;
        const len = try unicode.utf8Encode(cp, &buf);
        try cp_bytes.appendSlice(buf[0..len]);
    }

    try self.concat(cp_bytes.items);
}

test "Zigstr append" {
    var str = try init(std.testing.allocator, "Hell");
    defer str.deinit();

    try str.append('o');
    std.testing.expectEqual(@as(usize, 5), str.bytes.len);
    std.testing.expect(str.eql("Hello"));
    try str.appendAll(&[_]u21{ ' ', 'W', 'o', 'r', 'l', 'd' });
    std.testing.expectEqual(@as(usize, 11), str.bytes.len);
    std.testing.expect(str.eql("Hello World"));
}

/// empty returns true if this Zigstr has no bytes.
pub fn empty(self: Self) bool {
    return self.bytes.len == 0;
}

/// chomp will remove trailing \n or \r\n from this Zigstr, mutating it.
pub fn chomp(self: *Self) !void {
    if (self.empty()) return;

    const len = self.bytes.len;
    const last = self.bytes[len - 1];
    if (last == '\r' or last == '\n') {
        // CR
        var chomp_size: usize = 1;
        if (len > 1 and last == '\r' and self.bytes[len - 2] == '\n') chomp_size = 2; // CR+LF
        try self.reinit(self.bytes[0 .. len - chomp_size]);
    }
}

test "Zigstr chomp" {
    var str = try init(std.testing.allocator, "Hello\n");
    defer str.deinit();

    try str.chomp();
    std.testing.expectEqual(@as(usize, 5), str.bytes.len);
    std.testing.expect(str.eql("Hello"));

    try str.reinit("Hello\r");
    try str.chomp();
    std.testing.expectEqual(@as(usize, 5), str.bytes.len);
    std.testing.expect(str.eql("Hello"));

    try str.reinit("Hello\n\r");
    try str.chomp();
    std.testing.expectEqual(@as(usize, 5), str.bytes.len);
    std.testing.expect(str.eql("Hello"));
}
