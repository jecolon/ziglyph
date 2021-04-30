const std = @import("std");
const mem = std.mem;
const ascii = @import("../../ascii.zig");

const Context = @import("../../Context.zig");

const Self = @This();

context: *Context,

pub fn new(ctx: *Context) Self {
    return Self{ .context = ctx };
}

// isSymbol detects symbols which curiosly may include some code points commonly thought of as
// punctuation.
pub fn isSymbol(self: Self, cp: u21) bool {
    return self.context.math.isMathSymbol(cp) or self.context.modifier_symbol.isModifierSymbol(cp) or
        self.context.currency.isCurrencySymbol(cp) or self.context.other_symbol.isOtherSymbol(cp);
}

/// isAsciiSymbol detects ASCII only symbols.
pub fn isAsciiSymbol(cp: u21) bool {
    return if (cp < 128) ascii.isSymbol(@intCast(u8, cp)) else false;
}

const expect = std.testing.expect;

test "Component isSymbol" {
    var ctx = try Context.init(std.testing.allocator);
    defer ctx.deinit();

    var symbol = new(&ctx);

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
