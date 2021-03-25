const std = @import("std");
const mem = std.mem;

pub const Control = @import("data/Control.zig");
pub const DecomposeMap = @import("data/DecomposeMap.zig");
pub const Letter = @import("data/Letter.zig");
pub const Lower = @import("data/Lower.zig");
pub const Mark = @import("data/Mark.zig");
pub const Number = @import("data/Number.zig");
pub const Punct = @import("data/Punct.zig");
pub const Space = @import("data/Space.zig");
pub const Symbol = @import("data/Symbol.zig");
pub const Title = @import("data/Title.zig");
pub const Upper = @import("data/Upper.zig");

pub const LowerMap = @import("data/LowerMap.zig");
pub const TitleMap = @import("data/TitleMap.zig");
pub const UpperMap = @import("data/UpperMap.zig");

/// Ziglyph consolidates all the major Unicode utility functions in one place. Because these functions
/// each allocate space for their respective code point data, this struct performs lazy initialization
/// to only allocate when needed. This in turn requires that the functions return error unions instead
/// of the simple values that the counterpart functions in the various sub-structs of this library return.
pub const Ziglyph = struct {
    allocator: *mem.Allocator,
    control: ?Control,
    decomp_map: ?DecomposeMap,
    letter: ?Letter,
    lower: ?Lower,
    lower_map: ?LowerMap,
    mark: ?Mark,
    number: ?Number,
    punct: ?Punct,
    space: ?Space,
    symbol: ?Symbol,
    title: ?Title,
    title_map: ?TitleMap,
    upper: ?Upper,
    upper_map: ?UpperMap,

    pub fn init(allocator: *mem.Allocator) Ziglyph {
        return Ziglyph{
            .allocator = allocator,
            .control = null,
            .decomp_map = null,
            .letter = null,
            .lower = null,
            .lower_map = null,
            .mark = null,
            .number = null,
            .punct = null,
            .space = null,
            .symbol = null,
            .title = null,
            .title_map = null,
            .upper = null,
            .upper_map = null,
        };
    }

    const Self = @This();
    pub fn deinit(self: *Self) void {
        if (self.control) |*control| {
            control.deinit();
        }
        if (self.decomp_map) |*decomp_map| {
            decomp_map.deinit();
        }
        if (self.letter) |*letter| {
            letter.deinit();
        }
        if (self.lower) |*lower| {
            lower.deinit();
        }
        if (self.lower_map) |*lower_map| {
            lower_map.deinit();
        }
        if (self.mark) |*mark| {
            mark.deinit();
        }
        if (self.number) |*number| {
            number.deinit();
        }
        if (self.punct) |*punct| {
            punct.deinit();
        }
        if (self.space) |*space| {
            space.deinit();
        }
        if (self.symbol) |*symbol| {
            symbol.deinit();
        }
        if (self.title) |*title| {
            title.deinit();
        }
        if (self.title_map) |*title_map| {
            title_map.deinit();
        }
        if (self.upper) |*upper| {
            upper.deinit();
        }
        if (self.upper_map) |*upper_map| {
            upper_map.deinit();
        }
    }

    pub fn isAlphaNum(self: *Self, cp: u21) !bool {
        // Lazy init.
        if (self.letter == null) {
            self.letter = try Letter.init(self.allocator);
        }
        if (self.number == null) {
            self.number = try Number.init(self.allocator);
        }

        return self.letter.?.isLetter(cp) or self.number.?.isNumber(cp);
    }

    pub fn isGraphic(self: *Self, cp: u21) !bool {
        // Lazy init.
        if (self.space == null) {
            self.space = try Space.init(self.allocator);
        }

        return (try self.isPrint(cp)) or self.space.?.isSpace(cp);
    }

    pub fn isPrint(self: *Self, cp: u21) !bool {
        // Lazy init.
        if (self.mark == null) {
            self.mark = try Mark.init(self.allocator);
        }
        if (self.punct == null) {
            self.punct = try Punct.init(self.allocator);
        }
        if (self.symbol == null) {
            self.symbol = try Symbol.init(self.allocator);
        }

        return (try self.isAlphaNum(cp)) or self.mark.?.isMark(cp) or self.punct.?.isPunct(cp) or self.symbol.?.isSymbol(cp);
    }

    pub fn isWhiteSpace(self: *Self, cp: u21) !bool {
        const ascii = @import("std").ascii;
        if (cp < 256) {
            return ascii.isSpace(@intCast(u8, cp));
        } else {
            // Lazy init.
            if (self.space == null) {
                self.space = try Space.init(self.allocator);
            }

            return self.space.?.isSpace(cp);
        }
    }

    pub fn isControl(self: *Self, cp: u21) !bool {
        // Lazy init.
        if (self.control == null) {
            self.control = try Control.init(self.allocator);
        }

        return self.control.?.isControl(cp);
    }

    pub fn isLetter(self: *Self, cp: u21) !bool {
        // Lazy init.
        if (self.letter == null) {
            self.letter = try Letter.init(self.allocator);
        }

        return self.letter.?.isLetter(cp);
    }

    pub fn isLower(self: *Self, cp: u21) !bool {
        // Lazy init.
        if (self.lower == null) {
            self.lower = try Lower.init(self.allocator);
        }

        return self.lower.?.isLower(cp);
    }

    pub fn isMark(self: *Self, cp: u21) !bool {
        // Lazy init.
        if (self.mark == null) {
            self.mark = try Mark.init(self.allocator);
        }

        return self.mark.?.isMark(cp);
    }

    pub fn isNumber(self: *Self, cp: u21) !bool {
        // Lazy init.
        if (self.number == null) {
            self.number = try Number.init(self.allocator);
        }

        return self.number.?.isNumber(cp);
    }

    pub fn isPunct(self: *Self, cp: u21) !bool {
        // Lazy init.
        if (self.punct == null) {
            self.punct = try Punct.init(self.allocator);
        }

        return self.punct.?.isPunct(cp);
    }

    pub fn isSpace(self: *Self, cp: u21) !bool {
        // Lazy init.
        if (self.space == null) {
            self.space = try Space.init(self.allocator);
        }

        return self.space.?.isSpace(cp);
    }

    pub fn isSymbol(self: *Self, cp: u21) !bool {
        // Lazy init.
        if (self.symbol == null) {
            self.symbol = try Symbol.init(self.allocator);
        }

        return self.symbol.?.isSymbol(cp);
    }

    pub fn isTitle(self: *Self, cp: u21) !bool {
        // Lazy init.
        if (self.title == null) {
            self.title = try Title.init(self.allocator);
        }

        return self.title.?.isTitle(cp);
    }

    pub fn isUpper(self: *Self, cp: u21) !bool {
        // Lazy init.
        if (self.upper == null) {
            self.upper = try Upper.init(self.allocator);
        }

        return self.upper.?.isUpper(cp);
    }

    pub fn toLower(self: *Self, cp: u21) !u21 {
        // Lazy init.
        if (self.lower_map == null) {
            self.lower_map = try LowerMap.init(self.allocator);
        }

        return self.lower_map.toLower(cp);
    }

    pub fn toTitle(self: *Self, cp: u21) !u21 {
        // Lazy init.
        if (self.title_map == null) {
            self.title_map = try TitleMap.init(self.allocator);
        }

        return self.title_map.toTitle(cp);
    }

    pub fn toUpper(self: *Self, cp: u21) !u21 {
        // Lazy init.
        if (self.upper_map == null) {
            self.upper_map = try UpperMap.init(self.allocator);
        }

        return self.upper_map.toUpper(cp);
    }

    pub fn decomposeCodePoint(self: *Self, cp: u21) ![]const u21 {
        // Lazy init.
        if (self.decomp_map == null) {
            self.decomp_map = try DecompMap.init(self.allocator);
        }

        return self.decomp_map.?.decomposeCodePoint(cp);
    }

    pub fn decomposeString(self: *Self, str: []const u8) []const u8 {
        // Lazy init.
        if (self.decomp_map == null) {
            self.decomp_map = try DecompMap.init(self.allocator);
        }

        return self.decomp_map.?.decomposeString(str);
    }
};
