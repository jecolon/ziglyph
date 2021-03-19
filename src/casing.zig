const values = @import("values.zig");
const tables = @import("tables.zig");

const Lower = values.Lower;
const Title = values.Title;
const Upper = values.Upper;
const isExcludingLatin = tables.isExcludingLatin;
const max_ascii = values.max_ascii;
const max_latin_1 = values.max_latin_1;
const max_rune = values.max_rune;
const pLl = values.pLl;
const pLu = values.pLu;
const pLmask = values.pLmask;
const properties = values.properties;
const range_tables = tables.range_tables;
const replacement_char = values.replacement_char;
const rune = values.rune;

/// CaseRange represents a range of Unicode code points for simple (one
/// code point to one code point) case conversion.
/// The range runs from low to high inclusive, with a fixed stride of 1. Deltas
/// are the number to add to the code point to reach the code point for a
/// different case for that character. They may be negative. If zero, it
/// means the character is in the corresponding case. There is a special
/// case representing sequences of alternating corresponding Upper and Lower
/// pairs. It appears with a fixed Delta of
///	{upper_lower, upper_lower, upper_lower}
/// The constant upper_lower has an otherwise impossible delta value.
pub const CaseRange = struct {
    low: rune,
    high: rune,
    delta: d,
};

// TODO: There is no mechanism for full case folding, that is, for
// characters that involve multiple runes in the input or output.

/// Indices into the Delta arrays inside CaseRanges for case mapping. Must be in upper, lower, title,
/// max order.
pub const Cases = enum {
    upper,
    lower,
    title,
    max,

    pub fn isValid(c: Cases) bool {
        return switch (c) {
            .upper, .lower, .title => true,
            else => false,
        };
    }
};

const d = [@enumToInt(Cases.max)]i32; // to make the CaseRanges text shorter

/// If the Delta field of a CaseRange is upper_lower, it means
/// this CaseRange represents a sequence of the form (say)
/// Upper Lower Upper Lower.
pub const upper_lower = max_rune + 1; // (Cannot be a valid delta.)

/// isUpper reports whether the rune is an upper case letter.
pub fn isUpper(r: rune) bool {
    // See comment in isGraphic.
    if (r <= max_latin_1) {
        return properties[r] & pLmask == pLu;
    }
    return isExcludingLatin(range_tables[@enumToInt(Upper)], r);
}

/// isLower reports whether the rune is a lower case letter.
pub fn isLower(r: rune) bool {
    // See comment in IsGraphic.
    if (r <= max_latin_1) {
        return properties[r] & pLmask == pLl;
    }
    return isExcludingLatin(range_tables[@enumToInt(Lower)], r);
}

/// isTitle reports whether the rune is a title case letter.
pub fn isTitle(r: rune) bool {
    if (r <= max_latin_1) {
        return false;
    }
    return isExcludingLatin(range_tables[@enumToInt(Title)], r);
}

const ToResult = struct {
    mapped_rune: rune,
    found_mapping: bool,
};

// to maps the rune using the specified case mapping.
// It additionally reports whether caseRange contained a mapping for r.
fn to(case: Cases, r: rune, caseRange: []const CaseRange) ToResult {
    if (!Cases.isValid(case)) {
        return ToResult{ .mapped_rune = replacement_char, .found_mapping = false }; // as reasonable an error as any
    }
    // binary search over ranges
    var lo: usize = 0;
    var hi: usize = caseRange.len;
    while (lo < hi) {
        var m = lo + (hi - lo) / 2;
        var cr = caseRange[m];
        if (cr.low <= r and r <= cr.high) {
            const delta = cr.delta[@enumToInt(case)];
            if (delta > max_rune) {
                // In an Upper-Lower sequence, which always starts with
                // an Cases.upper letter, the real deltas always look like:
                //	{0, 1, 0}    Cases.upper (Lower is next)
                //	{-1, 0, -1}  Cases.lower (Upper, Title are previous)
                // The characters at even offsets from the beginning of the
                // sequence are upper case; the ones at odd offsets are lower.
                // The correct mapping can be done by clearing or setting the low
                // bit in the sequence offset.
                // The constants Cases.upper and Cases.title are even while Cases.lower
                // is odd so we take the low bit from _case.
                const one: rune = 1;
                const mr: rune = cr.low + ((r - cr.low) & ~one | (@enumToInt(case) & one));
                return ToResult{ .mapped_rune = mr, .found_mapping = true };
            }
            return ToResult{ .mapped_rune = @intCast(rune, r + delta), .found_mapping = true };
        }
        if (r < cr.low) {
            hi = m;
        } else {
            lo = m + 1;
        }
    }
    return ToResult{ .mapped_rune = r, .found_mapping = false };
}

/// mapTo maps the rune to the specified case: Cases.upper, Cases.lower, or Cases.title.
pub fn mapTo(case: Cases, r: rune) rune {
    const tr = to(case, r, &CaseRanges);
    return tr.mapped_rune;
}

/// toUpper maps the rune to upper case.
pub fn toUpper(r: rune) rune {
    var rr = r;
    if (r <= max_ascii) {
        if ('a' <= r and r <= 'z') {
            rr -= 'a' - 'A';
        }
        return rr;
    }
    return mapTo(Cases.upper, r);
}

/// toLower maps the rune to lower case.
pub fn toLower(r: rune) rune {
    var rr = r;
    if (r <= max_ascii) {
        if ('A' <= r and r <= 'Z') {
            rr += 'a' - 'A';
        }
        return rr;
    }
    return mapTo(Cases.lower, r);
}

/// toTitle maps the rune to title case.
pub fn toTitle(r: rune) rune {
    var rr = r;
    if (r <= max_ascii) {
        if ('a' <= r and r <= 'z') { // title case is upper case for ASCII
            rr -= 'a' - 'A';
        }
        return rr;
    }
    return mapTo(Cases.title, r);
}

/// SpecialCase represents language-specific case mappings such as Turkish.
/// Methods of SpecialCase customize (by overriding) the standard mappings.
pub const SpecialCase = struct {
    const Self = @This();

    case_ranges: []const CaseRange,

    // specialToUpper maps the rune to upper case giving priority to the special mapping.
    pub fn specialToUpper(self: Self, r: rune) rune {
        var tr = to(Cases.upper, r, self.case_ranges);
        if (tr.mapped_rune == r and !tr.found_mapping) {
            tr.mapped_rune = toUpper(r);
        }
        return tr.mapped_rune;
    }

    // specialToTitle maps the rune to title case giving priority to the special mapping.
    pub fn specialToTitle(self: Self, r: rune) rune {
        var tr = to(Cases.title, r, self.case_ranges);
        if (tr.mapped_rune == r and !tr.found_mapping) {
            tr.mapped_rune = toTitle(r);
        }
        return tr.mapped_rune;
    }

    // specialToLower maps the rune to lower case giving priority to the special mapping.
    pub fn specialToLower(self: Self, r: rune) rune {
        var tr = to(Cases.lower, r, self.case_ranges);
        if (tr.mapped_rune == r and !tr.found_mapping) {
            tr.mapped_rune = toLower(r);
        }
        return tr.mapped_rune;
    }
};

/// case_orbit is defined in tables.go as []foldPair. Right now all the
/// entries fit in u16, so use u16. If that changes, compilation
/// will fail (the constants in the composite literal will not fit in u16)
/// and the types here can change to u32.
pub const FoldPair = struct {
    from: rune,
    to: rune,
};

pub const case_orbit = [_]FoldPair{
    .{ .from = 0x004B, .to = 0x006B },
    .{ .from = 0x0053, .to = 0x0073 },
    .{ .from = 0x006B, .to = 0x212A },
    .{ .from = 0x0073, .to = 0x017F },
    .{ .from = 0x00B5, .to = 0x039C },
    .{ .from = 0x00C5, .to = 0x00E5 },
    .{ .from = 0x00DF, .to = 0x1E9E },
    .{ .from = 0x00E5, .to = 0x212B },
    .{ .from = 0x0130, .to = 0x0130 },
    .{ .from = 0x0131, .to = 0x0131 },
    .{ .from = 0x017F, .to = 0x0053 },
    .{ .from = 0x01C4, .to = 0x01C5 },
    .{ .from = 0x01C5, .to = 0x01C6 },
    .{ .from = 0x01C6, .to = 0x01C4 },
    .{ .from = 0x01C7, .to = 0x01C8 },
    .{ .from = 0x01C8, .to = 0x01C9 },
    .{ .from = 0x01C9, .to = 0x01C7 },
    .{ .from = 0x01CA, .to = 0x01CB },
    .{ .from = 0x01CB, .to = 0x01CC },
    .{ .from = 0x01CC, .to = 0x01CA },
    .{ .from = 0x01F1, .to = 0x01F2 },
    .{ .from = 0x01F2, .to = 0x01F3 },
    .{ .from = 0x01F3, .to = 0x01F1 },
    .{ .from = 0x0345, .to = 0x0399 },
    .{ .from = 0x0392, .to = 0x03B2 },
    .{ .from = 0x0395, .to = 0x03B5 },
    .{ .from = 0x0398, .to = 0x03B8 },
    .{ .from = 0x0399, .to = 0x03B9 },
    .{ .from = 0x039A, .to = 0x03BA },
    .{ .from = 0x039C, .to = 0x03BC },
    .{ .from = 0x03A0, .to = 0x03C0 },
    .{ .from = 0x03A1, .to = 0x03C1 },
    .{ .from = 0x03A3, .to = 0x03C2 },
    .{ .from = 0x03A6, .to = 0x03C6 },
    .{ .from = 0x03A9, .to = 0x03C9 },
    .{ .from = 0x03B2, .to = 0x03D0 },
    .{ .from = 0x03B5, .to = 0x03F5 },
    .{ .from = 0x03B8, .to = 0x03D1 },
    .{ .from = 0x03B9, .to = 0x1FBE },
    .{ .from = 0x03BA, .to = 0x03F0 },
    .{ .from = 0x03BC, .to = 0x00B5 },
    .{ .from = 0x03C0, .to = 0x03D6 },
    .{ .from = 0x03C1, .to = 0x03F1 },
    .{ .from = 0x03C2, .to = 0x03C3 },
    .{ .from = 0x03C3, .to = 0x03A3 },
    .{ .from = 0x03C6, .to = 0x03D5 },
    .{ .from = 0x03C9, .to = 0x2126 },
    .{ .from = 0x03D0, .to = 0x0392 },
    .{ .from = 0x03D1, .to = 0x03F4 },
    .{ .from = 0x03D5, .to = 0x03A6 },
    .{ .from = 0x03D6, .to = 0x03A0 },
    .{ .from = 0x03F0, .to = 0x039A },
    .{ .from = 0x03F1, .to = 0x03A1 },
    .{ .from = 0x03F4, .to = 0x0398 },
    .{ .from = 0x03F5, .to = 0x0395 },
    .{ .from = 0x0412, .to = 0x0432 },
    .{ .from = 0x0414, .to = 0x0434 },
    .{ .from = 0x041E, .to = 0x043E },
    .{ .from = 0x0421, .to = 0x0441 },
    .{ .from = 0x0422, .to = 0x0442 },
    .{ .from = 0x042A, .to = 0x044A },
    .{ .from = 0x0432, .to = 0x1C80 },
    .{ .from = 0x0434, .to = 0x1C81 },
    .{ .from = 0x043E, .to = 0x1C82 },
    .{ .from = 0x0441, .to = 0x1C83 },
    .{ .from = 0x0442, .to = 0x1C84 },
    .{ .from = 0x044A, .to = 0x1C86 },
    .{ .from = 0x0462, .to = 0x0463 },
    .{ .from = 0x0463, .to = 0x1C87 },
    .{ .from = 0x1C80, .to = 0x0412 },
    .{ .from = 0x1C81, .to = 0x0414 },
    .{ .from = 0x1C82, .to = 0x041E },
    .{ .from = 0x1C83, .to = 0x0421 },
    .{ .from = 0x1C84, .to = 0x1C85 },
    .{ .from = 0x1C85, .to = 0x0422 },
    .{ .from = 0x1C86, .to = 0x042A },
    .{ .from = 0x1C87, .to = 0x0462 },
    .{ .from = 0x1C88, .to = 0xA64A },
    .{ .from = 0x1E60, .to = 0x1E61 },
    .{ .from = 0x1E61, .to = 0x1E9B },
    .{ .from = 0x1E9B, .to = 0x1E60 },
    .{ .from = 0x1E9E, .to = 0x00DF },
    .{ .from = 0x1FBE, .to = 0x0345 },
    .{ .from = 0x2126, .to = 0x03A9 },
    .{ .from = 0x212A, .to = 0x004B },
    .{ .from = 0x212B, .to = 0x00C5 },
    .{ .from = 0xA64A, .to = 0xA64B },
    .{ .from = 0xA64B, .to = 0x1C88 },
};

/// SimpleFold iterates over Unicode code points equivalent under
/// the Unicode-defined simple case folding. Among the code points
/// equivalent to rune (including rune itself), SimpleFold returns the
/// smallest rune > r if one exists, or else the smallest rune >= 0.
/// If r is not a valid Unicode code point, SimpleFold(r) returns r.
///
/// For example:
///	SimpleFold('A') = 'a'
///	SimpleFold('a') = 'A'
///
///	SimpleFold('K') = 'k'
///	SimpleFold('k') = '\u212A' (Kelvin symbol, K)
///	SimpleFold('\u212A') = 'K'
///
///	SimpleFold('1') = '1'
///
///	SimpleFold(-2) = -2
///
pub fn simpleFold(r: rune) rune {
    if (r < 0 or r > max_rune) {
        return r;
    }

    if (r < ascii_fold.len) {
        return ascii_fold[r];
    }

    // Consult case_orbit table for special cases.
    var lo: usize = 0;
    var hi: usize = case_orbit.len;
    while (lo < hi) {
        var m = lo + (hi - lo) / 2;
        if (case_orbit[m].from < r) {
            lo = m + 1;
        } else {
            hi = m;
        }
    }
    if (lo < case_orbit.len and case_orbit[lo].from == r) {
        return case_orbit[lo].to;
    }

    // No folding specified. This is a one- or two-element
    // equivalence class containing rune and ToLower(rune)
    // and ToUpper(rune) if they are different from rune.
    const l = toLower(r);
    if (l != r) {
        return l;
    }
    return toUpper(r);
}

pub const turkish_case_ranges = [_]CaseRange{
    .{ .low = 0x0049, .high = 0x0049, .delta = d{ 0, 0x131 - 0x49, 0 } },
    .{ .low = 0x0069, .high = 0x0069, .delta = d{ 0x130 - 0x69, 0, 0x130 - 0x69 } },
    .{ .low = 0x0130, .high = 0x0130, .delta = d{ 0, 0x69 - 0x130, 0 } },
    .{ .low = 0x0131, .high = 0x0131, .delta = d{ 0x49 - 0x131, 0, 0x49 - 0x131 } },
};

pub const TurkishCase = SpecialCase{
    .case_ranges = &turkish_case_ranges,
};

const AzeriCase = TurkishCase;

/// CaseRanges is the table describing case mappings for all letters with non-self mappings.
pub const CaseRanges = [_]CaseRange{
    .{ .low = 0x0041, .high = 0x005A, .delta = d{ 0, 32, 0 } },
    .{ .low = 0x0061, .high = 0x007A, .delta = d{ -32, 0, -32 } },
    .{ .low = 0x00B5, .high = 0x00B5, .delta = d{ 743, 0, 743 } },
    .{ .low = 0x00C0, .high = 0x00D6, .delta = d{ 0, 32, 0 } },
    .{ .low = 0x00D8, .high = 0x00DE, .delta = d{ 0, 32, 0 } },
    .{ .low = 0x00E0, .high = 0x00F6, .delta = d{ -32, 0, -32 } },
    .{ .low = 0x00F8, .high = 0x00FE, .delta = d{ -32, 0, -32 } },
    .{ .low = 0x00FF, .high = 0x00FF, .delta = d{ 121, 0, 121 } },
    .{ .low = 0x0100, .high = 0x012F, .delta = d{ upper_lower, upper_lower, upper_lower } },
    .{ .low = 0x0130, .high = 0x0130, .delta = d{ 0, -199, 0 } },
    .{ .low = 0x0131, .high = 0x0131, .delta = d{ -232, 0, -232 } },
    .{ .low = 0x0132, .high = 0x0137, .delta = d{ upper_lower, upper_lower, upper_lower } },
    .{ .low = 0x0139, .high = 0x0148, .delta = d{ upper_lower, upper_lower, upper_lower } },
    .{ .low = 0x014A, .high = 0x0177, .delta = d{ upper_lower, upper_lower, upper_lower } },
    .{ .low = 0x0178, .high = 0x0178, .delta = d{ 0, -121, 0 } },
    .{ .low = 0x0179, .high = 0x017E, .delta = d{ upper_lower, upper_lower, upper_lower } },
    .{ .low = 0x017F, .high = 0x017F, .delta = d{ -300, 0, -300 } },
    .{ .low = 0x0180, .high = 0x0180, .delta = d{ 195, 0, 195 } },
    .{ .low = 0x0181, .high = 0x0181, .delta = d{ 0, 210, 0 } },
    .{ .low = 0x0182, .high = 0x0185, .delta = d{ upper_lower, upper_lower, upper_lower } },
    .{ .low = 0x0186, .high = 0x0186, .delta = d{ 0, 206, 0 } },
    .{ .low = 0x0187, .high = 0x0188, .delta = d{ upper_lower, upper_lower, upper_lower } },
    .{ .low = 0x0189, .high = 0x018A, .delta = d{ 0, 205, 0 } },
    .{ .low = 0x018B, .high = 0x018C, .delta = d{ upper_lower, upper_lower, upper_lower } },
    .{ .low = 0x018E, .high = 0x018E, .delta = d{ 0, 79, 0 } },
    .{ .low = 0x018F, .high = 0x018F, .delta = d{ 0, 202, 0 } },
    .{ .low = 0x0190, .high = 0x0190, .delta = d{ 0, 203, 0 } },
    .{ .low = 0x0191, .high = 0x0192, .delta = d{ upper_lower, upper_lower, upper_lower } },
    .{ .low = 0x0193, .high = 0x0193, .delta = d{ 0, 205, 0 } },
    .{ .low = 0x0194, .high = 0x0194, .delta = d{ 0, 207, 0 } },
    .{ .low = 0x0195, .high = 0x0195, .delta = d{ 97, 0, 97 } },
    .{ .low = 0x0196, .high = 0x0196, .delta = d{ 0, 211, 0 } },
    .{ .low = 0x0197, .high = 0x0197, .delta = d{ 0, 209, 0 } },
    .{ .low = 0x0198, .high = 0x0199, .delta = d{ upper_lower, upper_lower, upper_lower } },
    .{ .low = 0x019A, .high = 0x019A, .delta = d{ 163, 0, 163 } },
    .{ .low = 0x019C, .high = 0x019C, .delta = d{ 0, 211, 0 } },
    .{ .low = 0x019D, .high = 0x019D, .delta = d{ 0, 213, 0 } },
    .{ .low = 0x019E, .high = 0x019E, .delta = d{ 130, 0, 130 } },
    .{ .low = 0x019F, .high = 0x019F, .delta = d{ 0, 214, 0 } },
    .{ .low = 0x01A0, .high = 0x01A5, .delta = d{ upper_lower, upper_lower, upper_lower } },
    .{ .low = 0x01A6, .high = 0x01A6, .delta = d{ 0, 218, 0 } },
    .{ .low = 0x01A7, .high = 0x01A8, .delta = d{ upper_lower, upper_lower, upper_lower } },
    .{ .low = 0x01A9, .high = 0x01A9, .delta = d{ 0, 218, 0 } },
    .{ .low = 0x01AC, .high = 0x01AD, .delta = d{ upper_lower, upper_lower, upper_lower } },
    .{ .low = 0x01AE, .high = 0x01AE, .delta = d{ 0, 218, 0 } },
    .{ .low = 0x01AF, .high = 0x01B0, .delta = d{ upper_lower, upper_lower, upper_lower } },
    .{ .low = 0x01B1, .high = 0x01B2, .delta = d{ 0, 217, 0 } },
    .{ .low = 0x01B3, .high = 0x01B6, .delta = d{ upper_lower, upper_lower, upper_lower } },
    .{ .low = 0x01B7, .high = 0x01B7, .delta = d{ 0, 219, 0 } },
    .{ .low = 0x01B8, .high = 0x01B9, .delta = d{ upper_lower, upper_lower, upper_lower } },
    .{ .low = 0x01BC, .high = 0x01BD, .delta = d{ upper_lower, upper_lower, upper_lower } },
    .{ .low = 0x01BF, .high = 0x01BF, .delta = d{ 56, 0, 56 } },
    .{ .low = 0x01C4, .high = 0x01C4, .delta = d{ 0, 2, 1 } },
    .{ .low = 0x01C5, .high = 0x01C5, .delta = d{ -1, 1, 0 } },
    .{ .low = 0x01C6, .high = 0x01C6, .delta = d{ -2, 0, -1 } },
    .{ .low = 0x01C7, .high = 0x01C7, .delta = d{ 0, 2, 1 } },
    .{ .low = 0x01C8, .high = 0x01C8, .delta = d{ -1, 1, 0 } },
    .{ .low = 0x01C9, .high = 0x01C9, .delta = d{ -2, 0, -1 } },
    .{ .low = 0x01CA, .high = 0x01CA, .delta = d{ 0, 2, 1 } },
    .{ .low = 0x01CB, .high = 0x01CB, .delta = d{ -1, 1, 0 } },
    .{ .low = 0x01CC, .high = 0x01CC, .delta = d{ -2, 0, -1 } },
    .{ .low = 0x01CD, .high = 0x01DC, .delta = d{ upper_lower, upper_lower, upper_lower } },
    .{ .low = 0x01DD, .high = 0x01DD, .delta = d{ -79, 0, -79 } },
    .{ .low = 0x01DE, .high = 0x01EF, .delta = d{ upper_lower, upper_lower, upper_lower } },
    .{ .low = 0x01F1, .high = 0x01F1, .delta = d{ 0, 2, 1 } },
    .{ .low = 0x01F2, .high = 0x01F2, .delta = d{ -1, 1, 0 } },
    .{ .low = 0x01F3, .high = 0x01F3, .delta = d{ -2, 0, -1 } },
    .{ .low = 0x01F4, .high = 0x01F5, .delta = d{ upper_lower, upper_lower, upper_lower } },
    .{ .low = 0x01F6, .high = 0x01F6, .delta = d{ 0, -97, 0 } },
    .{ .low = 0x01F7, .high = 0x01F7, .delta = d{ 0, -56, 0 } },
    .{ .low = 0x01F8, .high = 0x021F, .delta = d{ upper_lower, upper_lower, upper_lower } },
    .{ .low = 0x0220, .high = 0x0220, .delta = d{ 0, -130, 0 } },
    .{ .low = 0x0222, .high = 0x0233, .delta = d{ upper_lower, upper_lower, upper_lower } },
    .{ .low = 0x023A, .high = 0x023A, .delta = d{ 0, 10795, 0 } },
    .{ .low = 0x023B, .high = 0x023C, .delta = d{ upper_lower, upper_lower, upper_lower } },
    .{ .low = 0x023D, .high = 0x023D, .delta = d{ 0, -163, 0 } },
    .{ .low = 0x023E, .high = 0x023E, .delta = d{ 0, 10792, 0 } },
    .{ .low = 0x023F, .high = 0x0240, .delta = d{ 10815, 0, 10815 } },
    .{ .low = 0x0241, .high = 0x0242, .delta = d{ upper_lower, upper_lower, upper_lower } },
    .{ .low = 0x0243, .high = 0x0243, .delta = d{ 0, -195, 0 } },
    .{ .low = 0x0244, .high = 0x0244, .delta = d{ 0, 69, 0 } },
    .{ .low = 0x0245, .high = 0x0245, .delta = d{ 0, 71, 0 } },
    .{ .low = 0x0246, .high = 0x024F, .delta = d{ upper_lower, upper_lower, upper_lower } },
    .{ .low = 0x0250, .high = 0x0250, .delta = d{ 10783, 0, 10783 } },
    .{ .low = 0x0251, .high = 0x0251, .delta = d{ 10780, 0, 10780 } },
    .{ .low = 0x0252, .high = 0x0252, .delta = d{ 10782, 0, 10782 } },
    .{ .low = 0x0253, .high = 0x0253, .delta = d{ -210, 0, -210 } },
    .{ .low = 0x0254, .high = 0x0254, .delta = d{ -206, 0, -206 } },
    .{ .low = 0x0256, .high = 0x0257, .delta = d{ -205, 0, -205 } },
    .{ .low = 0x0259, .high = 0x0259, .delta = d{ -202, 0, -202 } },
    .{ .low = 0x025B, .high = 0x025B, .delta = d{ -203, 0, -203 } },
    .{ .low = 0x025C, .high = 0x025C, .delta = d{ 42319, 0, 42319 } },
    .{ .low = 0x0260, .high = 0x0260, .delta = d{ -205, 0, -205 } },
    .{ .low = 0x0261, .high = 0x0261, .delta = d{ 42315, 0, 42315 } },
    .{ .low = 0x0263, .high = 0x0263, .delta = d{ -207, 0, -207 } },
    .{ .low = 0x0265, .high = 0x0265, .delta = d{ 42280, 0, 42280 } },
    .{ .low = 0x0266, .high = 0x0266, .delta = d{ 42308, 0, 42308 } },
    .{ .low = 0x0268, .high = 0x0268, .delta = d{ -209, 0, -209 } },
    .{ .low = 0x0269, .high = 0x0269, .delta = d{ -211, 0, -211 } },
    .{ .low = 0x026A, .high = 0x026A, .delta = d{ 42308, 0, 42308 } },
    .{ .low = 0x026B, .high = 0x026B, .delta = d{ 10743, 0, 10743 } },
    .{ .low = 0x026C, .high = 0x026C, .delta = d{ 42305, 0, 42305 } },
    .{ .low = 0x026F, .high = 0x026F, .delta = d{ -211, 0, -211 } },
    .{ .low = 0x0271, .high = 0x0271, .delta = d{ 10749, 0, 10749 } },
    .{ .low = 0x0272, .high = 0x0272, .delta = d{ -213, 0, -213 } },
    .{ .low = 0x0275, .high = 0x0275, .delta = d{ -214, 0, -214 } },
    .{ .low = 0x027D, .high = 0x027D, .delta = d{ 10727, 0, 10727 } },
    .{ .low = 0x0280, .high = 0x0280, .delta = d{ -218, 0, -218 } },
    .{ .low = 0x0282, .high = 0x0282, .delta = d{ 42307, 0, 42307 } },
    .{ .low = 0x0283, .high = 0x0283, .delta = d{ -218, 0, -218 } },
    .{ .low = 0x0287, .high = 0x0287, .delta = d{ 42282, 0, 42282 } },
    .{ .low = 0x0288, .high = 0x0288, .delta = d{ -218, 0, -218 } },
    .{ .low = 0x0289, .high = 0x0289, .delta = d{ -69, 0, -69 } },
    .{ .low = 0x028A, .high = 0x028B, .delta = d{ -217, 0, -217 } },
    .{ .low = 0x028C, .high = 0x028C, .delta = d{ -71, 0, -71 } },
    .{ .low = 0x0292, .high = 0x0292, .delta = d{ -219, 0, -219 } },
    .{ .low = 0x029D, .high = 0x029D, .delta = d{ 42261, 0, 42261 } },
    .{ .low = 0x029E, .high = 0x029E, .delta = d{ 42258, 0, 42258 } },
    .{ .low = 0x0345, .high = 0x0345, .delta = d{ 84, 0, 84 } },
    .{ .low = 0x0370, .high = 0x0373, .delta = d{ upper_lower, upper_lower, upper_lower } },
    .{ .low = 0x0376, .high = 0x0377, .delta = d{ upper_lower, upper_lower, upper_lower } },
    .{ .low = 0x037B, .high = 0x037D, .delta = d{ 130, 0, 130 } },
    .{ .low = 0x037F, .high = 0x037F, .delta = d{ 0, 116, 0 } },
    .{ .low = 0x0386, .high = 0x0386, .delta = d{ 0, 38, 0 } },
    .{ .low = 0x0388, .high = 0x038A, .delta = d{ 0, 37, 0 } },
    .{ .low = 0x038C, .high = 0x038C, .delta = d{ 0, 64, 0 } },
    .{ .low = 0x038E, .high = 0x038F, .delta = d{ 0, 63, 0 } },
    .{ .low = 0x0391, .high = 0x03A1, .delta = d{ 0, 32, 0 } },
    .{ .low = 0x03A3, .high = 0x03AB, .delta = d{ 0, 32, 0 } },
    .{ .low = 0x03AC, .high = 0x03AC, .delta = d{ -38, 0, -38 } },
    .{ .low = 0x03AD, .high = 0x03AF, .delta = d{ -37, 0, -37 } },
    .{ .low = 0x03B1, .high = 0x03C1, .delta = d{ -32, 0, -32 } },
    .{ .low = 0x03C2, .high = 0x03C2, .delta = d{ -31, 0, -31 } },
    .{ .low = 0x03C3, .high = 0x03CB, .delta = d{ -32, 0, -32 } },
    .{ .low = 0x03CC, .high = 0x03CC, .delta = d{ -64, 0, -64 } },
    .{ .low = 0x03CD, .high = 0x03CE, .delta = d{ -63, 0, -63 } },
    .{ .low = 0x03CF, .high = 0x03CF, .delta = d{ 0, 8, 0 } },
    .{ .low = 0x03D0, .high = 0x03D0, .delta = d{ -62, 0, -62 } },
    .{ .low = 0x03D1, .high = 0x03D1, .delta = d{ -57, 0, -57 } },
    .{ .low = 0x03D5, .high = 0x03D5, .delta = d{ -47, 0, -47 } },
    .{ .low = 0x03D6, .high = 0x03D6, .delta = d{ -54, 0, -54 } },
    .{ .low = 0x03D7, .high = 0x03D7, .delta = d{ -8, 0, -8 } },
    .{ .low = 0x03D8, .high = 0x03EF, .delta = d{ upper_lower, upper_lower, upper_lower } },
    .{ .low = 0x03F0, .high = 0x03F0, .delta = d{ -86, 0, -86 } },
    .{ .low = 0x03F1, .high = 0x03F1, .delta = d{ -80, 0, -80 } },
    .{ .low = 0x03F2, .high = 0x03F2, .delta = d{ 7, 0, 7 } },
    .{ .low = 0x03F3, .high = 0x03F3, .delta = d{ -116, 0, -116 } },
    .{ .low = 0x03F4, .high = 0x03F4, .delta = d{ 0, -60, 0 } },
    .{ .low = 0x03F5, .high = 0x03F5, .delta = d{ -96, 0, -96 } },
    .{ .low = 0x03F7, .high = 0x03F8, .delta = d{ upper_lower, upper_lower, upper_lower } },
    .{ .low = 0x03F9, .high = 0x03F9, .delta = d{ 0, -7, 0 } },
    .{ .low = 0x03FA, .high = 0x03FB, .delta = d{ upper_lower, upper_lower, upper_lower } },
    .{ .low = 0x03FD, .high = 0x03FF, .delta = d{ 0, -130, 0 } },
    .{ .low = 0x0400, .high = 0x040F, .delta = d{ 0, 80, 0 } },
    .{ .low = 0x0410, .high = 0x042F, .delta = d{ 0, 32, 0 } },
    .{ .low = 0x0430, .high = 0x044F, .delta = d{ -32, 0, -32 } },
    .{ .low = 0x0450, .high = 0x045F, .delta = d{ -80, 0, -80 } },
    .{ .low = 0x0460, .high = 0x0481, .delta = d{ upper_lower, upper_lower, upper_lower } },
    .{ .low = 0x048A, .high = 0x04BF, .delta = d{ upper_lower, upper_lower, upper_lower } },
    .{ .low = 0x04C0, .high = 0x04C0, .delta = d{ 0, 15, 0 } },
    .{ .low = 0x04C1, .high = 0x04CE, .delta = d{ upper_lower, upper_lower, upper_lower } },
    .{ .low = 0x04CF, .high = 0x04CF, .delta = d{ -15, 0, -15 } },
    .{ .low = 0x04D0, .high = 0x052F, .delta = d{ upper_lower, upper_lower, upper_lower } },
    .{ .low = 0x0531, .high = 0x0556, .delta = d{ 0, 48, 0 } },
    .{ .low = 0x0561, .high = 0x0586, .delta = d{ -48, 0, -48 } },
    .{ .low = 0x10A0, .high = 0x10C5, .delta = d{ 0, 7264, 0 } },
    .{ .low = 0x10C7, .high = 0x10C7, .delta = d{ 0, 7264, 0 } },
    .{ .low = 0x10CD, .high = 0x10CD, .delta = d{ 0, 7264, 0 } },
    .{ .low = 0x10D0, .high = 0x10FA, .delta = d{ 3008, 0, 0 } },
    .{ .low = 0x10FD, .high = 0x10FF, .delta = d{ 3008, 0, 0 } },
    .{ .low = 0x13A0, .high = 0x13EF, .delta = d{ 0, 38864, 0 } },
    .{ .low = 0x13F0, .high = 0x13F5, .delta = d{ 0, 8, 0 } },
    .{ .low = 0x13F8, .high = 0x13FD, .delta = d{ -8, 0, -8 } },
    .{ .low = 0x1C80, .high = 0x1C80, .delta = d{ -6254, 0, -6254 } },
    .{ .low = 0x1C81, .high = 0x1C81, .delta = d{ -6253, 0, -6253 } },
    .{ .low = 0x1C82, .high = 0x1C82, .delta = d{ -6244, 0, -6244 } },
    .{ .low = 0x1C83, .high = 0x1C84, .delta = d{ -6242, 0, -6242 } },
    .{ .low = 0x1C85, .high = 0x1C85, .delta = d{ -6243, 0, -6243 } },
    .{ .low = 0x1C86, .high = 0x1C86, .delta = d{ -6236, 0, -6236 } },
    .{ .low = 0x1C87, .high = 0x1C87, .delta = d{ -6181, 0, -6181 } },
    .{ .low = 0x1C88, .high = 0x1C88, .delta = d{ 35266, 0, 35266 } },
    .{ .low = 0x1C90, .high = 0x1CBA, .delta = d{ 0, -3008, 0 } },
    .{ .low = 0x1CBD, .high = 0x1CBF, .delta = d{ 0, -3008, 0 } },
    .{ .low = 0x1D79, .high = 0x1D79, .delta = d{ 35332, 0, 35332 } },
    .{ .low = 0x1D7D, .high = 0x1D7D, .delta = d{ 3814, 0, 3814 } },
    .{ .low = 0x1D8E, .high = 0x1D8E, .delta = d{ 35384, 0, 35384 } },
    .{ .low = 0x1E00, .high = 0x1E95, .delta = d{ upper_lower, upper_lower, upper_lower } },
    .{ .low = 0x1E9B, .high = 0x1E9B, .delta = d{ -59, 0, -59 } },
    .{ .low = 0x1E9E, .high = 0x1E9E, .delta = d{ 0, -7615, 0 } },
    .{ .low = 0x1EA0, .high = 0x1EFF, .delta = d{ upper_lower, upper_lower, upper_lower } },
    .{ .low = 0x1F00, .high = 0x1F07, .delta = d{ 8, 0, 8 } },
    .{ .low = 0x1F08, .high = 0x1F0F, .delta = d{ 0, -8, 0 } },
    .{ .low = 0x1F10, .high = 0x1F15, .delta = d{ 8, 0, 8 } },
    .{ .low = 0x1F18, .high = 0x1F1D, .delta = d{ 0, -8, 0 } },
    .{ .low = 0x1F20, .high = 0x1F27, .delta = d{ 8, 0, 8 } },
    .{ .low = 0x1F28, .high = 0x1F2F, .delta = d{ 0, -8, 0 } },
    .{ .low = 0x1F30, .high = 0x1F37, .delta = d{ 8, 0, 8 } },
    .{ .low = 0x1F38, .high = 0x1F3F, .delta = d{ 0, -8, 0 } },
    .{ .low = 0x1F40, .high = 0x1F45, .delta = d{ 8, 0, 8 } },
    .{ .low = 0x1F48, .high = 0x1F4D, .delta = d{ 0, -8, 0 } },
    .{ .low = 0x1F51, .high = 0x1F51, .delta = d{ 8, 0, 8 } },
    .{ .low = 0x1F53, .high = 0x1F53, .delta = d{ 8, 0, 8 } },
    .{ .low = 0x1F55, .high = 0x1F55, .delta = d{ 8, 0, 8 } },
    .{ .low = 0x1F57, .high = 0x1F57, .delta = d{ 8, 0, 8 } },
    .{ .low = 0x1F59, .high = 0x1F59, .delta = d{ 0, -8, 0 } },
    .{ .low = 0x1F5B, .high = 0x1F5B, .delta = d{ 0, -8, 0 } },
    .{ .low = 0x1F5D, .high = 0x1F5D, .delta = d{ 0, -8, 0 } },
    .{ .low = 0x1F5F, .high = 0x1F5F, .delta = d{ 0, -8, 0 } },
    .{ .low = 0x1F60, .high = 0x1F67, .delta = d{ 8, 0, 8 } },
    .{ .low = 0x1F68, .high = 0x1F6F, .delta = d{ 0, -8, 0 } },
    .{ .low = 0x1F70, .high = 0x1F71, .delta = d{ 74, 0, 74 } },
    .{ .low = 0x1F72, .high = 0x1F75, .delta = d{ 86, 0, 86 } },
    .{ .low = 0x1F76, .high = 0x1F77, .delta = d{ 100, 0, 100 } },
    .{ .low = 0x1F78, .high = 0x1F79, .delta = d{ 128, 0, 128 } },
    .{ .low = 0x1F7A, .high = 0x1F7B, .delta = d{ 112, 0, 112 } },
    .{ .low = 0x1F7C, .high = 0x1F7D, .delta = d{ 126, 0, 126 } },
    .{ .low = 0x1F80, .high = 0x1F87, .delta = d{ 8, 0, 8 } },
    .{ .low = 0x1F88, .high = 0x1F8F, .delta = d{ 0, -8, 0 } },
    .{ .low = 0x1F90, .high = 0x1F97, .delta = d{ 8, 0, 8 } },
    .{ .low = 0x1F98, .high = 0x1F9F, .delta = d{ 0, -8, 0 } },
    .{ .low = 0x1FA0, .high = 0x1FA7, .delta = d{ 8, 0, 8 } },
    .{ .low = 0x1FA8, .high = 0x1FAF, .delta = d{ 0, -8, 0 } },
    .{ .low = 0x1FB0, .high = 0x1FB1, .delta = d{ 8, 0, 8 } },
    .{ .low = 0x1FB3, .high = 0x1FB3, .delta = d{ 9, 0, 9 } },
    .{ .low = 0x1FB8, .high = 0x1FB9, .delta = d{ 0, -8, 0 } },
    .{ .low = 0x1FBA, .high = 0x1FBB, .delta = d{ 0, -74, 0 } },
    .{ .low = 0x1FBC, .high = 0x1FBC, .delta = d{ 0, -9, 0 } },
    .{ .low = 0x1FBE, .high = 0x1FBE, .delta = d{ -7205, 0, -7205 } },
    .{ .low = 0x1FC3, .high = 0x1FC3, .delta = d{ 9, 0, 9 } },
    .{ .low = 0x1FC8, .high = 0x1FCB, .delta = d{ 0, -86, 0 } },
    .{ .low = 0x1FCC, .high = 0x1FCC, .delta = d{ 0, -9, 0 } },
    .{ .low = 0x1FD0, .high = 0x1FD1, .delta = d{ 8, 0, 8 } },
    .{ .low = 0x1FD8, .high = 0x1FD9, .delta = d{ 0, -8, 0 } },
    .{ .low = 0x1FDA, .high = 0x1FDB, .delta = d{ 0, -100, 0 } },
    .{ .low = 0x1FE0, .high = 0x1FE1, .delta = d{ 8, 0, 8 } },
    .{ .low = 0x1FE5, .high = 0x1FE5, .delta = d{ 7, 0, 7 } },
    .{ .low = 0x1FE8, .high = 0x1FE9, .delta = d{ 0, -8, 0 } },
    .{ .low = 0x1FEA, .high = 0x1FEB, .delta = d{ 0, -112, 0 } },
    .{ .low = 0x1FEC, .high = 0x1FEC, .delta = d{ 0, -7, 0 } },
    .{ .low = 0x1FF3, .high = 0x1FF3, .delta = d{ 9, 0, 9 } },
    .{ .low = 0x1FF8, .high = 0x1FF9, .delta = d{ 0, -128, 0 } },
    .{ .low = 0x1FFA, .high = 0x1FFB, .delta = d{ 0, -126, 0 } },
    .{ .low = 0x1FFC, .high = 0x1FFC, .delta = d{ 0, -9, 0 } },
    .{ .low = 0x2126, .high = 0x2126, .delta = d{ 0, -7517, 0 } },
    .{ .low = 0x212A, .high = 0x212A, .delta = d{ 0, -8383, 0 } },
    .{ .low = 0x212B, .high = 0x212B, .delta = d{ 0, -8262, 0 } },
    .{ .low = 0x2132, .high = 0x2132, .delta = d{ 0, 28, 0 } },
    .{ .low = 0x214E, .high = 0x214E, .delta = d{ -28, 0, -28 } },
    .{ .low = 0x2160, .high = 0x216F, .delta = d{ 0, 16, 0 } },
    .{ .low = 0x2170, .high = 0x217F, .delta = d{ -16, 0, -16 } },
    .{ .low = 0x2183, .high = 0x2184, .delta = d{ upper_lower, upper_lower, upper_lower } },
    .{ .low = 0x24B6, .high = 0x24CF, .delta = d{ 0, 26, 0 } },
    .{ .low = 0x24D0, .high = 0x24E9, .delta = d{ -26, 0, -26 } },
    .{ .low = 0x2C00, .high = 0x2C2E, .delta = d{ 0, 48, 0 } },
    .{ .low = 0x2C30, .high = 0x2C5E, .delta = d{ -48, 0, -48 } },
    .{ .low = 0x2C60, .high = 0x2C61, .delta = d{ upper_lower, upper_lower, upper_lower } },
    .{ .low = 0x2C62, .high = 0x2C62, .delta = d{ 0, -10743, 0 } },
    .{ .low = 0x2C63, .high = 0x2C63, .delta = d{ 0, -3814, 0 } },
    .{ .low = 0x2C64, .high = 0x2C64, .delta = d{ 0, -10727, 0 } },
    .{ .low = 0x2C65, .high = 0x2C65, .delta = d{ -10795, 0, -10795 } },
    .{ .low = 0x2C66, .high = 0x2C66, .delta = d{ -10792, 0, -10792 } },
    .{ .low = 0x2C67, .high = 0x2C6C, .delta = d{ upper_lower, upper_lower, upper_lower } },
    .{ .low = 0x2C6D, .high = 0x2C6D, .delta = d{ 0, -10780, 0 } },
    .{ .low = 0x2C6E, .high = 0x2C6E, .delta = d{ 0, -10749, 0 } },
    .{ .low = 0x2C6F, .high = 0x2C6F, .delta = d{ 0, -10783, 0 } },
    .{ .low = 0x2C70, .high = 0x2C70, .delta = d{ 0, -10782, 0 } },
    .{ .low = 0x2C72, .high = 0x2C73, .delta = d{ upper_lower, upper_lower, upper_lower } },
    .{ .low = 0x2C75, .high = 0x2C76, .delta = d{ upper_lower, upper_lower, upper_lower } },
    .{ .low = 0x2C7E, .high = 0x2C7F, .delta = d{ 0, -10815, 0 } },
    .{ .low = 0x2C80, .high = 0x2CE3, .delta = d{ upper_lower, upper_lower, upper_lower } },
    .{ .low = 0x2CEB, .high = 0x2CEE, .delta = d{ upper_lower, upper_lower, upper_lower } },
    .{ .low = 0x2CF2, .high = 0x2CF3, .delta = d{ upper_lower, upper_lower, upper_lower } },
    .{ .low = 0x2D00, .high = 0x2D25, .delta = d{ -7264, 0, -7264 } },
    .{ .low = 0x2D27, .high = 0x2D27, .delta = d{ -7264, 0, -7264 } },
    .{ .low = 0x2D2D, .high = 0x2D2D, .delta = d{ -7264, 0, -7264 } },
    .{ .low = 0xA640, .high = 0xA66D, .delta = d{ upper_lower, upper_lower, upper_lower } },
    .{ .low = 0xA680, .high = 0xA69B, .delta = d{ upper_lower, upper_lower, upper_lower } },
    .{ .low = 0xA722, .high = 0xA72F, .delta = d{ upper_lower, upper_lower, upper_lower } },
    .{ .low = 0xA732, .high = 0xA76F, .delta = d{ upper_lower, upper_lower, upper_lower } },
    .{ .low = 0xA779, .high = 0xA77C, .delta = d{ upper_lower, upper_lower, upper_lower } },
    .{ .low = 0xA77D, .high = 0xA77D, .delta = d{ 0, -35332, 0 } },
    .{ .low = 0xA77E, .high = 0xA787, .delta = d{ upper_lower, upper_lower, upper_lower } },
    .{ .low = 0xA78B, .high = 0xA78C, .delta = d{ upper_lower, upper_lower, upper_lower } },
    .{ .low = 0xA78D, .high = 0xA78D, .delta = d{ 0, -42280, 0 } },
    .{ .low = 0xA790, .high = 0xA793, .delta = d{ upper_lower, upper_lower, upper_lower } },
    .{ .low = 0xA794, .high = 0xA794, .delta = d{ 48, 0, 48 } },
    .{ .low = 0xA796, .high = 0xA7A9, .delta = d{ upper_lower, upper_lower, upper_lower } },
    .{ .low = 0xA7AA, .high = 0xA7AA, .delta = d{ 0, -42308, 0 } },
    .{ .low = 0xA7AB, .high = 0xA7AB, .delta = d{ 0, -42319, 0 } },
    .{ .low = 0xA7AC, .high = 0xA7AC, .delta = d{ 0, -42315, 0 } },
    .{ .low = 0xA7AD, .high = 0xA7AD, .delta = d{ 0, -42305, 0 } },
    .{ .low = 0xA7AE, .high = 0xA7AE, .delta = d{ 0, -42308, 0 } },
    .{ .low = 0xA7B0, .high = 0xA7B0, .delta = d{ 0, -42258, 0 } },
    .{ .low = 0xA7B1, .high = 0xA7B1, .delta = d{ 0, -42282, 0 } },
    .{ .low = 0xA7B2, .high = 0xA7B2, .delta = d{ 0, -42261, 0 } },
    .{ .low = 0xA7B3, .high = 0xA7B3, .delta = d{ 0, 928, 0 } },
    .{ .low = 0xA7B4, .high = 0xA7BF, .delta = d{ upper_lower, upper_lower, upper_lower } },
    .{ .low = 0xA7C2, .high = 0xA7C3, .delta = d{ upper_lower, upper_lower, upper_lower } },
    .{ .low = 0xA7C4, .high = 0xA7C4, .delta = d{ 0, -48, 0 } },
    .{ .low = 0xA7C5, .high = 0xA7C5, .delta = d{ 0, -42307, 0 } },
    .{ .low = 0xA7C6, .high = 0xA7C6, .delta = d{ 0, -35384, 0 } },
    .{ .low = 0xA7C7, .high = 0xA7CA, .delta = d{ upper_lower, upper_lower, upper_lower } },
    .{ .low = 0xA7F5, .high = 0xA7F6, .delta = d{ upper_lower, upper_lower, upper_lower } },
    .{ .low = 0xAB53, .high = 0xAB53, .delta = d{ -928, 0, -928 } },
    .{ .low = 0xAB70, .high = 0xABBF, .delta = d{ -38864, 0, -38864 } },
    .{ .low = 0xFF21, .high = 0xFF3A, .delta = d{ 0, 32, 0 } },
    .{ .low = 0xFF41, .high = 0xFF5A, .delta = d{ -32, 0, -32 } },
    .{ .low = 0x10400, .high = 0x10427, .delta = d{ 0, 40, 0 } },
    .{ .low = 0x10428, .high = 0x1044F, .delta = d{ -40, 0, -40 } },
    .{ .low = 0x104B0, .high = 0x104D3, .delta = d{ 0, 40, 0 } },
    .{ .low = 0x104D8, .high = 0x104FB, .delta = d{ -40, 0, -40 } },
    .{ .low = 0x10C80, .high = 0x10CB2, .delta = d{ 0, 64, 0 } },
    .{ .low = 0x10CC0, .high = 0x10CF2, .delta = d{ -64, 0, -64 } },
    .{ .low = 0x118A0, .high = 0x118BF, .delta = d{ 0, 32, 0 } },
    .{ .low = 0x118C0, .high = 0x118DF, .delta = d{ -32, 0, -32 } },
    .{ .low = 0x16E40, .high = 0x16E5F, .delta = d{ 0, 32, 0 } },
    .{ .low = 0x16E60, .high = 0x16E7F, .delta = d{ -32, 0, -32 } },
    .{ .low = 0x1E900, .high = 0x1E921, .delta = d{ 0, 34, 0 } },
    .{ .low = 0x1E922, .high = 0x1E943, .delta = d{ -34, 0, -34 } },
};

pub const ascii_fold = [max_ascii + 1]u16{
    0x0000,
    0x0001,
    0x0002,
    0x0003,
    0x0004,
    0x0005,
    0x0006,
    0x0007,
    0x0008,
    0x0009,
    0x000A,
    0x000B,
    0x000C,
    0x000D,
    0x000E,
    0x000F,
    0x0010,
    0x0011,
    0x0012,
    0x0013,
    0x0014,
    0x0015,
    0x0016,
    0x0017,
    0x0018,
    0x0019,
    0x001A,
    0x001B,
    0x001C,
    0x001D,
    0x001E,
    0x001F,
    0x0020,
    0x0021,
    0x0022,
    0x0023,
    0x0024,
    0x0025,
    0x0026,
    0x0027,
    0x0028,
    0x0029,
    0x002A,
    0x002B,
    0x002C,
    0x002D,
    0x002E,
    0x002F,
    0x0030,
    0x0031,
    0x0032,
    0x0033,
    0x0034,
    0x0035,
    0x0036,
    0x0037,
    0x0038,
    0x0039,
    0x003A,
    0x003B,
    0x003C,
    0x003D,
    0x003E,
    0x003F,
    0x0040,
    0x0061,
    0x0062,
    0x0063,
    0x0064,
    0x0065,
    0x0066,
    0x0067,
    0x0068,
    0x0069,
    0x006A,
    0x006B,
    0x006C,
    0x006D,
    0x006E,
    0x006F,
    0x0070,
    0x0071,
    0x0072,
    0x0073,
    0x0074,
    0x0075,
    0x0076,
    0x0077,
    0x0078,
    0x0079,
    0x007A,
    0x005B,
    0x005C,
    0x005D,
    0x005E,
    0x005F,
    0x0060,
    0x0041,
    0x0042,
    0x0043,
    0x0044,
    0x0045,
    0x0046,
    0x0047,
    0x0048,
    0x0049,
    0x004A,
    0x212A,
    0x004C,
    0x004D,
    0x004E,
    0x004F,
    0x0050,
    0x0051,
    0x0052,
    0x017F,
    0x0054,
    0x0055,
    0x0056,
    0x0057,
    0x0058,
    0x0059,
    0x005A,
    0x007B,
    0x007C,
    0x007D,
    0x007E,
    0x007F,
};

/// FoldCategory maps a category name to a table of
/// code points outside the category that are equivalent under
/// simple case folding to code points inside the category.
/// If there is no entry for a category name, there are no such points.
pub const FoldCategory = enum {
    L,
    Ll,
    Lt,
    Lu,
    M,
    Mn,
};

/// FoldScript maps a script name to a table of
/// code points outside the script that are equivalent under
/// simple case folding to code points inside the script.
/// If there is no entry for a script name, there are no such points.
pub const FoldScript = enum {
    Common,
    Greek,
    Inherited,
};

pub const fold_script_tables = [_]RangeTable{
    RangeTable{
        .r16 = &[_]Range16{
            .{ 0x039c, 0x03bc, 32 },
        },
    },
    RangeTable{
        .r16 = &[_]Range16{
            .{ 0x00b5, 0x0345, 656 },
        },
    },
    RangeTable{
        .r16 = &[_]Range16{
            .{ 0x0399, 0x03b9, 32 },
            .{ 0x1fbe, 0x1fbe, 1 },
        },
    },
};
