const std = @import("std");
const mem = std.mem;
const unicode = std.unicode;

const ascii = @import("../ascii.zig");
const DecomposeMap = @import("../ziglyph.zig").DecomposeMap;
const CaseFoldMap = @import("../components/autogen/CaseFolding/CaseFoldMap.zig");
pub const GraphemeIterator = @import("GraphemeIterator.zig");

allocator: *mem.Allocator,
decomp_map: DecomposeMap,
fold_map: CaseFoldMap,

const Self = @This();

pub fn init(allocator: *mem.Allocator) !Self {
    return Self{
        .allocator = allocator,
        .decomp_map = try DecomposeMap.init(allocator),
        .fold_map = try CaseFoldMap.init(allocator),
    };
}

pub fn deinit(self: *Self) void {
    self.decomp_map.deinit();
    self.fold_map.deinit();
}

pub const StrOpts = enum {
    exact,
    ignore_case,
    normalize,
    norm_ignore,
};

pub fn eql(self: *Self, a: []const u8, b: []const u8, opts: StrOpts) !bool {
    var ascii_only = true;
    var bytes_eql = true;
    var inner: []const u8 = undefined;
    const len_a = a.len;
    const len_b = b.len;
    var len_eql = len_a == len_b;
    var outer: []const u8 = undefined;

    if (len_a <= len_b) {
        outer = a;
        inner = b;
    } else {
        outer = b;
        inner = a;
    }

    for (outer) |c, i| {
        if (c != inner[i]) bytes_eql = false;
        if (!isAscii(c) and !isAscii(inner[i])) ascii_only = false;
    }

    // Exact bytes match.
    if (opts == .exact and len_eql and bytes_eql) return true;

    if (opts == .ignore_case and len_eql) {
        if (ascii_only) {
            // ASCII case insensitive.
            for (a) |c, i| {
                if (ascii.toLower(c) != ascii.toLower(b[i])) return false;
            }
            return true;
        }

        // Non-ASCII case insensitive.
        return try self.ignoreCaseEql(a, b);
    }

    if (opts == .normalize) return try self.normalizeEql(a, b);
    if (opts == .norm_ignore) return try self.normIgnoreEql(a, b);

    return false;
}

fn ignoreCaseEql(self: *Self, a: []const u8, b: []const u8) !bool {
    const cf_a = try self.fold_map.caseFoldStr(self.allocator, a);
    defer self.allocator.free(cf_a);
    const cf_b = try self.fold_map.caseFoldStr(self.allocator, b);
    defer self.allocator.free(cf_b);

    return mem.eql(u8, cf_a, cf_b);
}

fn normalizeEql(self: *Self, a: []const u8, b: []const u8) !bool {
    var arena = std.heap.ArenaAllocator.init(self.allocator);
    defer arena.deinit();

    const norm_a = try self.decomp_map.normalizeTo(&arena.allocator, .KD, a);
    const norm_b = try self.decomp_map.normalizeTo(&arena.allocator, .KD, b);

    return mem.eql(u8, norm_a, norm_b);
}

fn normIgnoreEql(self: *Self, a: []const u8, b: []const u8) !bool {
    var arena = std.heap.ArenaAllocator.init(self.allocator);
    defer arena.deinit();

    // The long winding road of normalized caseless matching...
    // NFKD(CaseFold(NFKD(CaseFold(NFD(str)))))
    var norm_a = try self.decomp_map.normalizeTo(&arena.allocator, .D, a);
    var cf_a = try self.fold_map.caseFoldStr(&arena.allocator, norm_a);
    norm_a = try self.decomp_map.normalizeTo(&arena.allocator, .KD, cf_a);
    cf_a = try self.fold_map.caseFoldStr(&arena.allocator, norm_a);
    norm_a = try self.decomp_map.normalizeTo(&arena.allocator, .KD, cf_a);
    var norm_b = try self.decomp_map.normalizeTo(&arena.allocator, .D, b);
    var cf_b = try self.fold_map.caseFoldStr(&arena.allocator, norm_b);
    norm_b = try self.decomp_map.normalizeTo(&arena.allocator, .KD, cf_b);
    cf_b = try self.fold_map.caseFoldStr(&arena.allocator, norm_b);
    norm_b = try self.decomp_map.normalizeTo(&arena.allocator, .KD, cf_b);

    return mem.eql(u8, norm_a, norm_b);
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

test "isAsciiStr" {
    std.testing.expect(try isAsciiStr("Hello!"));
    std.testing.expect(!try isAsciiStr("Héllo!"));
}

test "isLatin1Str" {
    std.testing.expect(try isLatin1Str("Hello!"));
    std.testing.expect(try isLatin1Str("Héllo!"));
    std.testing.expect(!try isLatin1Str("H\u{0065}\u{0301}llo!"));
    std.testing.expect(!try isLatin1Str("H😀llo!"));
}

test "Zigstr eql" {
    var allocator = std.testing.allocator;
    var str = try init(allocator);
    defer str.deinit();

    std.testing.expect(try str.eql("foo", "foo", .exact));
    std.testing.expect(!try str.eql("fooo", "foo", .exact));
    std.testing.expect(!try str.eql("foó", "foo", .exact));
    std.testing.expect(try str.eql("foó", "foó", .exact));
    std.testing.expect(!try str.eql("Foo", "foo", .exact));
    std.testing.expect(try str.eql("Foo", "foo", .ignore_case));
    std.testing.expect(try str.eql("Foé", "foe\u{301}", .ignore_case));
    std.testing.expect(try str.eql("foé", "foe\u{0301}", .normalize));
    std.testing.expect(try str.eql("foϓ", "foΥ\u{0301}", .normalize));
    std.testing.expect(try str.eql("Foϓ", "foΥ\u{0301}", .norm_ignore));
    std.testing.expect(try str.eql("FOÉ", "foe\u{0301}", .norm_ignore)); // foÉ == foé
}
