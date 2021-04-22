const std = @import("std");
const mem = std.mem;
const ascii = @import("../../ascii.zig");

/// Currency symbols.
pub const Currency = @import("../autogen/DerivedGeneralCategory/CurrencySymbol.zig");
/// Mathematical symbols.
pub const Math = @import("../autogen/DerivedGeneralCategory/MathSymbol.zig");
/// Symbols that modify other code points.
pub const Modifier = @import("../autogen/DerivedGeneralCategory/ModifierSymbol.zig");
/// Other symbols.
pub const Other = @import("../autogen/DerivedGeneralCategory/OtherSymbol.zig");

const Self = @This();

allocator: *mem.Allocator,
currency: Currency,
math: Math,
modifier: Modifier,
other: Other,

pub fn init(allocator: *mem.Allocator) !Self {
    return Self{
        .allocator = allocator,
        .currency = try Currency.init(allocator),
        .math = try Math.init(allocator),
        .modifier = try Modifier.init(allocator),
        .other = try Other.init(allocator),
    };
}

pub fn deinit(self: *Self) void {
    self.currency.deinit();
    self.math.deinit();
    self.modifier.deinit();
    self.other.deinit();
}

// isSymbol detects symbols which curiosly may include some code points commonly thought of as
// punctuation.
pub fn isSymbol(self: *Self, cp: u21) bool {
    return self.math.isMathSymbol(cp) or self.modifier.isModifierSymbol(cp) or
        self.currency.isCurrencySymbol(cp) or self.other.isOtherSymbol(cp);
}

/// isAsciiSymbol detects ASCII only symbols.
pub fn isAsciiSymbol(self: Self, cp: u21) bool {
    return if (cp < 128) ascii.isSymbol(@intCast(u8, cp)) else false;
}

test "isSymbol" {
    var z = try init(std.testing.allocator);
    defer z.deinit();

    std.testing.expect(z.isSymbol('<'));
    std.testing.expect(z.isSymbol('>'));
    std.testing.expect(z.isSymbol('='));
    std.testing.expect(z.isSymbol('$'));
    std.testing.expect(z.isSymbol('^'));
    std.testing.expect(z.isSymbol('+'));
    std.testing.expect(z.isSymbol('|'));
    std.testing.expect(!z.isSymbol('A'));
    std.testing.expect(!z.isSymbol('?'));
}
