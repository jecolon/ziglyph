const std = @import("std");
const mem = std.mem;
const ascii = @import("../../ascii.zig");

/// Decimal number code points.
pub const Decimal = @import("../autogen/DerivedGeneralCategory/DecimalNumber.zig");
/// Unicode digit code points, which do not include ASCII digits.
pub const Digit = @import("../autogen/DerivedNumericType/Digit.zig");
/// Hexadecimal digits.
pub const Hex = @import("../autogen/PropList/HexDigit.zig");
/// Numbers expressed as letters.
pub const Letter = @import("../autogen/DerivedGeneralCategory/LetterNumber.zig");
/// Other numbers.
pub const Other = @import("../autogen/DerivedGeneralCategory/OtherNumber.zig");

const Self = @This();

allocator: *mem.Allocator,
decimal: Decimal,
digit: Digit,
hex: Hex,
letter: Letter,
other: Other,

pub fn init(allocator: *mem.Allocator) !Self {
    return Self{
        .allocator = allocator,
        .decimal = try Decimal.init(allocator),
        .digit = try Digit.init(allocator),
        .hex = try Hex.init(allocator),
        .letter = try Letter.init(allocator),
        .other = try Other.init(allocator),
    };
}

pub fn deinit(self: *Self) void {
    self.decimal.deinit();
    self.digit.deinit();
    self.hex.deinit();
    self.letter.deinit();
    self.other.deinit();
}

// isDecimal detects all Unicode digits.
pub fn isDecimal(self: *Self, cp: u21) bool {
    return self.decimal.isDecimalNumber(cp);
}

// isDigit detects all Unicode digits, which don't include the ASCII digits..
pub fn isDigit(self: *Self, cp: u21) bool {
    return self.digit.isDigit(cp) or self.isDecimal(cp);
}

/// isAsciiAlphabetic detects ASCII only letters.
pub fn isAsciiDigit(self: Self, cp: u21) bool {
    return if (cp < 128) ascii.isDigit(@intCast(u8, cp)) else false;
}

// isHex detects the 16 ASCII characters 0-9 A-F, and a-f.
pub fn isHexDigit(self: *Self, cp: u21) bool {
    return self.hex.isHexDigit(cp);
}

/// isAsciiHexDigit detects ASCII only hexadecimal digits.
pub fn isAsciiHexDigit(self: Self, cp: u21) bool {
    return if (cp < 128) ascii.isXDigit(@intCast(u8, cp)) else false;
}

/// isNumber covers all Unicode numbers, not just ASII.
pub fn isNumber(self: *Self, cp: u21) bool {
    return self.decimal.isDecimalNumber(cp) or self.letter.isLetterNumber(cp) or
        self.other.isOtherNumber(cp);
}

/// isAsciiNumber detects ASCII only numbers.
pub fn isAsciiNumber(self: Self, cp: u21) bool {
    return if (cp < 128) ascii.isDigit(@intCast(u8, cp)) else false;
}

test "isDecimal" {
    var z = try init(std.testing.allocator);
    defer z.deinit();

    var cp: u21 = '0';
    while (cp <= '9') : (cp += 1) {
        std.testing.expect(z.isDecimal(cp));
    }
    std.testing.expect(!z.isDecimal('\u{0003}'));
    std.testing.expect(!z.isDecimal('A'));
}

test "isHexDigit" {
    var z = try init(std.testing.allocator);
    defer z.deinit();

    var cp: u21 = '0';
    while (cp <= '9') : (cp += 1) {
        std.testing.expect(z.isHexDigit(cp));
    }
    std.testing.expect(!z.isHexDigit('\u{0003}'));
    std.testing.expect(!z.isHexDigit('Z'));
}

test "isNumber" {
    var z = try init(std.testing.allocator);
    defer z.deinit();

    var cp: u21 = '0';
    while (cp <= '9') : (cp += 1) {
        std.testing.expect(z.isNumber(cp));
    }
    std.testing.expect(!z.isNumber('\u{0003}'));
    std.testing.expect(!z.isNumber('A'));
}
