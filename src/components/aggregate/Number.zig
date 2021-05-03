const std = @import("std");
const mem = std.mem;

pub const Decimal = @import("../../components.zig").Decimal;
pub const Digit = @import("../../components.zig").Digit;
pub const Hex = @import("../../components.zig").Hex;
pub const LetterNumber = @import("../../components.zig").LetterNumber;
pub const OtherNumber = @import("../../components.zig").OtherNumber;

const Self = @This();

allocator: *mem.Allocator,
decimal: *Decimal,
digit: *Digit,
hex: *Hex,
letter_number: *LetterNumber,
other_number: *OtherNumber,

const Singleton = struct {
    instance: *Self,
    ref_count: usize,
};

var singleton: ?Singleton = null;

pub fn init(allocator: *mem.Allocator) !*Self {
    if (singleton) |*s| {
        s.ref_count += 1;
        return s.instance;
    }

    var instance = try allocator.create(Self);

    instance.* = Self{
        .allocator = allocator,
        .decimal = try Decimal.init(allocator),
        .digit = try Digit.init(allocator),
        .hex = try Hex.init(allocator),
        .letter_number = try LetterNumber.init(allocator),
        .other_number = try OtherNumber.init(allocator),
    };

    singleton = Singleton{
        .instance = instance,
        .ref_count = 1,
    };

    return instance;
}

pub fn deinit(self: *Self) void {
    if (singleton) |*s| {
        s.ref_count -= 1;
        if (s.ref_count == 0) {
            self.decimal.deinit();
            self.digit.deinit();
            self.hex.deinit();
            self.letter_number.deinit();
            self.other_number.deinit();

            self.allocator.destroy(s.instance);
            singleton = null;
        }
    }
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
    var number = try init(std.testing.allocator);
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
