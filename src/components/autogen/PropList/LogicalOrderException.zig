// Autogenerated from http://www.unicode.org/Public/UCD/latest/ucd/UCD.zip by running ucd_gen.sh.
// Placeholders:
//    0. Struct name
//    1. Lowest code point
//    2. Highest code point
//! Unicode LogicalOrderException code points.

const lo: u21 = 0xe40;
const hi: u21 = 0xaabc;

pub fn isLogicalOrderException(cp: u21) bool {
    if (cp < lo or cp > hi) return false;
    return switch (cp) {
        0xe40...0xe44 => true,
        0xec0...0xec4 => true,
        0x19b5...0x19b7 => true,
        0x19ba => true,
        0xaab5...0xaab6 => true,
        0xaab9 => true,
        0xaabb...0xaabc => true,
        else => false,
    };
}