// Autogenerated from http://www.unicode.org/Public/UCD/latest/ucd/UCD.zip by running ucd_gen.sh.
// Placeholders:
//    0. Struct name
//    1. Lowest code point
//    2. Highest code point
//! Unicode ChangesWhenCasemapped code points.

const lo: u21 = 0x41;
const hi: u21 = 0x1e943;

pub fn isChangesWhenCasemapped(cp: u21) bool {
    if (cp < lo or cp > hi) return false;
    return switch (cp) {
        0x41...0x5a => true,
        0x61...0x7a => true,
        0xb5 => true,
        0xc0...0xd6 => true,
        0xd8...0xf6 => true,
        0xf8...0x137 => true,
        0x139...0x18c => true,
        0x18e...0x19a => true,
        0x19c...0x1a9 => true,
        0x1ac...0x1b9 => true,
        0x1bc...0x1bd => true,
        0x1bf => true,
        0x1c4...0x220 => true,
        0x222...0x233 => true,
        0x23a...0x254 => true,
        0x256...0x257 => true,
        0x259 => true,
        0x25b...0x25c => true,
        0x260...0x261 => true,
        0x263 => true,
        0x265...0x266 => true,
        0x268...0x26c => true,
        0x26f => true,
        0x271...0x272 => true,
        0x275 => true,
        0x27d => true,
        0x280 => true,
        0x282...0x283 => true,
        0x287...0x28c => true,
        0x292 => true,
        0x29d...0x29e => true,
        0x345 => true,
        0x370...0x373 => true,
        0x376...0x377 => true,
        0x37b...0x37d => true,
        0x37f => true,
        0x386 => true,
        0x388...0x38a => true,
        0x38c => true,
        0x38e...0x3a1 => true,
        0x3a3...0x3d1 => true,
        0x3d5...0x3f5 => true,
        0x3f7...0x3fb => true,
        0x3fd...0x481 => true,
        0x48a...0x52f => true,
        0x531...0x556 => true,
        0x561...0x587 => true,
        0x10a0...0x10c5 => true,
        0x10c7 => true,
        0x10cd => true,
        0x10d0...0x10fa => true,
        0x10fd...0x10ff => true,
        0x13a0...0x13f5 => true,
        0x13f8...0x13fd => true,
        0x1c80...0x1c88 => true,
        0x1c90...0x1cba => true,
        0x1cbd...0x1cbf => true,
        0x1d79 => true,
        0x1d7d => true,
        0x1d8e => true,
        0x1e00...0x1e9b => true,
        0x1e9e => true,
        0x1ea0...0x1f15 => true,
        0x1f18...0x1f1d => true,
        0x1f20...0x1f45 => true,
        0x1f48...0x1f4d => true,
        0x1f50...0x1f57 => true,
        0x1f59 => true,
        0x1f5b => true,
        0x1f5d => true,
        0x1f5f...0x1f7d => true,
        0x1f80...0x1fb4 => true,
        0x1fb6...0x1fbc => true,
        0x1fbe => true,
        0x1fc2...0x1fc4 => true,
        0x1fc6...0x1fcc => true,
        0x1fd0...0x1fd3 => true,
        0x1fd6...0x1fdb => true,
        0x1fe0...0x1fec => true,
        0x1ff2...0x1ff4 => true,
        0x1ff6...0x1ffc => true,
        0x2126 => true,
        0x212a...0x212b => true,
        0x2132 => true,
        0x214e => true,
        0x2160...0x217f => true,
        0x2183...0x2184 => true,
        0x24b6...0x24e9 => true,
        0x2c00...0x2c2e => true,
        0x2c30...0x2c5e => true,
        0x2c60...0x2c70 => true,
        0x2c72...0x2c73 => true,
        0x2c75...0x2c76 => true,
        0x2c7e...0x2ce3 => true,
        0x2ceb...0x2cee => true,
        0x2cf2...0x2cf3 => true,
        0x2d00...0x2d25 => true,
        0x2d27 => true,
        0x2d2d => true,
        0xa640...0xa66d => true,
        0xa680...0xa69b => true,
        0xa722...0xa72f => true,
        0xa732...0xa76f => true,
        0xa779...0xa787 => true,
        0xa78b...0xa78d => true,
        0xa790...0xa794 => true,
        0xa796...0xa7ae => true,
        0xa7b0...0xa7bf => true,
        0xa7c2...0xa7ca => true,
        0xa7f5...0xa7f6 => true,
        0xab53 => true,
        0xab70...0xabbf => true,
        0xfb00...0xfb06 => true,
        0xfb13...0xfb17 => true,
        0xff21...0xff3a => true,
        0xff41...0xff5a => true,
        0x10400...0x1044f => true,
        0x104b0...0x104d3 => true,
        0x104d8...0x104fb => true,
        0x10c80...0x10cb2 => true,
        0x10cc0...0x10cf2 => true,
        0x118a0...0x118df => true,
        0x16e40...0x16e7f => true,
        0x1e900...0x1e943 => true,
        else => false,
    };
}