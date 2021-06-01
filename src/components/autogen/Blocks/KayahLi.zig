// Autogenerated from http://www.unicode.org/Public/UCD/latest/ucd/UCD.zip by running ucd_gen.sh.
// Placeholders:
//    0. Struct name
//    1. Lowest code point
//    2. Highest code point
//! Unicode KayahLi code points.

const lo: u21 = 0xa900;
const hi: u21 = 0xa92f;

pub fn isKayahLi(cp: u21) bool {
    if (cp < lo or cp > hi) return false;
    return switch (cp) {
        0xa900...0xa92f => true,
        else => false,
    };
}