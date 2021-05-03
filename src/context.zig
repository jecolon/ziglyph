const std = @import("std");
const mem = std.mem;

pub const Alphabetic = @import("components/autogen/DerivedCoreProperties/Alphabetic.zig");
pub const CccMap = @import("components/autogen/DerivedCombiningClass/CccMap.zig");
pub const Control = @import("components/autogen/DerivedGeneralCategory/Control.zig");
pub const DecomposeMap = @import("components/autogen/UnicodeData/DecomposeMap.zig");
pub const Extend = @import("components/autogen/GraphemeBreakProperty/Extend.zig");
pub const ExtPic = @import("components/autogen/emoji-data/ExtendedPictographic.zig");
pub const Format = @import("components/autogen/DerivedGeneralCategory/Format.zig");
pub const HangulMap = @import("components/autogen/HangulSyllableType/HangulMap.zig");
pub const Prepend = @import("components/autogen/GraphemeBreakProperty/Prepend.zig");
pub const Regional = @import("components/autogen/GraphemeBreakProperty/RegionalIndicator.zig");
pub const Width = @import("components/aggregate/Width.zig");
// Letter
pub const CaseFoldMap = @import("components/autogen/CaseFolding/CaseFoldMap.zig");
pub const CaseFold = CaseFoldMap.CaseFold;
pub const Cased = @import("components/autogen/DerivedCoreProperties/Cased.zig");
pub const Lower = @import("components/autogen/DerivedGeneralCategory/LowercaseLetter.zig");
pub const LowerMap = @import("components/autogen/UnicodeData/LowerMap.zig");
pub const ModifierLetter = @import("components/autogen/DerivedGeneralCategory/ModifierLetter.zig");
pub const OtherLetter = @import("components/autogen/DerivedGeneralCategory/OtherLetter.zig");
pub const Title = @import("components/autogen/DerivedGeneralCategory/TitlecaseLetter.zig");
pub const TitleMap = @import("components/autogen/UnicodeData/TitleMap.zig");
pub const Upper = @import("components/autogen/DerivedGeneralCategory/UppercaseLetter.zig");
pub const UpperMap = @import("components/autogen/UnicodeData/UpperMap.zig");
// Mark
pub const Enclosing = @import("components/autogen/DerivedGeneralCategory/EnclosingMark.zig");
pub const Nonspacing = @import("components/autogen/DerivedGeneralCategory/NonspacingMark.zig");
pub const Spacing = @import("components/autogen/DerivedGeneralCategory/SpacingMark.zig");
// Number
pub const Decimal = @import("components/autogen/DerivedGeneralCategory/DecimalNumber.zig");
pub const Digit = @import("components/autogen/DerivedNumericType/Digit.zig");
pub const Hex = @import("components/autogen/PropList/HexDigit.zig");
pub const LetterNumber = @import("components/autogen/DerivedGeneralCategory/LetterNumber.zig");
pub const OtherNumber = @import("components/autogen/DerivedGeneralCategory/OtherNumber.zig");
// Punct
pub const Close = @import("components/autogen/DerivedGeneralCategory/ClosePunctuation.zig");
pub const Connector = @import("components/autogen/DerivedGeneralCategory/ConnectorPunctuation.zig");
pub const Dash = @import("components/autogen/DerivedGeneralCategory/DashPunctuation.zig");
pub const Final = @import("components/autogen/UnicodeData/FinalPunctuation.zig");
pub const Initial = @import("components/autogen/DerivedGeneralCategory/InitialPunctuation.zig");
pub const Open = @import("components/autogen/DerivedGeneralCategory/OpenPunctuation.zig");
pub const OtherPunct = @import("components/autogen/DerivedGeneralCategory/OtherPunctuation.zig");
// Space
pub const WhiteSpace = @import("components/autogen/PropList/WhiteSpace.zig");
pub const Space = @import("components/autogen/DerivedGeneralCategory/SpaceSeparator.zig");
// Symbol
pub const Currency = @import("components/autogen/DerivedGeneralCategory/CurrencySymbol.zig");
pub const Math = @import("components/autogen/DerivedGeneralCategory/MathSymbol.zig");
pub const ModifierSymbol = @import("components/autogen/DerivedGeneralCategory/ModifierSymbol.zig");
pub const OtherSymbol = @import("components/autogen/DerivedGeneralCategory/OtherSymbol.zig");
// Width
pub const Ambiguous = @import("components/autogen/DerivedEastAsianWidth/Ambiguous.zig");
pub const Fullwidth = @import("components/autogen/DerivedEastAsianWidth/Fullwidth.zig");
pub const Wide = @import("components/autogen/DerivedEastAsianWidth/Wide.zig");

pub const DataSet = enum {
    all,
    decompose,
    grapheme,
    letter,
    mark,
    number,
    punct,
    space,
    symbol,
    width,
    ziglyph,
    zigstr,
};

pub fn Context(comptime data_set: DataSet) type {
    return switch (data_set) {
        .all => struct {
            allocator: *mem.Allocator,
            alphabetic: *Alphabetic,
            ccc_map: *CccMap,
            control: *Control,
            extend: *Extend,
            extpic: *ExtPic,
            format: *Format,
            hangul_map: *HangulMap,
            prepend: *Prepend,
            regional: *Regional,
            ambiguous: *Ambiguous,
            fullwidth: *Fullwidth,
            wide: *Wide,
            fold_map: *CaseFoldMap,
            cased: *Cased,
            lower: *Lower,
            lower_map: LowerMap,
            modifier_letter: *ModifierLetter,
            other_letter: *OtherLetter,
            title: *Title,
            title_map: TitleMap,
            upper: *Upper,
            upper_map: UpperMap,
            enclosing: *Enclosing,
            nonspacing: *Nonspacing,
            spacing: *Spacing,
            decimal: *Decimal,
            digit: *Digit,
            hex: *Hex,
            letter_number: *LetterNumber,
            other_number: *OtherNumber,
            close: *Close,
            connector: *Connector,
            dash: *Dash,
            final: *Final,
            initial: *Initial,
            open: *Open,
            other_punct: *OtherPunct,
            whitespace: *WhiteSpace,
            space: *Space,
            currency: *Currency,
            math: *Math,
            modifier_symbol: *ModifierSymbol,
            other_symbol: *OtherSymbol,

            const Self = @This();

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
                    .alphabetic = try Alphabetic.init(allocator),
                    .ccc_map = try CccMap.init(allocator),
                    .control = try Control.init(allocator),
                    .extend = try Extend.init(allocator),
                    .extpic = try ExtPic.init(allocator),
                    .format = try Format.init(allocator),
                    .hangul_map = try HangulMap.init(allocator),
                    .prepend = try Prepend.init(allocator),
                    .regional = try Regional.init(allocator),
                    .ambiguous = try Ambiguous.init(allocator),
                    .fullwidth = try Fullwidth.init(allocator),
                    .wide = try Wide.init(allocator),
                    .fold_map = try CaseFoldMap.init(allocator),
                    .cased = try Cased.init(allocator),
                    .lower = try Lower.init(allocator),
                    .lower_map = try LowerMap.init(allocator),
                    .modifier_letter = try ModifierLetter.init(allocator),
                    .other_letter = try OtherLetter.init(allocator),
                    .title = try Title.init(allocator),
                    .title_map = try TitleMap.init(allocator),
                    .upper = try Upper.init(allocator),
                    .upper_map = try UpperMap.init(allocator),
                    .enclosing = try Enclosing.init(allocator),
                    .nonspacing = try Nonspacing.init(allocator),
                    .spacing = try Spacing.init(allocator),
                    .decimal = try Decimal.init(allocator),
                    .digit = try Digit.init(allocator),
                    .hex = try Hex.init(allocator),
                    .letter_number = try LetterNumber.init(allocator),
                    .other_number = try OtherNumber.init(allocator),
                    .close = try Close.init(allocator),
                    .connector = try Connector.init(allocator),
                    .dash = try Dash.init(allocator),
                    .final = try Final.init(allocator),
                    .initial = try Initial.init(allocator),
                    .open = try Open.init(allocator),
                    .other_punct = try OtherPunct.init(allocator),
                    .whitespace = try WhiteSpace.init(allocator),
                    .space = try Space.init(allocator),
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
                self.alphabetic.deinit();
                self.ccc_map.deinit();
                self.control.deinit();
                self.extend.deinit();
                self.extpic.deinit();
                self.format.deinit();
                self.hangul_map.deinit();
                self.prepend.deinit();
                self.regional.deinit();
                self.fold_map.deinit();
                self.cased.deinit();
                self.lower.deinit();
                self.lower_map.deinit();
                self.modifier_letter.deinit();
                self.other_letter.deinit();
                self.title.deinit();
                self.title_map.deinit();
                self.upper.deinit();
                self.upper_map.deinit();
                self.enclosing.deinit();
                self.nonspacing.deinit();
                self.spacing.deinit();
                self.decimal.deinit();
                self.digit.deinit();
                self.hex.deinit();
                self.letter_number.deinit();
                self.other_number.deinit();
                self.close.deinit();
                self.connector.deinit();
                self.dash.deinit();
                self.final.deinit();
                self.initial.deinit();
                self.open.deinit();
                self.other_punct.deinit();
                self.whitespace.deinit();
                self.space.deinit();
                self.currency.deinit();
                self.math.deinit();
                self.modifier_symbol.deinit();
                self.other_symbol.deinit();
                self.fullwidth.deinit();
                self.wide.deinit();
                self.ambiguous.deinit();

                if (singleton) |*s| {
                    s.ref_count -= 1;
                    if (s.ref_count == 0) {
                        self.allocator.destroy(s.instance);
                        singleton = null;
                    }
                }
            }
        },
        .decompose => struct {
            allocator: *mem.Allocator,
            ccc_map: *CccMap,
            hangul_map: *HangulMap,

            const Self = @This();

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
                    .ccc_map = try CccMap.init(allocator),
                    .hangul_map = try HangulMap.init(allocator),
                };

                singleton = Singleton{
                    .instance = instance,
                    .ref_count = 1,
                };

                return instance;
            }

            pub fn deinit(self: *Self) void {
                self.ccc_map.deinit();
                self.hangul_map.deinit();

                if (singleton) |*s| {
                    s.ref_count -= 1;
                    if (s.ref_count == 0) {
                        self.allocator.destroy(s.instance);
                        singleton = null;
                    }
                }
            }
        },
        .grapheme => struct {
            allocator: *mem.Allocator,
            control: *Control,
            extend: *Extend,
            extpic: *ExtPic,
            hangul_map: *HangulMap,
            prepend: *Prepend,
            regional: *Regional,
            spacing: *Spacing,

            const Self = @This();

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
                    .control = try Control.init(allocator),
                    .extend = try Extend.init(allocator),
                    .extpic = try ExtPic.init(allocator),
                    .hangul_map = try HangulMap.init(allocator),
                    .prepend = try Prepend.init(allocator),
                    .regional = try Regional.init(allocator),
                    .spacing = try Spacing.init(allocator),
                };

                singleton = Singleton{
                    .instance = instance,
                    .ref_count = 1,
                };

                return instance;
            }

            pub fn deinit(self: *Self) void {
                self.control.deinit();
                self.extend.deinit();
                self.extpic.deinit();
                self.hangul_map.deinit();
                self.prepend.deinit();
                self.regional.deinit();
                self.spacing.deinit();

                if (singleton) |*s| {
                    s.ref_count -= 1;
                    if (s.ref_count == 0) {
                        self.allocator.destroy(s.instance);
                        singleton = null;
                    }
                }
            }
        },
        .letter => struct {
            allocator: *mem.Allocator,
            fold_map: *CaseFoldMap,
            cased: *Cased,
            lower: *Lower,
            lower_map: LowerMap,
            modifier_letter: *ModifierLetter,
            other_letter: *OtherLetter,
            title: *Title,
            title_map: TitleMap,
            upper: *Upper,
            upper_map: UpperMap,

            const Self = @This();

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
                    .fold_map = try CaseFoldMap.init(allocator),
                    .cased = try Cased.init(allocator),
                    .lower = try Lower.init(allocator),
                    .lower_map = try LowerMap.init(allocator),
                    .modifier_letter = try ModifierLetter.init(allocator),
                    .other_letter = try OtherLetter.init(allocator),
                    .title = try Title.init(allocator),
                    .title_map = try TitleMap.init(allocator),
                    .upper = try Upper.init(allocator),
                    .upper_map = try UpperMap.init(allocator),
                };

                singleton = Singleton{
                    .instance = instance,
                    .ref_count = 1,
                };

                return instance;
            }

            pub fn deinit(self: *Self) void {
                self.fold_map.deinit();
                self.cased.deinit();
                self.lower.deinit();
                self.lower_map.deinit();
                self.modifier_letter.deinit();
                self.other_letter.deinit();
                self.title.deinit();
                self.title_map.deinit();
                self.upper.deinit();
                self.upper_map.deinit();

                if (singleton) |*s| {
                    s.ref_count -= 1;
                    if (s.ref_count == 0) {
                        self.allocator.destroy(s.instance);
                        singleton = null;
                    }
                }
            }
        },
        .mark => struct {
            allocator: *mem.Allocator,
            enclosing: *Enclosing,
            nonspacing: *Nonspacing,
            spacing: *Spacing,

            const Self = @This();

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
                    .enclosing = try Enclosing.init(allocator),
                    .nonspacing = try Nonspacing.init(allocator),
                    .spacing = try Spacing.init(allocator),
                };

                singleton = Singleton{
                    .instance = instance,
                    .ref_count = 1,
                };

                return instance;
            }

            pub fn deinit(self: *Self) void {
                self.enclosing.deinit();
                self.nonspacing.deinit();
                self.spacing.deinit();

                if (singleton) |*s| {
                    s.ref_count -= 1;
                    if (s.ref_count == 0) {
                        self.allocator.destroy(s.instance);
                        singleton = null;
                    }
                }
            }
        },
        .number => struct {
            allocator: *mem.Allocator,
            decimal: *Decimal,
            digit: *Digit,
            hex: *Hex,
            letter_number: *LetterNumber,
            other_number: *OtherNumber,

            const Self = @This();

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
                    .decimal = try Decimal.init(allocator),
                    .digit = try Digit.init(allocator),
                    .hex = try Hex.init(allocator),
                    .letter_number = try LetterNumber.init(allocator),
                    .other_number = try OtherNumber.init(allocator),
                };

                singleton = Singleton{
                    .instance = instance,
                    .ref_count = 1,
                };

                return instance;
            }

            pub fn deinit(self: *Self) void {
                self.decimal.deinit();
                self.digit.deinit();
                self.hex.deinit();
                self.letter_number.deinit();
                self.other_number.deinit();

                if (singleton) |*s| {
                    s.ref_count -= 1;
                    if (s.ref_count == 0) {
                        self.allocator.destroy(s.instance);
                        singleton = null;
                    }
                }
            }
        },
        .punct => struct {
            allocator: *mem.Allocator,
            close: *Close,
            connector: *Connector,
            dash: *Dash,
            final: *Final,
            initial: *Initial,
            open: *Open,
            other_punct: *OtherPunct,

            const Self = @This();

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
                self.close.deinit();
                self.connector.deinit();
                self.dash.deinit();
                self.final.deinit();
                self.initial.deinit();
                self.open.deinit();
                self.other_punct.deinit();

                if (singleton) |*s| {
                    s.ref_count -= 1;
                    if (s.ref_count == 0) {
                        self.allocator.destroy(s.instance);
                        singleton = null;
                    }
                }
            }
        },
        .space => struct {
            allocator: *mem.Allocator,
            space: *Space,
            whitespace: *WhiteSpace,

            const Self = @This();

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
                    .space = try Space.init(allocator),
                    .whitespace = try WhiteSpace.init(allocator),
                };

                singleton = Singleton{
                    .instance = instance,
                    .ref_count = 1,
                };

                return instance;
            }

            pub fn deinit(self: *Self) void {
                self.space.deinit();
                self.whitespace.deinit();

                if (singleton) |*s| {
                    s.ref_count -= 1;
                    if (s.ref_count == 0) {
                        self.allocator.destroy(s.instance);
                        singleton = null;
                    }
                }
            }
        },
        .symbol => struct {
            allocator: *mem.Allocator,
            currency: *Currency,
            math: *Math,
            modifier_symbol: *ModifierSymbol,
            other_symbol: *OtherSymbol,

            const Self = @This();

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
                self.currency.deinit();
                self.math.deinit();
                self.modifier_symbol.deinit();
                self.other_symbol.deinit();

                if (singleton) |*s| {
                    s.ref_count -= 1;
                    if (s.ref_count == 0) {
                        self.allocator.destroy(s.instance);
                        singleton = null;
                    }
                }
            }
        },
        .width => struct {
            allocator: *mem.Allocator,
            ambiguous: *Ambiguous,
            control: *Control,
            enclosing: *Enclosing,
            extend: *Extend,
            extpic: *ExtPic,
            format: *Format,
            fullwidth: *Fullwidth,
            hangul_map: *HangulMap,
            nonspacing: *Nonspacing,
            prepend: *Prepend,
            regional: *Regional,
            spacing: *Spacing,
            wide: *Wide,
            alphabetic: *Alphabetic,
            fold_map: *CaseFoldMap,
            cased: *Cased,
            lower: *Lower,
            lower_map: LowerMap,
            modifier_letter: *ModifierLetter,
            other_letter: *OtherLetter,
            title: *Title,
            title_map: TitleMap,
            upper: *Upper,
            upper_map: UpperMap,
            decimal: *Decimal,
            digit: *Digit,
            hex: *Hex,
            letter_number: *LetterNumber,
            other_number: *OtherNumber,
            close: *Close,
            connector: *Connector,
            dash: *Dash,
            final: *Final,
            initial: *Initial,
            open: *Open,
            other_punct: *OtherPunct,
            whitespace: *WhiteSpace,
            space: *Space,
            currency: *Currency,
            math: *Math,
            modifier_symbol: *ModifierSymbol,
            other_symbol: *OtherSymbol,

            const Self = @This();

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
                    .ambiguous = try Ambiguous.init(allocator),
                    .control = try Control.init(allocator),
                    .enclosing = try Enclosing.init(allocator),
                    .extend = try Extend.init(allocator),
                    .extpic = try ExtPic.init(allocator),
                    .format = try Format.init(allocator),
                    .fullwidth = try Fullwidth.init(allocator),
                    .hangul_map = try HangulMap.init(allocator),
                    .nonspacing = try Nonspacing.init(allocator),
                    .prepend = try Prepend.init(allocator),
                    .regional = try Regional.init(allocator),
                    .spacing = try Spacing.init(allocator),
                    .wide = try Wide.init(allocator),
                    .alphabetic = try Alphabetic.init(allocator),
                    .fold_map = try CaseFoldMap.init(allocator),
                    .cased = try Cased.init(allocator),
                    .lower = try Lower.init(allocator),
                    .lower_map = try LowerMap.init(allocator),
                    .modifier_letter = try ModifierLetter.init(allocator),
                    .other_letter = try OtherLetter.init(allocator),
                    .title = try Title.init(allocator),
                    .title_map = try TitleMap.init(allocator),
                    .upper = try Upper.init(allocator),
                    .upper_map = try UpperMap.init(allocator),
                    .decimal = try Decimal.init(allocator),
                    .digit = try Digit.init(allocator),
                    .hex = try Hex.init(allocator),
                    .letter_number = try LetterNumber.init(allocator),
                    .other_number = try OtherNumber.init(allocator),
                    .close = try Close.init(allocator),
                    .connector = try Connector.init(allocator),
                    .dash = try Dash.init(allocator),
                    .final = try Final.init(allocator),
                    .initial = try Initial.init(allocator),
                    .open = try Open.init(allocator),
                    .other_punct = try OtherPunct.init(allocator),
                    .whitespace = try WhiteSpace.init(allocator),
                    .space = try Space.init(allocator),
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
                self.ambiguous.deinit();
                self.control.deinit();
                self.enclosing.deinit();
                self.extend.deinit();
                self.extpic.deinit();
                self.format.deinit();
                self.fullwidth.deinit();
                self.hangul_map.deinit();
                self.nonspacing.deinit();
                self.prepend.deinit();
                self.regional.deinit();
                self.spacing.deinit();
                self.wide.deinit();
                self.alphabetic.deinit();
                self.fold_map.deinit();
                self.cased.deinit();
                self.lower.deinit();
                self.lower_map.deinit();
                self.modifier_letter.deinit();
                self.other_letter.deinit();
                self.title.deinit();
                self.title_map.deinit();
                self.upper.deinit();
                self.upper_map.deinit();
                self.decimal.deinit();
                self.digit.deinit();
                self.hex.deinit();
                self.letter_number.deinit();
                self.other_number.deinit();
                self.close.deinit();
                self.connector.deinit();
                self.dash.deinit();
                self.final.deinit();
                self.initial.deinit();
                self.open.deinit();
                self.other_punct.deinit();
                self.whitespace.deinit();
                self.space.deinit();
                self.currency.deinit();
                self.math.deinit();
                self.modifier_symbol.deinit();
                self.other_symbol.deinit();

                if (singleton) |*s| {
                    s.ref_count -= 1;
                    if (s.ref_count == 0) {
                        self.allocator.destroy(s.instance);
                        singleton = null;
                    }
                }
            }
        },
        .ziglyph => struct {
            allocator: *mem.Allocator,
            alphabetic: *Alphabetic,
            control: *Control,
            fold_map: *CaseFoldMap,
            cased: *Cased,
            lower: *Lower,
            lower_map: LowerMap,
            modifier_letter: *ModifierLetter,
            other_letter: *OtherLetter,
            title: *Title,
            title_map: TitleMap,
            upper: *Upper,
            upper_map: UpperMap,
            enclosing: *Enclosing,
            nonspacing: *Nonspacing,
            spacing: *Spacing,
            decimal: *Decimal,
            digit: *Digit,
            hex: *Hex,
            letter_number: *LetterNumber,
            other_number: *OtherNumber,
            close: *Close,
            connector: *Connector,
            dash: *Dash,
            final: *Final,
            initial: *Initial,
            open: *Open,
            other_punct: *OtherPunct,
            whitespace: *WhiteSpace,
            space: *Space,
            currency: *Currency,
            math: *Math,
            modifier_symbol: *ModifierSymbol,
            other_symbol: *OtherSymbol,

            const Self = @This();

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
                    .alphabetic = try Alphabetic.init(allocator),
                    .control = try Control.init(allocator),
                    .fold_map = try CaseFoldMap.init(allocator),
                    .cased = try Cased.init(allocator),
                    .lower = try Lower.init(allocator),
                    .lower_map = try LowerMap.init(allocator),
                    .modifier_letter = try ModifierLetter.init(allocator),
                    .other_letter = try OtherLetter.init(allocator),
                    .title = try Title.init(allocator),
                    .title_map = try TitleMap.init(allocator),
                    .upper = try Upper.init(allocator),
                    .upper_map = try UpperMap.init(allocator),
                    .enclosing = try Enclosing.init(allocator),
                    .nonspacing = try Nonspacing.init(allocator),
                    .spacing = try Spacing.init(allocator),
                    .decimal = try Decimal.init(allocator),
                    .digit = try Digit.init(allocator),
                    .hex = try Hex.init(allocator),
                    .letter_number = try LetterNumber.init(allocator),
                    .other_number = try OtherNumber.init(allocator),
                    .close = try Close.init(allocator),
                    .connector = try Connector.init(allocator),
                    .dash = try Dash.init(allocator),
                    .final = try Final.init(allocator),
                    .initial = try Initial.init(allocator),
                    .open = try Open.init(allocator),
                    .other_punct = try OtherPunct.init(allocator),
                    .whitespace = try WhiteSpace.init(allocator),
                    .space = try Space.init(allocator),
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
                self.alphabetic.deinit();
                self.control.deinit();
                self.fold_map.deinit();
                self.cased.deinit();
                self.lower.deinit();
                self.lower_map.deinit();
                self.modifier_letter.deinit();
                self.other_letter.deinit();
                self.title.deinit();
                self.title_map.deinit();
                self.upper.deinit();
                self.upper_map.deinit();
                self.enclosing.deinit();
                self.nonspacing.deinit();
                self.spacing.deinit();
                self.decimal.deinit();
                self.digit.deinit();
                self.hex.deinit();
                self.letter_number.deinit();
                self.other_number.deinit();
                self.close.deinit();
                self.connector.deinit();
                self.dash.deinit();
                self.final.deinit();
                self.initial.deinit();
                self.open.deinit();
                self.other_punct.deinit();
                self.whitespace.deinit();
                self.space.deinit();
                self.currency.deinit();
                self.math.deinit();
                self.modifier_symbol.deinit();
                self.other_symbol.deinit();

                if (singleton) |*s| {
                    s.ref_count -= 1;
                    if (s.ref_count == 0) {
                        self.allocator.destroy(s.instance);
                        singleton = null;
                    }
                }
            }
        },
        .zigstr => struct {
            allocator: *mem.Allocator,
            ambiguous: *Ambiguous,
            ccc_map: *CccMap,
            control: *Control,
            enclosing: *Enclosing,
            extend: *Extend,
            extpic: *ExtPic,
            format: *Format,
            fullwidth: *Fullwidth,
            hangul_map: *HangulMap,
            nonspacing: *Nonspacing,
            prepend: *Prepend,
            regional: *Regional,
            spacing: *Spacing,
            wide: *Wide,
            alphabetic: *Alphabetic,
            fold_map: *CaseFoldMap,
            cased: *Cased,
            lower: *Lower,
            lower_map: LowerMap,
            modifier_letter: *ModifierLetter,
            other_letter: *OtherLetter,
            title: *Title,
            title_map: TitleMap,
            upper: *Upper,
            upper_map: UpperMap,
            decimal: *Decimal,
            digit: *Digit,
            hex: *Hex,
            letter_number: *LetterNumber,
            other_number: *OtherNumber,
            close: *Close,
            connector: *Connector,
            dash: *Dash,
            final: *Final,
            initial: *Initial,
            open: *Open,
            other_punct: *OtherPunct,
            whitespace: *WhiteSpace,
            space: *Space,
            currency: *Currency,
            math: *Math,
            modifier_symbol: *ModifierSymbol,
            other_symbol: *OtherSymbol,

            const Singleton = struct {
                instance: *Self,
                ref_count: usize,
            };

            var singleton: ?Singleton = null;

            const Self = @This();

            pub fn init(allocator: *mem.Allocator) !*Self {
                if (singleton) |*s| {
                    s.ref_count += 1;
                    return s.instance;
                }

                var instance = try allocator.create(Self);

                instance.* = Self{
                    .allocator = allocator,
                    .ambiguous = try Ambiguous.init(allocator),
                    .ccc_map = try CccMap.init(allocator),
                    .control = try Control.init(allocator),
                    .enclosing = try Enclosing.init(allocator),
                    .extend = try Extend.init(allocator),
                    .extpic = try ExtPic.init(allocator),
                    .format = try Format.init(allocator),
                    .fullwidth = try Fullwidth.init(allocator),
                    .hangul_map = try HangulMap.init(allocator),
                    .nonspacing = try Nonspacing.init(allocator),
                    .prepend = try Prepend.init(allocator),
                    .regional = try Regional.init(allocator),
                    .spacing = try Spacing.init(allocator),
                    .wide = try Wide.init(allocator),
                    .alphabetic = try Alphabetic.init(allocator),
                    .fold_map = try CaseFoldMap.init(allocator),
                    .cased = try Cased.init(allocator),
                    .lower = try Lower.init(allocator),
                    .lower_map = try LowerMap.init(allocator),
                    .modifier_letter = try ModifierLetter.init(allocator),
                    .other_letter = try OtherLetter.init(allocator),
                    .title = try Title.init(allocator),
                    .title_map = try TitleMap.init(allocator),
                    .upper = try Upper.init(allocator),
                    .upper_map = try UpperMap.init(allocator),
                    .decimal = try Decimal.init(allocator),
                    .digit = try Digit.init(allocator),
                    .hex = try Hex.init(allocator),
                    .letter_number = try LetterNumber.init(allocator),
                    .other_number = try OtherNumber.init(allocator),
                    .close = try Close.init(allocator),
                    .connector = try Connector.init(allocator),
                    .dash = try Dash.init(allocator),
                    .final = try Final.init(allocator),
                    .initial = try Initial.init(allocator),
                    .open = try Open.init(allocator),
                    .other_punct = try OtherPunct.init(allocator),
                    .whitespace = try WhiteSpace.init(allocator),
                    .space = try Space.init(allocator),
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
                self.ambiguous.deinit();
                self.ccc_map.deinit();
                self.control.deinit();
                self.enclosing.deinit();
                self.extend.deinit();
                self.extpic.deinit();
                self.format.deinit();
                self.fullwidth.deinit();
                self.hangul_map.deinit();
                self.nonspacing.deinit();
                self.prepend.deinit();
                self.regional.deinit();
                self.spacing.deinit();
                self.wide.deinit();
                self.alphabetic.deinit();
                self.fold_map.deinit();
                self.cased.deinit();
                self.lower.deinit();
                self.lower_map.deinit();
                self.modifier_letter.deinit();
                self.other_letter.deinit();
                self.title.deinit();
                self.title_map.deinit();
                self.upper.deinit();
                self.upper_map.deinit();
                self.decimal.deinit();
                self.digit.deinit();
                self.hex.deinit();
                self.letter_number.deinit();
                self.other_number.deinit();
                self.close.deinit();
                self.connector.deinit();
                self.dash.deinit();
                self.final.deinit();
                self.initial.deinit();
                self.open.deinit();
                self.other_punct.deinit();
                self.whitespace.deinit();
                self.space.deinit();
                self.currency.deinit();
                self.math.deinit();
                self.modifier_symbol.deinit();
                self.other_symbol.deinit();

                if (singleton) |*s| {
                    s.ref_count -= 1;
                    if (s.ref_count == 0) {
                        self.allocator.destroy(s.instance);
                        singleton = null;
                    }
                }
            }
        },
    };
}
