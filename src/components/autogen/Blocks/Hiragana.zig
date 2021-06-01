// Autogenerated from http://www.unicode.org/Public/UCD/latest/ucd/UCD.zip by running ucd_gen.sh.
// Placeholders:
//    0. Struct name
//    1. Lowest code point
//    2. Highest code point
//! Unicode Hiragana code points.

const lo: u21 = 0x3040;
const hi: u21 = 0x309f;

pub fn isHiragana(cp: u21) bool {
    if (cp < lo or cp > hi) return false;
    return switch (cp) {
        0x3040...0x309f => true,
        else => false,
    };
}