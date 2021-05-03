const std = @import("std");
const mem = std.mem;
const ascii = @import("../../ascii.zig");

pub const Close = @import("../../components.zig").Close;
pub const Connector = @import("../../components.zig").Connector;
pub const Dash = @import("../../components.zig").Dash;
pub const Final = @import("../../components.zig").Final;
pub const Initial = @import("../../components.zig").Initial;
pub const Open = @import("../../components.zig").Open;
pub const OtherPunct = @import("../../components.zig").OtherPunct;

const Self = @This();

allocator: *mem.Allocator,
close: *Close,
connector: *Connector,
dash: *Dash,
final: *Final,
initial: *Initial,
open: *Open,
other_punct: *OtherPunct,

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
        .close = try Close.init(allocator),
        .connector = try Connector.init(allocator),
        .dash = try Dash.init(allocator),
        .final = try Final.init(allocator),
        .initial = try Initial.init(allocator),
        .open = try Open.init(allocator),
        .other_punct = try OtherPunct.init(allocator),
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
            self.close.deinit();
            self.connector.deinit();
            self.dash.deinit();
            self.final.deinit();
            self.initial.deinit();
            self.open.deinit();
            self.other_punct.deinit();

            self.allocator.destroy(s.instance);
            singleton = null;
        }
    }
}

/// isPunct detects punctuation characters. Note some punctuation maybe considered symbols by Unicode.
pub fn isPunct(self: Self, cp: u21) bool {
    return self.close.isClosePunctuation(cp) or self.connector.isConnectorPunctuation(cp) or
        self.dash.isDashPunctuation(cp) or self.final.isFinalPunctuation(cp) or
        self.initial.isInitialPunctuation(cp) or self.open.isOpenPunctuation(cp) or
        self.other_punct.isOtherPunctuation(cp);
}

/// isAsciiPunct detects ASCII only punctuation.
pub fn isAsciiPunct(cp: u21) bool {
    return if (cp < 128) ascii.isPunct(@intCast(u8, cp)) else false;
}

const expect = std.testing.expect;

test "Component isPunct" {
    var punct = try init(std.testing.allocator);
    defer punct.deinit();

    expect(punct.isPunct('!'));
    expect(punct.isPunct('?'));
    expect(punct.isPunct(','));
    expect(punct.isPunct('.'));
    expect(punct.isPunct(':'));
    expect(punct.isPunct(';'));
    expect(punct.isPunct('\''));
    expect(punct.isPunct('"'));
    expect(punct.isPunct('¿'));
    expect(punct.isPunct('¡'));
    expect(punct.isPunct('-'));
    expect(punct.isPunct('('));
    expect(punct.isPunct(')'));
    expect(punct.isPunct('{'));
    expect(punct.isPunct('}'));
    expect(punct.isPunct('–'));
    // Punct? in Unicode.
    expect(punct.isPunct('@'));
    expect(punct.isPunct('#'));
    expect(punct.isPunct('%'));
    expect(punct.isPunct('&'));
    expect(punct.isPunct('*'));
    expect(punct.isPunct('_'));
    expect(punct.isPunct('/'));
    expect(punct.isPunct('\\'));
    expect(!punct.isPunct('\u{0003}'));
}
