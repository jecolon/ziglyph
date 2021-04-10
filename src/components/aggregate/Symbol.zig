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
currency: ?Currency = null,
math: ?Math = null,
modifier: ?Modifier = null,
other: ?Other = null,

pub fn init(allocator: *mem.Allocator) !Self {
    return Self{ .allocator = allocator };
}

pub fn deinit(self: *Self) void {
    if (self.currency) |*currency| currency.deinit();
    if (self.math) |*math| math.deinit();
    if (self.modifier) |*modifier| modifier.deinit();
    if (self.other) |*other| other.deinit();
}

// isSymbol detects symbols which curiosly may include some code points commonly thought of as
// punctuation.
pub fn isSymbol(self: *Self, cp: u21) !bool {
    // Lazy init.
    if (self.math == null) self.math = try Math.init(self.allocator);
    if (self.modifier == null) self.modifier = try Modifier.init(self.allocator);
    if (self.currency == null) self.currency = try Currency.init(self.allocator);
    if (self.other == null) self.other = try Other.init(self.allocator);

    return self.math.?.isMathSymbol(cp) or self.modifier.?.isModifierSymbol(cp) or
        self.currency.?.isCurrencySymbol(cp) or self.other.?.isOtherSymbol(cp);
}

/// isAsciiSymbol detects ASCII only symbols.
pub fn isAsciiSymbol(self: Self, cp: u21) bool {
    return if (cp < 128) ascii.isSymbol(@intCast(u8, cp)) else false;
}
