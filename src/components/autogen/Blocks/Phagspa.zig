// Autogenerated from http://www.unicode.org/Public/UCD/latest/ucd/UCD.zip by running ucd_gen.sh.
// Placeholders:
//    0. Struct name
//    1. Lowest code point
//    2. Highest code point
//! Unicode Phagspa code points.

const lo: u21 = 0xa840;
const hi: u21 = 0xa87f;

pub fn isPhagspa(cp: u21) bool {
    if (cp < lo or cp > hi) return false;
    return switch (cp) {
        0xa840...0xa87f => true,
        else => false,
    };
}