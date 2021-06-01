// Autogenerated from http://www.unicode.org/Public/UCD/latest/ucd/UCD.zip by running ucd_gen.sh.
// Placeholders:
//    0. Struct name
//    1. Lowest code point
//    2. Highest code point
//! Unicode PlayingCards code points.

const lo: u21 = 0x1f0a0;
const hi: u21 = 0x1f0ff;

pub fn isPlayingCards(cp: u21) bool {
    if (cp < lo or cp > hi) return false;
    return switch (cp) {
        0x1f0a0...0x1f0ff => true,
        else => false,
    };
}