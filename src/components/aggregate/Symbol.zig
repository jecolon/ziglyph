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
pub fn isSymbol(self: Self, cp: u21) !bool {
    const math = try self.context.getMath();
    const modifier_symbol = try self.context.getModifierSymbol();
    const currency = try self.context.getCurrency();
    const other_symbol = try self.context.getOtherSymbol();

    return math.isMathSymbol(cp) or modifier_symbol.isModifierSymbol(cp) or
        currency.isCurrencySymbol(cp) or other_symbol.isOtherSymbol(cp);
}

/// isAsciiSymbol detects ASCII only symbols.
pub fn isAsciiSymbol(cp: u21) bool {
    return if (cp < 128) ascii.isSymbol(@intCast(u8, cp)) else false;
}

const expect = std.testing.expect;

test "Component isSymbol" {
    var ctx = Context.init(std.testing.allocator);
    defer ctx.deinit();

    var symbol = new(&ctx);

    expect(try symbol.isSymbol('<'));
    expect(try symbol.isSymbol('>'));
    expect(try symbol.isSymbol('='));
    expect(try symbol.isSymbol('$'));
    expect(try symbol.isSymbol('^'));
    expect(try symbol.isSymbol('+'));
    expect(try symbol.isSymbol('|'));
    expect(!try symbol.isSymbol('A'));
    expect(!try symbol.isSymbol('?'));
}
