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

pub const Ziglyph = struct {
    allocator: *mem.Allocator,
    control: Control,
    decomp_map: DecomposeMap,
    letter: Letter,
    lower: Lower,
    lower_map: LowerMap,
    mark: Mark,
    number: Number,
    punct: Punct,
    space: Space,
    symbol: Symbol,
    title: Title,
    title_map: TitleMap,
    upper: Upper,
    upper_map: UpperMap,

    pub fn init(allocator: *mem.Allocator) !Ziglyph {
        return Ziglyph{
            .allocator = allocator,
            .control = try Control.init(allocator),
            .decomp_map = try DecomposeMap.init(allocator),
            .letter = try Letter.init(allocator),
            .lower = try Lower.init(allocator),
            .lower_map = try LowerMap.init(allocator),
            .mark = try Mark.init(allocator),
            .number = try Number.init(allocator),
            .punct = try Punct.init(allocator),
            .space = try Space.init(allocator),
            .symbol = try Symbol.init(allocator),
            .title = try Title.init(allocator),
            .title_map = try TitleMap.init(allocator),
            .upper = try Upper.init(allocator),
            .upper_map = try UpperMap.init(allocator),
        };
    }

    const Self = @This();
    pub fn deinit(self: *Self) void {
        self.control.deinit();
        self.decomp_map.deinit();
        self.letter.deinit();
        self.lower.deinit();
        self.lower_map.deinit();
        self.mark.deinit();
        self.number.deinit();
        self.punct.deinit();
        self.space.deinit();
        self.symbol.deinit();
        self.title.deinit();
        self.title_map.deinit();
        self.upper.deinit();
        self.upper_map.deinit();
    }

    pub fn isAlphaNum(self: Self, cp: u21) bool {
        return self.letter.isLetter(cp) or self.number.isNumber(cp);
    }

    pub fn isGraphic(self: Self, cp: u21) bool {
        return self.isPrint(cp) or self.space.isSpace(cp);
    }

    pub fn isPrint(self: Self, cp: u21) bool {
        return self.isAlphaNum(cp) or self.mark.isMark(cp) or self.punct.isPunct(cp) or self.symbol.isSymbol(cp);
    }

    pub fn isWhiteSpace(self: Self, cp: u21) bool {
        const ascii = @import("std").ascii;
        if (cp < 256) {
            return ascii.isSpace(@intCast(u8, cp));
        } else {
            return self.space.isSpace(cp);
        }
    }

    pub fn isControl(self: Self, cp: u21) bool {
        return self.control.isControl(cp);
    }

    pub fn isLetter(self: Self, cp: u21) bool {
        return self.letter.isLetter(cp);
    }

    pub fn isLower(self: Self, cp: u21) bool {
        return self.lower.isLower(cp);
    }

    pub fn toLower(self: Self, cp: u21) u21 {
        return self.lower_map.toLower(cp);
    }

    pub fn isMark(self: Self, cp: u21) bool {
        return self.mark.isMark(cp);
    }

    pub fn isNumber(self: Self, cp: u21) bool {
        return self.number.isNumber(cp);
    }

    pub fn isPunct(self: Self, cp: u21) bool {
        return self.punct.isPunct(cp);
    }

    pub fn isSpace(self: Self, cp: u21) bool {
        return self.space.isSpace(cp);
    }

    pub fn isSymbol(self: Self, cp: u21) bool {
        return self.symbol.isSymbol(cp);
    }

    pub fn isTitle(self: Self, cp: u21) bool {
        return self.title.isTitle(cp);
    }

    pub fn isUpper(self: Self, cp: u21) bool {
        return self.upper.isUpper(cp);
    }

    pub fn toTitle(self: Self, cp: u21) u21 {
        return self.title_map.toTitle(cp);
    }

    pub fn toUpper(self: Self, cp: u21) u21 {
        return self.upper_map.toUpper(cp);
    }

    pub fn decomposeCodePoint(self: Self, cp: u21) []const u21 {
        return self.decomp_map.decomposeCodePoint(cp);
    }

    pub fn decomposeString(self: Self, str: []const u8) []const u8 {
        return self.decomp_map.decomposeString(str);
    }
};
