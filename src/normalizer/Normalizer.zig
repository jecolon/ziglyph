//! Normalizer contains functions and methods that implement Unicode Normalization algorithms. You can normalize strings
//! into NFC, NFKC, NFD, and NFKD normalization forms (see `nfc`, `nfkc`, `nfd`, and `nfkd`). You can also test for
//! string equality under different parameters related to normalization (see `eql`, `eqlCaseless`, `eqlIdentifiers`).

const std = @import("std");

const ziglyph = @import("../ziglyph.zig");
const case_fold_map = ziglyph.case_fold_map;
const ccc_map = ziglyph.combining_map;
const hangul_map = ziglyph.hangul_map;
const norm_props = ziglyph.derived_normalization_props;

composites: std.AutoHashMap([2]u21, u21),
decomp_map: std.AutoHashMap(u21, Decomp),

const Self = @This();

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

pub fn init(allocator: std.mem.Allocator) !Self {
    var self = Self{
        .composites = std.AutoHashMap([2]u21, u21).init(allocator),
        .decomp_map = std.AutoHashMap(u21, Decomp).init(allocator),
    };
    errdefer self.deinit();

    // Composites file.
    const comp_gz_file = @embedFile("../data/ucd/Composites.txt.gz");
    var comp_in_stream = std.io.fixedBufferStream(comp_gz_file);
    var comp_gzip_stream = try std.compress.gzip.gzipStream(allocator, comp_in_stream.reader());
    defer comp_gzip_stream.deinit();

    var comp_br = std.io.bufferedReader(comp_gzip_stream.reader());
    const comp_reader = comp_br.reader();
    var buf: [256]u8 = undefined;

    while (try comp_reader.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        if (line.len == 0) continue;
        var fields = std.mem.split(u8, line, ";");
        const cp_a = try std.fmt.parseInt(u21, fields.next().?, 16);
        const cp_b = try std.fmt.parseInt(u21, fields.next().?, 16);
        const cp_c = try std.fmt.parseInt(u21, fields.next().?, 16);
        try self.composites.put([_]u21{ cp_a, cp_b }, cp_c);
    }

    // Decompositions file.
    const decomp_gz_file = @embedFile("../data/ucd/Decompositions.txt.gz");
    var decomp_in_stream = std.io.fixedBufferStream(decomp_gz_file);
    var decomp_gzip_stream = try std.compress.gzip.gzipStream(allocator, decomp_in_stream.reader());
    defer decomp_gzip_stream.deinit();

    var decomp_br = std.io.bufferedReader(decomp_gzip_stream.reader());
    const decomp_reader = decomp_br.reader();

    while (try decomp_reader.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        if (line.len == 0) continue;

        var fields = std.mem.split(u8, line, ";");
        const cp = try std.fmt.parseInt(u21, fields.next().?, 16);
        const decomp_strs = fields.next().?;
        var dc = Decomp{ .form = if (std.mem.startsWith(u8, decomp_strs, "<")) .nfkd else .nfd };

        var cp_strs = std.mem.split(u8, decomp_strs, " ");
        if (dc.form == .nfkd) _ = cp_strs.next(); // Skip <

        var i: usize = 0;
        while (cp_strs.next()) |cp_str| : (i += 1) {
            dc.cps[i] = try std.fmt.parseInt(u21, cp_str, 16);
        }

        try self.decomp_map.put(cp, dc);
    }

    return self;
}

pub fn deinit(self: *Self) void {
    self.composites.deinit();
    self.decomp_map.deinit();
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

/// `mapping` retrieves the decomposition mapping for a code point as per the UCD.
pub fn mapping(self: Self, cp: u21, form: Form) Decomp {
    if (self.decomp_map.get(cp)) |dc| {
        return if (form == .nfd and dc.form == .nfkd)
            Decomp{ .form = .same, .cps = [_]u21{cp} ++ [_]u21{0} ** 17 }
        else
            dc;
    }

    return .{ .form = .same, .cps = [_]u21{cp} ++ [_]u21{0} ** 17 };
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
        var m_last: usize = 0;
        while (m_last < m.cps.len) : (m_last += 1) {
            if (m.cps[m_last] == 0) break;
        }

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
    var n = try init(std.testing.allocator);
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

fn onlyLatin1(str: []const u8) !bool {
    const view = try std.unicode.Utf8View.init(str);
    var cp_iter = view.iterator();
    return while (cp_iter.nextCodepoint()) |cp| {
        if (cp > 256) break false;
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
        std.sort.sort(u21, cps[start..i], {}, cccLess);
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

    const view = try std.unicode.Utf8View.init(str);
    var cp_iter = view.iterator();
    while (cp_iter.nextCodepoint()) |cp| {
        const dc = self.decompose(cp, form);
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

    return Result{ .allocator = allocator, .slice = dstr_list.toOwnedSlice() };
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
    return hangul_map.syllableType(cp) != null;
}

fn isStarter(cp: u21) bool {
    return ccc_map.combiningClass(cp) == 0;
}

fn isCombining(cp: u21) bool {
    return ccc_map.combiningClass(cp) > 0;
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
    if (form == .nfc and try onlyLatin1(str)) return Result{ .slice = str };

    // Decompose first.
    var d_result = if (form == .nfc)
        try self.nfd(allocator, str)
    else
        try self.nfkd(allocator, str);
    defer d_result.deinit();

    // Get code points.
    const view = try std.unicode.Utf8View.init(d_result.slice);
    var cp_iter = view.iterator();

    var d_list = try std.ArrayList(u21).initCapacity(allocator, d_result.slice.len);
    defer d_list.deinit();

    while (cp_iter.nextCodepoint()) |cp| d_list.appendAssumeCapacity(cp);

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
                    if (self.composites.get([_]u21{ L, C })) |P| {
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

            return Result{ .allocator = allocator, .slice = cstr_list.toOwnedSlice() };
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

test "UCD tests" {
    var path_buf: [1024]u8 = undefined;
    var path = try std.fs.cwd().realpath(".", &path_buf);
    // Check if testing in this library path.
    if (!std.mem.endsWith(u8, path, "ziglyph")) return error.SkipZigTest;

    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    var allocator = arena.allocator();
    var normalizer = try init(allocator);
    defer normalizer.deinit();

    var file = try std.fs.cwd().openFile("src/data/ucd/NormalizationTest.txt", .{});
    defer file.close();
    var buf_reader = std.io.bufferedReader(file.reader());
    const input_stream = buf_reader.reader();

    var line_no: usize = 0;
    var buf: [4096]u8 = undefined;
    var cp_buf: [4]u8 = undefined;

    while (try input_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        line_no += 1;
        // Skip comments or empty lines.
        if (line.len == 0 or line[0] == '#' or line[0] == '@') continue;
        //std.debug.print("{}: {s}\n", .{ line_no, line });
        // Iterate over fields.
        var fields = std.mem.split(u8, line, ";");
        var field_index: usize = 0;
        var input: []u8 = undefined;
        defer allocator.free(input);

        while (fields.next()) |field| : (field_index += 1) {
            if (field_index == 0) {
                var i_buf = std.ArrayList(u8).init(allocator);
                defer i_buf.deinit();

                var i_fields = std.mem.split(u8, field, " ");
                while (i_fields.next()) |s| {
                    const icp = try std.fmt.parseInt(u21, s, 16);
                    const len = try std.unicode.utf8Encode(icp, &cp_buf);
                    try i_buf.appendSlice(cp_buf[0..len]);
                }

                input = i_buf.toOwnedSlice();
            } else if (field_index == 1) {
                // NFC, time to test.
                var w_buf = std.ArrayList(u8).init(allocator);
                defer w_buf.deinit();

                var w_fields = std.mem.split(u8, field, " ");
                while (w_fields.next()) |s| {
                    const wcp = try std.fmt.parseInt(u21, s, 16);
                    const len = try std.unicode.utf8Encode(wcp, &cp_buf);
                    try w_buf.appendSlice(cp_buf[0..len]);
                }

                const want = w_buf.items;
                var got = try normalizer.nfc(allocator, input);
                defer got.deinit();

                try std.testing.expectEqualStrings(want, got.slice);
            } else if (field_index == 2) {
                // NFD, time to test.
                var w_buf = std.ArrayList(u8).init(allocator);
                defer w_buf.deinit();

                var w_fields = std.mem.split(u8, field, " ");
                while (w_fields.next()) |s| {
                    const wcp = try std.fmt.parseInt(u21, s, 16);
                    const len = try std.unicode.utf8Encode(wcp, &cp_buf);
                    try w_buf.appendSlice(cp_buf[0..len]);
                }

                const want = w_buf.items;
                var got = try normalizer.nfd(allocator, input);
                defer got.deinit();

                try std.testing.expectEqualStrings(want, got.slice);
            } else if (field_index == 3) {
                // NFKC, time to test.
                var w_buf = std.ArrayList(u8).init(allocator);
                defer w_buf.deinit();

                var w_fields = std.mem.split(u8, field, " ");
                while (w_fields.next()) |s| {
                    const wcp = try std.fmt.parseInt(u21, s, 16);
                    const len = try std.unicode.utf8Encode(wcp, &cp_buf);
                    try w_buf.appendSlice(cp_buf[0..len]);
                }

                const want = w_buf.items;
                var got = try normalizer.nfkc(allocator, input);
                defer got.deinit();

                try std.testing.expectEqualStrings(want, got.slice);
            } else if (field_index == 4) {
                // NFKD, time to test.
                var w_buf = std.ArrayList(u8).init(allocator);
                defer w_buf.deinit();

                var w_fields = std.mem.split(u8, field, " ");
                while (w_fields.next()) |s| {
                    const wcp = try std.fmt.parseInt(u21, s, 16);
                    const len = try std.unicode.utf8Encode(wcp, &cp_buf);
                    try w_buf.appendSlice(cp_buf[0..len]);
                }

                const want = w_buf.items;
                var got = try normalizer.nfkd(allocator, input);
                defer got.deinit();

                try std.testing.expectEqualStrings(want, got.slice);
            } else {
                continue;
            }
        }
    }
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
        const view = try std.unicode.Utf8View.init(item.str);
        var cp_iter = view.iterator();
        while (cp_iter.nextCodepoint()) |cp| {
            const nfkcf = norm_props.toNfkcCaseFold(cp);
            switch (nfkcf.len) {
                0 => item.list.appendAssumeCapacity(cp), // maps to itself
                1 => {}, // ignore
                else => {
                    // Got list; parse and add it. "x,y,z..."
                    var cp_strs = std.mem.split(u8, nfkcf, ",");

                    while (cp_strs.next()) |cp_str| {
                        const parsed_cp = try std.fmt.parseInt(u21, cp_str, 16);
                        item.list.appendAssumeCapacity(parsed_cp);
                    }
                },
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
    var n = try init(std.testing.allocator);
    defer n.deinit();

    try std.testing.expect(try n.eql(std.testing.allocator, "foé", "foe\u{0301}"));
    try std.testing.expect(try n.eql(std.testing.allocator, "foϓ", "fo\u{03D2}\u{0301}"));
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
    const view = try std.unicode.Utf8View.init(str);
    var cp_iter = view.iterator();

    return while (cp_iter.nextCodepoint()) |cp| {
        if (requiresNfdBeforeCaseFold(cp)) break true;
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
    var n = try init(std.testing.allocator);
    defer n.deinit();

    try std.testing.expect(try n.eqlCaseless(std.testing.allocator, "Foϓ", "fo\u{03D2}\u{0301}"));
    try std.testing.expect(try n.eqlCaseless(std.testing.allocator, "FOÉ", "foe\u{0301}")); // foÉ == foé
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
    const view = try std.unicode.Utf8View.init(str);
    var cp_iter = view.iterator();

    return while (cp_iter.nextCodepoint()) |cp| {
        const ccc = self.getLeadCcc(cp);
        if (ccc != 0 and ccc < prev_ccc) break false;
        prev_ccc = self.getTrailCcc(cp);
    } else true;
}

test "isFcd" {
    var n = try init(std.testing.allocator);
    defer n.deinit();

    const is_nfc = "José \u{3D3}";
    try std.testing.expect(try n.isFcd(is_nfc));

    const is_nfd = "Jose\u{301} \u{3d2}\u{301}";
    try std.testing.expect(try n.isFcd(is_nfd));

    const not_fcd = "Jose\u{301} \u{3d2}\u{315}\u{301}";
    try std.testing.expect(!try n.isFcd(not_fcd));
}
