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
pub fn isPunct(self: Self, cp: u21) !bool {
    const close = try self.context.getClose();
    const connector = try self.context.getConnector();
    const dash = try self.context.getDash();
    const final = try self.context.getFinal();
    const initial = try self.context.getInitial();
    const open = try self.context.getOpen();
    const other_punct = try self.context.getOtherPunct();

    return close.isClosePunctuation(cp) or connector.isConnectorPunctuation(cp) or
        dash.isDashPunctuation(cp) or final.isFinalPunctuation(cp) or
        initial.isInitialPunctuation(cp) or open.isOpenPunctuation(cp) or
        other_punct.isOtherPunctuation(cp);
}

/// isAsciiPunct detects ASCII only punctuation.
pub fn isAsciiPunct(cp: u21) bool {
    return if (cp < 128) ascii.isPunct(@intCast(u8, cp)) else false;
}

const expect = std.testing.expect;

test "Component isPunct" {
    var ctx = Context.init(std.testing.allocator);
    defer ctx.deinit();

    var punct = new(&ctx);

    expect(try punct.isPunct('!'));
    expect(try punct.isPunct('?'));
    expect(try punct.isPunct(','));
    expect(try punct.isPunct('.'));
    expect(try punct.isPunct(':'));
    expect(try punct.isPunct(';'));
    expect(try punct.isPunct('\''));
    expect(try punct.isPunct('"'));
    expect(try punct.isPunct('¿'));
    expect(try punct.isPunct('¡'));
    expect(try punct.isPunct('-'));
    expect(try punct.isPunct('('));
    expect(try punct.isPunct(')'));
    expect(try punct.isPunct('{'));
    expect(try punct.isPunct('}'));
    expect(try punct.isPunct('–'));
    // Punct? in Unicode.
    expect(try punct.isPunct('@'));
    expect(try punct.isPunct('#'));
    expect(try punct.isPunct('%'));
    expect(try punct.isPunct('&'));
    expect(try punct.isPunct('*'));
    expect(try punct.isPunct('_'));
    expect(try punct.isPunct('/'));
    expect(try punct.isPunct('\\'));
    expect(!try punct.isPunct('\u{0003}'));
}
