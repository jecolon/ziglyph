const std = @import("std");
const mem = std.mem;
const ascii = @import("../../ascii.zig");

const Context = @import("../../context.zig").Context;
pub const Decimal = @import("../../context.zig").Decimal;
pub const Digit = @import("../../context.zig").Digit;
pub const Hex = @import("../../context.zig").Hex;
pub const LetterNumber = @import("../../context.zig").LetterNumber;
pub const OtherNumber = @import("../../context.zig").OtherNumber;

const Self = @This();

decimal: *Decimal,
digit: *Digit,
hex: *Hex,
letter_number: *LetterNumber,
other_number: *OtherNumber,

pub fn new(ctx: anytype) Self {
    return Self{
        .decimal = &ctx.decimal,
        .digit = &ctx.digit,
        .hex = &ctx.hex,
        .letter_number = &ctx.letter_number,
        .other_number = &ctx.other_number,
    };
}

// isDecimal detects all Unicode digits.
pub fn isDecimal(self: Self, cp: u21) bool {
    return self.decimal.isDecimalNumber(cp);
}

// isDigit detects all Unicode digits, which don't include the ASCII digits..
pub fn isDigit(self: Self, cp: u21) bool {
    return self.digit.isDigit(cp) or self.isDecimal(cp);
}

/// isAsciiAlphabetic detects ASCII only letters.
pub fn isAsciiDigit(cp: u21) bool {
    return if (cp < 128) ascii.isDigit(@intCast(u8, cp)) else false;
}

// isHex detects the 16 ASCII characters 0-9 A-F, and a-f.
pub fn isHexDigit(self: Self, cp: u21) bool {
    return self.hex.isHexDigit(cp);
}

/// isAsciiHexDigit detects ASCII only hexadecimal digits.
pub fn isAsciiHexDigit(cp: u21) bool {
    return if (cp < 128) ascii.isXDigit(@intCast(u8, cp)) else false;
}

/// isNumber covers all Unicode numbers, not just ASII.
pub fn isNumber(self: Self, cp: u21) bool {
    return self.decimal.isDecimalNumber(cp) or self.letter_number.isLetterNumber(cp) or
        self.other_number.isOtherNumber(cp);
}

/// isAsciiNumber detects ASCII only numbers.
pub fn isAsciiNumber(cp: u21) bool {
    return if (cp < 128) ascii.isDigit(@intCast(u8, cp)) else false;
}

const expect = std.testing.expect;

test "Component isDecimal" {
    var ctx = try Context(.number).init(std.testing.allocator);
    defer ctx.deinit();

    var number = new(&ctx);

    var cp: u21 = '0';
    while (cp <= '9') : (cp += 1) {
        expect(number.isDecimal(cp));
    }

    expect(!number.isDecimal('\u{0003}'));
    expect(!number.isDecimal('A'));
}

test "Component isHexDigit" {
    var ctx = try Context(.number).init(std.testing.allocator);
    defer ctx.deinit();

    var number = new(&ctx);

    var cp: u21 = '0';
    while (cp <= '9') : (cp += 1) {
        expect(number.isHexDigit(cp));
    }

    expect(!number.isHexDigit('\u{0003}'));
    expect(!number.isHexDigit('Z'));
}

test "Component isNumber" {
    var ctx = try Context(.number).init(std.testing.allocator);
    defer ctx.deinit();

    var number = new(&ctx);

    var cp: u21 = '0';
    while (cp <= '9') : (cp += 1) {
        expect(number.isNumber(cp));
    }

    expect(!number.isNumber('\u{0003}'));
    expect(!number.isNumber('A'));
}
