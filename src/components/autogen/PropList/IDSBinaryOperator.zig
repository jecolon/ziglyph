// Autogenerated from http://www.unicode.org/Public/UCD/latest/ucd/UCD.zip by running ucd_gen.sh.
// Placeholders:
//    0. Struct name
//    1. Lowest code point
//    2. Highest code point
//! Unicode IDSBinaryOperator code points.

const lo: u21 = 0x2ff0;
const hi: u21 = 0x2ffb;

pub fn isIDSBinaryOperator(cp: u21) bool {
    if (cp < lo or cp > hi) return false;
    return switch (cp) {
        0x2ff0...0x2ff1 => true,
        0x2ff4...0x2ffb => true,
        else => false,
    };
}