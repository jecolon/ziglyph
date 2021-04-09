//! Ziglyph provides Unicode processing in Zig.
//! To minimize memory requirements and binary size, this library is divided into component structs
//! that provide specific pieces of functionality. For a consolidated struct with the most frequently
//! used functionality, see the Ziglyph struct below.

const std = @import("std");
const mem = std.mem;
const ascii = @import("ascii.zig");

/// Alphabeticbetic code points.
pub const Alphabetic = @import("components/DerivedCoreProperties/Alphabetic.zig");
/// Cased code points are either lower, upper, or title cased, but not all three.
pub const Cased = @import("components/DerivedCoreProperties/Cased.zig");
/// Control code points like form feed.
pub const Control = @import("components/DerivedGeneralCategory/Control.zig");
/// Decimal code points.
pub const Decimal = @import("components/DerivedGeneralCategory/DecimalNumber.zig");
/// Digit code points.
pub const Digit = @import("components/DerivedNumericType/Digit.zig");
/// Hexadecimal digits.
pub const HexDigit = @import("components/PropList/HexDigit.zig");
/// Lowercase letters.
pub const Lower = @import("components/DerivedGeneralCategory/LowercaseLetter.zig");
const ModLetter = @import("components/DerivedGeneralCategory/ModifierLetter.zig");
const OtherLetter = @import("components/DerivedGeneralCategory/OtherLetter.zig");
/// Titlecase letters.
pub const Title = @import("components/DerivedGeneralCategory/TitlecaseLetter.zig");
/// Uppercase letters.
pub const Upper = @import("components/DerivedGeneralCategory/UppercaseLetter.zig");
/// Marks.
const SpacingMark = @import("components/DerivedGeneralCategory/SpacingMark.zig");
const NonSpacingMark = @import("components/DerivedGeneralCategory/NonspacingMark.zig");
const EnclosingMark = @import("components/DerivedGeneralCategory/EnclosingMark.zig");
/// Numbers.
const LetterNumber = @import("components/DerivedGeneralCategory/LetterNumber.zig");
const OtherNumber = @import("components/DerivedGeneralCategory/OtherNumber.zig");
/// Punctuation.
const ClosePunct = @import("components/DerivedGeneralCategory/ClosePunctuation.zig");
const ConnectPunct = @import("components/DerivedGeneralCategory/ConnectorPunctuation.zig");
const DashPunct = @import("components/DerivedGeneralCategory/DashPunctuation.zig");
const InitialPunct = @import("components/DerivedGeneralCategory/InitialPunctuation.zig");
const OpenPunct = @import("components/DerivedGeneralCategory/OpenPunctuation.zig");
const OtherPunct = @import("components/DerivedGeneralCategory/OtherPunctuation.zig");
/// Symbols
pub const MathSymbol = @import("components/DerivedGeneralCategory/MathSymbol.zig");
const ModSymbol = @import("components/DerivedGeneralCategory/ModifierSymbol.zig");
pub const CurrencySymbol = @import("components/DerivedGeneralCategory/CurrencySymbol.zig");
const OtherSymbol = @import("components/DerivedGeneralCategory/OtherSymbol.zig");
/// WhiteSpace.
pub const WhiteSpace = @import("components/PropList/WhiteSpace.zig");

/// Case fold mappings.
pub const CaseFoldMap = @import("components/CaseFolding/CaseFoldMap.zig");
/// Code point decomposition.
pub const DecomposeMap = @import("components/UnicodeData/DecomposeMap.zig");
/// Mapping to lowercase.
pub const LowerMap = @import("components/UnicodeData/LowerMap.zig");
/// Mapping to titlecase.
pub const TitleMap = @import("components/UnicodeData/TitleMap.zig");
/// Mapping to uppercase.
pub const UpperMap = @import("components/UnicodeData/UpperMap.zig");

/// Ziglyph consolidates all the major Unicode utility functions in one place. Because these functions
/// each consume memory for their respective code point data, this struct performs lazy initialization
/// to only consume memory when needed.
pub const Ziglyph = struct {
    allocator: *mem.Allocator,
    alpha: ?Alphabetic = null,
    cased: ?Cased = null,
    control: ?Control = null,
    decimal: ?Decimal = null,
    digit: ?Digit = null,
    hex: ?HexDigit = null,
    mod_letter: ?ModLetter = null,
    other_letter: ?OtherLetter = null,
    lower: ?Lower = null,
    lower_map: ?LowerMap = null,
    spacing_mark: ?SpacingMark = null,
    nonspacing_mark: ?NonSpacingMark = null,
    enclosing_mark: ?EnclosingMark = null,
    letter_number: ?LetterNumber = null,
    other_number: ?OtherNumber = null,
    close_punct: ?ClosePunct = null,
    connect_punct: ?ConnectPunct = null,
    dash_punct: ?DashPunct = null,
    initial_punct: ?InitialPunct = null,
    open_punct: ?OpenPunct = null,
    other_punct: ?OtherPunct = null,
    math_symbol: ?MathSymbol = null,
    mod_symbol: ?ModSymbol = null,
    currency_symbol: ?CurrencySymbol = null,
    other_symbol: ?OtherSymbol = null,
    whitespace: ?WhiteSpace = null,
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
        if (self.alpha) |*alpha| {
            alpha.deinit();
        }
        if (self.cased) |*cased| {
            cased.deinit();
        }
        if (self.control) |*control| {
            control.deinit();
        }
        if (self.decimal) |*decimal| {
            decimal.deinit();
        }
        if (self.digit) |*digit| {
            digit.deinit();
        }
        if (self.hex) |*hex| {
            hex.deinit();
        }
        if (self.mod_letter) |*mod_letter| {
            mod_letter.deinit();
        }
        if (self.other_letter) |*other_letter| {
            other_letter.deinit();
        }
        if (self.lower) |*lower| {
            lower.deinit();
        }
        if (self.lower_map) |*lower_map| {
            lower_map.deinit();
        }
        if (self.spacing_mark) |*spacing_mark| {
            spacing_mark.deinit();
        }
        if (self.nonspacing_mark) |*nonspacing_mark| {
            nonspacing_mark.deinit();
        }
        if (self.enclosing_mark) |*enclosing_mark| {
            enclosing_mark.deinit();
        }
        if (self.letter_number) |*letter_number| {
            letter_number.deinit();
        }
        if (self.other_number) |*other_number| {
            other_number.deinit();
        }
        if (self.close_punct) |*close_punct| {
            close_punct.deinit();
        }
        if (self.connect_punct) |*connect_punct| {
            connect_punct.deinit();
        }
        if (self.dash_punct) |*dash_punct| {
            dash_punct.deinit();
        }
        if (self.initial_punct) |*initial_punct| {
            initial_punct.deinit();
        }
        if (self.open_punct) |*open_punct| {
            open_punct.deinit();
        }
        if (self.other_punct) |*other_punct| {
            other_punct.deinit();
        }
        if (self.whitespace) |*whitespace| {
            whitespace.deinit();
        }
        if (self.math_symbol) |*math_symbol| {
            math_symbol.deinit();
        }
        if (self.mod_symbol) |*mod_symbol| {
            mod_symbol.deinit();
        }
        if (self.currency_symbol) |*currency_symbol| {
            currency_symbol.deinit();
        }
        if (self.other_symbol) |*other_symbol| {
            other_symbol.deinit();
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

    /// isAlphabetic detects if a code point is alphabetic.
    pub fn isAlphabetic(self: *Self, cp: u21) !bool {
        // Lazy init.
        if (self.alpha == null) {
            self.alpha = try Alphabetic.init(self.allocator);
        }

        return self.alpha.?.isAlphabetic(cp);
    }

    /// isAlphaNum covers all the Unicode alphabetic and number space, not just ASCII.
    pub fn isAlphaNum(self: *Self, cp: u21) !bool {
        return (try self.isAlphabetic(cp)) or (try self.isNumber(cp));
    }

    /// isCased detects cased letters.
    pub fn isCased(self: *Self, cp: u21) !bool {
        // Lazy init.
        if (self.cased == null) {
            self.cased = try Cased.init(self.allocator);
        }

        return self.cased.?.isCased(cp);
    }

    // isDecimal detects all Unicode digits.
    pub fn isDecimal(self: *Self, cp: u21) !bool {
        // Lazy init.
        if (self.decimal == null) {
            self.decimal = try Decimal.init(self.allocator);
        }

        return self.decimal.?.isDecimalNumber(cp);
    }

    // isDigit detects all Unicode digits.
    pub fn isDigit(self: *Self, cp: u21) !bool {
        // ASCII optimization.
        // Lazy init.
        if (self.digit == null) {
            self.digit = try Digit.init(self.allocator);
        }

        return self.digit.?.isDigit(cp) or (try self.isDecimal(cp));
    }

    /// isGraphic detects any code point that can be represented graphically, including spaces.
    pub fn isGraphic(self: *Self, cp: u21) !bool {
        // Lazy init.
        if (self.whitespace == null) {
            self.whitespace = try WhiteSpace.init(self.allocator);
        }

        return (try self.isPrint(cp)) or self.whitespace.?.isWhiteSpace(cp);
    }

    // isHex detects the 16 ASCII characters 0-9 A-F, and a-f.
    pub fn isHexDigit(self: *Self, cp: u21) !bool {
        if (self.hex == null) self.hex = try HexDigit.init(self.allocator);
        return self.hex.?.isHexDigit(cp);
    }

    /// isPrint detects any code point that can be printed, but not spaces.
    pub fn isPrint(self: *Self, cp: u21) !bool {
        return (try self.isAlphaNum(cp)) or
            (try self.isMark(cp)) or
            (try self.isPunct(cp)) or
            (try self.isSymbol(cp)) or
            (try self.isWhiteSpace(cp));
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
        if (self.lower == null) {
            self.lower = try Lower.init(self.allocator);
        }
        if (self.mod_letter == null) {
            self.mod_letter = try ModLetter.init(self.allocator);
        }
        if (self.other_letter == null) {
            self.other_letter = try OtherLetter.init(self.allocator);
        }
        if (self.title == null) {
            self.title = try Title.init(self.allocator);
        }
        if (self.upper == null) {
            self.upper = try Upper.init(self.allocator);
        }

        return self.lower.?.isLowercaseLetter(cp) or
            self.mod_letter.?.isModifierLetter(cp) or
            self.other_letter.?.isOtherLetter(cp) or
            self.title.?.isTitlecaseLetter(cp) or
            self.upper.?.isUppercaseLetter(cp);
    }

    /// isLower detects code points that are lowercase.
    pub fn isLower(self: *Self, cp: u21) !bool {
        // Lazy init.
        if (self.lower == null) {
            self.lower = try Lower.init(self.allocator);
        }

        return (try self.isCased(cp)) and self.lower.?.isLowercaseLetter(cp);
    }

    /// isMark detects special code points that serve as marks in different alphabets.
    pub fn isMark(self: *Self, cp: u21) !bool {
        // Lazy init.
        if (self.spacing_mark == null) {
            self.spacing_mark = try SpacingMark.init(self.allocator);
        }
        if (self.nonspacing_mark == null) {
            self.nonspacing_mark = try NonSpacingMark.init(self.allocator);
        }
        if (self.enclosing_mark == null) {
            self.enclosing_mark = try EnclosingMark.init(self.allocator);
        }

        return self.spacing_mark.?.isSpacingMark(cp) or
            self.nonspacing_mark.?.isNonspacingMark(cp) or
            self.enclosing_mark.?.isEnclosingMark(cp);
    }

    /// isNumber covers all Unicode numbers, not just ASII.
    pub fn isNumber(self: *Self, cp: u21) !bool {
        // Lazy init.
        if (self.decimal == null) {
            self.decimal = try Decimal.init(self.allocator);
        }
        if (self.letter_number == null) {
            self.letter_number = try LetterNumber.init(self.allocator);
        }
        if (self.other_number == null) {
            self.other_number = try OtherNumber.init(self.allocator);
        }

        return self.decimal.?.isDecimalNumber(cp) or
            self.letter_number.?.isLetterNumber(cp) or
            self.other_number.?.isOtherNumber(cp);
    }

    /// isPunct detects punctuation characters. Note some punctuation maybe considered symbols by Unicode.
    pub fn isPunct(self: *Self, cp: u21) !bool {
        // Lazy init.
        if (self.close_punct == null) {
            self.close_punct = try ClosePunct.init(self.allocator);
        }
        if (self.connect_punct == null) {
            self.connect_punct = try ConnectPunct.init(self.allocator);
        }
        if (self.dash_punct == null) {
            self.dash_punct = try DashPunct.init(self.allocator);
        }
        if (self.initial_punct == null) {
            self.initial_punct = try InitialPunct.init(self.allocator);
        }
        if (self.open_punct == null) {
            self.open_punct = try OpenPunct.init(self.allocator);
        }
        if (self.other_punct == null) {
            self.other_punct = try OtherPunct.init(self.allocator);
        }

        return self.close_punct.?.isClosePunctuation(cp) or
            self.connect_punct.?.isConnectorPunctuation(cp) or
            self.dash_punct.?.isDashPunctuation(cp) or
            self.initial_punct.?.isInitialPunctuation(cp) or
            self.open_punct.?.isOpenPunctuation(cp) or
            self.other_punct.?.isOtherPunctuation(cp);
    }

    /// isWhiteSpace checks for spaces.
    pub fn isWhiteSpace(self: *Self, cp: u21) !bool {
        // Lazy init.
        if (self.whitespace == null) {
            self.whitespace = try WhiteSpace.init(self.allocator);
        }

        return self.whitespace.?.isWhiteSpace(cp);
    }

    // isSymbol detects symbols which curiosly may include some code points commonly thought of as
    // punctuation.
    pub fn isSymbol(self: *Self, cp: u21) !bool {
        // Lazy init.
        if (self.math_symbol == null) {
            self.math_symbol = try MathSymbol.init(self.allocator);
        }
        if (self.mod_symbol == null) {
            self.mod_symbol = try ModSymbol.init(self.allocator);
        }
        if (self.currency_symbol == null) {
            self.currency_symbol = try CurrencySymbol.init(self.allocator);
        }
        if (self.other_symbol == null) {
            self.other_symbol = try OtherSymbol.init(self.allocator);
        }

        return self.math_symbol.?.isMathSymbol(cp) or
            self.mod_symbol.?.isModifierSymbol(cp) or
            self.currency_symbol.?.isCurrencySymbol(cp) or
            self.other_symbol.?.isOtherSymbol(cp);
    }

    /// isTitle detects code points in titlecase.
    pub fn isTitle(self: *Self, cp: u21) !bool {
        // Lazy init.
        if (self.title == null) {
            self.title = try Title.init(self.allocator);
        }

        return (try self.isCased(cp)) and self.title.?.isTitlecaseLetter(cp);
    }

    /// isTitle detects code points in uppercase.
    pub fn isUpper(self: *Self, cp: u21) !bool {
        // Lazy init.
        if (self.upper == null) {
            self.upper = try Upper.init(self.allocator);
        }

        return (try self.isCased(cp)) and self.upper.?.isUppercaseLetter(cp);
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
