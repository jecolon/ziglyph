// Autogenerated from http://www.unicode.org/Public/UCD/latest/ucd/UCD.zip by running ucd_gen.sh.
// Placeholders:
//    0. Struct name
//    1. Lowest code point
//    2. Highest code point
//! Unicode PahawhHmong code points.

const lo: u21 = 0x16b00;
const hi: u21 = 0x16b8f;

pub fn isPahawhHmong(cp: u21) bool {
    if (cp < lo or cp > hi) return false;
    return switch (cp) {
        0x16b00...0x16b8f => true,
        else => false,
    };
}