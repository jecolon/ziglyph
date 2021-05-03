const std = @import("std");
const mem = std.mem;
const ascii = @import("../../ascii.zig");

const Context = @import("../../context.zig").Context;
pub const Currency = @import("../../context.zig").Currency;
pub const Math = @import("../../context.zig").Math;
pub const ModifierSymbol = @import("../../context.zig").ModifierSymbol;
pub const OtherSymbol = @import("../../context.zig").OtherSymbol;

const Self = @This();

currency: *Currency,
math: *Math,
modifier_symbol: *ModifierSymbol,
other_symbol: *OtherSymbol,
sctx: ?*Context(.symbol),

pub fn init(allocator: *mem.Allocator) !Self {
    var sctx = try Context(.symbol).init(allocator);

    return Self{
        .currency = sctx.currency,
        .math = sctx.math,
        .modifier_symbol = sctx.modifier_symbol,
        .other_symbol = sctx.other_symbol,
        .sctx = sctx,
    };
}

pub fn deinit(self: *Self) void {
    if (self.sctx) |sctx| sctx.deinit();
}

pub fn initWithContext(ctx: anytype) Self {
    return Self{
        .currency = ctx.currency,
        .math = ctx.math,
        .modifier_symbol = ctx.modifier_symbol,
        .other_symbol = ctx.other_symbol,
        .sctx = null,
    };
}

// isSymbol detects symbols which curiosly may include some code points commonly thought of as
// punctuation.
pub fn isSymbol(self: Self, cp: u21) bool {
    return self.math.isMathSymbol(cp) or self.modifier_symbol.isModifierSymbol(cp) or
        self.currency.isCurrencySymbol(cp) or self.other_symbol.isOtherSymbol(cp);
}

/// isAsciiSymbol detects ASCII only symbols.
pub fn isAsciiSymbol(cp: u21) bool {
    return if (cp < 128) ascii.isSymbol(@intCast(u8, cp)) else false;
}

const expect = std.testing.expect;

test "Component isSymbol" {
    var symbol = try init(std.testing.allocator);
    defer symbol.deinit();

    expect(symbol.isSymbol('<'));
    expect(symbol.isSymbol('>'));
    expect(symbol.isSymbol('='));
    expect(symbol.isSymbol('$'));
    expect(symbol.isSymbol('^'));
    expect(symbol.isSymbol('+'));
    expect(symbol.isSymbol('|'));
    expect(!symbol.isSymbol('A'));
    expect(!symbol.isSymbol('?'));
}
