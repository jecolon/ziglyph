//! Normalizer contains functions and methods that implement Unicode Normalization algorithms. You can normalize strings
//! into NFC, NFKC, NFD, and NFKD normalization forms (see `nfc`, `nfkc`, `nfd`, and `nfkd`). You can also test for
//! string equality under different parameters related to normalization (see `eql`, `eqlCaseless`, `eqlIdentifiers`).

const std = @import("std");

const CodePointIterator = @import("../segmenter/CodePoint.zig").CodePointIterator;
const case_fold_map = @import("../autogen/case_folding.zig");
const ccc_map = @import("../autogen/derived_combining_class.zig");
const hangul_map = @import("../autogen/hangul_syllable_type.zig");
const norm_props = @import("../autogen/derived_normalization_props.zig");

const Self = @This();

nfc_map: std.AutoHashMap([2]u21, u21),
nfd_map: std.AutoHashMap(u21, [2]u21),
nfkd_map: std.AutoHashMap(u21, [18]u21),

pub fn init(allocator: std.mem.Allocator) !Self {
    var self = Self{
        .nfc_map = std.AutoHashMap([2]u21, u21).init(allocator),
        .nfd_map = std.AutoHashMap(u21, [2]u21).init(allocator),
        .nfkd_map = std.AutoHashMap(u21, [18]u21).init(allocator),
    };
    errdefer self.deinit();

    // Canonical compositions
    const decompressor = std.compress.deflate.decompressor;
    const comp_file = @embedFile("../autogen/canonical_compositions.txt.deflate");
    var comp_stream = std.io.fixedBufferStream(comp_file);
    var comp_decomp = try decompressor(allocator, comp_stream.reader(), null);
    defer comp_decomp.deinit();

    var comp_buf = std.io.bufferedReader(comp_decomp.reader());
    const comp_reader = comp_buf.reader();
    var buf: [4096]u8 = undefined;

    while (try comp_reader.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        if (line.len == 0) continue;
        var fields = std.mem.split(u8, line, ";");
        const cp_a = try std.fmt.parseInt(u21, fields.next().?, 16);
        const cp_b = try std.fmt.parseInt(u21, fields.next().?, 16);
        const cp_c = try std.fmt.parseInt(u21, fields.next().?, 16);
        try self.nfc_map.put(.{ cp_a, cp_b }, cp_c);
    }

    // Canonical decompositions
    const decomp_file = @embedFile("../autogen/canonical_decompositions.txt.deflate");
    var decomp_stream = std.io.fixedBufferStream(decomp_file);
    var decomp_decomp = try decompressor(allocator, decomp_stream.reader(), null);
    defer decomp_decomp.deinit();

    var decomp_buf = std.io.bufferedReader(decomp_decomp.reader());
    const decomp_reader = decomp_buf.reader();

    while (try decomp_reader.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        if (line.len == 0) continue;
        var fields = std.mem.split(u8, line, ";");
        const cp_a = try std.fmt.parseInt(u21, fields.next().?, 16);
        const cp_b = try std.fmt.parseInt(u21, fields.next().?, 16);
        const cp_c = try std.fmt.parseInt(u21, fields.next().?, 16);
        try self.nfd_map.put(cp_a, .{ cp_b, cp_c });
    }

    // Compatibility decompositions
    const dekomp_file = @embedFile("../autogen/compatibility_decompositions.txt.deflate");
    var dekomp_stream = std.io.fixedBufferStream(dekomp_file);
    var dekomp_decomp = try decompressor(allocator, dekomp_stream.reader(), null);
    defer dekomp_decomp.deinit();

    var dekomp_buf = std.io.bufferedReader(dekomp_decomp.reader());
    const dekomp_reader = dekomp_buf.reader();

    while (try dekomp_reader.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        if (line.len == 0) continue;
        var fields = std.mem.split(u8, line, ";");
        const cp_a = try std.fmt.parseInt(u21, fields.next().?, 16);
        var cps = [_]u21{0} ** 18;
        var i: usize = 0;

        while (fields.next()) |cp| : (i += 1) {
            cps[i] = try std.fmt.parseInt(u21, cp, 16);
        }

        try self.nfkd_map.put(cp_a, cps);
    }

    return self;
}

pub fn deinit(self: *Self) void {
    self.nfc_map.deinit();
    self.nfd_map.deinit();
    self.nfkd_map.deinit();
}

test "init / deinit" {
    var n = try init(std.testing.allocator);
    defer n.deinit();
}
// Hangul processing utilities.
fn isHangulPrecomposed(cp: u21) bool {
    if (hangul_map.syllableType(cp)) |kind| return kind == .LV or kind == .LVT;
    return false;
}

const SBase: u21 = 0xAC00;
const LBase: u21 = 0x1100;
const VBase: u21 = 0x1161;
const TBase: u21 = 0x11A7;
const LCount: u21 = 19;
const VCount: u21 = 21;
const TCount: u21 = 28;
const NCount: u21 = 588; // VCount * TCount
const SCount: u21 = 11172; // LCount * NCount

fn decomposeHangul(cp: u21) [3]u21 {
    const SIndex: u21 = cp - SBase;
    const LIndex: u21 = SIndex / NCount;
    const VIndex: u21 = (SIndex % NCount) / TCount;
    const TIndex: u21 = SIndex % TCount;
    const LPart: u21 = LBase + LIndex;
    const VPart: u21 = VBase + VIndex;
    var TPart: u21 = 0;
    if (TIndex != 0) TPart = TBase + TIndex;

    return [3]u21{ LPart, VPart, TPart };
}

fn composeHangulCanon(lv: u21, t: u21) u21 {
    std.debug.assert(0x11A8 <= t and t <= 0x11C2);
    return lv + (t - TBase);
}

fn composeHangulFull(l: u21, v: u21, t: u21) u21 {
    std.debug.assert(0x1100 <= l and l <= 0x1112);
    std.debug.assert(0x1161 <= v and v <= 0x1175);
    const LIndex = l - LBase;
    const VIndex = v - VBase;
    const LVIndex = LIndex * NCount + VIndex * TCount;

    if (t == 0) return SBase + LVIndex;

    std.debug.assert(0x11A8 <= t and t <= 0x11C2);
    const TIndex = t - TBase;

    return SBase + LVIndex + TIndex;
}

const Form = enum {
    nfc,
    nfd,
    nfkc,
    nfkd,
    same,
};

const Decomp = struct {
    form: Form = .nfd,
    cps: [18]u21 = [_]u21{0} ** 18,
};

/// `mapping` retrieves the decomposition mapping for a code point as per the UCD.
pub fn mapping(self: Self, cp: u21, form: Form) Decomp {
    std.debug.assert(form == .nfd or form == .nfkd);

    var dc = Decomp{ .form = .same };
    dc.cps[0] = cp;

    if (self.nfkd_map.get(cp)) |array| {
        if (form != .nfd) {
            dc.form = .nfkd;
            @memcpy(dc.cps[0..array.len], &array);
        }
    } else if (self.nfd_map.get(cp)) |array| {
        dc.form = .nfd;
        @memcpy(dc.cps[0..array.len], &array);
    }

    return dc;
}

/// `decompose` a code point to the specified normalization form, which should be either `.nfd` or `.nfkd`.
pub fn decompose(self: Self, cp: u21, form: Form) Decomp {
    std.debug.assert(form == .nfd or form == .nfkd);

    var dc = Decomp{ .form = form };

    // ASCII or NFD / NFKD quick checks.
    if (cp <= 127 or (form == .nfd and norm_props.isNfd(cp)) or (form == .nfkd and norm_props.isNfkd(cp))) {
        dc.cps[0] = cp;
        return dc;
    }

    // Hangul precomposed syllable full decomposition.
    if (isHangulPrecomposed(cp)) {
        const cps = decomposeHangul(cp);
        std.mem.copy(u21, &dc.cps, &cps);
        return dc;
    }

    // Full decomposition.
    var result_index: usize = 0;
    var work_index: usize = 1;

    // Start work with argument code point.
    var work = [_]u21{cp} ++ [_]u21{0} ** 17;

    while (work_index > 0) {
        // Look at previous code point in work queue.
        work_index -= 1;
        const next = work[work_index];
        const m = self.mapping(next, form);

        // No more of decompositions for this code point.
        if (m.form == .same) {
            dc.cps[result_index] = m.cps[0];
            result_index += 1;
            continue;
        }

        // Find last index of decomposition.
        const m_last = for (m.cps, 0..) |mcp, i| {
            if (mcp == 0) break i;
        } else m.cps.len;

        // Work backwards through decomposition.
        // `i` starts at 1 because m_last is 1 past the last code point.
        var i: usize = 1;
        while (i <= m_last) : ({
            i += 1;
            work_index += 1;
        }) {
            work[work_index] = m.cps[m_last - i];
        }
    }

    return dc;
}

test "decompose" {
    const allocator = std.testing.allocator;
    var n = try init(allocator);
    defer n.deinit();

    var dc = n.decompose('é', .nfd);
    try std.testing.expect(dc.form == .nfd);
    try std.testing.expectEqualSlices(u21, &[_]u21{ 'e', '\u{301}' }, dc.cps[0..2]);

    dc = n.decompose('\u{1e0a}', .nfd);
    try std.testing.expect(dc.form == .nfd);
    try std.testing.expectEqualSlices(u21, &[_]u21{ 'D', '\u{307}' }, dc.cps[0..2]);

    dc = n.decompose('\u{1e0a}', .nfkd);
    try std.testing.expect(dc.form == .nfkd);
    try std.testing.expectEqualSlices(u21, &[_]u21{ 'D', '\u{307}' }, dc.cps[0..2]);

    dc = n.decompose('\u{3189}', .nfd);
    try std.testing.expect(dc.form == .nfd);
    try std.testing.expectEqualSlices(u21, &[_]u21{'\u{3189}'}, dc.cps[0..1]);

    dc = n.decompose('\u{3189}', .nfkd);
    try std.testing.expect(dc.form == .nfkd);
    try std.testing.expectEqualSlices(u21, &[_]u21{'\u{1188}'}, dc.cps[0..1]);

    dc = n.decompose('\u{ace1}', .nfd);
    try std.testing.expect(dc.form == .nfd);
    try std.testing.expectEqualSlices(u21, &[_]u21{ '\u{1100}', '\u{1169}', '\u{11a8}' }, dc.cps[0..3]);

    dc = n.decompose('\u{ace1}', .nfkd);
    try std.testing.expect(dc.form == .nfkd);
    try std.testing.expectEqualSlices(u21, &[_]u21{ '\u{1100}', '\u{1169}', '\u{11a8}' }, dc.cps[0..3]);

    dc = n.decompose('\u{3d3}', .nfd);
    try std.testing.expect(dc.form == .nfd);
    try std.testing.expectEqualSlices(u21, &[_]u21{ '\u{3d2}', '\u{301}' }, dc.cps[0..2]);

    dc = n.decompose('\u{3d3}', .nfkd);
    try std.testing.expect(dc.form == .nfkd);
    try std.testing.expectEqualSlices(u21, &[_]u21{ '\u{3a5}', '\u{301}' }, dc.cps[0..2]);
}

// Some quick checks.

fn onlyAscii(str: []const u8) bool {
    return for (str) |b| {
        if (b > 127) break false;
    } else true;
}

fn onlyLatin1(str: []const u8) bool {
    var cp_iter = CodePointIterator{ .bytes = str };
    return while (cp_iter.next()) |cp| {
        if (cp.code > 256) break false;
    } else true;
}

/// Returned from various functions in this namespace. Remember to call `deinit` to free any allocated memory.
pub const Result = struct {
    allocator: ?std.mem.Allocator = null,
    slice: []const u8,

    pub fn deinit(self: *Result) void {
        if (self.allocator) |allocator| allocator.free(self.slice);
    }
};

// Compares code points by Canonical Combining Class order.
fn cccLess(_: void, lhs: u21, rhs: u21) bool {
    return ccc_map.combiningClass(lhs) < ccc_map.combiningClass(rhs);
}

// Applies the Canonical Sorting Algorithm.
fn canonicalSort(cps: []u21) void {
    var i: usize = 0;
    while (i < cps.len) : (i += 1) {
        var start: usize = i;
        while (i < cps.len and ccc_map.combiningClass(cps[i]) != 0) : (i += 1) {}
        std.mem.sort(u21, cps[start..i], {}, cccLess);
    }
}

/// Normalize `str` to NFD.
pub fn nfd(self: Self, allocator: std.mem.Allocator, str: []const u8) !Result {
    return self.nfxd(allocator, str, .nfd);
}

/// Normalize `str` to NFKD.
pub fn nfkd(self: Self, allocator: std.mem.Allocator, str: []const u8) !Result {
    return self.nfxd(allocator, str, .nfkd);
}

fn nfxd(self: Self, allocator: std.mem.Allocator, str: []const u8, form: Form) !Result {
    // Quick checks.
    if (onlyAscii(str)) return Result{ .slice = str };

    var dcp_list = try std.ArrayList(u21).initCapacity(allocator, str.len + str.len / 2);
    defer dcp_list.deinit();

    var cp_iter = CodePointIterator{ .bytes = str };
    while (cp_iter.next()) |cp| {
        const dc = self.decompose(cp.code, form);
        const slice = for (dc.cps, 0..) |dcp, i| {
            if (dcp == 0) break dc.cps[0..i];
        } else dc.cps[0..];
        try dcp_list.appendSlice(slice);
    }

    canonicalSort(dcp_list.items);

    var dstr_list = try std.ArrayList(u8).initCapacity(allocator, dcp_list.items.len * 4);
    defer dstr_list.deinit();

    var buf: [4]u8 = undefined;
    for (dcp_list.items) |dcp| {
        const len = try std.unicode.utf8Encode(dcp, &buf);
        dstr_list.appendSliceAssumeCapacity(buf[0..len]);
    }

    return Result{ .allocator = allocator, .slice = try dstr_list.toOwnedSlice() };
}

test "nfd ASCII / no-alloc" {
    const allocator = std.testing.allocator;
    var n = try init(allocator);
    defer n.deinit();

    var result = try n.nfd(allocator, "Hello World!");
    defer result.deinit();

    try std.testing.expectEqualStrings("Hello World!", result.slice);
}

test "nfd !ASCII / alloc" {
    const allocator = std.testing.allocator;
    var n = try init(allocator);
    defer n.deinit();

    var result = try n.nfd(allocator, "Héllo World! \u{3d3}");
    defer result.deinit();

    try std.testing.expectEqualStrings("He\u{301}llo World! \u{3d2}\u{301}", result.slice);
}

test "nfkd ASCII / no-alloc" {
    const allocator = std.testing.allocator;
    var n = try init(allocator);
    defer n.deinit();

    var result = try n.nfkd(allocator, "Hello World!");
    defer result.deinit();

    try std.testing.expectEqualStrings("Hello World!", result.slice);
}

test "nfkd !ASCII / alloc" {
    const allocator = std.testing.allocator;
    var n = try init(allocator);
    defer n.deinit();

    var result = try n.nfkd(allocator, "Héllo World! \u{3d3}");
    defer result.deinit();

    try std.testing.expectEqualStrings("He\u{301}llo World! \u{3a5}\u{301}", result.slice);
}

// Composition utilities.

fn isHangul(cp: u21) bool {
    return cp >= 0x1100 and hangul_map.syllableType(cp) != null;
}

fn isStarter(cp: u21) bool {
    return ccc_map.combiningClass(cp) == 0;
}

fn isCombining(cp: u21) bool {
    return ccc_map.combiningClass(cp) != 0;
}

fn isNonHangulStarter(cp: u21) bool {
    return !isHangul(cp) and isStarter(cp);
}

/// Normalizes `str` to NFC.
pub fn nfc(self: Self, allocator: std.mem.Allocator, str: []const u8) !Result {
    return self.nfxc(allocator, str, .nfc);
}

/// Normalizes `str` to NFKC.
pub fn nfkc(self: Self, allocator: std.mem.Allocator, str: []const u8) !Result {
    return self.nfxc(allocator, str, .nfkc);
}

fn nfxc(self: Self, allocator: std.mem.Allocator, str: []const u8, form: Form) !Result {
    // Quick checks.
    if (onlyAscii(str)) return Result{ .slice = str };
    if (form == .nfc and onlyLatin1(str)) return Result{ .slice = str };

    // Decompose first.
    var d_result = if (form == .nfc)
        try self.nfd(allocator, str)
    else
        try self.nfkd(allocator, str);
    defer d_result.deinit();

    // Get code points.
    var cp_iter = CodePointIterator{ .bytes = d_result.slice };

    var d_list = try std.ArrayList(u21).initCapacity(allocator, d_result.slice.len);
    defer d_list.deinit();

    while (cp_iter.next()) |cp| d_list.appendAssumeCapacity(cp.code);

    // Compose
    const tombstone = 0xe000; // Start of BMP Private Use Area

    while (true) {
        var i: usize = 1; // start at second code point.
        var deleted: usize = 0;

        block_check: while (i < d_list.items.len) : (i += 1) {
            const C = d_list.items[i];
            var starter_index: ?usize = null;
            var j: usize = i;

            while (true) {
                j -= 1;

                // Check for starter.
                if (ccc_map.combiningClass(d_list.items[j]) == 0) {
                    if (i - j > 1) { // If there's distance between the starting point and the current position.
                        for (d_list.items[(j + 1)..i]) |B| {
                            // Check for blocking conditions.
                            if (isHangul(C)) {
                                if (isCombining(B) or isNonHangulStarter(B)) continue :block_check;
                            }
                            if (ccc_map.combiningClass(B) >= ccc_map.combiningClass(C)) continue :block_check;
                        }
                    }

                    // Found starter at j.
                    starter_index = j;
                    break;
                }

                if (j == 0) break;
            }

            if (starter_index) |sidx| {
                const L = d_list.items[sidx];
                var processed_hangul = false;

                if (isHangul(L) and isHangul(C)) {
                    const l_stype = hangul_map.syllableType(L).?;
                    const c_stype = hangul_map.syllableType(C).?;

                    if (l_stype == .LV and c_stype == .T) {
                        // LV, T
                        d_list.items[sidx] = composeHangulCanon(L, C);
                        d_list.items[i] = tombstone; // Mark for deletion.
                        processed_hangul = true;
                    }

                    if (l_stype == .L and c_stype == .V) {
                        // Handle L, V. L, V, T is handled via main loop.
                        d_list.items[sidx] = composeHangulFull(L, C, 0);
                        d_list.items[i] = tombstone; // Mark for deletion.
                        processed_hangul = true;
                    }

                    if (processed_hangul) deleted += 1;
                }

                if (!processed_hangul) {
                    // L -> C not Hangul.
                    if (self.nfc_map.get(.{ L, C })) |P| {
                        if (!norm_props.isFcx(P)) {
                            d_list.items[sidx] = P;
                            d_list.items[i] = tombstone; // Mark for deletion.
                            deleted += 1;
                        }
                    }
                }
            }
        }

        // Check if finished.
        if (deleted == 0) {
            var cstr_list = try std.ArrayList(u8).initCapacity(allocator, d_list.items.len * 4);
            defer cstr_list.deinit();
            var buf: [4]u8 = undefined;

            for (d_list.items) |cp| {
                if (cp == tombstone) continue; // "Delete"
                const len = try std.unicode.utf8Encode(cp, &buf);
                cstr_list.appendSliceAssumeCapacity(buf[0..len]);
            }

            return Result{ .allocator = allocator, .slice = try cstr_list.toOwnedSlice() };
        }

        // Otherwise update code points list.
        var tmp_d_list = try std.ArrayList(u21).initCapacity(allocator, d_list.items.len - deleted);
        defer tmp_d_list.deinit();

        for (d_list.items) |cp| {
            if (cp != tombstone) tmp_d_list.appendAssumeCapacity(cp);
        }

        d_list.clearRetainingCapacity();
        d_list.appendSliceAssumeCapacity(tmp_d_list.items);
    }
}

test "nfc" {
    const allocator = std.testing.allocator;
    var n = try init(allocator);
    defer n.deinit();

    var result = try n.nfc(allocator, "Complex char: \u{3D2}\u{301}");
    defer result.deinit();

    try std.testing.expectEqualStrings("Complex char: \u{3D3}", result.slice);
}

test "nfkc" {
    const allocator = std.testing.allocator;
    var n = try init(allocator);
    defer n.deinit();

    var result = try n.nfkc(allocator, "Complex char: \u{03A5}\u{0301}");
    defer result.deinit();

    try std.testing.expectEqualStrings("Complex char: \u{038E}", result.slice);
}

/// Tests for equality as per Unicode rules for Identifiers.
pub fn eqlIdentifiers(allocator: std.mem.Allocator, a: []const u8, b: []const u8) !bool {
    var list_a = try std.ArrayList(u21).initCapacity(allocator, a.len);
    defer list_a.deinit();
    var list_b = try std.ArrayList(u21).initCapacity(allocator, b.len);
    defer list_b.deinit();

    const Item = struct {
        str: []const u8,
        list: *std.ArrayList(u21),
    };

    const items = [_]Item{
        .{ .str = a, .list = &list_a },
        .{ .str = b, .list = &list_b },
    };

    for (items) |item| {
        var cp_iter = CodePointIterator{ .bytes = item.str };
        while (cp_iter.next()) |cp| {
            if (norm_props.toNfkcCaseFold(cp.code)) |nfkcf| {
                for (nfkcf) |c| {
                    if (c == 0) break;
                    item.list.appendAssumeCapacity(c);
                }
            } else {
                item.list.appendAssumeCapacity(cp.code); // maps to itself
            }
        }
    }

    return std.mem.eql(u21, list_a.items, list_b.items);
}

test "eqlIdentifiers" {
    try std.testing.expect(try eqlIdentifiers(std.testing.allocator, "Foé", "foé"));
}

/// Tests for equality of `a` and `b` after normalizing to NFD.
pub fn eql(self: Self, allocator: std.mem.Allocator, a: []const u8, b: []const u8) !bool {
    var norm_result_a = try self.nfd(allocator, a);
    defer norm_result_a.deinit();
    var norm_result_b = try self.nfd(allocator, b);
    defer norm_result_b.deinit();

    return std.mem.eql(u8, norm_result_a.slice, norm_result_b.slice);
}

test "eql" {
    const allocator = std.testing.allocator;
    var n = try init(allocator);
    defer n.deinit();

    try std.testing.expect(try n.eql(allocator, "foé", "foe\u{0301}"));
    try std.testing.expect(try n.eql(allocator, "foϓ", "fo\u{03D2}\u{0301}"));
}

fn requiresNfdBeforeCaseFold(cp: u21) bool {
    return switch (cp) {
        0x0345 => true,
        0x1F80...0x1FAF => true,
        0x1FB2...0x1FB4 => true,
        0x1FB7 => true,
        0x1FBC => true,
        0x1FC2...0x1FC4 => true,
        0x1FC7 => true,
        0x1FCC => true,
        0x1FF2...0x1FF4 => true,
        0x1FF7 => true,
        0x1FFC => true,
        else => false,
    };
}

fn requiresPreNfd(str: []const u8) !bool {
    var cp_iter = CodePointIterator{ .bytes = str };

    return while (cp_iter.next()) |cp| {
        if (requiresNfdBeforeCaseFold(cp.code)) break true;
    } else false;
}

/// `eqlCaseless` tests for equality of `a` and `b` after normalizing to NFD and ignoring letter case.
pub fn eqlCaseless(self: Self, allocator: std.mem.Allocator, a: []const u8, b: []const u8) !bool {
    // The long winding road of normalized caseless matching...
    // NFD(CaseFold(NFD(str))) or NFD(CaseFold(str))
    var norm_result_a = if (try requiresPreNfd(a)) try self.nfd(allocator, a) else Result{ .slice = a };
    defer norm_result_a.deinit();
    var cf_a = try case_fold_map.caseFoldStr(allocator, norm_result_a.slice);
    defer allocator.free(cf_a);
    norm_result_a.deinit();
    norm_result_a = try self.nfd(allocator, cf_a);

    var norm_result_b = if (try requiresPreNfd(b)) try self.nfd(allocator, b) else Result{ .slice = b };
    defer norm_result_b.deinit();
    var cf_b = try case_fold_map.caseFoldStr(allocator, norm_result_b.slice);
    defer allocator.free(cf_b);
    norm_result_b.deinit();
    norm_result_b = try self.nfd(allocator, cf_b);

    return std.mem.eql(u8, norm_result_a.slice, norm_result_b.slice);
}

test "eqlCaseless" {
    const allocator = std.testing.allocator;
    var n = try init(allocator);
    defer n.deinit();

    try std.testing.expect(try n.eqlCaseless(allocator, "Foϓ", "fo\u{03D2}\u{0301}"));
    try std.testing.expect(try n.eqlCaseless(allocator, "FOÉ", "foe\u{0301}")); // foÉ == foé
}

// FCD
fn getLeadCcc(self: Self, cp: u21) u8 {
    const dc = self.mapping(cp, .nfd);
    return ccc_map.combiningClass(dc.cps[0]);
}

fn getTrailCcc(self: Self, cp: u21) u8 {
    const dc = self.mapping(cp, .nfd);
    const len = for (dc.cps, 0..) |dcp, i| {
        if (dcp == 0) break i;
    } else dc.cps.len;
    return ccc_map.combiningClass(dc.cps[len -| 1]);
}

/// Fast check to detect if a string is already in NFC or NFD form.
pub fn isFcd(self: Self, str: []const u8) !bool {
    var prev_ccc: u8 = 0;
    var cp_iter = CodePointIterator{ .bytes = str };

    return while (cp_iter.next()) |cp| {
        const ccc = self.getLeadCcc(cp.code);
        if (ccc != 0 and ccc < prev_ccc) break false;
        prev_ccc = self.getTrailCcc(cp.code);
    } else true;
}

test "isFcd" {
    const allocator = std.testing.allocator;
    var n = try init(allocator);
    defer n.deinit();

    const is_nfc = "José \u{3D3}";
    try std.testing.expect(try n.isFcd(is_nfc));

    const is_nfd = "Jose\u{301} \u{3d2}\u{301}";
    try std.testing.expect(try n.isFcd(is_nfd));

    const not_fcd = "Jose\u{301} \u{3d2}\u{315}\u{301}";
    try std.testing.expect(!try n.isFcd(not_fcd));
}
