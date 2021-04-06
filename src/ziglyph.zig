//! Ziglyph provides Unicode processing in Zig.
//! To minimize memory requirements and binary size, this library is divided into component structs
//! that provide specific pieces of functionality. For a consolidated struct with the most frequently
//! used functionality, see the Ziglyph struct below.

const std = @import("std");
const ascii = @import("ascii.zig"); // Pending std.ascii fix.
const mem = std.mem;

/// Alphabetic code points.
pub const Alpha = @import("components/Alpha.zig");
/// Cased code points are either lower, upper, or title cased, but not all three.
pub const Cased = @import("components/Cased.zig");
/// Code point case folding.
pub const CaseFoldMap = @import("components/CaseFoldMap.zig");
/// Control code points like form feed.
pub const Control = @import("components/Control.zig");
/// Decimal code points.
pub const Decimal = @import("components/Decimal.zig");
/// Digit code points.
pub const Digit = @import("components/Digit.zig");
/// Code point decomposition.
pub const DecomposeMap = @import("components/DecomposeMap.zig");
/// Format control characters.
pub const Format = @import("components/Format.zig");
/// Unicode letters.
pub const Letter = @import("components/Letter.zig");
/// Lowercase letters.
pub const Lower = @import("components/Lower.zig");
/// Marks from different alphabets.
pub const Mark = @import("components/Mark.zig");
/// Unicode numbers.
pub const Number = @import("components/Number.zig");
/// Punctuation code points.
pub const Punct = @import("components/Punct.zig");
/// Unicode space code points.
pub const Space = @import("components/Space.zig");
/// All sorts of symbols.
pub const Symbol = @import("components/Symbol.zig");
/// Titlecase letters.
pub const Title = @import("components/Title.zig");
/// Uppercase letters.
pub const Upper = @import("components/Upper.zig");
/// Unassigned code points.
pub const Unassigned = @import("components/Unassigned.zig");

/// Mapping to lowercase.
pub const LowerMap = @import("components/LowerMap.zig");
/// Mapping to titlecase.
pub const TitleMap = @import("components/TitleMap.zig");
/// Mapping to uppercase.
pub const UpperMap = @import("components/UpperMap.zig");

/// Ziglyph consolidates all the major Unicode utility functions in one place. Because these functions
/// each consume memory for their respective code point data, this struct performs lazy initialization
/// to only consume memory when needed.
pub const Ziglyph = struct {
    allocator: *mem.Allocator,
    alpha: ?Alpha = null,
    control: ?Control = null,
    decimal: ?Decimal = null,
    digit: ?Digit = null,
    letter: ?Letter = null,
    lower: ?Lower = null,
    lower_map: ?LowerMap = null,
    mark: ?Mark = null,
    number: ?Number = null,
    punct: ?Punct = null,
    space: ?Space = null,
    symbol: ?Symbol = null,
    title: ?Title = null,
    title_map: ?TitleMap = null,
    upper: ?Upper = null,
    upper_map: ?UpperMap = null,

    pub fn init(allocator: *mem.Allocator) !Ziglyph {
        return Ziglyph{
            .allocator = allocator,
        };
    }

    const Self = @This();

    pub fn deinit(self: *Self) void {
        if (self.alpha) |*alpha| {
            alpha.deinit();
        }
        if (self.decimal) |*decimal| {
            decimal.deinit();
        }
        if (self.digit) |*digit| {
            digit.deinit();
        }
        if (self.control) |*control| {
            control.deinit();
        }
        if (self.letter) |*letter| {
            letter.deinit();
        }
        if (self.lower) |*lower| {
            lower.deinit();
        }
        if (self.lower_map) |*lower_map| {
            lower_map.deinit();
        }
        if (self.mark) |*mark| {
            mark.deinit();
        }
        if (self.number) |*number| {
            number.deinit();
        }
        if (self.punct) |*punct| {
            punct.deinit();
        }
        if (self.space) |*space| {
            space.deinit();
        }
        if (self.symbol) |*symbol| {
            symbol.deinit();
        }
        if (self.title) |*title| {
            title.deinit();
        }
        if (self.title_map) |*title_map| {
            title_map.deinit();
        }
        if (self.upper) |*upper| {
            upper.deinit();
        }
        if (self.upper_map) |*upper_map| {
            upper_map.deinit();
        }
    }

    /// isAlpha detects if a code point is alphabetic.
    pub fn isAlpha(self: *Self, cp: u21) !bool {
        if (cp < 128) {
            return ascii.isAlpha(@intCast(u8, cp));
        }

        // Lazy init.
        if (self.alpha == null) {
            self.alpha = try Alpha.init(self.allocator);
        }

        return self.alpha.?.isAlpha(cp);
    }

    /// isAlphaNum covers all the Unicode alphabetic and number space, not just ASCII.
    pub fn isAlphaNum(self: *Self, cp: u21) !bool {
        if (cp < 128) {
            return ascii.isAlNum(@intCast(u8, cp));
        }

        // Lazy init.
        if (self.number == null) {
            self.number = try Number.init(self.allocator);
        }

        return (try self.isAlpha(cp)) or self.number.?.isNumber(cp);
    }

    // isDecimal detects all Unicode digits.
    pub fn isDecimal(self: *Self, cp: u21) !bool {
        // Lazy init.
        if (self.decimal == null) {
            self.decimal = try Decimal.init(self.allocator);
        }

        return self.decimal.?.isDecimal(cp);
    }

    // isDigit detects all Unicode digits.
    pub fn isDigit(self: *Self, cp: u21) !bool {
        // ASCII optimization.
        if (cp < 128) {
            return ascii.isDigit(@intCast(u8, cp));
        }

        // Lazy init.
        if (self.digit == null) {
            self.digit = try Digit.init(self.allocator);
        }

        return self.digit.?.isDigit(cp);
    }

    /// isGraphic detects any code point that can be represented graphically, including spaces.
    pub fn isGraphic(self: *Self, cp: u21) !bool {
        // ASCII optimization.
        if (cp == ' ') return true;

        if (cp < 128) {
            return ascii.isGraph(@intCast(u8, cp));
        }

        // Lazy init.
        if (self.space == null) {
            self.space = try Space.init(self.allocator);
        }

        return (try self.isPrint(cp)) or self.space.?.isSpace(cp);
    }

    // isHex detects the 16 ASCII characters 0-9 A-F, and a-f.
    pub fn isHex(self: Self, cp: u21) bool {
        return ascii.isXDigit(@intCast(u8, cp));
    }

    /// isPrint detects any code point that can be printed, but not spaces.
    pub fn isPrint(self: *Self, cp: u21) !bool {
        // ASCII optimization.
        if (cp == ' ') return true;

        if (cp < 128) {
            return ascii.isPrint(@intCast(u8, cp));
        }

        // Lazy init.
        if (self.mark == null) {
            self.mark = try Mark.init(self.allocator);
        }
        if (self.punct == null) {
            self.punct = try Punct.init(self.allocator);
        }
        if (self.symbol == null) {
            self.symbol = try Symbol.init(self.allocator);
        }

        return (try self.isAlphaNum(cp)) or self.mark.?.isMark(cp) or self.punct.?.isPunct(cp) or self.symbol.?.isSymbol(cp);
    }

    /// isControl detects control code points such as form feeds.
    pub fn isControl(self: *Self, cp: u21) !bool {
        // ASCII optimization.
        if (cp < 128) {
            return ascii.isCntrl(@intCast(u8, cp));
        }

        // Lazy init.
        if (self.control == null) {
            self.control = try Control.init(self.allocator);
        }

        return self.control.?.isControl(cp);
    }

    /// isLetter covers all letters in Unicode, not just ASCII.
    pub fn isLetter(self: *Self, cp: u21) !bool {
        // ASCII optimization.
        if (cp < 128) {
            return ascii.isAlpha(@intCast(u8, cp));
        }

        // Lazy init.
        if (self.letter == null) {
            self.letter = try Letter.init(self.allocator);
        }

        return self.letter.?.isLetter(cp);
    }

    /// isLower detects code points that are lowercase.
    pub fn isLower(self: *Self, cp: u21) !bool {
        // ASCII optimization.
        if (cp < 128) {
            return ascii.isLower(@intCast(u8, cp));
        }

        // Lazy init.
        if (self.lower == null) {
            self.lower = try Lower.init(self.allocator);
        }

        return self.lower.?.isLower(cp);
    }

    /// isMark detects special code points that serve as marks in different alphabets.
    pub fn isMark(self: *Self, cp: u21) !bool {
        // Lazy init.
        if (self.mark == null) {
            self.mark = try Mark.init(self.allocator);
        }

        return self.mark.?.isMark(cp);
    }

    /// isNumber covers all Unicode numbers, not just ASII.
    pub fn isNumber(self: *Self, cp: u21) !bool {
        // ASCII optimization.
        if (cp < 128) {
            return ascii.isDigit(@intCast(u8, cp));
        }

        // Lazy init.
        if (self.number == null) {
            self.number = try Number.init(self.allocator);
        }

        return self.number.?.isNumber(cp);
    }

    /// isPunct detects punctuation characters. Note some punctuation maybe considered symbols by Unicode.
    pub fn isPunct(self: *Self, cp: u21) !bool {
        // ASCII optimization.
        if (cp < 128) {
            return ascii.isPunct(@intCast(u8, cp));
        }

        // Lazy init.
        if (self.punct == null) {
            self.punct = try Punct.init(self.allocator);
        }

        return self.punct.?.isPunct(cp);
    }

    /// isSpace adheres to the strict meaning of space as per Unicode, excluding some control characters
    /// such as tab \t.
    pub fn isSpace(self: *Self, cp: u21) !bool {
        // ASCII optimization.
        if (cp < 128) {
            return ascii.isSpace(@intCast(u8, cp));
        }

        // Lazy init.
        if (self.space == null) {
            self.space = try Space.init(self.allocator);
        }

        return self.space.?.isSpace(cp);
    }

    // isSymbol detects symbols which curiosly may include some code points commonly thought of as
    // punctuation.
    pub fn isSymbol(self: *Self, cp: u21) !bool {
        // ASCII optimization.
        if (cp < 128) {
            return ascii.isSymbol(@intCast(u8, cp));
        }

        // Lazy init.
        if (self.symbol == null) {
            self.symbol = try Symbol.init(self.allocator);
        }

        return self.symbol.?.isSymbol(cp);
    }

    /// isTitle detects code points in titlecase.
    pub fn isTitle(self: *Self, cp: u21) !bool {
        // Lazy init.
        if (self.title == null) {
            self.title = try Title.init(self.allocator);
        }

        return self.title.?.isTitle(cp);
    }

    /// isTitle detects code points in uppercase.
    pub fn isUpper(self: *Self, cp: u21) !bool {
        // ASCII optimization.
        if (cp < 128) {
            return ascii.isUpper(@intCast(u8, cp));
        }

        // Lazy init.
        if (self.upper == null) {
            self.upper = try Upper.init(self.allocator);
        }

        return self.upper.?.isUpper(cp);
    }

    /// toLower returns the lowercase code point for the given code point. It returns the same 
    /// code point given if no mapping exists.
    pub fn toLower(self: *Self, cp: u21) !u21 {
        // ASCII optimization.
        if (cp < 128) {
            return ascii.toLower(@intCast(u8, cp));
        }

        // Lazy init.
        if (self.lower_map == null) {
            self.lower_map = try LowerMap.init(self.allocator);
        }

        return self.lower_map.?.toLower(cp);
    }

    /// toTitle returns the titlecase code point for the given code point. It returns the same 
    /// code point given if no mapping exists.
    pub fn toTitle(self: *Self, cp: u21) !u21 {
        // Lazy init.
        if (self.title_map == null) {
            self.title_map = try TitleMap.init(self.allocator);
        }

        return self.title_map.?.toTitle(cp);
    }

    /// toUpper returns the uppercase code point for the given code point. It returns the same 
    /// code point given if no mapping exists.
    pub fn toUpper(self: *Self, cp: u21) !u21 {
        // Lazy init.
        if (self.upper_map == null) {
            self.upper_map = try UpperMap.init(self.allocator);
        }

        return self.upper_map.?.toUpper(cp);
    }

    // Self-contained methods.

    /// isCr checks for carriage return.
    pub fn isCr(self: Self, cp: u21) bool {
        return cp == 0x000D;
    }

    /// isDefIgnorable checks for Default_Ignorable_Code_Point.
    pub fn isDefIgnorable(self: Self, cp: u21) bool {
        const list = [_]u21{ 0x00AD, 0x034F, 0x061C, 0x180E, 0x2065, 0x3164, 0xFEFF, 0xFFA0, 0xE0000, 0xE0001 };
        for (list) |dicp| {
            if (cp == dicp) return true;
        }

        return (cp >= 0x115F and cp <= 0x1160) or
            (cp >= 0x17B4 and cp <= 0x17B5) or
            (cp >= 0x180B and cp <= 0x180D) or
            (cp >= 0x200B and cp <= 0x200F) or
            (cp >= 0x202A and cp <= 0x202E) or
            (cp >= 0x2060 and cp <= 0x2064) or
            (cp >= 0x2066 and cp <= 0x206F) or
            (cp >= 0xFE00 and cp <= 0xFE0F) or
            (cp >= 0xFFF0 and cp <= 0xFFF8) or
            (cp >= 0x1BCA0 and cp <= 0x1BCA3) or
            (cp >= 0x1D173 and cp <= 0x1D17A) or
            (cp >= 0xE0002 and cp <= 0xE001F) or
            (cp >= 0xE0020 and cp <= 0xE007F) or
            (cp >= 0xE0080 and cp <= 0xE00FF) or
            (cp >= 0xE0100 and cp <= 0xE01EF) or
            (cp >= 0xE01F0 and cp <= 0xE0FFF);
    }

    /// isEmojiMod checks for emoji modifierss.
    pub fn isEmojiMod(self: Self, cp: u21) bool {
        return cp >= 0x1F3FB and cp <= 0x1F3FF;
    }

    /// isLf checks for line feed.
    pub fn isLf(self: Self, cp: u21) bool {
        return cp == 0x000A;
    }

    /// isPrepend checks for Prepended_Concatenation_Mark
    pub fn isPrepend(self: Self, cp: u21) bool {
        const list = [_]u21{ 0x06DD, 0x070F, 0x08E2, 0x110BD, 0x110CD };
        for (list) |ppcp| {
            if (cp == ppcp) return true;
        }

        return cp >= 0x0600 and cp <= 0x0605;
    }

    /// isRi checks for regional indicators.
    pub fn isRi(self: Self, cp: u21) bool {
        return cp >= 0x1F1E6 and cp <= 0x1F1FF;
    }

    /// isZl checks for line separator.
    pub fn isZl(self: Self, cp: u21) bool {
        return cp == 0x2028;
    }

    /// isZp checks for paragraph separator.
    pub fn isZp(self: Self, cp: u21) bool {
        return cp == 0x2029;
    }

    /// isZwj checks for zero width joiner.
    pub fn isZwj(self: Self, cp: u21) bool {
        return cp == 0x200D;
    }

    /// isZwnj checks for zero width non-joiner.
    pub fn isZwnj(self: Self, cp: u21) bool {
        return cp == 0x200C;
    }
};
