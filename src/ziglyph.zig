//! Ziglyph provides Unicode processing in Zig.

const std = @import("std");
const mem = std.mem;
const unicode = std.unicode;
const ascii = @import("ascii.zig");

pub const Context = @import("Context.zig");
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
    context: *Context,
    letter: Letter,
    mark: Mark,
    number: Number,
    punct: Punct,
    symbol: Symbol,
    space: Space,

    const Self = @This();

    pub fn new(ctx: *Context) !Self {
        return Self{
            .context = ctx,
            .letter = Letter.new(ctx),
            .mark = Mark.new(ctx),
            .number = Number.new(ctx),
            .punct = Punct.new(ctx),
            .symbol = Symbol.new(ctx),
            .space = Space.new(ctx),
        };
    }

    pub fn isAlphabetic(self: Self, cp: u21) bool {
        return self.context.alphabetic.isAlphabetic(cp);
    }

    pub fn isAsciiAlphabetic(cp: u21) bool {
        return if (cp < 128) ascii.isAlpha(@intCast(u8, cp)) else false;
    }

    pub fn isAlphaNum(self: Self, cp: u21) bool {
        return self.isAlphabetic(cp) or self.isNumber(cp);
    }

    pub fn isAsciiAlphaNum(cp: u21) bool {
        return if (cp < 128) ascii.isAlNum(@intCast(u8, cp)) else false;
    }

    /// isCased detects cased code points, usually letters.
    pub fn isCased(self: Self, cp: u21) bool {
        return self.letter.isCased(cp);
    }

    /// isDecimal detects all Unicode decimal numbers.
    pub fn isDecimal(self: Self, cp: u21) bool {
        return self.number.isDecimal(cp);
    }

    /// isDigit detects all Unicode digits, which curiosly don't include the ASCII digits.
    pub fn isDigit(self: Self, cp: u21) bool {
        return self.number.isDigit(cp);
    }

    pub fn isAsciiDigit(cp: u21) bool {
        return if (cp < 128) ascii.isDigit(@intCast(u8, cp)) else false;
    }

    /// isGraphic detects any code point that can be represented graphically, including spaces.
    pub fn isGraphic(self: Self, cp: u21) bool {
        return self.isPrint(cp) or self.isSpace(cp);
    }

    pub fn isAsciiGraphic(cp: u21) bool {
        return if (cp < 128) ascii.isGraph(@intCast(u8, cp)) else false;
    }

    // isHex detects hexadecimal code points.
    pub fn isHexDigit(self: Self, cp: u21) bool {
        return self.number.isHexDigit(cp);
    }

    pub fn isAsciiHexDigit(cp: u21) bool {
        return if (cp < 128) ascii.isXDigit(@intCast(u8, cp)) else false;
    }

    /// isPrint detects any code point that can be printed, excluding spaces.
    pub fn isPrint(self: Self, cp: u21) bool {
        return self.isAlphaNum(cp) or self.isMark(cp) or self.isPunct(cp) or
            self.isSymbol(cp) or self.isWhiteSpace(cp);
    }

    pub fn isAsciiPrint(cp: u21) bool {
        return if (cp < 128) ascii.isPrint(@intCast(u8, cp)) else false;
    }

    pub fn isControl(self: Self, cp: u21) bool {
        return self.context.control.isControl(cp);
    }

    pub fn isAsciiControl(cp: u21) bool {
        return if (cp < 128) ascii.isCntrl(@intCast(u8, cp)) else false;
    }

    pub fn isLetter(self: Self, cp: u21) bool {
        return self.letter.isLetter(cp);
    }

    pub fn isAsciiLetter(cp: u21) bool {
        return if (cp < 128) ascii.isAlpha(@intCast(u8, cp)) else false;
    }

    /// isLower detects code points that are lowercase.
    pub fn isLower(self: Self, cp: u21) bool {
        return self.letter.isLower(cp);
    }

    pub fn isAsciiLower(cp: u21) bool {
        return if (cp < 128) ascii.isLower(@intCast(u8, cp)) else false;
    }

    /// isMark detects special code points that serve as marks in different alphabets.
    pub fn isMark(self: Self, cp: u21) bool {
        return self.mark.isMark(cp);
    }

    pub fn isNumber(self: Self, cp: u21) bool {
        return self.number.isNumber(cp);
    }

    pub fn isAsciiNumber(cp: u21) bool {
        return if (cp < 128) ascii.isDigit(@intCast(u8, cp)) else false;
    }

    /// isPunct detects punctuation characters. Note some punctuation may be considered as symbols by Unicode.
    pub fn isPunct(self: Self, cp: u21) bool {
        return self.punct.isPunct(cp);
    }

    pub fn isAsciiPunct(cp: u21) bool {
        return if (cp < 128) ascii.isPunct(@intCast(u8, cp)) else false;
    }

    /// isSpace detects code points that are Unicode space separators.
    pub fn isSpace(self: Self, cp: u21) bool {
        return self.space.isSpace(cp);
    }

    /// isWhiteSpace detects code points that have the Unicode *WhiteSpace* property.
    pub fn isWhiteSpace(self: Self, cp: u21) bool {
        return self.space.isWhiteSpace(cp);
    }

    pub fn isAsciiWhiteSpace(cp: u21) bool {
        return if (cp < 128) ascii.isSpace(@intCast(u8, cp)) else false;
    }

    // isSymbol detects symbols which may include code points commonly considered punctuation.
    pub fn isSymbol(self: Self, cp: u21) bool {
        return self.symbol.isSymbol(cp);
    }

    pub fn isAsciiSymbol(cp: u21) bool {
        return if (cp < 128) ascii.isSymbol(@intCast(u8, cp)) else false;
    }

    /// isTitle detects code points in titlecase.
    pub fn isTitle(self: Self, cp: u21) bool {
        return self.letter.isTitle(cp);
    }

    /// isUpper detects code points in uppercase.
    pub fn isUpper(self: Self, cp: u21) bool {
        return self.letter.isUpper(cp);
    }

    pub fn isAsciiUpper(cp: u21) bool {
        return if (cp < 128) ascii.isUpper(@intCast(u8, cp)) else false;
    }

    /// toLower returns the lowercase code point for the given code point. It returns the same 
    /// code point given if no mapping exists.
    pub fn toLower(self: Self, cp: u21) u21 {
        return self.letter.toLower(cp);
    }

    pub fn toAsciiLower(cp: u21) u21 {
        return if (cp < 128) ascii.toLower(@intCast(u8, cp)) else cp;
    }

    /// toTitle returns the titlecase code point for the given code point. It returns the same 
    /// code point given if no mapping exists.
    pub fn toTitle(self: Self, cp: u21) u21 {
        return self.letter.toTitle(cp);
    }

    /// toUpper returns the uppercase code point for the given code point. It returns the same 
    /// code point given if no mapping exists.
    pub fn toUpper(self: Self, cp: u21) u21 {
        return self.letter.toUpper(cp);
    }

    pub fn toAsciiUpper(cp: u21) u21 {
        return if (cp < 128) ascii.toUpper(@intCast(u8, cp)) else false;
    }
};

const expect = std.testing.expect;
const expectEqual = std.testing.expectEqual;

test "Ziglyph ASCII methods" {
    const z = 'F';
    expect(Ziglyph.isAsciiAlphabetic(z));
    expect(Ziglyph.isAsciiAlphaNum(z));
    expect(Ziglyph.isAsciiHexDigit(z));
    expect(Ziglyph.isAsciiGraphic(z));
    expect(Ziglyph.isAsciiPrint(z));
    expect(Ziglyph.isAsciiUpper(z));
    expect(!Ziglyph.isAsciiControl(z));
    expect(!Ziglyph.isAsciiDigit(z));
    expect(!Ziglyph.isAsciiNumber(z));
    expect(!Ziglyph.isAsciiLower(z));
    expectEqual(Ziglyph.toAsciiLower(z), 'f');
    expect(Ziglyph.isAsciiLower(Ziglyph.toAsciiLower(z)));
}

test "Ziglyph struct" {
    var ctx = try Context.init(std.testing.allocator);
    defer ctx.deinit();

    var ziglyph = try Ziglyph.new(&ctx);

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

test "Ziglyph isGraphic" {
    var ctx = try Context.init(std.testing.allocator);
    defer ctx.deinit();

    var ziglyph = try Ziglyph.new(&ctx);

    expect(ziglyph.isGraphic('A'));
    expect(ziglyph.isGraphic('\u{20E4}'));
    expect(ziglyph.isGraphic('1'));
    expect(ziglyph.isGraphic('?'));
    expect(ziglyph.isGraphic(' '));
    expect(ziglyph.isGraphic('='));
    expect(!ziglyph.isGraphic('\u{0003}'));
}

test "Ziglyph isHexDigit" {
    var ctx = try Context.init(std.testing.allocator);
    defer ctx.deinit();

    var ziglyph = try Ziglyph.new(&ctx);

    var cp: u21 = '0';
    while (cp <= '9') : (cp += 1) {
        expect(ziglyph.isHexDigit(cp));
    }

    cp = 'A';
    while (cp <= 'F') : (cp += 1) {
        expect(ziglyph.isHexDigit(cp));
    }

    cp = 'a';
    while (cp <= 'f') : (cp += 1) {
        expect(ziglyph.isHexDigit(cp));
    }

    expect(!ziglyph.isHexDigit('\u{0003}'));
    expect(!ziglyph.isHexDigit('Z'));
}

test "Ziglyph isPrint" {
    var ctx = try Context.init(std.testing.allocator);
    defer ctx.deinit();

    var ziglyph = try Ziglyph.new(&ctx);

    expect(ziglyph.isPrint('A'));
    expect(ziglyph.isPrint('\u{20E4}'));
    expect(ziglyph.isPrint('1'));
    expect(ziglyph.isPrint('?'));
    expect(ziglyph.isPrint('='));
    expect(ziglyph.isPrint(' '));
    expect(ziglyph.isPrint('\t'));
    expect(!ziglyph.isPrint('\u{0003}'));
}

test "Ziglyph isAlphaNum" {
    var ctx = try Context.init(std.testing.allocator);
    defer ctx.deinit();

    var ziglyph = try Ziglyph.new(&ctx);

    var cp: u21 = '0';
    while (cp <= '9') : (cp += 1) {
        expect(ziglyph.isAlphaNum(cp));
    }

    cp = 'a';
    while (cp <= 'z') : (cp += 1) {
        expect(ziglyph.isAlphaNum(cp));
    }

    cp = 'A';
    while (cp <= 'Z') : (cp += 1) {
        expect(ziglyph.isAlphaNum(cp));
    }

    expect(!ziglyph.isAlphaNum('='));
}

test "Ziglyph isControl" {
    var ctx = try Context.init(std.testing.allocator);
    defer ctx.deinit();

    var ziglyph = try Ziglyph.new(&ctx);

    expect(ziglyph.isControl('\n'));
    expect(ziglyph.isControl('\r'));
    expect(ziglyph.isControl('\t'));
    expect(ziglyph.isControl('\u{0003}'));
    expect(ziglyph.isControl('\u{0012}'));
    expect(!ziglyph.isControl('A'));
}
