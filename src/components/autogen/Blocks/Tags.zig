// Autogenerated from http://www.unicode.org/Public/UCD/latest/ucd/UCD.zip by running ucd_gen.sh.
// Placeholders:
//    0. Struct name
//    1. Lowest code point
//    2. Highest code point
//! Unicode Tags code points.

const lo: u21 = 0xe0000;
const hi: u21 = 0xe007f;

pub fn isTags(cp: u21) bool {
    if (cp < lo or cp > hi) return false;
    return switch (cp) {
        0xe0000...0xe007f => true,
        else => false,
    };
}