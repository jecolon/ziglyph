//! Ziglyph provides Unicode processing in Zig.
//! To minimize memory requirements and binary size, this library is divided into component structs
//! that provide specific pieces of functionality. For a consolidated struct with the most frequently
//! used functionality, see the Ziglyph struct below.

const std = @import("std");
const mem = std.mem;
const unicode = std.unicode;
const ascii = @import("ascii.zig");

/// Alphabeticbetic code points.
pub const Alphabetic = @import("components/autogen/DerivedCoreProperties/Alphabetic.zig");
/// Control code points like form feed.
pub const Control = @import("components/autogen/DerivedGeneralCategory/Control.zig");
/// Code point decomposition.
pub const DecomposeMap = @import("components/autogen/UnicodeData/DecomposeMap.zig");
/// Grapheme Clusters.
pub const GraphemeIterator = @import("zigstr/Zigstr.zig").GraphemeIterator;
/// Unicode letters.
pub const Letter = @import("components/aggregate/Letter.zig");
// Marks.
pub const Mark = @import("components/aggregate/Mark.zig");
// Numbers.
pub const Number = @import("components/aggregate/Number.zig");
// Punctuation.
pub const Punct = @import("components/aggregate/Punct.zig");
/// Spaces
pub const Space = @import("components/aggregate/Space.zig");
// Symbols
pub const Symbol = @import("components/aggregate/Symbol.zig");

/// Ziglyph consolidates all the major Unicode utility functions in one place. Because these functions
/// each consume memory for their respective code point data, this struct performs lazy initialization
/// to only consume memory when needed.
pub const Ziglyph = struct {
    allocator: *mem.Allocator,
    alpha: Alphabetic,
    control: Control,
    letter: Letter,
    mark: Mark,
    number: Number,
    punct: Punct,
    symbol: Symbol,
    space: Space,

    pub fn init(allocator: *mem.Allocator) !Ziglyph {
        return Ziglyph{
            .allocator = allocator,
            .alpha = try Alphabetic.init(allocator),
            .control = try Control.init(allocator),
            .letter = try Letter.init(allocator),
            .mark = try Mark.init(allocator),
            .number = try Number.init(allocator),
            .punct = try Punct.init(allocator),
            .symbol = try Symbol.init(allocator),
            .space = try Space.init(allocator),
        };
    }

    const Self = @This();

    pub fn deinit(self: *Self) void {
        self.alpha.deinit();
        self.control.deinit();
        self.letter.deinit();
        self.mark.deinit();
        self.number.deinit();
        self.punct.deinit();
        self.space.deinit();
        self.symbol.deinit();
    }

    /// isAlphabetic detects if a code point is alphabetic.
    pub fn isAlphabetic(self: *Self, cp: u21) bool {
        return self.alpha.isAlphabetic(cp);
    }

    /// isAsciiAlphabetic detects ASCII only letters.
    pub fn isAsciiAlphabetic(self: Self, cp: u21) bool {
        return if (cp < 128) ascii.isAlpha(@intCast(u8, cp)) else false;
    }

    /// isAlphaNum covers all the Unicode alphabetic and number space, not just ASCII.
    pub fn isAlphaNum(self: *Self, cp: u21) bool {
        return (self.isAlphabetic(cp) or self.isNumber(cp));
    }

    /// isAsciiAlphaNum detects ASCII only letters or numbers.
    pub fn isAsciiAlphaNum(self: Self, cp: u21) bool {
        return if (cp < 128) ascii.isAlNum(@intCast(u8, cp)) else false;
    }

    /// isBase detects Unicode base code points.
    pub fn isBase(self: *Self, cp: u21) bool {
        return self.isLetter(cp) or self.isNumber(cp) or self.isPunct(cp) or
            self.isSymbol(cp) or self.isSpace(cp);
    }

    /// isCombining detects Unicode base characters.
    pub fn isCombining(self: *Self, cp: u21) bool {
        return self.isMark(cp);
    }

    /// isCased detects cased letters.
    pub fn isCased(self: *Self, cp: u21) bool {
        return self.letter.isCased(cp);
    }

    // isDecimal detects all Unicode digits.
    pub fn isDecimal(self: *Self, cp: u21) bool {
        return self.number.isDecimal(cp);
    }

    // isDigit detects all Unicode digits, which don't include the ASCII digits..
    pub fn isDigit(self: *Self, cp: u21) bool {
        return self.number.isDigit(cp);
    }

    /// isAsciiAlphabetic detects ASCII only letters.
    pub fn isAsciiDigit(self: Self, cp: u21) bool {
        return if (cp < 128) ascii.isDigit(@intCast(u8, cp)) else false;
    }

    /// isGraphic detects any code point that can be represented graphically, including spaces.
    pub fn isGraphic(self: *Self, cp: u21) bool {
        return self.isPrint(cp) or self.isSpace(cp);
    }

    /// isAsciiGraphic detects ASCII only graphic code points.
    pub fn isAsciiGraphic(self: Self, cp: u21) bool {
        return if (cp < 128) ascii.isGraph(@intCast(u8, cp)) else false;
    }

    // isHex detects the 16 ASCII characters 0-9 A-F, and a-f.
    pub fn isHexDigit(self: *Self, cp: u21) bool {
        return self.number.isHexDigit(cp);
    }

    /// isAsciiHexDigit detects ASCII only hexadecimal digits.
    pub fn isAsciiHexDigit(self: Self, cp: u21) bool {
        return if (cp < 128) ascii.isXDigit(@intCast(u8, cp)) else false;
    }

    /// isPrint detects any code point that can be printed, but not spaces.
    pub fn isPrint(self: *Self, cp: u21) bool {
        return self.isAlphaNum(cp) or self.isMark(cp) or self.isPunct(cp) or
            self.isSymbol(cp) or self.isWhiteSpace(cp);
    }

    /// isAsciiPrint detects ASCII printable code points.
    pub fn isAsciiPrint(self: Self, cp: u21) bool {
        return if (cp < 128) ascii.isPrint(@intCast(u8, cp)) else false;
    }

    /// isControl detects control code points such as form feeds.
    pub fn isControl(self: *Self, cp: u21) bool {
        return self.control.isControl(cp);
    }

    /// isAsciiControl detects ASCII only control code points.
    pub fn isAsciiControl(self: Self, cp: u21) bool {
        return if (cp < 128) ascii.isCntrl(@intCast(u8, cp)) else false;
    }

    /// isLetter covers all letters in Unicode, not just ASCII.
    pub fn isLetter(self: *Self, cp: u21) bool {
        return self.letter.isLetter(cp);
    }

    /// isAsciiLetter detects ASCII only letters.
    pub fn isAsciiLetter(self: Self, cp: u21) bool {
        return if (cp < 128) ascii.isAlpha(@intCast(u8, cp)) else false;
    }

    /// isLower detects code points that are lowercase.
    pub fn isLower(self: *Self, cp: u21) bool {
        return (self.letter.isLower(cp));
    }

    /// isAsciiLower detects ASCII only lowercase letters.
    pub fn isAsciiLower(self: Self, cp: u21) bool {
        return if (cp < 128) ascii.isLower(@intCast(u8, cp)) else false;
    }

    /// isMark detects special code points that serve as marks in different alphabets.
    pub fn isMark(self: *Self, cp: u21) bool {
        return (self.mark.isMark(cp));
    }

    /// isNumber covers all Unicode numbers, not just ASII.
    pub fn isNumber(self: *Self, cp: u21) bool {
        return (self.number.isNumber(cp));
    }

    /// isAsciiNumber detects ASCII only numbers.
    pub fn isAsciiNumber(self: Self, cp: u21) bool {
        return if (cp < 128) ascii.isDigit(@intCast(u8, cp)) else false;
    }

    /// isPunct detects punctuation characters. Note some punctuation maybe considered symbols by Unicode.
    pub fn isPunct(self: *Self, cp: u21) bool {
        return (self.punct.isPunct(cp));
    }

    /// isAsciiPunct detects ASCII only punctuation.
    pub fn isAsciiPunct(self: Self, cp: u21) bool {
        return if (cp < 128) ascii.isPunct(@intCast(u8, cp)) else false;
    }

    /// isSpace detects code points that are Unicode space separators.
    pub fn isSpace(self: *Self, cp: u21) bool {
        return self.space.isSpace(cp);
    }

    /// isWhiteSpace checks for spaces.
    pub fn isWhiteSpace(self: *Self, cp: u21) bool {
        return (self.space.isWhiteSpace(cp));
    }

    /// isAsciiWhiteSpace detects ASCII only whitespace.
    pub fn isAsciiWhiteSpace(self: Self, cp: u21) bool {
        return if (cp < 128) ascii.isSpace(@intCast(u8, cp)) else false;
    }

    // isSymbol detects symbols which curiosly may include some code points commonly thought of as
    // punctuation.
    pub fn isSymbol(self: *Self, cp: u21) bool {
        return (self.symbol.isSymbol(cp));
    }

    /// isAsciiSymbol detects ASCII only symbols.
    pub fn isAsciiSymbol(self: Self, cp: u21) bool {
        return if (cp < 128) ascii.isSymbol(@intCast(u8, cp)) else false;
    }

    /// isTitle detects code points in titlecase.
    pub fn isTitle(self: *Self, cp: u21) bool {
        return (self.letter.isTitle(cp));
    }

    /// isUpper detects code points in uppercase.
    pub fn isUpper(self: *Self, cp: u21) bool {
        return (self.letter.isUpper(cp));
    }

    /// isAsciiUpper detects ASCII only uppercase letters.
    pub fn isAsciiUpper(self: Self, cp: u21) bool {
        return if (cp < 128) ascii.isUpper(@intCast(u8, cp)) else false;
    }

    /// toLower returns the lowercase code point for the given code point. It returns the same 
    /// code point given if no mapping exists.
    pub fn toLower(self: *Self, cp: u21) u21 {
        return self.letter.toLower(cp);
    }

    /// toAsciiLower converts an ASCII letter to lowercase.
    pub fn toAsciiLower(self: Self, cp: u21) u21 {
        return if (cp < 128) ascii.toLower(@intCast(u8, cp)) else cp;
    }

    /// toTitle returns the titlecase code point for the given code point. It returns the same 
    /// code point given if no mapping exists.
    pub fn toTitle(self: *Self, cp: u21) u21 {
        return self.letter.toTitle(cp);
    }

    /// toUpper returns the uppercase code point for the given code point. It returns the same 
    /// code point given if no mapping exists.
    pub fn toUpper(self: *Self, cp: u21) u21 {
        return self.letter.toUpper(cp);
    }

    /// toAsciiUpper converts an ASCII letter to uppercase.
    pub fn toAsciiUpper(self: Self, cp: u21) u21 {
        return if (cp < 128) ascii.toUpper(@intCast(u8, cp)) else false;
    }

    /// isAscii checks a code point to see if it's an ASCII character.
    pub fn isAscii(self: Self, cp: u21) bool {
        return cp < 128;
    }

    /// isAsciiStr checks if a string (`[]const uu`) is composed solely of ASCII characters.
    pub fn isAsciiStr(self: Self, str: []const u8) !bool {
        var cp_iter = (try unicode.Utf8View.init(str)).iterator();
        while (cp_iter.nextCodepoint()) |cp| {
            if (!self.isAscii(cp)) return false;
        }
        return true;
    }

    /// isLatin1 checks a code point to see if it's a Latin-1 character.
    pub fn isLatin1(self: Self, cp: u21) bool {
        return cp < 256;
    }

    /// isLatin1Str checks if a string (`[]const uu`) is composed solely of Latin-1 characters.
    pub fn isLatin1Str(self: Self, str: []const u8) !bool {
        var cp_iter = (try unicode.Utf8View.init(str)).iterator();
        while (cp_iter.nextCodepoint()) |cp| {
            if (!self.isLatin1(cp)) return false;
        }
        return true;
    }
};
