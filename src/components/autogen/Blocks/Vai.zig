// Autogenerated from http://www.unicode.org/Public/UCD/latest/ucd/UCD.zip by running ucd_gen.sh.
// Placeholders:
//    0. Struct name
//    1. Lowest code point
//    2. Highest code point
//! Unicode Vai code points.

const lo: u21 = 0xa500;
const hi: u21 = 0xa63f;

pub fn isVai(cp: u21) bool {
    if (cp < lo or cp > hi) return false;
    return switch (cp) {
        0xa500...0xa63f => true,
        else => false,
    };
}