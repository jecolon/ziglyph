const std = @import("std");
const mem = std.mem;

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
nctx: ?*Context(.number),

pub fn init(allocator: *mem.Allocator) !Self {
    var nctx = try Context(.number).init(allocator);

    return Self{
        .decimal = nctx.decimal,
        .digit = nctx.digit,
        .hex = nctx.hex,
        .letter_number = nctx.letter_number,
        .other_number = nctx.other_number,
        .nctx = nctx,
    };
}

pub fn deinit(self: *Self) void {
    if (self.nctx) |nctx| nctx.deinit();
}

pub fn initWithContext(ctx: anytype) Self {
    return Self{
        .decimal = ctx.decimal,
        .digit = ctx.digit,
        .hex = ctx.hex,
        .letter_number = ctx.letter_number,
        .other_number = ctx.other_number,
        .nctx = null,
    };
}

// isDecimal detects all Unicode digits.
pub fn isDecimal(self: Self, cp: u21) bool {
    // ASCII optimization.
    if (cp < 128 and (cp >= '0' and cp <= '9')) return true;
    return self.decimal.isDecimalNumber(cp);
}

// isDigit detects all Unicode digits, which don't include the ASCII digits..
pub fn isDigit(self: Self, cp: u21) bool {
    // ASCII optimization.
    if (cp < 128 and (cp >= '0' and cp <= '9')) return true;
    return self.digit.isDigit(cp) or self.isDecimal(cp);
}

/// isAsciiAlphabetic detects ASCII only letters.
pub fn isAsciiDigit(cp: u21) bool {
    return cp < 128 and (cp >= '0' and cp <= '9');
}

// isHex detects the 16 ASCII characters 0-9 A-F, and a-f.
pub fn isHexDigit(self: Self, cp: u21) bool {
    // ASCII optimization.
    if (cp < 128 and ((cp >= 'a' and cp <= 'f') or (cp >= 'A' and cp <= 'F') or (cp >= '0' and cp <= '9'))) return true;
    return self.hex.isHexDigit(cp);
}

/// isAsciiHexDigit detects ASCII only hexadecimal digits.
pub fn isAsciiHexDigit(cp: u21) bool {
    return cp < 128 and ((cp >= 'a' and cp <= 'f') or (cp >= 'A' and cp <= 'F') or (cp >= '0' and cp <= '9'));
}

/// isNumber covers all Unicode numbers, not just ASII.
pub fn isNumber(self: Self, cp: u21) bool {
    // ASCII optimization.
    if (cp < 128 and (cp >= '0' and cp <= '9')) return true;
    return self.decimal.isDecimalNumber(cp) or self.letter_number.isLetterNumber(cp) or
        self.other_number.isOtherNumber(cp);
}

/// isAsciiNumber detects ASCII only numbers.
pub fn isAsciiNumber(cp: u21) bool {
    return cp < 128 and (cp >= '0' and cp <= '9');
}

const expect = std.testing.expect;

test "Component isDecimal" {
    var ctx = try Context(.number).init(std.testing.allocator);
    defer ctx.deinit();

    var number = initWithContext(ctx);
    defer number.deinit();

    var cp: u21 = '0';
    while (cp <= '9') : (cp += 1) {
        expect(number.isDecimal(cp));
    }

    expect(!number.isDecimal('\u{0003}'));
    expect(!number.isDecimal('A'));
}

test "Component isHexDigit" {
    var number = try init(std.testing.allocator);
    defer number.deinit();

    var cp: u21 = '0';
    while (cp <= '9') : (cp += 1) {
        expect(number.isHexDigit(cp));
    }

    expect(!number.isHexDigit('\u{0003}'));
    expect(!number.isHexDigit('Z'));
}

test "Component isNumber" {
    var number = try init(std.testing.allocator);
    defer number.deinit();

    var cp: u21 = '0';
    while (cp <= '9') : (cp += 1) {
        expect(number.isNumber(cp));
    }

    expect(!number.isNumber('\u{0003}'));
    expect(!number.isNumber('A'));
}
