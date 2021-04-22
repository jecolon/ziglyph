const std = @import("std");
const mem = std.mem;
const ascii = @import("../../ascii.zig");

const Close = @import("../autogen/DerivedGeneralCategory/ClosePunctuation.zig");
const Connector = @import("../autogen/DerivedGeneralCategory/ConnectorPunctuation.zig");
const Dash = @import("../autogen/DerivedGeneralCategory/DashPunctuation.zig");
const Final = @import("../autogen/UnicodeData/FinalPunctuation.zig");
const Initial = @import("../autogen/DerivedGeneralCategory/InitialPunctuation.zig");
const Open = @import("../autogen/DerivedGeneralCategory/OpenPunctuation.zig");
const Other = @import("../autogen/DerivedGeneralCategory/OtherPunctuation.zig");

const Self = @This();

allocator: *mem.Allocator,
close: Close,
connector: Connector,
dash: Dash,
final: Final,
initial: Initial,
open: Open,
other: Other,

pub fn init(allocator: *mem.Allocator) !Self {
    return Self{
        .allocator = allocator,
        .close = try Close.init(allocator),
        .connector = try Connector.init(allocator),
        .dash = try Dash.init(allocator),
        .final = try Final.init(allocator),
        .initial = try Initial.init(allocator),
        .open = try Open.init(allocator),
        .other = try Other.init(allocator),
    };
}

pub fn deinit(self: *Self) void {
    self.close.deinit();
    self.connector.deinit();
    self.dash.deinit();
    self.final.deinit();
    self.initial.deinit();
    self.open.deinit();
    self.other.deinit();
}

/// isPunct detects punctuation characters. Note some punctuation maybe considered symbols by Unicode.
pub fn isPunct(self: *Self, cp: u21) bool {
    return self.close.isClosePunctuation(cp) or self.connector.isConnectorPunctuation(cp) or
        self.dash.isDashPunctuation(cp) or self.final.isFinalPunctuation(cp) or
        self.initial.isInitialPunctuation(cp) or self.open.isOpenPunctuation(cp) or
        self.other.isOtherPunctuation(cp);
}

/// isAsciiPunct detects ASCII only punctuation.
pub fn isAsciiPunct(self: Self, cp: u21) bool {
    return if (cp < 128) ascii.isPunct(@intCast(u8, cp)) else false;
}

test "isPunct" {
    var z = try init(std.testing.allocator);
    defer z.deinit();

    std.testing.expect(z.isPunct('!'));
    std.testing.expect(z.isPunct('?'));
    std.testing.expect(z.isPunct(','));
    std.testing.expect(z.isPunct('.'));
    std.testing.expect(z.isPunct(':'));
    std.testing.expect(z.isPunct(';'));
    std.testing.expect(z.isPunct('\''));
    std.testing.expect(z.isPunct('"'));
    std.testing.expect(z.isPunct('¿'));
    std.testing.expect(z.isPunct('¡'));
    std.testing.expect(z.isPunct('-'));
    std.testing.expect(z.isPunct('('));
    std.testing.expect(z.isPunct(')'));
    std.testing.expect(z.isPunct('{'));
    std.testing.expect(z.isPunct('}'));
    std.testing.expect(z.isPunct('–'));
    // Punct? in Unicode.
    std.testing.expect(z.isPunct('@'));
    std.testing.expect(z.isPunct('#'));
    std.testing.expect(z.isPunct('%'));
    std.testing.expect(z.isPunct('&'));
    std.testing.expect(z.isPunct('*'));
    std.testing.expect(z.isPunct('_'));
    std.testing.expect(z.isPunct('/'));
    std.testing.expect(z.isPunct('\\'));
    std.testing.expect(!z.isPunct('\u{0003}'));
}
