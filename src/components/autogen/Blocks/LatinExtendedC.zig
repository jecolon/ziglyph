// Autogenerated from http://www.unicode.org/Public/UCD/latest/ucd/UCD.zip by running ucd_gen.sh.
// Placeholders:
//    0. Struct name
//    1. Lowest code point
//    2. Highest code point
//! Unicode LatinExtendedC code points.

const lo: u21 = 0x2c60;
const hi: u21 = 0x2c7f;

pub fn isLatinExtendedC(cp: u21) bool {
    if (cp < lo or cp > hi) return false;
    return switch (cp) {
        0x2c60...0x2c7f => true,
        else => false,
    };
}