// Autogenerated from http://www.unicode.org/Public/UCD/latest/ucd/UCD.zip by running ucd_gen.sh.
// Placeholders:
//    0. Struct name
//    1. Lowest code point
//    2. Highest code point
//! Unicode CombiningDiacriticalMarksSupplement code points.

const lo: u21 = 0x1dc0;
const hi: u21 = 0x1dff;

pub fn isCombiningDiacriticalMarksSupplement(cp: u21) bool {
    if (cp < lo or cp > hi) return false;
    return switch (cp) {
        0x1dc0...0x1dff => true,
        else => false,
    };
}