// Autogenerated from http://www.unicode.org/Public/UCD/latest/ucd/UCD.zip by running ucd_gen.sh.
// Placeholders:
//    0. Struct name
//    1. Lowest code point
//    2. Highest code point
//! Unicode HangulSyllables code points.

const lo: u21 = 0xac00;
const hi: u21 = 0xd7af;

pub fn isHangulSyllables(cp: u21) bool {
    if (cp < lo or cp > hi) return false;
    return switch (cp) {
        0xac00...0xd7af => true,
        else => false,
    };
}