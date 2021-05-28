const std = @import("std");
const ascii = @import("../../ascii.zig");

pub const Close = @import("../../components.zig").Close;
pub const Connector = @import("../../components.zig").Connector;
pub const Dash = @import("../../components.zig").Dash;
pub const Final = @import("../../components.zig").Final;
pub const Initial = @import("../../components.zig").Initial;
pub const Open = @import("../../components.zig").Open;
pub const OtherPunct = @import("../../components.zig").OtherPunct;

/// isPunct detects punctuation characters. Note some punctuation maybe considered symbols by Unicode.
pub fn isPunct(cp: u21) bool {
    return Close.isClosePunctuation(cp) or Connector.isConnectorPunctuation(cp) or
        Dash.isDashPunctuation(cp) or Final.isFinalPunctuation(cp) or
        Initial.isInitialPunctuation(cp) or Open.isOpenPunctuation(cp) or
        OtherPunct.isOtherPunctuation(cp);
}

/// isAsciiPunct detects ASCII only punctuation.
pub fn isAsciiPunct(cp: u21) bool {
    return if (cp < 128) ascii.isPunct(@intCast(u8, cp)) else false;
}

const expect = std.testing.expect;

test "Component isPunct" {
    try expect(isPunct('!'));
    try expect(isPunct('?'));
    try expect(isPunct(','));
    try expect(isPunct('.'));
    try expect(isPunct(':'));
    try expect(isPunct(';'));
    try expect(isPunct('\''));
    try expect(isPunct('"'));
    try expect(isPunct('¿'));
    try expect(isPunct('¡'));
    try expect(isPunct('-'));
    try expect(isPunct('('));
    try expect(isPunct(')'));
    try expect(isPunct('{'));
    try expect(isPunct('}'));
    try expect(isPunct('–'));
    // Punct? in Unicode.
    try expect(isPunct('@'));
    try expect(isPunct('#'));
    try expect(isPunct('%'));
    try expect(isPunct('&'));
    try expect(isPunct('*'));
    try expect(isPunct('_'));
    try expect(isPunct('/'));
    try expect(isPunct('\\'));
    try expect(!isPunct('\u{0003}'));
}
