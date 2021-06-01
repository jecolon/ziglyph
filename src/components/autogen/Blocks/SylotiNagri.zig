// Autogenerated from http://www.unicode.org/Public/UCD/latest/ucd/UCD.zip by running ucd_gen.sh.
// Placeholders:
//    0. Struct name
//    1. Lowest code point
//    2. Highest code point
//! Unicode SylotiNagri code points.

const lo: u21 = 0xa800;
const hi: u21 = 0xa82f;

pub fn isSylotiNagri(cp: u21) bool {
    if (cp < lo or cp > hi) return false;
    return switch (cp) {
        0xa800...0xa82f => true,
        else => false,
    };
}