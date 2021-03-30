//! Ziglyph provides Unicode processing in Zig.
//! To minimize memory requirements and binary size, this library is divided into component structs
//! that provide specific pieces of functionality. For a consolidated struct with the most frequently
//! used functionality, see the Ziglyph struct below.

const std = @import("std");
const mem = std.mem;

/// Control code points like form feed.
pub const Control = @import("components/Control.zig");
/// Code point decomposition.
pub const DecomposeMap = @import("components/DecomposeMap.zig");
/// Unicode letters.
pub const Letter = @import("components/Letter.zig");
/// Lowercase letters.
pub const Lower = @import("components/Lower.zig");
/// Marks from different alphabets.
pub const Mark = @import("components/Mark.zig");
/// Unicode numbers.
pub const Number = @import("components/Number.zig");
/// Punctuation code points.
pub const Punct = @import("components/Punct.zig");
/// Unicode space code points.
pub const Space = @import("components/Space.zig");
/// All sorts of symbols.
pub const Symbol = @import("components/Symbol.zig");
/// Titlecase letters.
pub const Title = @import("components/Title.zig");
/// Uppercase letters.
pub const Upper = @import("components/Upper.zig");

/// Mapping to lowercase.
pub const LowerMap = @import("components/LowerMap.zig");
/// Mapping to titlecase.
pub const TitleMap = @import("components/TitleMap.zig");
/// Mapping to uppercase.
pub const UpperMap = @import("components/UpperMap.zig");

/// Ziglyph consolidates all the major Unicode utility functions in one place. Because these functions
/// each consume memory for their respective code point data, this struct performs lazy initialization
/// to only consume memory when needed.
pub const Ziglyph = struct {
    allocator: *mem.Allocator,
    control: ?Control = null,
    letter: ?Letter = null,
    lower: ?Lower = null,
    lower_map: ?LowerMap = null,
    mark: ?Mark = null,
    number: ?Number = null,
    punct: ?Punct = null,
    space: ?Space = null,
    symbol: ?Symbol = null,
    title: ?Title = null,
    title_map: ?TitleMap = null,
    upper: ?Upper = null,
    upper_map: ?UpperMap = null,

    pub fn init(allocator: *mem.Allocator) !Ziglyph {
        return Ziglyph{
            .allocator = allocator,
        };
    }

    const Self = @This();

    pub fn deinit(self: *Self) void {
        if (self.control) |*control| {
            control.deinit();
        }
        if (self.letter) |*letter| {
            letter.deinit();
        }
        if (self.lower) |*lower| {
            lower.deinit();
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

    /// isAlphaNum covers all the Unicode letter and number space, not just ASCII.
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

    /// isGraphic detects any code point that can be represented graphically, including spaces.
    pub fn isGraphic(self: *Self, cp: u21) !bool {
        // Lazy init.
        if (self.space == null) {
            self.space = try Space.init(self.allocator);
        }

        return (try self.isPrint(cp)) or self.space.?.isSpace(cp);
    }

    /// isPrint detects any code point that can be printed, but not spaces.
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

    /// isControl detects control code points such as form feeds.
    pub fn isControl(self: *Self, cp: u21) !bool {
        // Lazy init.
        if (self.control == null) {
            self.control = try Control.init(self.allocator);
        }

        return self.control.?.isControl(cp);
    }

    /// isLetter covers all letters in Unicode, not just ASCII.
    pub fn isLetter(self: *Self, cp: u21) !bool {
        // Lazy init.
        if (self.letter == null) {
            self.letter = try Letter.init(self.allocator);
        }

        return self.letter.?.isLetter(cp);
    }

    /// isLower detects code points that are lowercase.
    pub fn isLower(self: *Self, cp: u21) !bool {
        // Lazy init.
        if (self.lower == null) {
            self.lower = try Lower.init(self.allocator);
        }

        return self.lower.?.isLower(cp);
    }

    /// isMark detects special code points that serve as marks in different alphabets.
    pub fn isMark(self: *Self, cp: u21) !bool {
        // Lazy init.
        if (self.mark == null) {
            self.mark = try Mark.init(self.allocator);
        }

        return self.mark.?.isMark(cp);
    }

    /// isNumber covers all Unicode numbers, not just ASII.
    pub fn isNumber(self: *Self, cp: u21) !bool {
        // Lazy init.
        if (self.number == null) {
            self.number = try Number.init(self.allocator);
        }

        return self.number.?.isNumber(cp);
    }

    /// isPunct detects punctuation characters. Note some punctuation maybe considered symbols by Unicode.
    pub fn isPunct(self: *Self, cp: u21) !bool {
        // Lazy init.
        if (self.punct == null) {
            self.punct = try Punct.init(self.allocator);
        }

        return self.punct.?.isPunct(cp);
    }

    /// isSpace adheres to the strict meaning of space as per Unicode, excluding some control characters
    /// such as tab \t.
    pub fn isSpace(self: *Self, cp: u21) !bool {
        // Lazy init.
        if (self.space == null) {
            self.space = try Space.init(self.allocator);
        }

        return self.space.?.isSpace(cp);
    }

    // isSymbol detects symbols which curiosly may include some code points commonly thought of as
    // punctuation.
    pub fn isSymbol(self: *Self, cp: u21) !bool {
        // Lazy init.
        if (self.symbol == null) {
            self.symbol = try Symbol.init(self.allocator);
        }

        return self.symbol.?.isSymbol(cp);
    }

    /// isTitle detects code points in titlecase.
    pub fn isTitle(self: *Self, cp: u21) !bool {
        // Lazy init.
        if (self.title == null) {
            self.title = try Title.init(self.allocator);
        }

        return self.title.?.isTitle(cp);
    }

    /// isTitle detects code points in uppercase.
    pub fn isUpper(self: *Self, cp: u21) !bool {
        // Lazy init.
        if (self.upper == null) {
            self.upper = try Upper.init(self.allocator);
        }

        return self.upper.?.isUpper(cp);
    }

    /// isWhiteSpace detects space code points including some (like tab: \t) not considered as such 
    /// by Unicode (as is the cse with the isSpace method).
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

    /// toLower returns the lowercase code point for the given code point. It returns the same 
    /// code point given if no mapping exists.
    pub fn toLower(self: *Self, cp: u21) !u21 {
        // Lazy init.
        if (self.lower_map == null) {
            self.lower_map = try LowerMap.init(self.allocator);
        }

        return self.lower_map.?.toLower(cp);
    }

    /// toTitle returns the titlecase code point for the given code point. It returns the same 
    /// code point given if no mapping exists.
    pub fn toTitle(self: *Self, cp: u21) !u21 {
        // Lazy init.
        if (self.title_map == null) {
            self.title_map = try TitleMap.init(self.allocator);
        }

        return self.title_map.?.toTitle(cp);
    }

    /// toUpper returns the uppercase code point for the given code point. It returns the same 
    /// code point given if no mapping exists.
    pub fn toUpper(self: *Self, cp: u21) !u21 {
        // Lazy init.
        if (self.upper_map == null) {
            self.upper_map = try UpperMap.init(self.allocator);
        }

        return self.upper_map.?.toUpper(cp);
    }
};
