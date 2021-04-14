const std = @import("std");
const mem = std.mem;
const ascii = @import("../../ascii.zig");

/// Case fold mappings.
pub const CaseFoldMap = @import("../autogen/CaseFolding/CaseFoldMap.zig");
const CaseFold = @import("../autogen/CaseFolding/CaseFoldMap.zig").CaseFold;
/// Cased code points are either lower, upper, or title cased, but not all three.
pub const Cased = @import("../autogen/DerivedCoreProperties/Cased.zig");
/// Lowercase
pub const Lower = @import("../autogen/DerivedGeneralCategory/LowercaseLetter.zig");
pub const LowerMap = @import("../autogen/UnicodeData/LowerMap.zig");
/// Modifier
pub const Modifier = @import("../autogen/DerivedGeneralCategory/ModifierLetter.zig");
/// Other
pub const Other = @import("../autogen/DerivedGeneralCategory/OtherLetter.zig");
/// Titlecase
pub const Title = @import("../autogen/DerivedGeneralCategory/TitlecaseLetter.zig");
pub const TitleMap = @import("../autogen/UnicodeData/TitleMap.zig");
/// Uppercase
pub const Upper = @import("../autogen/DerivedGeneralCategory/UppercaseLetter.zig");
pub const UpperMap = @import("../autogen/UnicodeData/UpperMap.zig");

const Self = @This();

allocator: *mem.Allocator,
cased: ?Cased = null,
fold_map: ?CaseFoldMap = null,
lower: ?Lower = null,
lower_map: ?LowerMap = null,
modifier: ?Modifier = null,
other: ?Other = null,
title: ?Title = null,
title_map: ?TitleMap = null,
upper: ?Upper = null,
upper_map: ?UpperMap = null,

pub fn init(allocator: *mem.Allocator) !Self {
    return Self{ .allocator = allocator };
}

pub fn deinit(self: *Self) void {
    if (self.cased) |*cased| cased.deinit();
    if (self.fold_map) |*fold_map| fold_map.deinit();
    if (self.lower) |*lower| lower.deinit();
    if (self.lower_map) |*lower_map| lower_map.deinit();
    if (self.modifier) |*modifier| modifier.deinit();
    if (self.other) |*other| other.deinit();
    if (self.title) |*title| title.deinit();
    if (self.title_map) |*title_map| title_map.deinit();
    if (self.upper) |*upper| upper.deinit();
    if (self.upper_map) |*upper_map| upper_map.deinit();
}

/// isCased detects cased letters.
pub fn isCased(self: *Self, cp: u21) !bool {
    // Lazy init.
    if (self.cased == null) self.cased = try Cased.init(self.allocator);
    return self.cased.?.isCased(cp);
}

/// isLetter covers all letters in Unicode, not just ASCII.
pub fn isLetter(self: *Self, cp: u21) !bool {
    // Lazy init.
    if (self.lower == null) self.lower = try Lower.init(self.allocator);
    if (self.modifier == null) self.modifier = try Modifier.init(self.allocator);
    if (self.other == null) self.other = try Other.init(self.allocator);
    if (self.title == null) self.title = try Title.init(self.allocator);
    if (self.upper == null) self.upper = try Upper.init(self.allocator);

    return self.lower.?.isLowercaseLetter(cp) or
        self.modifier.?.isModifierLetter(cp) or
        self.other.?.isOtherLetter(cp) or
        self.title.?.isTitlecaseLetter(cp) or
        self.upper.?.isUppercaseLetter(cp);
}

/// isAscii detects ASCII only letters.
pub fn isAscii(self: Self, cp: u21) bool {
    return if (cp < 128) ascii.isAlpha(@intCast(u8, cp)) else false;
}

/// isLower detects code points that are lowercase.
pub fn isLower(self: *Self, cp: u21) !bool {
    // Lazy init.
    if (self.lower == null) self.lower = try Lower.init(self.allocator);
    return self.lower.?.isLowercaseLetter(cp) or !(try self.isCased(cp));
}

/// isAsciiLower detects ASCII only lowercase letters.
pub fn isAsciiLower(self: Self, cp: u21) bool {
    return if (cp < 128) ascii.isLower(@intCast(u8, cp)) else false;
}

/// isTitle detects code points in titlecase.
pub fn isTitle(self: *Self, cp: u21) !bool {
    // Lazy init.
    if (self.title == null) self.title = try Title.init(self.allocator);
    return self.title.?.isTitlecaseLetter(cp) or !(try self.isCased(cp));
}

/// isUpper detects code points in uppercase.
pub fn isUpper(self: *Self, cp: u21) !bool {
    // Lazy init.
    if (self.upper == null) self.upper = try Upper.init(self.allocator);
    return self.upper.?.isUppercaseLetter(cp) or !(try self.isCased(cp));
}

/// isAsciiUpper detects ASCII only uppercase letters.
pub fn isAsciiUpper(self: Self, cp: u21) bool {
    return if (cp < 128) ascii.isUpper(@intCast(u8, cp)) else false;
}

/// toLower returns the lowercase code point for the given code point. It returns the same 
/// code point given if no mapping exists.
pub fn toLower(self: *Self, cp: u21) !u21 {
    // Only cased letters.
    if (!try self.isCased(cp)) return cp;
    // Lazy init.
    if (self.lower_map == null) self.lower_map = try LowerMap.init(self.allocator);
    return self.lower_map.?.toLower(cp);
}

/// toAsciiLower converts an ASCII letter to lowercase.
pub fn toAsciiLower(self: Self, cp: u21) u21 {
    return if (cp < 128) ascii.toLower(@intCast(u8, cp)) else cp;
}

/// toTitle returns the titlecase code point for the given code point. It returns the same 
/// code point given if no mapping exists.
pub fn toTitle(self: *Self, cp: u21) !u21 {
    // Only cased letters.
    if (!try self.isCased(cp)) return cp;
    // Lazy init.
    if (self.title_map == null) self.title_map = try TitleMap.init(self.allocator);
    return self.title_map.?.toTitle(cp);
}

/// toUpper returns the uppercase code point for the given code point. It returns the same 
/// code point given if no mapping exists.
pub fn toUpper(self: *Self, cp: u21) !u21 {
    // Only cased letters.
    if (!try self.isCased(cp)) return cp;
    // Lazy init.
    if (self.upper_map == null) self.upper_map = try UpperMap.init(self.allocator);
    return self.upper_map.?.toUpper(cp);
}

/// toAsciiUpper converts an ASCII letter to uppercase.
pub fn toAsciiUpper(self: Self, cp: u21) u21 {
    return if (cp < 128) ascii.toUpper(@intCast(u8, cp)) else false;
}

/// toCaseFold will convert a code point into its case folded equivalent. Note that this can result
/// in a mapping to more than one code point, known as the full case fold.
pub fn toCaseFold(self: *Self, cp: u21) !CaseFold {
    if (self.fold_map == null) self.fold_map = try CaseFoldMap.init(self.allocator);
    return self.fold_map.?.toCaseFold(cp);
}
