const std = @import("std");
const mem = std.mem;
const ascii = @import("../../ascii.zig");

pub const Currency = @import("../../components.zig").Currency;
pub const Math = @import("../../components.zig").Math;
pub const ModifierSymbol = @import("../../components.zig").ModifierSymbol;
pub const OtherSymbol = @import("../../components.zig").OtherSymbol;

const Self = @This();

allocator: *mem.Allocator,
currency: *Currency,
math: *Math,
modifier_symbol: *ModifierSymbol,
other_symbol: *OtherSymbol,

const Singleton = struct {
    instance: *Self,
    ref_count: usize,
};

var singleton: ?Singleton = null;

pub fn init(allocator: *mem.Allocator) !*Self {
    if (singleton) |*s| {
        s.ref_count += 1;
        return s.instance;
    }

    var instance = try allocator.create(Self);

    instance.* = Self{
        .allocator = allocator,
        .currency = try Currency.init(allocator),
        .math = try Math.init(allocator),
        .modifier_symbol = try ModifierSymbol.init(allocator),
        .other_symbol = try OtherSymbol.init(allocator),
    };

    singleton = Singleton{
        .instance = instance,
        .ref_count = 1,
    };

    return instance;
}

pub fn deinit(self: *Self) void {
    if (singleton) |*s| {
        s.ref_count -= 1;
        if (s.ref_count == 0) {
            self.currency.deinit();
            self.math.deinit();
            self.modifier_symbol.deinit();
            self.other_symbol.deinit();

            self.allocator.destroy(s.instance);
            singleton = null;
        }
    }
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
