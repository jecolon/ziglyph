const std = @import("std");
const unicode = std.unicode;

const Control = @import("ziglyph.zig").Control;
const Lower = @import("components/autogen/DerivedGeneralCategory/LowercaseLetter.zig");
const ModLetter = @import("components/autogen/DerivedGeneralCategory/ModifierLetter.zig");
const OtherLetter = @import("components/autogen/DerivedGeneralCategory/OtherLetter.zig");
const Title = @import("components/autogen/DerivedGeneralCategory/TitlecaseLetter.zig");
const Upper = @import("components/autogen/DerivedGeneralCategory/UppercaseLetter.zig");
const SpacingMark = @import("components/autogen/DerivedGeneralCategory/SpacingMark.zig");
const NonSpacingMark = @import("components/autogen/DerivedGeneralCategory/NonspacingMark.zig");
const EnclosingMark = @import("components/autogen/DerivedGeneralCategory/EnclosingMark.zig");
const Decimal = @import("components/autogen/DerivedGeneralCategory/DecimalNumber.zig");
const LetterNumber = @import("components/autogen/DerivedGeneralCategory/LetterNumber.zig");
const OtherNumber = @import("components/autogen/DerivedGeneralCategory/OtherNumber.zig");
const ClosePunct = @import("components/autogen/DerivedGeneralCategory/ClosePunctuation.zig");
const ConnectPunct = @import("components/autogen/DerivedGeneralCategory/ConnectorPunctuation.zig");
const DashPunct = @import("components/autogen/DerivedGeneralCategory/DashPunctuation.zig");
const FinalPunct = @import("components/autogen/UnicodeData/FinalPunctuation.zig");
const InitialPunct = @import("components/autogen/DerivedGeneralCategory/InitialPunctuation.zig");
const OpenPunct = @import("components/autogen/DerivedGeneralCategory/OpenPunctuation.zig");
const OtherPunct = @import("components/autogen/DerivedGeneralCategory/OtherPunctuation.zig");
const WhiteSpace = @import("ziglyph.zig").Space.WhiteSpace;
const MathSymbol = @import("components/autogen/DerivedGeneralCategory/MathSymbol.zig");
const ModSymbol = @import("components/autogen/DerivedGeneralCategory/ModifierSymbol.zig");
const CurrencySymbol = @import("components/autogen/DerivedGeneralCategory/CurrencySymbol.zig");
const OtherSymbol = @import("components/autogen/DerivedGeneralCategory/OtherSymbol.zig");

const LowerMap = @import("ziglyph.zig").Letter.LowerMap;
const TitleMap = @import("ziglyph.zig").Letter.TitleMap;
const UpperMap = @import("ziglyph.zig").Letter.UpperMap;

pub fn main() !void {
    const corpus = "src/data/lang_mix.txt";
    var file = try std.fs.cwd().openFile(corpus, .{});
    defer file.close();
    var buf_reader = std.io.bufferedReader(file.reader()).reader();

    //var allocator = std.testing.allocator;
    var allocator = std.heap.page_allocator;
    var control = try Control.init(allocator);
    defer control.deinit();
    var mod_letter = try ModLetter.init(allocator);
    defer mod_letter.deinit();
    var other_letter = try OtherLetter.init(allocator);
    defer other_letter.deinit();
    var lower = try Lower.init(allocator);
    defer lower.deinit();
    var spacing_mark = try SpacingMark.init(allocator);
    defer spacing_mark.deinit();
    var nonspacing_mark = try NonSpacingMark.init(allocator);
    defer nonspacing_mark.deinit();
    var enclosing_mark = try EnclosingMark.init(allocator);
    defer enclosing_mark.deinit();
    var letter_number = try LetterNumber.init(allocator);
    defer letter_number.deinit();
    var other_number = try OtherNumber.init(allocator);
    defer other_number.deinit();
    var decimal = try Decimal.init(allocator);
    defer decimal.deinit();
    var close_punct = try ClosePunct.init(allocator);
    defer close_punct.deinit();
    var connect_punct = try ConnectPunct.init(allocator);
    defer connect_punct.deinit();
    var dash_punct = try DashPunct.init(allocator);
    defer dash_punct.deinit();
    var final_punct = try FinalPunct.init(allocator);
    defer final_punct.deinit();
    var initial_punct = try InitialPunct.init(allocator);
    defer initial_punct.deinit();
    var open_punct = try OpenPunct.init(allocator);
    defer open_punct.deinit();
    var other_punct = try OtherPunct.init(allocator);
    defer other_punct.deinit();
    var whitespace = try WhiteSpace.init(allocator);
    defer whitespace.deinit();
    var math_symbol = try MathSymbol.init(allocator);
    defer math_symbol.deinit();
    var currency_symbol = try CurrencySymbol.init(allocator);
    defer currency_symbol.deinit();
    var mod_symbol = try ModSymbol.init(allocator);
    defer mod_symbol.deinit();
    var other_symbol = try OtherSymbol.init(allocator);
    defer other_symbol.deinit();
    var title = try Title.init(allocator);
    defer title.deinit();
    var upper = try Upper.init(allocator);
    defer upper.deinit();

    var lower_map = try LowerMap.init(allocator);
    defer lower_map.deinit();
    var title_map = try TitleMap.init(allocator);
    defer title_map.deinit();
    var upper_map = try UpperMap.init(allocator);
    defer upper_map.deinit();

    var c_count: usize = 0;
    var l_count: usize = 0;
    var ll_count: usize = 0;
    var lt_count: usize = 0;
    var lu_count: usize = 0;
    var m_count: usize = 0;
    var n_count: usize = 0;
    var p_count: usize = 0;
    var z_count: usize = 0;
    var s_count: usize = 0;

    var buf: [1024]u8 = undefined;
    while (try buf_reader.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        const s = try unicode.Utf8View.init(line);
        var iter = s.iterator();
        while (iter.nextCodepoint()) |cp| {
            if (control.isControl(cp)) {
                c_count += 1;
            } else if (lower.isLowercaseLetter(cp) or
                mod_letter.isModifierLetter(cp) or
                other_letter.isOtherLetter(cp) or
                title.isTitlecaseLetter(cp) or
                upper.isUppercaseLetter(cp))
            {
                l_count += 1;
                if (lower.isLowercaseLetter(cp)) {
                    ll_count += 1;
                    _ = title_map.toTitle(cp);
                } else if (title.isTitlecaseLetter(cp)) {
                    lt_count += 1;
                    _ = upper_map.toUpper(cp);
                } else if (upper.isUppercaseLetter(cp)) {
                    lu_count += 1;
                    _ = lower_map.toLower(cp);
                }
            } else if (spacing_mark.isSpacingMark(cp) or
                nonspacing_mark.isNonspacingMark(cp) or
                enclosing_mark.isEnclosingMark(cp))
            {
                m_count += 1;
            } else if (decimal.isDecimalNumber(cp) or
                letter_number.isLetterNumber(cp) or
                other_number.isOtherNumber(cp))
            {
                n_count += 1;
            } else if (close_punct.isClosePunctuation(cp) or
                connect_punct.isConnectorPunctuation(cp) or
                dash_punct.isDashPunctuation(cp) or
                final_punct.isFinalPunctuation(cp) or
                initial_punct.isInitialPunctuation(cp) or
                open_punct.isOpenPunctuation(cp) or
                other_punct.isOtherPunctuation(cp))
            {
                p_count += 1;
            } else if (whitespace.isWhiteSpace(cp)) {
                z_count += 1;
            } else if (math_symbol.isMathSymbol(cp) or
                mod_symbol.isModifierSymbol(cp) or
                currency_symbol.isCurrencySymbol(cp) or
                other_symbol.isOtherSymbol(cp))
            {
                s_count += 1;
            }
        }
    }

    try std.io.getStdOut().writer().print(
        "c: {d}, l: {d}, ll: {d}, lt: {d}, lu: {d}, m: {d}, n: {d}, p: {d}, z: {d}, s: {d}\n",
        .{
            c_count,  l_count, ll_count, lt_count,
            lu_count, m_count, n_count,  p_count,
            z_count,  s_count,
        },
    );
}
