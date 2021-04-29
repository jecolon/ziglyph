const std = @import("std");
const mem = std.mem;
const ascii = @import("../../ascii.zig");

const Context = @import("../../Context.zig");

const Self = @This();

context: *Context,

pub fn new(ctx: *Context) Self {
    return Self{ .context = ctx };
}

// isDecimal detects all Unicode digits.
pub fn isDecimal(self: Self, cp: u21) !bool {
    const decimal = try self.context.getDecimal();
    return decimal.isDecimalNumber(cp);
}

// isDigit detects all Unicode digits, which don't include the ASCII digits..
pub fn isDigit(self: Self, cp: u21) !bool {
    const digit = try self.context.getDigit();
    return digit.isDigit(cp) or (try self.isDecimal(cp));
}

/// isAsciiAlphabetic detects ASCII only letters.
pub fn isAsciiDigit(cp: u21) bool {
    return if (cp < 128) ascii.isDigit(@intCast(u8, cp)) else false;
}

// isHex detects the 16 ASCII characters 0-9 A-F, and a-f.
pub fn isHexDigit(self: Self, cp: u21) !bool {
    const hex = try self.context.getHex();
    return hex.isHexDigit(cp);
}

/// isAsciiHexDigit detects ASCII only hexadecimal digits.
pub fn isAsciiHexDigit(cp: u21) bool {
    return if (cp < 128) ascii.isXDigit(@intCast(u8, cp)) else false;
}

/// isNumber covers all Unicode numbers, not just ASII.
pub fn isNumber(self: Self, cp: u21) !bool {
    const decimal = try self.context.getDecimal();
    const letter_number = try self.context.getLetterNumber();
    const other_number = try self.context.getOtherNumber();

    return decimal.isDecimalNumber(cp) or letter_number.isLetterNumber(cp) or
        other_number.isOtherNumber(cp);
}

/// isAsciiNumber detects ASCII only numbers.
pub fn isAsciiNumber(cp: u21) bool {
    return if (cp < 128) ascii.isDigit(@intCast(u8, cp)) else false;
}

const expect = std.testing.expect;

test "Component isDecimal" {
    var ctx = Context.init(std.testing.allocator);
    defer ctx.deinit();

    var number = new(&ctx);

    var cp: u21 = '0';
    while (cp <= '9') : (cp += 1) {
        expect(try number.isDecimal(cp));
    }

    expect(!try number.isDecimal('\u{0003}'));
    expect(!try number.isDecimal('A'));
}

test "Component isHexDigit" {
    var ctx = Context.init(std.testing.allocator);
    defer ctx.deinit();

    var number = new(&ctx);

    var cp: u21 = '0';
    while (cp <= '9') : (cp += 1) {
        expect(try number.isHexDigit(cp));
    }

    expect(!try number.isHexDigit('\u{0003}'));
    expect(!try number.isHexDigit('Z'));
}

test "Component isNumber" {
    var ctx = Context.init(std.testing.allocator);
    defer ctx.deinit();

    var number = new(&ctx);

    var cp: u21 = '0';
    while (cp <= '9') : (cp += 1) {
        expect(try number.isNumber(cp));
    }

    expect(!try number.isNumber('\u{0003}'));
    expect(!try number.isNumber('A'));
}
