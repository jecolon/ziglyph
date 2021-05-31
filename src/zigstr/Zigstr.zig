const std = @import("std");
const mem = std.mem;
const unicode = std.unicode;

const ascii = @import("../ascii.zig");
const Letter = @import("../ziglyph.zig").Letter;

const CodePointIterator = @import("CodePointIterator.zig");
const Grapheme = GraphemeIterator.Grapheme;
const GraphemeIterator = @import("GraphemeIterator.zig");
const WhiteSpace = @import("../components.zig").WhiteSpace;

const Self = @This();

allocator: *mem.Allocator,
ascii_only: bool,
bytes: std.ArrayList(u8),
code_points: ?[]const u21,
cp_count: usize,
grapheme_clusters: ?[]const Grapheme,
owned_cp: bool = true,

/// fromBytes returns a new Zigstr from the byte slice `str`, which will *not* be freed on `deinit`.
pub fn fromBytes(allocator: *mem.Allocator, str: []const u8) !Self {
    var self = Self{
        .allocator = allocator,
        .ascii_only = try isAsciiStr(str),
        .bytes = blk: {
            var al = try std.ArrayList(u8).initCapacity(allocator, str.len);
            al.appendSliceAssumeCapacity(str);
            break :blk al;
        },
        .code_points = null,
        .cp_count = 0,
        .grapheme_clusters = null,
    };

    try self.processCodePoints();

    return self;
}

/// fromOwnedBytes returns a new Zigstr from the owned byte slice `str`, which will be freed on `deinit`.
pub fn fromOwnedBytes(allocator: *mem.Allocator, str: []u8) !Self {
    var self = Self{
        .allocator = allocator,
        .ascii_only = try isAsciiStr(str),
        .bytes = std.ArrayList(u8).fromOwnedSlice(allocator, str),
        .code_points = null,
        .cp_count = 0,
        .grapheme_clusters = null,
    };

    try self.processCodePoints();

    return self;
}

/// fromCodePoints returns a new Zigstr from `code points`, which will *not* be freed on `deinit`.
pub fn fromCodePoints(allocator: *mem.Allocator, code_points: []const u21) !Self {
    return initCodePoints(allocator, code_points, false);
}

/// fromOwnedCodePoints returns a new Zigstr from the owned `code_points`, which will be freed on `deinit`.
pub fn fromOwnedCodePoints(allocator: *mem.Allocator, code_points: []u21) !Self {
    return initCodePoints(allocator, code_points, true);
}

/// initCodePoints creates a new Zigstr instance using the code points in `code_points`. `owned`
/// determines if `code_points` should be freed on `deinit`.
fn initCodePoints(allocator: *mem.Allocator, code_points: []const u21, owned: bool) !Self {
    const ascii_only = blk_ascii: {
        break :blk_ascii for (code_points) |cp| {
            if (cp > 127) break false;
        } else true;
    };

    if (ascii_only) {
        return Self{
            .allocator = allocator,
            .ascii_only = true,
            .bytes = blk_cp: {
                var al = try std.ArrayList(u8).initCapacity(allocator, code_points.len);
                for (code_points) |cp, i| {
                    al.appendAssumeCapacity(@intCast(u8, cp));
                }
                break :blk_cp al;
            },
            .code_points = code_points,
            .cp_count = code_points.len,
            .grapheme_clusters = blk_gc: {
                var buf = try allocator.alloc(Grapheme, code_points.len);
                for (code_points) |cp, i| {
                    buf[i] = .{ .bytes = &[_]u8{@intCast(u8, cp)}, .offset = i };
                }
                break :blk_gc buf;
            },
            .owned_cp = owned,
        };
    } else {
        return Self{
            .allocator = allocator,
            .ascii_only = false,
            .bytes = blk_b: {
                var al = std.ArrayList(u8).init(allocator);
                var cp_buf: [4]u8 = undefined;
                for (code_points) |cp| {
                    const len = try unicode.utf8Encode(cp, &cp_buf);
                    try al.appendSlice(cp_buf[0..len]);
                }
                break :blk_b al;
            },
            .code_points = code_points,
            .cp_count = code_points.len,
            .grapheme_clusters = null,
            .owned_cp = owned,
        };
    }
}

test "Zigstr from code points" {
    var allocator = std.testing.allocator;
    const cp_array = [_]u21{ 0x68, 0x65, 0x6C, 0x6C, 0x6F }; // "hello"

    var str = try fromCodePoints(allocator, &cp_array);
    defer str.deinit();

    try expectEqualStrings(str.bytes.items, "hello");
    try expectEqual(str.cp_count, 5);
    try expectEqual(str.ascii_only, true);

    str.deinit();
    var code_points = try allocator.alloc(u21, cp_array.len);
    for (cp_array) |cp, i| {
        code_points[i] = cp;
    }
    str = try fromOwnedCodePoints(std.testing.allocator, code_points);
    try expectEqualStrings(str.bytes.items, "hello");
    try expectEqual(str.cp_count, 5);
    try expectEqual(str.ascii_only, true);
}

/// fromJoined returns a new Zigstr from the concatenation of strings in `slice` with `sep` separator.
pub fn fromJoined(allocator: *mem.Allocator, slice: []const []const u8, sep: []const u8) !Self {
    return fromOwnedBytes(allocator, try mem.join(allocator, sep, slice));
}

test "Zigstr fromJoined" {
    var str = try fromJoined(std.testing.allocator, &[_][]const u8{ "Hello", "World" }, " ");
    defer str.deinit();

    try expect(str.eql("Hello World"));
}

pub fn deinit(self: *Self) void {
    self.bytes.deinit();
    if (self.owned_cp) {
        if (self.code_points) |code_points| self.allocator.free(code_points);
        self.code_points = null;
    } else {
        if (self.code_points) |code_points| self.code_points = null;
        self.owned_cp = true;
    }
    if (self.grapheme_clusters) |gcs| {
        self.allocator.free(gcs);
        self.grapheme_clusters = null;
    }
}

/// toOwnedSlice returns the bytes of this Zigstr to be freed by caller. This Zigstr is reset to empty.
pub fn toOwnedSlice(self: *Self) ![]u8 {
    self.resetState();
    self.ascii_only = false;
    return self.bytes.toOwnedSlice();
}

test "Zigstr toOwnedSlice" {
    var allocator = std.testing.allocator;
    var str = try fromBytes(allocator, "Hello");
    defer str.deinit();

    try expect(str.eql("Hello"));
    const bytes = try str.toOwnedSlice();
    defer allocator.free(bytes);
    try expectEqualStrings(bytes, "Hello");
    try expect(str.eql(""));
}

fn resetState(self: *Self) void {
    // Free and reset old content.
    if (self.owned_cp) {
        if (self.code_points) |code_points| {
            self.allocator.free(code_points);
            self.code_points = null;
        }
    } else {
        if (self.code_points) |code_points| self.code_points = null;
        self.owned_cp = true;
    }

    self.cp_count = 0;

    if (self.grapheme_clusters) |gcs| {
        self.allocator.free(gcs);
        self.grapheme_clusters = null;
    }
}

/// reset reinitializes this Zigstr from the byte slice `str`.
pub fn reset(self: *Self, str: []const u8) !void {
    try self.bytes.replaceRange(0, self.bytes.items.len, str);
    try self.updateState();
}

fn updateState(self: *Self) !void {
    self.resetState();
    self.ascii_only = try isAsciiStr(self.bytes.items);
    try self.processCodePoints();
}

/// byteCount returns the number of bytes, which can be different from the number of code points and the 
/// number of graphemes.
pub fn byteCount(self: Self) usize {
    return self.bytes.items.len;
}

/// codePointIter returns a code point iterator based on the bytes of this Zigstr.
pub fn codePointIter(self: Self) !CodePointIterator {
    return CodePointIterator.init(self.bytes.items);
}

/// codePoints returns the code points that make up this Zigstr.
pub fn codePoints(self: *Self) ![]const u21 {
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
    self.owned_cp = true;

    return self.code_points.?;
}

/// codePointCount returns the number of code points, which can be different from the number of bytes
/// and the number of graphemes.
pub fn codePointCount(self: *Self) usize {
    return self.cp_count;
}

/// graphemeIter returns a grapheme cluster iterator based on the bytes of this Zigstr. Each grapheme
/// can be composed of multiple code points, so the next method returns a slice of bytes.
pub fn graphemeIter(self: *Self) anyerror!GraphemeIterator {
    return if (self.ascii_only) GraphemeIterator.newAscii(self.bytes.items) else GraphemeIterator.new(self.bytes.items);
}

/// graphemes returns the grapheme clusters that make up this Zigstr.
pub fn graphemes(self: *Self) ![]const Grapheme {
    // Check for cached code points.
    if (self.grapheme_clusters) |gcs| return gcs;

    // Cache miss, generate.
    var giter = try self.graphemeIter();
    var gcs = std.ArrayList(Grapheme).init(self.allocator);
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

/// copy a Zigstr to a new Zigstr. Don't forget to to `deinit` the returned Zigstr!
pub fn copy(self: Self) !Self {
    var other = Self{
        .allocator = self.allocator,
        .ascii_only = self.ascii_only,
        .bytes = b_blk: {
            var al = try std.ArrayList(u8).initCapacity(self.allocator, self.bytes.items.len);
            al.appendSliceAssumeCapacity(self.bytes.items);
            break :b_blk al;
        },
        .code_points = cp_blk: {
            if (self.code_points) |code_points| {
                var cps = try self.allocator.alloc(u21, code_points.len);
                mem.copy(u21, cps, code_points);
                break :cp_blk cps;
            } else {
                break :cp_blk null;
            }
        },
        .cp_count = self.cp_count,
        .grapheme_clusters = gc_blk: {
            if (self.grapheme_clusters) |grapheme_clusters| {
                var gcs = try self.allocator.alloc(Grapheme, grapheme_clusters.len);
                mem.copy(Grapheme, gcs, grapheme_clusters);
                break :gc_blk gcs;
            } else {
                break :gc_blk null;
            }
        },
    };

    try other.processCodePoints();

    return other;
}

/// sameAs convenience method to test exact byte equality of two Zigstrs.
pub fn sameAs(self: Self, other: Self) bool {
    return self.eql(other.bytes.items);
}

/// eql compares for exact byte per byte equality with `other`.
pub fn eql(self: Self, other: []const u8) bool {
    return mem.eql(u8, self.bytes.items, other);
}

/// isAsciiStr checks if a string (`[]const uu`) is composed solely of ASCII characters.
pub fn isAsciiStr(str: []const u8) !bool {
    // Shamelessly stolen from std.unicode.
    const N = @sizeOf(usize);
    const MASK = 0x80 * (std.math.maxInt(usize) / 0xff);

    var i: usize = 0;
    while (i < str.len) {
        // Fast path for ASCII sequences
        while (i + N <= str.len) : (i += N) {
            const v = mem.readIntNative(usize, str[i..][0..N]);
            if (v & MASK != 0) {
                return false;
            }
        }

        if (i < str.len) {
            const n = try unicode.utf8ByteSequenceLength(str[i]);
            if (i + n > str.len) return error.TruncatedInput;

            switch (n) {
                1 => {}, // ASCII
                else => return false,
            }

            i += n;
        }
    }

    return true;
}

/// trimLeft removes `str` from the left of this Zigstr, mutating it.
pub fn trimLeft(self: *Self, str: []const u8) !void {
    const trimmed = mem.trimLeft(u8, self.bytes.items, str);
    try self.bytes.replaceRange(0, self.bytes.items.len, trimmed);
    self.resetState();
    try self.processCodePoints();
}

/// trimRight removes `str` from the right of this Zigstr, mutating it.
pub fn trimRight(self: *Self, str: []const u8) !void {
    const trimmed = mem.trimRight(u8, self.bytes.items, str);
    try self.bytes.replaceRange(0, self.bytes.items.len, trimmed);
    self.resetState();
    try self.processCodePoints();
}

/// trim removes `str` from both the left and right of this Zigstr, mutating it.
pub fn trim(self: *Self, str: []const u8) !void {
    const trimmed = mem.trim(u8, self.bytes.items, str);
    try self.bytes.replaceRange(0, self.bytes.items.len, trimmed);
    self.resetState();
    try self.processCodePoints();
}

/// dropLeft removes `n` graphemes from the left of this Zigstr, mutating it.
pub fn dropLeft(self: *Self, n: usize) !void {
    const gcs = try self.graphemes();
    if (n >= gcs.len) return error.IndexOutOfBounds;

    const offset = gcs[n].offset;

    mem.rotate(u8, self.bytes.items, offset);
    self.bytes.shrinkRetainingCapacity(self.bytes.items.len - offset);
    self.resetState();
    try self.processCodePoints();
}

test "Zigstr dropLeft" {
    var str = try fromBytes(std.testing.allocator, "Héllo");
    defer str.deinit();

    try str.dropLeft(4);
    try expect(str.eql("o"));
}

/// dropRight removes `n` graphemes from the right of this Zigstr, mutating it.
pub fn dropRight(self: *Self, n: usize) !void {
    const gcs = try self.graphemes();
    if (n > gcs.len) return error.IndexOutOfBounds;
    if (n == gcs.len) try self.reset("");

    const offset = gcs[gcs.len - n].offset;
    self.bytes.shrinkRetainingCapacity(offset);
    self.resetState();
    try self.processCodePoints();
}

test "Zigstr dropRight" {
    var str = try fromBytes(std.testing.allocator, "Héllo");
    defer str.deinit();

    try str.dropRight(4);
    try expect(str.eql("H"));
}

/// inserts `str` at grapheme index `n`. This operation is O(n).
pub fn insert(self: *Self, str: []const u8, n: usize) !void {
    const gcs = try self.graphemes();
    if (n < gcs.len) {
        try self.bytes.insertSlice(gcs[n].offset, str);
    } else {
        try self.bytes.insertSlice(gcs[n - 1].offset + gcs[n - 1].bytes.len, str);
    }
    try self.updateState();
}

test "Zigstr insertions" {
    var str = try fromBytes(std.testing.allocator, "Hélo");
    defer str.deinit();

    try str.insert("l", 3);
    try expect(str.eql("Héllo"));
    try str.insert("Hey ", 0);
    try expect(str.eql("Hey Héllo"));
    try str.insert("!", try str.graphemeCount());
    try expect(str.eql("Hey Héllo!"));
}

/// indexOf returns the index of `needle` in this Zigstr or null if not found.
pub fn indexOf(self: Self, needle: []const u8) ?usize {
    return mem.indexOf(u8, self.bytes.items, needle);
}

/// containes ceonvenience method to check if `str` is a substring of this Zigstr.
pub fn contains(self: Self, str: []const u8) bool {
    return self.indexOf(str) != null;
}

/// lastIndexOf returns the index of `needle` in this Zigstr starting from the end, or null if not found.
pub fn lastIndexOf(self: Self, needle: []const u8) ?usize {
    return mem.lastIndexOf(u8, self.bytes.items, needle);
}

/// count returns the number of `needle`s in this Zigstr.
pub fn count(self: Self, needle: []const u8) usize {
    return mem.count(u8, self.bytes.items, needle);
}

/// tokenIter returns an iterator on tokens resulting from splitting this Zigstr at every `delim`.
/// Semantics are that of `std.mem.tokenize`.
pub fn tokenIter(self: Self, delim: []const u8) mem.TokenIterator {
    return mem.tokenize(self.bytes.items, delim);
}

/// tokenize returns a slice of tokens resulting from splitting this Zigstr at every `delim`.
pub fn tokenize(self: Self, delim: []const u8) ![][]const u8 {
    var ts = std.ArrayList([]const u8).init(self.allocator);
    defer ts.deinit();

    var iter = self.tokenIter(delim);
    while (iter.next()) |t| {
        try ts.append(t);
    }

    return ts.toOwnedSlice();
}

/// splitIter returns an iterator on substrings resulting from splitting this Zigstr at every `delim`.
/// Semantics are that of `std.mem.split`.
pub fn splitIter(self: Self, delim: []const u8) mem.SplitIterator {
    return mem.split(self.bytes.items, delim);
}

/// split returns a slice of substrings resulting from splitting this Zigstr at every `delim`.
pub fn split(self: Self, delim: []const u8) ![][]const u8 {
    var ss = std.ArrayList([]const u8).init(self.allocator);
    defer ss.deinit();

    var iter = mem.split(self.bytes.items, delim);
    while (iter.next()) |s| {
        try ss.append(s);
    }

    return ss.toOwnedSlice();
}

/// lineIter returns an iterator of lines separated by \n in this Zigstr.
pub fn lineIter(self: Self) mem.SplitIterator {
    return self.splitIter("\n");
}

/// lines returns a slice of substrings resulting from splitting this Zigstr at every \n.
pub fn lines(self: Self) ![][]const u8 {
    return self.split("\n");
}

test "Zigstr lines" {
    var allocator = std.testing.allocator;
    var str = try fromBytes(allocator, "Hello\nWorld");
    defer str.deinit();

    var iter = str.lineIter();
    try expectEqualStrings(iter.next().?, "Hello");
    try expectEqualStrings(iter.next().?, "World");

    var lines_array = try str.lines();
    defer allocator.free(lines_array);
    try expectEqualStrings(lines_array[0], "Hello");
    try expectEqualStrings(lines_array[1], "World");
}

/// reverses the grapheme clusters in this Zigstr, mutating it.
pub fn reverse(self: *Self) !void {
    var gcs = try self.graphemes();
    var new_al = try std.ArrayList(u8).initCapacity(self.allocator, self.bytes.items.len);
    var gc_index: isize = @intCast(isize, gcs.len) - 1;

    while (gc_index >= 0) : (gc_index -= 1) {
        new_al.appendSliceAssumeCapacity(gcs[@intCast(usize, gc_index)].bytes);
    }

    self.bytes.deinit();
    self.bytes = new_al;
    try self.updateState();
}

test "Zigstr reverse" {
    var str = try fromBytes(std.testing.allocator, "Héllo 😊");
    defer str.deinit();

    try str.reverse();
    try expectEqualStrings(str.bytes.items, "😊 olléH");
}

/// startsWith returns true if this Zigstr starts with `str`.
pub fn startsWith(self: Self, str: []const u8) bool {
    return mem.startsWith(u8, self.bytes.items, str);
}

/// endsWith returns true if this Zigstr ends with `str`.
pub fn endsWith(self: Self, str: []const u8) bool {
    return mem.endsWith(u8, self.bytes.items, str);
}

/// concatAll appends each string in `others` to this Zigstr, mutating it.
pub fn concatAll(self: *Self, others: []const []const u8) !void {
    for (others) |o| {
        try self.bytes.appendSlice(o);
    }
    try self.updateState();
}

/// concat appends `other` to this Zigstr, mutating it.
pub fn concat(self: *Self, other: []const u8) !void {
    try self.concatAll(&[1][]const u8{other});
}

/// replace all occurrences of `needle` with `replacement`, mutating this Zigstr. Returns the total
/// replacements made.
pub fn replace(self: *Self, needle: []const u8, replacement: []const u8) !usize {
    const len = mem.replacementSize(u8, self.bytes.items, needle, replacement);
    var buf = try self.allocator.alloc(u8, len);
    defer self.allocator.free(buf);
    const replacements = mem.replace(u8, self.bytes.items, needle, replacement, buf);
    try self.bytes.replaceRange(0, self.bytes.items.len, buf);
    try self.updateState();

    return replacements;
}

/// remove `str` from this Zigstr, mutating it.
pub fn remove(self: *Self, str: []const u8) !void {
    _ = try self.replace(str, "");
    try self.updateState();
}

test "Zigstr remove" {
    var str = try fromBytes(std.testing.allocator, "HiHello");
    defer str.deinit();

    try str.remove("Hi");
    try expect(str.eql("Hello"));
    try str.remove("Hello");
    try expect(str.eql(""));
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

    var buf: [4]u8 = undefined;
    for (cp_list) |cp| {
        const len = try unicode.utf8Encode(cp, &buf);
        try cp_bytes.appendSlice(buf[0..len]);
    }

    try self.concat(cp_bytes.items);
}

/// isEmpty returns true if this Zigstr has no bytes.
pub fn isEmpty(self: Self) bool {
    return self.bytes.items.len == 0;
}

/// isBlank returns true if this Zigstr consits of whitespace only .
pub fn isBlank(self: *Self) !bool {
    return for (try self.codePoints()) |cp| {
        if (!WhiteSpace.isWhiteSpace(cp)) break false;
    } else true;
}

test "Zigstr isBlank" {
    var str = try fromBytes(std.testing.allocator, " \t   ");
    defer str.deinit();

    try expect(try str.isBlank());
    try str.reset(" a b \t");
    try expect(!try str.isBlank());
}

/// chomp will remove trailing \n or \r\n from this Zigstr, mutating it.
pub fn chomp(self: *Self) !void {
    if (self.isEmpty()) return;

    const len = self.bytes.items.len;
    const last = self.bytes.items[len - 1];
    if (last == '\r' or last == '\n') {
        // CR
        var chomp_size: usize = 1;
        if (len > 1 and last == '\n' and self.bytes.items[self.bytes.items.len - 2] == '\r') chomp_size = 2; // CR+LF
        self.bytes.shrinkRetainingCapacity(len - chomp_size);
        try self.updateState();
    }
}

/// byteAt returns the byte at index `i`.
pub fn byteAt(self: Self, i: isize) !u8 {
    if (i >= self.bytes.items.len) return error.IndexOutOfBounds;
    if (i < 0) {
        if (-%i > self.bytes.items.len) return error.IndexOutOfBounds;
        return self.bytes.items[self.bytes.items.len - @intCast(usize, -i)];
    }

    return self.bytes.items[@intCast(usize, i)];
}

/// codePointAt returns the `i`th code point.
pub fn codePointAt(self: *Self, i: isize) !u21 {
    if (i >= self.cp_count) return error.IndexOutOfBounds;
    if (i < 0) {
        if (-%i > self.cp_count) return error.IndexOutOfBounds;
        return (try self.codePoints())[self.cp_count - @intCast(usize, -i)];
    }

    return (try self.codePoints())[@intCast(usize, i)];
}

/// graphemeAt returns the `i`th grapheme cluster.
pub fn graphemeAt(self: *Self, i: isize) !Grapheme {
    const gcs = try self.graphemes();
    if (i >= gcs.len) return error.IndexOutOfBounds;
    if (i < 0) {
        if (-%i > gcs.len) return error.IndexOutOfBounds;
        return gcs[gcs.len - @intCast(usize, -i)];
    }

    return gcs[@intCast(usize, i)];
}

/// byteSlice returnes the bytes from this Zigstr in the specified range from `start` to `end` - 1.
pub fn byteSlice(self: Self, start: usize, end: usize) ![]const u8 {
    if (start >= self.bytes.items.len or end > self.bytes.items.len) return error.IndexOutOfBounds;
    return self.bytes.items[start..end];
}

/// codePointSlice returnes the code points from this Zigstr in the specified range from `start` to `end` - 1.
pub fn codePointSlice(self: *Self, start: usize, end: usize) ![]const u21 {
    if (start >= self.cp_count or end > self.cp_count) return error.IndexOutOfBounds;
    return (try self.codePoints())[start..end];
}

/// graphemeSlice returnes the grapheme clusters from this Zigstr in the specified range from `start` to `end` - 1.
pub fn graphemeSlice(self: *Self, start: usize, end: usize) ![]const Grapheme {
    const gcs = try self.graphemes();
    if (start >= gcs.len or end > gcs.len) return error.IndexOutOfBounds;
    return gcs[start..end];
}

/// substr returns a byte slice representing the grapheme range starting at `start` grapheme index
/// up to `end` grapheme index - 1.
pub fn substr(self: *Self, start: usize, end: usize) ![]const u8 {
    if (self.ascii_only) {
        if (start >= self.bytes.items.len or end > self.bytes.items.len) return error.IndexOutOfBounds;
        return self.bytes.items[start..end];
    }

    const gcs = try self.graphemes();
    if (start >= gcs.len or end > gcs.len) return error.IndexOutOfBounds;
    return self.bytes.items[gcs[start].offset..gcs[end].offset];
}

/// processCodePoints performs some house-keeping and accounting on the code points that make up this
/// Zigstr.  Asserts that our bytes are valid UTF-8.
pub fn processCodePoints(self: *Self) !void {
    if (self.ascii_only) {
        // UTF-8 ASCII code points are just bytes.
        if (self.code_points == null) {
            var code_points = try self.allocator.alloc(u21, self.bytes.items.len);
            for (self.bytes.items) |b, i| {
                code_points[i] = b;
            }
            self.cp_count = code_points.len;
            self.code_points = code_points;
            self.owned_cp = true;
        }

        // UTF-8 ASCII grapheme clusters are just bytes.
        if (self.grapheme_clusters == null) {
            var grapheme_clusters = try self.allocator.alloc(Grapheme, self.bytes.items.len);
            for (self.bytes.items) |b, i| {
                grapheme_clusters[i] = .{ .bytes = &[_]u8{b}, .offset = i };
            }
            self.grapheme_clusters = grapheme_clusters;
        }

        return;
    }

    // Shamelessly stolen from std.unicode.
    var ascii_only = true;
    var len: usize = 0;

    const N = @sizeOf(usize);
    const MASK = 0x80 * (std.math.maxInt(usize) / 0xff);

    var i: usize = 0;
    while (i < self.bytes.items.len) {
        // Fast path for ASCII sequences
        while (i + N <= self.bytes.items.len) : (i += N) {
            const v = mem.readIntNative(usize, self.bytes.items[i..][0..N]);
            if (v & MASK != 0) {
                ascii_only = false;
                break;
            }
            len += N;
        }

        if (i < self.bytes.items.len) {
            const n = try unicode.utf8ByteSequenceLength(self.bytes.items[i]);
            if (i + n > self.bytes.items.len) return error.TruncatedInput;

            switch (n) {
                1 => {}, // ASCII, no validation needed
                else => {
                    _ = try unicode.utf8Decode(self.bytes.items[i .. i + n]);
                    ascii_only = false;
                },
            }

            i += n;
            len += 1;
        }
    }

    self.ascii_only = ascii_only;
    self.cp_count = len;
}

/// isLower detects if all the code points in this Zigstr are lowercase.
pub fn isLower(self: *Self) !bool {
    for (try self.codePoints()) |cp| {
        if (!Letter.isLower(cp)) return false;
    }

    return true;
}

/// toLower converts this Zigstr to lowercase, mutating it.
pub fn toLower(self: *Self) !void {
    var new_al = try std.ArrayList(u8).initCapacity(self.allocator, self.bytes.items.len);

    var buf: [4]u8 = undefined;
    for (try self.codePoints()) |cp| {
        const lcp = Letter.toLower(cp);
        const len = try unicode.utf8Encode(lcp, &buf);
        new_al.appendSliceAssumeCapacity(buf[0..len]);
    }

    self.bytes.deinit();
    self.bytes = new_al;
    try self.updateState();
}

/// isUpper detects if all the code points in this Zigstr are uppercase.
pub fn isUpper(self: *Self) !bool {
    for (try self.codePoints()) |cp| {
        if (!Letter.isUpper(cp)) return false;
    }

    return true;
}

/// toUpper converts this Zigstr to uppercase, mutating it.
pub fn toUpper(self: *Self) !void {
    var new_al = try std.ArrayList(u8).initCapacity(self.allocator, self.bytes.items.len);

    var buf: [4]u8 = undefined;
    for (try self.codePoints()) |cp| {
        const ucp = Letter.toUpper(cp);
        const len = try unicode.utf8Encode(ucp, &buf);
        new_al.appendSliceAssumeCapacity(buf[0..len]);
    }

    self.bytes.deinit();
    self.bytes = new_al;
    try self.updateState();
}

/// format implements the `std.fmt` format interface for printing types.
pub fn format(self: Self, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
    _ = try writer.print("{s}", .{self.bytes.items});
}

/// parseInt tries to parse this Zigstr as an integer of type `T` in base `radix`.
pub fn parseInt(self: Self, comptime T: type, radix: u8) !T {
    return std.fmt.parseInt(T, self.bytes.items, radix);
}

/// parseFloat tries to parse this Zigstr as an floating point number of type `T`.
pub fn parseFloat(self: Self, comptime T: type) !T {
    return std.fmt.parseFloat(T, self.bytes.items);
}

test "Zigstr parse numbers" {
    var str = try fromBytes(std.testing.allocator, "2112");
    defer str.deinit();

    try expectEqual(@as(u16, 2112), try str.parseInt(u16, 10));
    try expectEqual(@as(i16, 2112), try str.parseInt(i16, 10));
    try expectEqual(@as(f16, 2112.0), try str.parseFloat(f16));
}

/// repeats the contents of this Zigstr `n` times, mutating it.
pub fn repeat(self: *Self, n: usize) !void {
    if (n == 1) return;

    var new_al = try std.ArrayList(u8).initCapacity(self.allocator, self.bytes.items.len * n);

    var i: usize = 0;
    while (i < n) : (i += 1) {
        new_al.appendSliceAssumeCapacity(self.bytes.items);
    }

    self.bytes.deinit();
    self.bytes = new_al;
    try self.updateState();
}

test "Zigstr repeat" {
    var str = try fromBytes(std.testing.allocator, "*");
    defer str.deinit();

    try str.repeat(10);
    try expectEqualStrings(str.bytes.items, "**********");
    try str.repeat(1);
    try expectEqualStrings(str.bytes.items, "**********");
    try str.repeat(0);
    try expectEqualStrings(str.bytes.items, "");
}

/// parseBool parses this Zigstr as either true or false.
pub fn parseBool(self: Self) !bool {
    if (mem.eql(u8, self.bytes.items, "true")) return true;
    if (mem.eql(u8, self.bytes.items, "false")) return false;

    return error.ParseBoolError;
}

/// parseTruthy parses this Zigstr as a *truthy* value:
/// * True and T in any case combination are true.
/// * False and F in any case combination are false.
/// * 0 is false, 1 is true.
/// * Yes, Y, and On in any case combination are true.
/// * No, N, and Off in any case combination are false.
pub fn parseTruthy(self: Self) !bool {
    var lstr = try fromBytes(self.allocator, self.bytes.items);
    defer lstr.deinit();

    try lstr.toLower();
    // True
    if (mem.eql(u8, lstr.bytes.items, "true")) return true;
    if (mem.eql(u8, lstr.bytes.items, "t")) return true;
    if (mem.eql(u8, lstr.bytes.items, "on")) return true;
    if (mem.eql(u8, lstr.bytes.items, "yes")) return true;
    if (mem.eql(u8, lstr.bytes.items, "y")) return true;
    if (mem.eql(u8, lstr.bytes.items, "1")) return true;
    // False
    if (mem.eql(u8, lstr.bytes.items, "false")) return false;
    if (mem.eql(u8, lstr.bytes.items, "f")) return false;
    if (mem.eql(u8, lstr.bytes.items, "off")) return false;
    if (mem.eql(u8, lstr.bytes.items, "no")) return false;
    if (mem.eql(u8, lstr.bytes.items, "n")) return false;
    if (mem.eql(u8, lstr.bytes.items, "0")) return false;

    return error.ParseTruthyError;
}

test "Zigstr parse bool truthy" {
    var str = try fromBytes(std.testing.allocator, "true");
    defer str.deinit();

    try expect(try str.parseBool());
    try expect(try str.parseTruthy());
    try str.reset("false");
    try expect(!try str.parseBool());
    try expect(!try str.parseTruthy());

    try str.reset("true");
    try expect(try str.parseTruthy());
    try str.reset("t");
    try expect(try str.parseTruthy());
    try str.reset("on");
    try expect(try str.parseTruthy());
    try str.reset("yes");
    try expect(try str.parseTruthy());
    try str.reset("y");
    try expect(try str.parseTruthy());
    try str.reset("1");
    try expect(try str.parseTruthy());
    try str.reset("TrUe");
    try expect(try str.parseTruthy());

    try str.reset("false");
    try expect(!try str.parseTruthy());
    try str.reset("f");
    try expect(!try str.parseTruthy());
    try str.reset("off");
    try expect(!try str.parseTruthy());
    try str.reset("no");
    try expect(!try str.parseTruthy());
    try str.reset("n");
    try expect(!try str.parseTruthy());
    try str.reset("0");
    try expect(!try str.parseTruthy());
    try str.reset("FaLsE");
    try expect(!try str.parseTruthy());
}

const expect = std.testing.expect;
const expectEqual = std.testing.expectEqual;
const expectEqualSlices = std.testing.expectEqualSlices;
const expectEqualStrings = std.testing.expectEqualStrings;
const expectError = std.testing.expectError;

test "Zigstr code points" {
    var str = try fromBytes(std.testing.allocator, "Héllo");
    defer str.deinit();

    var cp_iter = try str.codePointIter();
    var want = [_]u21{ 'H', 0x00E9, 'l', 'l', 'o' };
    var i: usize = 0;
    while (cp_iter.next()) |cp| : (i += 1) {
        try expectEqual(want[i], cp);
    }

    try expectEqual(@as(usize, 5), str.codePointCount());
    try expectEqualSlices(u21, &want, try str.codePoints());
    try expectEqual(@as(usize, 6), str.byteCount());
    try expectEqual(@as(usize, 5), str.codePointCount());
}

test "Zigstr graphemes" {
    var str = try fromBytes(std.testing.allocator, "Héllo");
    defer str.deinit();

    var giter = try str.graphemeIter();
    var want = [_][]const u8{ "H", "é", "l", "l", "o" };
    var i: usize = 0;
    while (giter.next()) |gc| : (i += 1) {
        try expect(gc.eql(want[i]));
    }

    try expectEqual(@as(usize, 5), try str.graphemeCount());
    const gcs = try str.graphemes();
    for (gcs) |gc, j| {
        try expect(gc.eql(want[j]));
    }

    try expectEqual(@as(usize, 6), str.byteCount());
    try expectEqual(@as(usize, 5), try str.graphemeCount());
}

test "Zigstr copy" {
    var str1 = try fromBytes(std.testing.allocator, "Zig");
    defer str1.deinit();

    var str2 = try str1.copy();
    defer str2.deinit();

    try expect(str1.eql(str2.bytes.items));
    try expect(str2.eql("Zig"));
    try expect(str1.sameAs(str2));
}

test "Zigstr isAsciiStr" {
    try expect(try isAsciiStr("Hello!"));
    try expect(!try isAsciiStr("Héllo!"));
}

test "Zigstr trimLeft" {
    var str = try fromBytes(std.testing.allocator, "    Hello");
    defer str.deinit();

    try str.trimLeft(" ");
    try expect(str.eql("Hello"));
}

test "Zigstr trimRight" {
    var str = try fromBytes(std.testing.allocator, "Hello    ");
    defer str.deinit();

    try str.trimRight(" ");
    try expect(str.eql("Hello"));
}

test "Zigstr trim" {
    var str = try fromBytes(std.testing.allocator, "   Hello   ");
    defer str.deinit();

    try str.trim(" ");
    try expect(str.eql("Hello"));
}

test "Zigstr indexOf" {
    var str = try fromBytes(std.testing.allocator, "Hello");
    defer str.deinit();

    try expectEqual(str.indexOf("l"), 2);
    try expectEqual(str.indexOf("z"), null);
    try expect(str.contains("l"));
    try expect(!str.contains("z"));
}

test "Zigstr lastIndexOf" {
    var str = try fromBytes(std.testing.allocator, "Hello");
    defer str.deinit();

    try expectEqual(str.lastIndexOf("l"), 3);
    try expectEqual(str.lastIndexOf("z"), null);
}

test "Zigstr count" {
    var str = try fromBytes(std.testing.allocator, "Hello");
    defer str.deinit();

    try expectEqual(str.count("l"), 2);
    try expectEqual(str.count("ll"), 1);
    try expectEqual(str.count("z"), 0);
}

test "Zigstr tokenize" {
    var allocator = std.testing.allocator;
    var str = try fromBytes(allocator, " Hello World ");
    defer str.deinit();

    var iter = str.tokenIter(" ");
    try expectEqualStrings("Hello", iter.next().?);
    try expectEqualStrings("World", iter.next().?);
    try expect(iter.next() == null);

    var ts = try str.tokenize(" ");
    defer allocator.free(ts);
    try expectEqual(@as(usize, 2), ts.len);
    try expectEqualStrings("Hello", ts[0]);
    try expectEqualStrings("World", ts[1]);
}

test "Zigstr split" {
    var allocator = std.testing.allocator;
    var str = try fromBytes(allocator, " Hello World ");
    defer str.deinit();

    var iter = str.splitIter(" ");
    try expectEqualStrings("", iter.next().?);
    try expectEqualStrings("Hello", iter.next().?);
    try expectEqualStrings("World", iter.next().?);
    try expectEqualStrings("", iter.next().?);
    try expect(iter.next() == null);

    var ss = try str.split(" ");
    defer allocator.free(ss);
    try expectEqual(@as(usize, 4), ss.len);
    try expectEqualStrings("", ss[0]);
    try expectEqualStrings("Hello", ss[1]);
    try expectEqualStrings("World", ss[2]);
    try expectEqualStrings("", ss[3]);
}

test "Zigstr startsWith" {
    var str = try fromBytes(std.testing.allocator, "Hello World");
    defer str.deinit();

    try expect(str.startsWith("Hell"));
    try expect(!str.startsWith("Zig"));
}

test "Zigstr endsWith" {
    var str = try fromBytes(std.testing.allocator, "Hello World");
    defer str.deinit();

    try expect(str.endsWith("World"));
    try expect(!str.endsWith("Zig"));
}

test "Zigstr concat" {
    var str = try fromBytes(std.testing.allocator, "Hello");
    defer str.deinit();

    try str.concat(" World");
    try expectEqualStrings("Hello World", str.bytes.items);
    var others = [_][]const u8{ " is", " the", " tradition!" };
    try str.concatAll(&others);
    try expectEqualStrings("Hello World is the tradition!", str.bytes.items);
}

test "Zigstr replace" {
    var str = try fromBytes(std.testing.allocator, "Hello");
    defer str.deinit();

    var replacements = try str.replace("l", "z");
    try expectEqual(@as(usize, 2), replacements);
    try expect(str.eql("Hezzo"));

    replacements = try str.replace("z", "");
    try expectEqual(@as(usize, 2), replacements);
    try expect(str.eql("Heo"));
}

test "Zigstr append" {
    var str = try fromBytes(std.testing.allocator, "Hell");
    defer str.deinit();

    try str.append('o');
    try expectEqual(@as(usize, 5), str.bytes.items.len);
    try expect(str.eql("Hello"));
    try str.appendAll(&[_]u21{ ' ', 'W', 'o', 'r', 'l', 'd' });
    try expectEqual(@as(usize, 11), str.bytes.items.len);
    try expect(str.eql("Hello World"));
}

test "Zigstr chomp" {
    var str = try fromBytes(std.testing.allocator, "Hello\n");
    defer str.deinit();

    try str.chomp();
    try expectEqual(@as(usize, 5), str.bytes.items.len);
    try expect(str.eql("Hello"));

    try str.reset("Hello\r");
    try str.chomp();
    try expectEqual(@as(usize, 5), str.bytes.items.len);
    try expect(str.eql("Hello"));

    try str.reset("Hello\r\n");
    try str.chomp();
    try expectEqual(@as(usize, 5), str.bytes.items.len);
    try expect(str.eql("Hello"));
}

test "Zigstr xAt" {
    var str = try fromBytes(std.testing.allocator, "H\u{0065}\u{0301}llo");
    defer str.deinit();

    try expectEqual(try str.byteAt(2), 0x00CC);
    try expectEqual(try str.byteAt(-5), 0x00CC);
    try expectError(error.IndexOutOfBounds, str.byteAt(7));
    try expectError(error.IndexOutOfBounds, str.byteAt(-8));
    try expectEqual(try str.codePointAt(1), 0x0065);
    try expectEqual(try str.codePointAt(-5), 0x0065);
    try expectError(error.IndexOutOfBounds, str.codePointAt(6));
    try expectError(error.IndexOutOfBounds, str.codePointAt(-7));
    try expect((try str.graphemeAt(1)).eql("\u{0065}\u{0301}"));
    try expect((try str.graphemeAt(-4)).eql("\u{0065}\u{0301}"));
    try expectError(error.IndexOutOfBounds, str.graphemeAt(5));
    try expectError(error.IndexOutOfBounds, str.graphemeAt(-6));
}

test "Zigstr extractions" {
    var str = try fromBytes(std.testing.allocator, "H\u{0065}\u{0301}llo");
    defer str.deinit();

    // Slices
    try expectEqualSlices(u8, try str.byteSlice(1, 4), "\u{0065}\u{0301}");
    try expectEqualSlices(u21, try str.codePointSlice(1, 3), &[_]u21{ '\u{0065}', '\u{0301}' });
    const gc1 = try str.graphemeSlice(1, 2);
    try expect(gc1[0].eql("\u{0065}\u{0301}"));

    // Substrings
    var str2 = try str.substr(1, 2);
    try expectEqualStrings("\u{0065}\u{0301}", str2);
    try expectEqualStrings(try str.byteSlice(1, 4), str2);
}

test "Zigstr casing" {
    var str = try fromBytes(std.testing.allocator, "Héllo! 123");
    defer str.deinit();

    try expect(!try str.isLower());
    try expect(!try str.isUpper());
    try str.toLower();
    try expect(try str.isLower());
    try expect(str.eql("héllo! 123"));
    try str.toUpper();
    try expect(try str.isUpper());
    try expect(str.eql("HÉLLO! 123"));
}

test "Zigstr format" {
    var str = try fromBytes(std.testing.allocator, "Héllo 😊");
    defer str.deinit();

    std.debug.print("{}\n", .{str});
}
