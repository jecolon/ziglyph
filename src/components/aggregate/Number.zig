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
decimal: ?Decimal = null,
digit: ?Digit = null,
hex: ?Hex = null,
letter: ?Letter = null,
other: ?Other = null,

pub fn init(allocator: *mem.Allocator) !Self {
    return Self{ .allocator = allocator };
}

pub fn deinit(self: *Self) void {
    if (self.decimal) |*decimal| decimal.deinit();
    if (self.digit) |*digit| digit.deinit();
    if (self.hex) |*hex| hex.deinit();
    if (self.letter) |*letter| letter.deinit();
    if (self.other) |*other| other.deinit();
}

// isDecimal detects all Unicode digits.
pub fn isDecimal(self: *Self, cp: u21) !bool {
    // Lazy init.
    if (self.decimal == null) self.decimal = try Decimal.init(self.allocator);
    return self.decimal.?.isDecimalNumber(cp);
}

// isDigit detects all Unicode digits, which don't include the ASCII digits..
pub fn isDigit(self: *Self, cp: u21) !bool {
    // Lazy init.
    if (self.digit == null) self.digit = try Digit.init(self.allocator);
    return self.digit.?.isDigit(cp) or (try self.isDecimal(cp));
}

/// isAsciiAlphabetic detects ASCII only letters.
pub fn isAsciiDigit(self: Self, cp: u21) bool {
    return if (cp < 128) ascii.isDigit(@intCast(u8, cp)) else false;
}

// isHex detects the 16 ASCII characters 0-9 A-F, and a-f.
pub fn isHexDigit(self: *Self, cp: u21) !bool {
    if (self.hex == null) self.hex = try Hex.init(self.allocator);
    return self.hex.?.isHexDigit(cp);
}

/// isAsciiHexDigit detects ASCII only hexadecimal digits.
pub fn isAsciiHexDigit(self: Self, cp: u21) bool {
    return if (cp < 128) ascii.isXDigit(@intCast(u8, cp)) else false;
}

/// isNumber covers all Unicode numbers, not just ASII.
pub fn isNumber(self: *Self, cp: u21) !bool {
    // Lazy init.
    if (self.decimal == null) self.decimal = try Decimal.init(self.allocator);
    if (self.letter == null) self.letter = try Letter.init(self.allocator);
    if (self.other == null) self.other = try Other.init(self.allocator);

    return self.decimal.?.isDecimalNumber(cp) or self.letter.?.isLetterNumber(cp) or
        self.other.?.isOtherNumber(cp);
}

/// isAsciiNumber detects ASCII only numbers.
pub fn isAsciiNumber(self: Self, cp: u21) bool {
    return if (cp < 128) ascii.isDigit(@intCast(u8, cp)) else false;
}
