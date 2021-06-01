// Autogenerated from http://www.unicode.org/Public/UCD/latest/ucd/UCD.zip by running ucd_gen.sh.
// Placeholders:
//    0. Struct name
//    1. Lowest code point
//    2. Highest code point
//! Unicode KhmerSymbols code points.

const lo: u21 = 0x19e0;
const hi: u21 = 0x19ff;

pub fn isKhmerSymbols(cp: u21) bool {
    if (cp < lo or cp > hi) return false;
    return switch (cp) {
        0x19e0...0x19ff => true,
        else => false,
    };
}