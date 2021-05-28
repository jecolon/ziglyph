const std = @import("std");
const ascii = @import("../../ascii.zig");

pub const Currency = @import("../../components.zig").CurrencySymbol;
pub const Math = @import("../../components.zig").MathSymbol;
pub const ModifierSymbol = @import("../../components.zig").ModifierSymbol;
pub const OtherSymbol = @import("../../components.zig").OtherSymbol;

// isSymbol detects symbols which curiosly may include some code points commonly thought of as
// punctuation.
pub fn isSymbol(cp: u21) bool {
    return Math.isMathSymbol(cp) or ModifierSymbol.isModifierSymbol(cp) or
        Currency.isCurrencySymbol(cp) or OtherSymbol.isOtherSymbol(cp);
}

/// isAsciiSymbol detects ASCII only symbols.
pub fn isAsciiSymbol(cp: u21) bool {
    return if (cp < 128) ascii.isSymbol(@intCast(u8, cp)) else false;
}

const expect = std.testing.expect;

test "Component isSymbol" {
    try expect(isSymbol('<'));
    try expect(isSymbol('>'));
    try expect(isSymbol('='));
    try expect(isSymbol('$'));
    try expect(isSymbol('^'));
    try expect(isSymbol('+'));
    try expect(isSymbol('|'));
    try expect(!isSymbol('A'));
    try expect(!isSymbol('?'));
}
