//! Ziglyph provides Unicode processing in Zig.

const std = @import("std");
const mem = std.mem;
const unicode = std.unicode;
const ascii = @import("ascii.zig");

pub const Alphabetic = @import("components/autogen/DerivedCoreProperties/Alphabetic.zig");
pub const Control = @import("components/autogen/DerivedGeneralCategory/Control.zig");
pub const DecomposeMap = @import("components/autogen/UnicodeData/DecomposeMap.zig");
pub const Format = @import("components/autogen/DerivedGeneralCategory/Format.zig");
pub const Letter = @import("components/aggregate/Letter.zig");
pub const Mark = @import("components/aggregate/Mark.zig");
pub const Number = @import("components/aggregate/Number.zig");
pub const Punct = @import("components/aggregate/Punct.zig");
pub const Space = @import("components/aggregate/Space.zig");
pub const Symbol = @import("components/aggregate/Symbol.zig");

/// Zigstr is a UTF-8 string type.
pub const Zigstr = @import("zigstr/Zigstr.zig");
pub const GraphemeIterator = Zigstr.GraphemeIterator;

/// Ziglyph consolidates frequently-used Unicode utility functions in one place.
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

    pub fn isAlphabetic(self: *Self, cp: u21) bool {
        return self.alpha.isAlphabetic(cp);
    }

    pub fn isAsciiAlphabetic(self: Self, cp: u21) bool {
        return if (cp < 128) ascii.isAlpha(@intCast(u8, cp)) else false;
    }

    pub fn isAlphaNum(self: *Self, cp: u21) bool {
        return (self.isAlphabetic(cp) or self.isNumber(cp));
    }

    pub fn isAsciiAlphaNum(self: Self, cp: u21) bool {
        return if (cp < 128) ascii.isAlNum(@intCast(u8, cp)) else false;
    }

    /// isBase detects Unicode base code points which frequently are followed by combining code points.
    pub fn isBase(self: *Self, cp: u21) bool {
        return self.isLetter(cp) or self.isNumber(cp) or self.isPunct(cp) or
            self.isSymbol(cp) or self.isSpace(cp);
    }

    /// isCombining detects combining code points that can interact with base code points.
    pub fn isCombining(self: *Self, cp: u21) bool {
        return self.isMark(cp);
    }

    /// isCased detects cased code points, usually letters.
    pub fn isCased(self: *Self, cp: u21) bool {
        return self.letter.isCased(cp);
    }

    /// isDecimal detects all Unicode decimal numbers.
    pub fn isDecimal(self: *Self, cp: u21) bool {
        return self.number.isDecimal(cp);
    }

    /// isDigit detects all Unicode digits, which curiosly don't include the ASCII digits.
    pub fn isDigit(self: *Self, cp: u21) bool {
        return self.number.isDigit(cp);
    }

    pub fn isAsciiDigit(self: Self, cp: u21) bool {
        return if (cp < 128) ascii.isDigit(@intCast(u8, cp)) else false;
    }

    /// isGraphic detects any code point that can be represented graphically, including spaces.
    pub fn isGraphic(self: *Self, cp: u21) bool {
        return self.isPrint(cp) or self.isSpace(cp);
    }

    pub fn isAsciiGraphic(self: Self, cp: u21) bool {
        return if (cp < 128) ascii.isGraph(@intCast(u8, cp)) else false;
    }

    // isHex detects hexadecimal code points.
    pub fn isHexDigit(self: *Self, cp: u21) bool {
        return self.number.isHexDigit(cp);
    }

    pub fn isAsciiHexDigit(self: Self, cp: u21) bool {
        return if (cp < 128) ascii.isXDigit(@intCast(u8, cp)) else false;
    }

    /// isPrint detects any code point that can be printed, excluding spaces.
    pub fn isPrint(self: *Self, cp: u21) bool {
        return self.isAlphaNum(cp) or self.isMark(cp) or self.isPunct(cp) or
            self.isSymbol(cp) or self.isWhiteSpace(cp);
    }

    pub fn isAsciiPrint(self: Self, cp: u21) bool {
        return if (cp < 128) ascii.isPrint(@intCast(u8, cp)) else false;
    }

    pub fn isControl(self: *Self, cp: u21) bool {
        return self.control.isControl(cp);
    }

    pub fn isAsciiControl(self: Self, cp: u21) bool {
        return if (cp < 128) ascii.isCntrl(@intCast(u8, cp)) else false;
    }

    pub fn isLetter(self: *Self, cp: u21) bool {
        return self.letter.isLetter(cp);
    }

    pub fn isAsciiLetter(self: Self, cp: u21) bool {
        return if (cp < 128) ascii.isAlpha(@intCast(u8, cp)) else false;
    }

    /// isLower detects code points that are lowercase.
    pub fn isLower(self: *Self, cp: u21) bool {
        return (self.letter.isLower(cp));
    }

    pub fn isAsciiLower(self: Self, cp: u21) bool {
        return if (cp < 128) ascii.isLower(@intCast(u8, cp)) else false;
    }

    /// isMark detects special code points that serve as marks in different alphabets.
    pub fn isMark(self: *Self, cp: u21) bool {
        return (self.mark.isMark(cp));
    }

    pub fn isNumber(self: *Self, cp: u21) bool {
        return (self.number.isNumber(cp));
    }

    pub fn isAsciiNumber(self: Self, cp: u21) bool {
        return if (cp < 128) ascii.isDigit(@intCast(u8, cp)) else false;
    }

    /// isPunct detects punctuation characters. Note some punctuation may be considered as symbols by Unicode.
    pub fn isPunct(self: *Self, cp: u21) bool {
        return (self.punct.isPunct(cp));
    }

    pub fn isAsciiPunct(self: Self, cp: u21) bool {
        return if (cp < 128) ascii.isPunct(@intCast(u8, cp)) else false;
    }

    /// isSpace detects code points that are Unicode space separators.
    pub fn isSpace(self: *Self, cp: u21) bool {
        return self.space.isSpace(cp);
    }

    /// isWhiteSpace detects code points that have the Unicode *WhiteSpace* property.
    pub fn isWhiteSpace(self: *Self, cp: u21) bool {
        return (self.space.isWhiteSpace(cp));
    }

    pub fn isAsciiWhiteSpace(self: Self, cp: u21) bool {
        return if (cp < 128) ascii.isSpace(@intCast(u8, cp)) else false;
    }

    // isSymbol detects symbols which may include code points commonly considered punctuation.
    pub fn isSymbol(self: *Self, cp: u21) bool {
        return (self.symbol.isSymbol(cp));
    }

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

    pub fn isAsciiUpper(self: Self, cp: u21) bool {
        return if (cp < 128) ascii.isUpper(@intCast(u8, cp)) else false;
    }

    /// toLower returns the lowercase code point for the given code point. It returns the same 
    /// code point given if no mapping exists.
    pub fn toLower(self: *Self, cp: u21) u21 {
        return self.letter.toLower(cp);
    }

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

    pub fn toAsciiUpper(self: Self, cp: u21) u21 {
        return if (cp < 128) ascii.toUpper(@intCast(u8, cp)) else false;
    }
};

const expect = std.testing.expect;
const expectEqual = std.testing.expectEqual;

test "ASCII methods" {
    var ziglyph = try Ziglyph.init(std.testing.allocator);
    defer ziglyph.deinit();

    const z = 'F';
    expect(ziglyph.isAsciiAlphabetic(z));
    expect(ziglyph.isAsciiAlphaNum(z));
    expect(ziglyph.isAsciiHexDigit(z));
    expect(ziglyph.isAsciiGraphic(z));
    expect(ziglyph.isAsciiPrint(z));
    expect(ziglyph.isAsciiUpper(z));
    expect(!ziglyph.isAsciiControl(z));
    expect(!ziglyph.isAsciiDigit(z));
    expect(!ziglyph.isAsciiNumber(z));
    expect(!ziglyph.isAsciiLower(z));
    expectEqual(ziglyph.toAsciiLower(z), 'f');
    expect(ziglyph.isAsciiLower(ziglyph.toAsciiLower(z)));
}

test "Ziglyph struct" {
    var ziglyph = try Ziglyph.init(std.testing.allocator);
    defer ziglyph.deinit();

    const z = 'z';
    expect(ziglyph.isAlphaNum(z));
    expect(!ziglyph.isControl(z));
    expect(!ziglyph.isDecimal(z));
    expect(!ziglyph.isDigit(z));
    expect(!ziglyph.isHexDigit(z));
    expect(ziglyph.isGraphic(z));
    expect(ziglyph.isLetter(z));
    expect(ziglyph.isLower(z));
    expect(!ziglyph.isMark(z));
    expect(!ziglyph.isNumber(z));
    expect(ziglyph.isPrint(z));
    expect(!ziglyph.isPunct(z));
    expect(!ziglyph.isWhiteSpace(z));
    expect(!ziglyph.isSymbol(z));
    expect(!ziglyph.isTitle(z));
    expect(!ziglyph.isUpper(z));
    const uz = ziglyph.toUpper(z);
    expect(ziglyph.isUpper(uz));
    expectEqual(uz, 'Z');
    const lz = ziglyph.toLower(uz);
    expect(ziglyph.isLower(lz));
    expectEqual(lz, 'z');
    const tz = ziglyph.toTitle(lz);
    expect(ziglyph.isUpper(tz));
    expectEqual(tz, 'Z');
}

test "isGraphic" {
    var z = try Ziglyph.init(std.testing.allocator);
    defer z.deinit();

    expect(z.isGraphic('A'));
    expect(z.isGraphic('\u{20E4}'));
    expect(z.isGraphic('1'));
    expect(z.isGraphic('?'));
    expect(z.isGraphic(' '));
    expect(z.isGraphic('='));
    expect(!z.isGraphic('\u{0003}'));
}

test "isHexDigit" {
    var z = try Ziglyph.init(std.testing.allocator);
    defer z.deinit();

    var cp: u21 = '0';
    while (cp <= '9') : (cp += 1) {
        expect(z.isHexDigit(cp));
    }
    cp = 'A';
    while (cp <= 'F') : (cp += 1) {
        expect(z.isHexDigit(cp));
    }
    cp = 'a';
    while (cp <= 'f') : (cp += 1) {
        expect(z.isHexDigit(cp));
    }
    expect(!z.isHexDigit('\u{0003}'));
    expect(!z.isHexDigit('Z'));
}

test "isPrint" {
    var z = try Ziglyph.init(std.testing.allocator);
    defer z.deinit();

    expect(z.isPrint('A'));
    expect(z.isPrint('\u{20E4}'));
    expect(z.isPrint('1'));
    expect(z.isPrint('?'));
    expect(z.isPrint('='));
    expect(z.isPrint(' '));
    expect(z.isPrint('\t'));
    expect(!z.isPrint('\u{0003}'));
}

test "isAlphaNum" {
    var z = try Ziglyph.init(std.testing.allocator);
    defer z.deinit();

    var cp: u21 = '0';
    while (cp <= '9') : (cp += 1) {
        expect(z.isAlphaNum(cp));
    }
    cp = 'a';
    while (cp <= 'z') : (cp += 1) {
        expect(z.isAlphaNum(cp));
    }
    cp = 'A';
    while (cp <= 'Z') : (cp += 1) {
        expect(z.isAlphaNum(cp));
    }
    expect(!z.isAlphaNum('='));
}

test "isControl" {
    var z = try Control.init(std.testing.allocator);
    defer z.deinit();

    expect(z.isControl('\n'));
    expect(z.isControl('\r'));
    expect(z.isControl('\t'));
    expect(z.isControl('\u{0003}'));
    expect(z.isControl('\u{0012}'));
    expect(!z.isControl('A'));
}
