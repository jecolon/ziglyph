const std = @import("std");
const mem = std.mem;
const ascii = @import("../../ascii.zig");

const Context = @import("../../Context.zig");

const Self = @This();

context: *Context,

pub fn new(ctx: *Context) Self {
    return Self{ .context = ctx };
}

/// isPunct detects punctuation characters. Note some punctuation maybe considered symbols by Unicode.
pub fn isPunct(self: Self, cp: u21) bool {
    return self.context.close.isClosePunctuation(cp) or self.context.connector.isConnectorPunctuation(cp) or
        self.context.dash.isDashPunctuation(cp) or self.context.final.isFinalPunctuation(cp) or
        self.context.initial.isInitialPunctuation(cp) or self.context.open.isOpenPunctuation(cp) or
        self.context.other_punct.isOtherPunctuation(cp);
}

/// isAsciiPunct detects ASCII only punctuation.
pub fn isAsciiPunct(cp: u21) bool {
    return if (cp < 128) ascii.isPunct(@intCast(u8, cp)) else false;
}

const expect = std.testing.expect;

test "Component isPunct" {
    var ctx = try Context.init(std.testing.allocator);
    defer ctx.deinit();

    var punct = new(&ctx);

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
