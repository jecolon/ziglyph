// Autogenerated from http://www.unicode.org/Public/UCD/latest/ucd/UCD.zip by running ucd_gen.sh.
// Placeholders:
//    0. Struct name
//    1. Lowest code point
//    2. Highest code point
//! Unicode PatternWhiteSpace code points.

const lo: u21 = 0x9;
const hi: u21 = 0x2029;

pub fn isPatternWhiteSpace(cp: u21) bool {
    if (cp < lo or cp > hi) return false;
    return switch (cp) {
        0x9...0xd => true,
        0x20 => true,
        0x85 => true,
        0x200e...0x200f => true,
        0x2028 => true,
        0x2029 => true,
        else => false,
    };
}