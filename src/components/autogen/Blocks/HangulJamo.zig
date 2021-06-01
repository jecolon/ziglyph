// Autogenerated from http://www.unicode.org/Public/UCD/latest/ucd/UCD.zip by running ucd_gen.sh.
// Placeholders:
//    0. Struct name
//    1. Lowest code point
//    2. Highest code point
//! Unicode HangulJamo code points.

const lo: u21 = 0x1100;
const hi: u21 = 0x11ff;

pub fn isHangulJamo(cp: u21) bool {
    if (cp < lo or cp > hi) return false;
    return switch (cp) {
        0x1100...0x11ff => true,
        else => false,
    };
}