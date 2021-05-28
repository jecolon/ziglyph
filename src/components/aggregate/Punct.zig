const std = @import("std");
const ascii = @import("../../ascii.zig");

pub const Close = @import("../../components.zig").ClosePunctuation;
pub const Connector = @import("../../components.zig").ConnectorPunctuation;
pub const Dash = @import("../../components.zig").DashPunctuation;
pub const Final = @import("../../components.zig").FinalPunctuation;
pub const Initial = @import("../../components.zig").InitialPunctuation;
pub const Open = @import("../../components.zig").OpenPunctuation;
pub const OtherPunct = @import("../../components.zig").OtherPunctuation;

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
