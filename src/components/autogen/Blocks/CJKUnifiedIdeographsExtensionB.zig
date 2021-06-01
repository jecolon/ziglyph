// Autogenerated from http://www.unicode.org/Public/UCD/latest/ucd/UCD.zip by running ucd_gen.sh.
// Placeholders:
//    0. Struct name
//    1. Lowest code point
//    2. Highest code point
//! Unicode CJKUnifiedIdeographsExtensionB code points.

const lo: u21 = 0x20000;
const hi: u21 = 0x2a6df;

pub fn isCJKUnifiedIdeographsExtensionB(cp: u21) bool {
    if (cp < lo or cp > hi) return false;
    return switch (cp) {
        0x20000...0x2a6df => true,
        else => false,
    };
}