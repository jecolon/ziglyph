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
const Fullwidth = @import("components/autogen/DerivedEastAsianWidth/Fullwidth.zig");
const Narrow = @import("components/autogen/DerivedEastAsianWidth/Narrow.zig");
const Wide = @import("components/autogen/DerivedEastAsianWidth/Wide.zig");

allocator: *mem.Allocator,
alphabetic: ?Alphabetic = null,
ccc_map: ?CccMap = null,
control: ?Control = null,
decomp_map: ?DecomposeMap = null,
extend: ?Extend = null,
extpic: ?ExtPic = null,
format: ?Format = null,
hangul_map: ?HangulMap = null,
prepend: ?Prepend = null,
regional: ?Regional = null,
fullwidth: ?Fullwidth = null,
narrow: ?Narrow = null,
wide: ?Wide = null,
fold_map: ?CaseFoldMap = null,
cased: ?Cased = null,
lower: ?Lower = null,
lower_map: ?LowerMap = null,
modifier_letter: ?ModifierLetter = null,
other_letter: ?OtherLetter = null,
title: ?Title = null,
title_map: ?TitleMap = null,
upper: ?Upper = null,
upper_map: ?UpperMap = null,
enclosing: ?Enclosing = null,
nonspacing: ?Nonspacing = null,
spacing: ?Spacing = null,
decimal: ?Decimal = null,
digit: ?Digit = null,
hex: ?Hex = null,
letter_number: ?LetterNumber = null,
other_number: ?OtherNumber = null,
close: ?Close = null,
connector: ?Connector = null,
dash: ?Dash = null,
final: ?Final = null,
initial: ?Initial = null,
open: ?Open = null,
other_punct: ?OtherPunct = null,
whitespace: ?WhiteSpace = null,
space: ?Space = null,
currency: ?Currency = null,
math: ?Math = null,
modifier_symbol: ?ModifierSymbol = null,
other_symbol: ?OtherSymbol = null,

const Self = @This();

pub fn init(allocator: *mem.Allocator) Self {
    return Self{ .allocator = allocator };
}

pub fn deinit(self: *Self) void {
    if (self.alphabetic) |*alphabetic_| {
        alphabetic_.deinit();
    }

    if (self.ccc_map) |*ccc_map_| {
        ccc_map_.deinit();
    }

    if (self.control) |*control_| {
        control_.deinit();
    }

    if (self.decomp_map) |*decomp_map_| {
        decomp_map_.deinit();
    }

    if (self.extend) |*extend_| {
        extend_.deinit();
    }

    if (self.extpic) |*extpic_| {
        extpic_.deinit();
    }

    if (self.format) |*format_| {
        format_.deinit();
    }

    if (self.hangul_map) |*hangul_map_| {
        hangul_map_.deinit();
    }

    if (self.prepend) |*prepend_| {
        prepend_.deinit();
    }

    if (self.regional) |*regional_| {
        regional_.deinit();
    }

    if (self.fold_map) |*fold_map_| {
        fold_map_.deinit();
    }

    if (self.cased) |*cased_| {
        cased_.deinit();
    }

    if (self.lower) |*lower_| {
        lower_.deinit();
    }

    if (self.lower_map) |*lower_map_| {
        lower_map_.deinit();
    }

    if (self.modifier_letter) |*modifier_letter_| {
        modifier_letter_.deinit();
    }

    if (self.other_letter) |*other_letter_| {
        other_letter_.deinit();
    }

    if (self.title) |*title_| {
        title_.deinit();
    }

    if (self.title_map) |*title_map_| {
        title_map_.deinit();
    }

    if (self.upper) |*upper_| {
        upper_.deinit();
    }

    if (self.upper_map) |*upper_map_| {
        upper_map_.deinit();
    }

    if (self.enclosing) |*enclosing_| {
        enclosing_.deinit();
    }

    if (self.nonspacing) |*nonspacing_| {
        nonspacing_.deinit();
    }

    if (self.spacing) |*spacing_| {
        spacing_.deinit();
    }

    if (self.decimal) |*decimal_| {
        decimal_.deinit();
    }

    if (self.digit) |*digit_| {
        digit_.deinit();
    }

    if (self.hex) |*hex_| {
        hex_.deinit();
    }

    if (self.letter_number) |*letter_number_| {
        letter_number_.deinit();
    }

    if (self.other_number) |*other_number_| {
        other_number_.deinit();
    }

    if (self.close) |*close_| {
        close_.deinit();
    }

    if (self.connector) |*connector_| {
        connector_.deinit();
    }

    if (self.dash) |*dash_| {
        dash_.deinit();
    }

    if (self.final) |*final_| {
        final_.deinit();
    }

    if (self.initial) |*initial_| {
        initial_.deinit();
    }

    if (self.open) |*open_| {
        open_.deinit();
    }

    if (self.other_punct) |*other_punct_| {
        other_punct_.deinit();
    }

    if (self.whitespace) |*whitespace_| {
        whitespace_.deinit();
    }

    if (self.space) |*space_| {
        space_.deinit();
    }

    if (self.currency) |*currency_| {
        currency_.deinit();
    }

    if (self.math) |*math_| {
        math_.deinit();
    }

    if (self.modifier_symbol) |*modifier_symbol_| {
        modifier_symbol_.deinit();
    }

    if (self.other_symbol) |*other_symbol_| {
        other_symbol_.deinit();
    }

    if (self.fullwidth) |*fullwidth_| {
        fullwidth_.deinit();
    }

    if (self.narrow) |*narrow_| {
        narrow_.deinit();
    }

    if (self.wide) |*wide_| {
        wide_.deinit();
    }
}

pub fn getAlphabetic(self: *Self) !*Alphabetic {
    if (self.alphabetic) |*alphabetic| {
        return alphabetic;
    } else {
        self.alphabetic = try Alphabetic.init(self.allocator);
        return &self.alphabetic.?;
    }
}

pub fn getCccMap(self: *Self) !*CccMap {
    if (self.ccc_map) |*ccc_map| {
        return ccc_map;
    } else {
        self.ccc_map = try CccMap.init(self.allocator);
        return &self.ccc_map.?;
    }
}

pub fn getControl(self: *Self) !*Control {
    if (self.control) |*control| {
        return control;
    } else {
        self.control = try Control.init(self.allocator);
        return &self.control.?;
    }
}

pub fn getDecomposeMap(self: *Self) !*DecomposeMap {
    if (self.decomp_map) |*decomp_map| {
        return decomp_map;
    } else {
        self.decomp_map = try DecomposeMap.init(self.allocator);
        return &self.decomp_map.?;
    }
}

pub fn getExtend(self: *Self) !*Extend {
    if (self.extend) |*extend| {
        return extend;
    } else {
        self.extend = try Extend.init(self.allocator);
        return &self.extend.?;
    }
}

pub fn getExtPic(self: *Self) !*ExtPic {
    if (self.extpic) |*extpic| {
        return extpic;
    } else {
        self.extpic = try ExtPic.init(self.allocator);
        return &self.extpic.?;
    }
}

pub fn getFormat(self: *Self) !*Format {
    if (self.format) |*format| {
        return format;
    } else {
        self.format = try Format.init(self.allocator);
        return &self.format.?;
    }
}

pub fn getHangulMap(self: *Self) !*HangulMap {
    if (self.hangul_map) |*hangul_map| {
        return hangul_map;
    } else {
        self.hangul_map = try HangulMap.init(self.allocator);
        return &self.hangul_map.?;
    }
}

pub fn getPrepend(self: *Self) !*Prepend {
    if (self.prepend) |*prepend| {
        return prepend;
    } else {
        self.prepend = try Prepend.init(self.allocator);
        return &self.prepend.?;
    }
}

pub fn getRegional(self: *Self) !*Regional {
    if (self.regional) |*regional| {
        return regional;
    } else {
        self.regional = try Regional.init(self.allocator);
        return &self.regional.?;
    }
}

pub fn getCaseFoldMap(self: *Self) !*CaseFoldMap {
    if (self.fold_map) |*fold_map| {
        return fold_map;
    } else {
        self.fold_map = try CaseFoldMap.init(self.allocator);
        return &self.fold_map.?;
    }
}

pub fn getCased(self: *Self) !*Cased {
    if (self.cased) |*cased| {
        return cased;
    } else {
        self.cased = try Cased.init(self.allocator);
        return &self.cased.?;
    }
}

pub fn getLower(self: *Self) !*Lower {
    if (self.lower) |*lower| {
        return lower;
    } else {
        self.lower = try Lower.init(self.allocator);
        return &self.lower.?;
    }
}

pub fn getLowerMap(self: *Self) !*LowerMap {
    if (self.lower_map) |*lower_map| {
        return lower_map;
    } else {
        self.lower_map = try LowerMap.init(self.allocator);
        return &self.lower_map.?;
    }
}

pub fn getModifierLetter(self: *Self) !*ModifierLetter {
    if (self.modifier_letter) |*modifier_letter| {
        return modifier_letter;
    } else {
        self.modifier_letter = try ModifierLetter.init(self.allocator);
        return &self.modifier_letter.?;
    }
}

pub fn getOtherLetter(self: *Self) !*OtherLetter {
    if (self.other_letter) |*other_letter| {
        return other_letter;
    } else {
        self.other_letter = try OtherLetter.init(self.allocator);
        return &self.other_letter.?;
    }
}

pub fn getTitle(self: *Self) !*Title {
    if (self.title) |*title| {
        return title;
    } else {
        self.title = try Title.init(self.allocator);
        return &self.title.?;
    }
}

pub fn getTitleMap(self: *Self) !*TitleMap {
    if (self.title_map) |*title_map| {
        return title_map;
    } else {
        self.title_map = try TitleMap.init(self.allocator);
        return &self.title_map.?;
    }
}

pub fn getUpper(self: *Self) !*Upper {
    if (self.upper) |*upper| {
        return upper;
    } else {
        self.upper = try Upper.init(self.allocator);
        return &self.upper.?;
    }
}

pub fn getUpperMap(self: *Self) !*UpperMap {
    if (self.upper_map) |*upper_map| {
        return upper_map;
    } else {
        self.upper_map = try UpperMap.init(self.allocator);
        return &self.upper_map.?;
    }
}

pub fn getEnclosing(self: *Self) !*Enclosing {
    if (self.enclosing) |*enclosing| {
        return enclosing;
    } else {
        self.enclosing = try Enclosing.init(self.allocator);
        return &self.enclosing.?;
    }
}

pub fn getNonspacing(self: *Self) !*Nonspacing {
    if (self.nonspacing) |*nonspacing| {
        return nonspacing;
    } else {
        self.nonspacing = try Nonspacing.init(self.allocator);
        return &self.nonspacing.?;
    }
}

pub fn getSpacing(self: *Self) !*Spacing {
    if (self.spacing) |*spacing| {
        return spacing;
    } else {
        self.spacing = try Spacing.init(self.allocator);
        return &self.spacing.?;
    }
}

pub fn getDecimal(self: *Self) !*Decimal {
    if (self.decimal) |*decimal| {
        return decimal;
    } else {
        self.decimal = try Decimal.init(self.allocator);
        return &self.decimal.?;
    }
}

pub fn getDigit(self: *Self) !*Digit {
    if (self.digit) |*digit| {
        return digit;
    } else {
        self.digit = try Digit.init(self.allocator);
        return &self.digit.?;
    }
}

pub fn getHex(self: *Self) !*Hex {
    if (self.hex) |*hex| {
        return hex;
    } else {
        self.hex = try Hex.init(self.allocator);
        return &self.hex.?;
    }
}

pub fn getLetterNumber(self: *Self) !*LetterNumber {
    if (self.letter_number) |*letter_number| {
        return letter_number;
    } else {
        self.letter_number = try LetterNumber.init(self.allocator);
        return &self.letter_number.?;
    }
}

pub fn getOtherNumber(self: *Self) !*OtherNumber {
    if (self.other_number) |*other_number| {
        return other_number;
    } else {
        self.other_number = try OtherNumber.init(self.allocator);
        return &self.other_number.?;
    }
}

pub fn getClose(self: *Self) !*Close {
    if (self.close) |*close| {
        return close;
    } else {
        self.close = try Close.init(self.allocator);
        return &self.close.?;
    }
}

pub fn getConnector(self: *Self) !*Connector {
    if (self.connector) |*connector| {
        return connector;
    } else {
        self.connector = try Connector.init(self.allocator);
        return &self.connector.?;
    }
}

pub fn getDash(self: *Self) !*Dash {
    if (self.dash) |*dash| {
        return dash;
    } else {
        self.dash = try Dash.init(self.allocator);
        return &self.dash.?;
    }
}

pub fn getFinal(self: *Self) !*Final {
    if (self.final) |*final| {
        return final;
    } else {
        self.final = try Final.init(self.allocator);
        return &self.final.?;
    }
}

pub fn getInitial(self: *Self) !*Initial {
    if (self.initial) |*initial| {
        return initial;
    } else {
        self.initial = try Initial.init(self.allocator);
        return &self.initial.?;
    }
}

pub fn getOpen(self: *Self) !*Open {
    if (self.open) |*open| {
        return open;
    } else {
        self.open = try Open.init(self.allocator);
        return &self.open.?;
    }
}

pub fn getOtherPunct(self: *Self) !*OtherPunct {
    if (self.other_punct) |*other_punct| {
        return other_punct;
    } else {
        self.other_punct = try OtherPunct.init(self.allocator);
        return &self.other_punct.?;
    }
}

pub fn getWhiteSpace(self: *Self) !*WhiteSpace {
    if (self.whitespace) |*whitespace| {
        return whitespace;
    } else {
        self.whitespace = try WhiteSpace.init(self.allocator);
        return &self.whitespace.?;
    }
}

pub fn getSpace(self: *Self) !*Space {
    if (self.space) |*space| {
        return space;
    } else {
        self.space = try Space.init(self.allocator);
        return &self.space.?;
    }
}

pub fn getCurrency(self: *Self) !*Currency {
    if (self.currency) |*currency| {
        return currency;
    } else {
        self.currency = try Currency.init(self.allocator);
        return &self.currency.?;
    }
}

pub fn getMath(self: *Self) !*Math {
    if (self.math) |*math| {
        return math;
    } else {
        self.math = try Math.init(self.allocator);
        return &self.math.?;
    }
}

pub fn getModifierSymbol(self: *Self) !*ModifierSymbol {
    if (self.modifier_symbol) |*modifier_symbol| {
        return modifier_symbol;
    } else {
        self.modifier_symbol = try ModifierSymbol.init(self.allocator);
        return &self.modifier_symbol.?;
    }
}

pub fn getOtherSymbol(self: *Self) !*OtherSymbol {
    if (self.other_symbol) |*other_symbol| {
        return other_symbol;
    } else {
        self.other_symbol = try OtherSymbol.init(self.allocator);
        return &self.other_symbol.?;
    }
}

pub fn getFullwidth(self: *Self) !*Fullwidth {
    if (self.fullwidth) |*fullwidth| {
        return fullwidth;
    } else {
        self.fullwidth = try Fullwidth.init(self.allocator);
        return &self.fullwidth.?;
    }
}

pub fn getNarrow(self: *Self) !*Narrow {
    if (self.narrow) |*narrow| {
        return narrow;
    } else {
        self.narrow = try Narrow.init(self.allocator);
        return &self.narrow.?;
    }
}

pub fn getWide(self: *Self) !*Wide {
    if (self.wide) |*wide| {
        return wide;
    } else {
        self.wide = try Wide.init(self.allocator);
        return &self.wide.?;
    }
}
