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
close: ?Close = null,
connector: ?Connector = null,
dash: ?Dash = null,
final: ?Final = null,
initial: ?Initial = null,
open: ?Open = null,
other: ?Other = null,

pub fn init(allocator: *mem.Allocator) !Self {
    return Self{ .allocator = allocator };
}

pub fn deinit(self: *Self) void {
    if (self.close) |*close| close.deinit();
    if (self.connector) |*connector| connector.deinit();
    if (self.dash) |*dash| dash.deinit();
    if (self.final) |*final| final.deinit();
    if (self.initial) |*initial| initial.deinit();
    if (self.open) |*open| open.deinit();
    if (self.other) |*other| other.deinit();
}

/// isPunct detects punctuation characters. Note some punctuation maybe considered symbols by Unicode.
pub fn isPunct(self: *Self, cp: u21) !bool {
    // Lazy init.
    if (self.close == null) self.close = try Close.init(self.allocator);
    if (self.connector == null) self.connector = try Connector.init(self.allocator);
    if (self.dash == null) self.dash = try Dash.init(self.allocator);
    if (self.final == null) self.final = try Final.init(self.allocator);
    if (self.initial == null) self.initial = try Initial.init(self.allocator);
    if (self.open == null) self.open = try Open.init(self.allocator);
    if (self.other == null) self.other = try Other.init(self.allocator);

    return self.close.?.isClosePunctuation(cp) or self.connector.?.isConnectorPunctuation(cp) or
        self.dash.?.isDashPunctuation(cp) or self.final.?.isFinalPunctuation(cp) or
        self.initial.?.isInitialPunctuation(cp) or self.open.?.isOpenPunctuation(cp) or
        self.other.?.isOtherPunctuation(cp);
}

/// isAsciiPunct detects ASCII only punctuation.
pub fn isAsciiPunct(self: Self, cp: u21) bool {
    return if (cp < 128) ascii.isPunct(@intCast(u8, cp)) else false;
}
