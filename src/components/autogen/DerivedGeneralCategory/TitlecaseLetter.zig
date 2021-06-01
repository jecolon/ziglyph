// Autogenerated from http://www.unicode.org/Public/UCD/latest/ucd/UCD.zip by running ucd_gen.sh.
// Placeholders:
//    0. Struct name
//    1. Lowest code point
//    2. Highest code point
//! Unicode TitlecaseLetter code points.

const lo: u21 = 0x1c5;
const hi: u21 = 0x1ffc;

pub fn isTitlecaseLetter(cp: u21) bool {
    if (cp < lo or cp > hi) return false;
    return switch (cp) {
        0x1c5 => true,
        0x1c8 => true,
        0x1cb => true,
        0x1f2 => true,
        0x1f88...0x1f8f => true,
        0x1f98...0x1f9f => true,
        0x1fa8...0x1faf => true,
        0x1fbc => true,
        0x1fcc => true,
        0x1ffc => true,
        else => false,
    };
}