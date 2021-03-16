//! ziglyph provides functions and values to process Unicode encoded data. This library is based on
//! the unicode base package from the Go standard library.

pub const casing = @import("casing.zig");
pub const kinds = @import("kinds.zig");
pub const tables = @import("tables.zig");
pub const values = @import("values.zig");

/// A rune is an unsigned 21 bit integer that contains a Unicode codepoint.
pub const rune = values.rune;

/// Letter casing functions.
pub const isLower = casing.isLower;
pub const isTitle = casing.isTitle;
pub const isUpper = casing.isUpper;
pub const toLower = casing.toLower;
pub const toTitle = casing.toTitle;
pub const toUpper = casing.toUpper;

/// Rune kind detection functions.
pub const isControl = kinds.isControl;
pub const isDigit = kinds.isDigit;
pub const isGraphic = kinds.isGraphic;
pub const isLetter = kinds.isLetter;
pub const isMark = kinds.isMark;
pub const isNumber = kinds.isNumber;
pub const isPunct = kinds.isPunct;
pub const isPrint = kinds.isPrint;
pub const isSpace = kinds.isSpace;
pub const isSymbol = kinds.isSymbol;

/// Special rune kind values.
pub const Digit = values.Digit;
pub const Letter = values.Letter;
pub const Mark = values.Mark;
pub const Number = values.Number;
pub const Punct = values.Punct;
pub const Space = values.Space;
pub const Symbol = values.Symbol;
