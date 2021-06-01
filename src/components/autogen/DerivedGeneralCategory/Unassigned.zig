// Autogenerated from http://www.unicode.org/Public/UCD/latest/ucd/UCD.zip by running ucd_gen.sh.
// Placeholders:
//    0. Struct name
//    1. Lowest code point
//    2. Highest code point
//! Unicode Unassigned code points.

const lo: u21 = 0x378;
const hi: u21 = 0x10ffff;

pub fn isUnassigned(cp: u21) bool {
    if (cp < lo or cp > hi) return false;
    return switch (cp) {
        0x378...0x379 => true,
        0x380...0x383 => true,
        0x38b => true,
        0x38d => true,
        0x3a2 => true,
        0x530 => true,
        0x557...0x558 => true,
        0x58b...0x58c => true,
        0x590 => true,
        0x5c8...0x5cf => true,
        0x5eb...0x5ee => true,
        0x5f5...0x5ff => true,
        0x61d => true,
        0x70e => true,
        0x74b...0x74c => true,
        0x7b2...0x7bf => true,
        0x7fb...0x7fc => true,
        0x82e...0x82f => true,
        0x83f => true,
        0x85c...0x85d => true,
        0x85f => true,
        0x86b...0x89f => true,
        0x8b5 => true,
        0x8c8...0x8d2 => true,
        0x984 => true,
        0x98d...0x98e => true,
        0x991...0x992 => true,
        0x9a9 => true,
        0x9b1 => true,
        0x9b3...0x9b5 => true,
        0x9ba...0x9bb => true,
        0x9c5...0x9c6 => true,
        0x9c9...0x9ca => true,
        0x9cf...0x9d6 => true,
        0x9d8...0x9db => true,
        0x9de => true,
        0x9e4...0x9e5 => true,
        0x9ff...0xa00 => true,
        0xa04 => true,
        0xa0b...0xa0e => true,
        0xa11...0xa12 => true,
        0xa29 => true,
        0xa31 => true,
        0xa34 => true,
        0xa37 => true,
        0xa3a...0xa3b => true,
        0xa3d => true,
        0xa43...0xa46 => true,
        0xa49...0xa4a => true,
        0xa4e...0xa50 => true,
        0xa52...0xa58 => true,
        0xa5d => true,
        0xa5f...0xa65 => true,
        0xa77...0xa80 => true,
        0xa84 => true,
        0xa8e => true,
        0xa92 => true,
        0xaa9 => true,
        0xab1 => true,
        0xab4 => true,
        0xaba...0xabb => true,
        0xac6 => true,
        0xaca => true,
        0xace...0xacf => true,
        0xad1...0xadf => true,
        0xae4...0xae5 => true,
        0xaf2...0xaf8 => true,
        0xb00 => true,
        0xb04 => true,
        0xb0d...0xb0e => true,
        0xb11...0xb12 => true,
        0xb29 => true,
        0xb31 => true,
        0xb34 => true,
        0xb3a...0xb3b => true,
        0xb45...0xb46 => true,
        0xb49...0xb4a => true,
        0xb4e...0xb54 => true,
        0xb58...0xb5b => true,
        0xb5e => true,
        0xb64...0xb65 => true,
        0xb78...0xb81 => true,
        0xb84 => true,
        0xb8b...0xb8d => true,
        0xb91 => true,
        0xb96...0xb98 => true,
        0xb9b => true,
        0xb9d => true,
        0xba0...0xba2 => true,
        0xba5...0xba7 => true,
        0xbab...0xbad => true,
        0xbba...0xbbd => true,
        0xbc3...0xbc5 => true,
        0xbc9 => true,
        0xbce...0xbcf => true,
        0xbd1...0xbd6 => true,
        0xbd8...0xbe5 => true,
        0xbfb...0xbff => true,
        0xc0d => true,
        0xc11 => true,
        0xc29 => true,
        0xc3a...0xc3c => true,
        0xc45 => true,
        0xc49 => true,
        0xc4e...0xc54 => true,
        0xc57 => true,
        0xc5b...0xc5f => true,
        0xc64...0xc65 => true,
        0xc70...0xc76 => true,
        0xc8d => true,
        0xc91 => true,
        0xca9 => true,
        0xcb4 => true,
        0xcba...0xcbb => true,
        0xcc5 => true,
        0xcc9 => true,
        0xcce...0xcd4 => true,
        0xcd7...0xcdd => true,
        0xcdf => true,
        0xce4...0xce5 => true,
        0xcf0 => true,
        0xcf3...0xcff => true,
        0xd0d => true,
        0xd11 => true,
        0xd45 => true,
        0xd49 => true,
        0xd50...0xd53 => true,
        0xd64...0xd65 => true,
        0xd80 => true,
        0xd84 => true,
        0xd97...0xd99 => true,
        0xdb2 => true,
        0xdbc => true,
        0xdbe...0xdbf => true,
        0xdc7...0xdc9 => true,
        0xdcb...0xdce => true,
        0xdd5 => true,
        0xdd7 => true,
        0xde0...0xde5 => true,
        0xdf0...0xdf1 => true,
        0xdf5...0xe00 => true,
        0xe3b...0xe3e => true,
        0xe5c...0xe80 => true,
        0xe83 => true,
        0xe85 => true,
        0xe8b => true,
        0xea4 => true,
        0xea6 => true,
        0xebe...0xebf => true,
        0xec5 => true,
        0xec7 => true,
        0xece...0xecf => true,
        0xeda...0xedb => true,
        0xee0...0xeff => true,
        0xf48 => true,
        0xf6d...0xf70 => true,
        0xf98 => true,
        0xfbd => true,
        0xfcd => true,
        0xfdb...0xfff => true,
        0x10c6 => true,
        0x10c8...0x10cc => true,
        0x10ce...0x10cf => true,
        0x1249 => true,
        0x124e...0x124f => true,
        0x1257 => true,
        0x1259 => true,
        0x125e...0x125f => true,
        0x1289 => true,
        0x128e...0x128f => true,
        0x12b1 => true,
        0x12b6...0x12b7 => true,
        0x12bf => true,
        0x12c1 => true,
        0x12c6...0x12c7 => true,
        0x12d7 => true,
        0x1311 => true,
        0x1316...0x1317 => true,
        0x135b...0x135c => true,
        0x137d...0x137f => true,
        0x139a...0x139f => true,
        0x13f6...0x13f7 => true,
        0x13fe...0x13ff => true,
        0x169d...0x169f => true,
        0x16f9...0x16ff => true,
        0x170d => true,
        0x1715...0x171f => true,
        0x1737...0x173f => true,
        0x1754...0x175f => true,
        0x176d => true,
        0x1771 => true,
        0x1774...0x177f => true,
        0x17de...0x17df => true,
        0x17ea...0x17ef => true,
        0x17fa...0x17ff => true,
        0x180f => true,
        0x181a...0x181f => true,
        0x1879...0x187f => true,
        0x18ab...0x18af => true,
        0x18f6...0x18ff => true,
        0x191f => true,
        0x192c...0x192f => true,
        0x193c...0x193f => true,
        0x1941...0x1943 => true,
        0x196e...0x196f => true,
        0x1975...0x197f => true,
        0x19ac...0x19af => true,
        0x19ca...0x19cf => true,
        0x19db...0x19dd => true,
        0x1a1c...0x1a1d => true,
        0x1a5f => true,
        0x1a7d...0x1a7e => true,
        0x1a8a...0x1a8f => true,
        0x1a9a...0x1a9f => true,
        0x1aae...0x1aaf => true,
        0x1ac1...0x1aff => true,
        0x1b4c...0x1b4f => true,
        0x1b7d...0x1b7f => true,
        0x1bf4...0x1bfb => true,
        0x1c38...0x1c3a => true,
        0x1c4a...0x1c4c => true,
        0x1c89...0x1c8f => true,
        0x1cbb...0x1cbc => true,
        0x1cc8...0x1ccf => true,
        0x1cfb...0x1cff => true,
        0x1dfa => true,
        0x1f16...0x1f17 => true,
        0x1f1e...0x1f1f => true,
        0x1f46...0x1f47 => true,
        0x1f4e...0x1f4f => true,
        0x1f58 => true,
        0x1f5a => true,
        0x1f5c => true,
        0x1f5e => true,
        0x1f7e...0x1f7f => true,
        0x1fb5 => true,
        0x1fc5 => true,
        0x1fd4...0x1fd5 => true,
        0x1fdc => true,
        0x1ff0...0x1ff1 => true,
        0x1ff5 => true,
        0x1fff => true,
        0x2065 => true,
        0x2072...0x2073 => true,
        0x208f => true,
        0x209d...0x209f => true,
        0x20c0...0x20cf => true,
        0x20f1...0x20ff => true,
        0x218c...0x218f => true,
        0x2427...0x243f => true,
        0x244b...0x245f => true,
        0x2b74...0x2b75 => true,
        0x2b96 => true,
        0x2c2f => true,
        0x2c5f => true,
        0x2cf4...0x2cf8 => true,
        0x2d26 => true,
        0x2d28...0x2d2c => true,
        0x2d2e...0x2d2f => true,
        0x2d68...0x2d6e => true,
        0x2d71...0x2d7e => true,
        0x2d97...0x2d9f => true,
        0x2da7 => true,
        0x2daf => true,
        0x2db7 => true,
        0x2dbf => true,
        0x2dc7 => true,
        0x2dcf => true,
        0x2dd7 => true,
        0x2ddf => true,
        0x2e53...0x2e7f => true,
        0x2e9a => true,
        0x2ef4...0x2eff => true,
        0x2fd6...0x2fef => true,
        0x2ffc...0x2fff => true,
        0x3040 => true,
        0x3097...0x3098 => true,
        0x3100...0x3104 => true,
        0x3130 => true,
        0x318f => true,
        0x31e4...0x31ef => true,
        0x321f => true,
        0x9ffd...0x9fff => true,
        0xa48d...0xa48f => true,
        0xa4c7...0xa4cf => true,
        0xa62c...0xa63f => true,
        0xa6f8...0xa6ff => true,
        0xa7c0...0xa7c1 => true,
        0xa7cb...0xa7f4 => true,
        0xa82d...0xa82f => true,
        0xa83a...0xa83f => true,
        0xa878...0xa87f => true,
        0xa8c6...0xa8cd => true,
        0xa8da...0xa8df => true,
        0xa954...0xa95e => true,
        0xa97d...0xa97f => true,
        0xa9ce => true,
        0xa9da...0xa9dd => true,
        0xa9ff => true,
        0xaa37...0xaa3f => true,
        0xaa4e...0xaa4f => true,
        0xaa5a...0xaa5b => true,
        0xaac3...0xaada => true,
        0xaaf7...0xab00 => true,
        0xab07...0xab08 => true,
        0xab0f...0xab10 => true,
        0xab17...0xab1f => true,
        0xab27 => true,
        0xab2f => true,
        0xab6c...0xab6f => true,
        0xabee...0xabef => true,
        0xabfa...0xabff => true,
        0xd7a4...0xd7af => true,
        0xd7c7...0xd7ca => true,
        0xd7fc...0xd7ff => true,
        0xfa6e...0xfa6f => true,
        0xfada...0xfaff => true,
        0xfb07...0xfb12 => true,
        0xfb18...0xfb1c => true,
        0xfb37 => true,
        0xfb3d => true,
        0xfb3f => true,
        0xfb42 => true,
        0xfb45 => true,
        0xfbc2...0xfbd2 => true,
        0xfd40...0xfd4f => true,
        0xfd90...0xfd91 => true,
        0xfdc8...0xfdef => true,
        0xfdfe...0xfdff => true,
        0xfe1a...0xfe1f => true,
        0xfe53 => true,
        0xfe67 => true,
        0xfe6c...0xfe6f => true,
        0xfe75 => true,
        0xfefd...0xfefe => true,
        0xff00 => true,
        0xffbf...0xffc1 => true,
        0xffc8...0xffc9 => true,
        0xffd0...0xffd1 => true,
        0xffd8...0xffd9 => true,
        0xffdd...0xffdf => true,
        0xffe7 => true,
        0xffef...0xfff8 => true,
        0xfffe...0xffff => true,
        0x1000c => true,
        0x10027 => true,
        0x1003b => true,
        0x1003e => true,
        0x1004e...0x1004f => true,
        0x1005e...0x1007f => true,
        0x100fb...0x100ff => true,
        0x10103...0x10106 => true,
        0x10134...0x10136 => true,
        0x1018f => true,
        0x1019d...0x1019f => true,
        0x101a1...0x101cf => true,
        0x101fe...0x1027f => true,
        0x1029d...0x1029f => true,
        0x102d1...0x102df => true,
        0x102fc...0x102ff => true,
        0x10324...0x1032c => true,
        0x1034b...0x1034f => true,
        0x1037b...0x1037f => true,
        0x1039e => true,
        0x103c4...0x103c7 => true,
        0x103d6...0x103ff => true,
        0x1049e...0x1049f => true,
        0x104aa...0x104af => true,
        0x104d4...0x104d7 => true,
        0x104fc...0x104ff => true,
        0x10528...0x1052f => true,
        0x10564...0x1056e => true,
        0x10570...0x105ff => true,
        0x10737...0x1073f => true,
        0x10756...0x1075f => true,
        0x10768...0x107ff => true,
        0x10806...0x10807 => true,
        0x10809 => true,
        0x10836 => true,
        0x10839...0x1083b => true,
        0x1083d...0x1083e => true,
        0x10856 => true,
        0x1089f...0x108a6 => true,
        0x108b0...0x108df => true,
        0x108f3 => true,
        0x108f6...0x108fa => true,
        0x1091c...0x1091e => true,
        0x1093a...0x1093e => true,
        0x10940...0x1097f => true,
        0x109b8...0x109bb => true,
        0x109d0...0x109d1 => true,
        0x10a04 => true,
        0x10a07...0x10a0b => true,
        0x10a14 => true,
        0x10a18 => true,
        0x10a36...0x10a37 => true,
        0x10a3b...0x10a3e => true,
        0x10a49...0x10a4f => true,
        0x10a59...0x10a5f => true,
        0x10aa0...0x10abf => true,
        0x10ae7...0x10aea => true,
        0x10af7...0x10aff => true,
        0x10b36...0x10b38 => true,
        0x10b56...0x10b57 => true,
        0x10b73...0x10b77 => true,
        0x10b92...0x10b98 => true,
        0x10b9d...0x10ba8 => true,
        0x10bb0...0x10bff => true,
        0x10c49...0x10c7f => true,
        0x10cb3...0x10cbf => true,
        0x10cf3...0x10cf9 => true,
        0x10d28...0x10d2f => true,
        0x10d3a...0x10e5f => true,
        0x10e7f => true,
        0x10eaa => true,
        0x10eae...0x10eaf => true,
        0x10eb2...0x10eff => true,
        0x10f28...0x10f2f => true,
        0x10f5a...0x10faf => true,
        0x10fcc...0x10fdf => true,
        0x10ff7...0x10fff => true,
        0x1104e...0x11051 => true,
        0x11070...0x1107e => true,
        0x110c2...0x110cc => true,
        0x110ce...0x110cf => true,
        0x110e9...0x110ef => true,
        0x110fa...0x110ff => true,
        0x11135 => true,
        0x11148...0x1114f => true,
        0x11177...0x1117f => true,
        0x111e0 => true,
        0x111f5...0x111ff => true,
        0x11212 => true,
        0x1123f...0x1127f => true,
        0x11287 => true,
        0x11289 => true,
        0x1128e => true,
        0x1129e => true,
        0x112aa...0x112af => true,
        0x112eb...0x112ef => true,
        0x112fa...0x112ff => true,
        0x11304 => true,
        0x1130d...0x1130e => true,
        0x11311...0x11312 => true,
        0x11329 => true,
        0x11331 => true,
        0x11334 => true,
        0x1133a => true,
        0x11345...0x11346 => true,
        0x11349...0x1134a => true,
        0x1134e...0x1134f => true,
        0x11351...0x11356 => true,
        0x11358...0x1135c => true,
        0x11364...0x11365 => true,
        0x1136d...0x1136f => true,
        0x11375...0x113ff => true,
        0x1145c => true,
        0x11462...0x1147f => true,
        0x114c8...0x114cf => true,
        0x114da...0x1157f => true,
        0x115b6...0x115b7 => true,
        0x115de...0x115ff => true,
        0x11645...0x1164f => true,
        0x1165a...0x1165f => true,
        0x1166d...0x1167f => true,
        0x116b9...0x116bf => true,
        0x116ca...0x116ff => true,
        0x1171b...0x1171c => true,
        0x1172c...0x1172f => true,
        0x11740...0x117ff => true,
        0x1183c...0x1189f => true,
        0x118f3...0x118fe => true,
        0x11907...0x11908 => true,
        0x1190a...0x1190b => true,
        0x11914 => true,
        0x11917 => true,
        0x11936 => true,
        0x11939...0x1193a => true,
        0x11947...0x1194f => true,
        0x1195a...0x1199f => true,
        0x119a8...0x119a9 => true,
        0x119d8...0x119d9 => true,
        0x119e5...0x119ff => true,
        0x11a48...0x11a4f => true,
        0x11aa3...0x11abf => true,
        0x11af9...0x11bff => true,
        0x11c09 => true,
        0x11c37 => true,
        0x11c46...0x11c4f => true,
        0x11c6d...0x11c6f => true,
        0x11c90...0x11c91 => true,
        0x11ca8 => true,
        0x11cb7...0x11cff => true,
        0x11d07 => true,
        0x11d0a => true,
        0x11d37...0x11d39 => true,
        0x11d3b => true,
        0x11d3e => true,
        0x11d48...0x11d4f => true,
        0x11d5a...0x11d5f => true,
        0x11d66 => true,
        0x11d69 => true,
        0x11d8f => true,
        0x11d92 => true,
        0x11d99...0x11d9f => true,
        0x11daa...0x11edf => true,
        0x11ef9...0x11faf => true,
        0x11fb1...0x11fbf => true,
        0x11ff2...0x11ffe => true,
        0x1239a...0x123ff => true,
        0x1246f => true,
        0x12475...0x1247f => true,
        0x12544...0x12fff => true,
        0x1342f => true,
        0x13439...0x143ff => true,
        0x14647...0x167ff => true,
        0x16a39...0x16a3f => true,
        0x16a5f => true,
        0x16a6a...0x16a6d => true,
        0x16a70...0x16acf => true,
        0x16aee...0x16aef => true,
        0x16af6...0x16aff => true,
        0x16b46...0x16b4f => true,
        0x16b5a => true,
        0x16b62 => true,
        0x16b78...0x16b7c => true,
        0x16b90...0x16e3f => true,
        0x16e9b...0x16eff => true,
        0x16f4b...0x16f4e => true,
        0x16f88...0x16f8e => true,
        0x16fa0...0x16fdf => true,
        0x16fe5...0x16fef => true,
        0x16ff2...0x16fff => true,
        0x187f8...0x187ff => true,
        0x18cd6...0x18cff => true,
        0x18d09...0x1afff => true,
        0x1b11f...0x1b14f => true,
        0x1b153...0x1b163 => true,
        0x1b168...0x1b16f => true,
        0x1b2fc...0x1bbff => true,
        0x1bc6b...0x1bc6f => true,
        0x1bc7d...0x1bc7f => true,
        0x1bc89...0x1bc8f => true,
        0x1bc9a...0x1bc9b => true,
        0x1bca4...0x1cfff => true,
        0x1d0f6...0x1d0ff => true,
        0x1d127...0x1d128 => true,
        0x1d1e9...0x1d1ff => true,
        0x1d246...0x1d2df => true,
        0x1d2f4...0x1d2ff => true,
        0x1d357...0x1d35f => true,
        0x1d379...0x1d3ff => true,
        0x1d455 => true,
        0x1d49d => true,
        0x1d4a0...0x1d4a1 => true,
        0x1d4a3...0x1d4a4 => true,
        0x1d4a7...0x1d4a8 => true,
        0x1d4ad => true,
        0x1d4ba => true,
        0x1d4bc => true,
        0x1d4c4 => true,
        0x1d506 => true,
        0x1d50b...0x1d50c => true,
        0x1d515 => true,
        0x1d51d => true,
        0x1d53a => true,
        0x1d53f => true,
        0x1d545 => true,
        0x1d547...0x1d549 => true,
        0x1d551 => true,
        0x1d6a6...0x1d6a7 => true,
        0x1d7cc...0x1d7cd => true,
        0x1da8c...0x1da9a => true,
        0x1daa0 => true,
        0x1dab0...0x1dfff => true,
        0x1e007 => true,
        0x1e019...0x1e01a => true,
        0x1e022 => true,
        0x1e025 => true,
        0x1e02b...0x1e0ff => true,
        0x1e12d...0x1e12f => true,
        0x1e13e...0x1e13f => true,
        0x1e14a...0x1e14d => true,
        0x1e150...0x1e2bf => true,
        0x1e2fa...0x1e2fe => true,
        0x1e300...0x1e7ff => true,
        0x1e8c5...0x1e8c6 => true,
        0x1e8d7...0x1e8ff => true,
        0x1e94c...0x1e94f => true,
        0x1e95a...0x1e95d => true,
        0x1e960...0x1ec70 => true,
        0x1ecb5...0x1ed00 => true,
        0x1ed3e...0x1edff => true,
        0x1ee04 => true,
        0x1ee20 => true,
        0x1ee23 => true,
        0x1ee25...0x1ee26 => true,
        0x1ee28 => true,
        0x1ee33 => true,
        0x1ee38 => true,
        0x1ee3a => true,
        0x1ee3c...0x1ee41 => true,
        0x1ee43...0x1ee46 => true,
        0x1ee48 => true,
        0x1ee4a => true,
        0x1ee4c => true,
        0x1ee50 => true,
        0x1ee53 => true,
        0x1ee55...0x1ee56 => true,
        0x1ee58 => true,
        0x1ee5a => true,
        0x1ee5c => true,
        0x1ee5e => true,
        0x1ee60 => true,
        0x1ee63 => true,
        0x1ee65...0x1ee66 => true,
        0x1ee6b => true,
        0x1ee73 => true,
        0x1ee78 => true,
        0x1ee7d => true,
        0x1ee7f => true,
        0x1ee8a => true,
        0x1ee9c...0x1eea0 => true,
        0x1eea4 => true,
        0x1eeaa => true,
        0x1eebc...0x1eeef => true,
        0x1eef2...0x1efff => true,
        0x1f02c...0x1f02f => true,
        0x1f094...0x1f09f => true,
        0x1f0af...0x1f0b0 => true,
        0x1f0c0 => true,
        0x1f0d0 => true,
        0x1f0f6...0x1f0ff => true,
        0x1f1ae...0x1f1e5 => true,
        0x1f203...0x1f20f => true,
        0x1f23c...0x1f23f => true,
        0x1f249...0x1f24f => true,
        0x1f252...0x1f25f => true,
        0x1f266...0x1f2ff => true,
        0x1f6d8...0x1f6df => true,
        0x1f6ed...0x1f6ef => true,
        0x1f6fd...0x1f6ff => true,
        0x1f774...0x1f77f => true,
        0x1f7d9...0x1f7df => true,
        0x1f7ec...0x1f7ff => true,
        0x1f80c...0x1f80f => true,
        0x1f848...0x1f84f => true,
        0x1f85a...0x1f85f => true,
        0x1f888...0x1f88f => true,
        0x1f8ae...0x1f8af => true,
        0x1f8b2...0x1f8ff => true,
        0x1f979 => true,
        0x1f9cc => true,
        0x1fa54...0x1fa5f => true,
        0x1fa6e...0x1fa6f => true,
        0x1fa75...0x1fa77 => true,
        0x1fa7b...0x1fa7f => true,
        0x1fa87...0x1fa8f => true,
        0x1faa9...0x1faaf => true,
        0x1fab7...0x1fabf => true,
        0x1fac3...0x1facf => true,
        0x1fad7...0x1faff => true,
        0x1fb93 => true,
        0x1fbcb...0x1fbef => true,
        0x1fbfa...0x1ffff => true,
        0x2a6de...0x2a6ff => true,
        0x2b735...0x2b73f => true,
        0x2b81e...0x2b81f => true,
        0x2cea2...0x2ceaf => true,
        0x2ebe1...0x2f7ff => true,
        0x2fa1e...0x2ffff => true,
        0x3134b...0xe0000 => true,
        0xe0002...0xe001f => true,
        0xe0080...0xe00ff => true,
        0xe01f0...0xeffff => true,
        0xffffe...0xfffff => true,
        0x10fffe...0x10ffff => true,
        else => false,
    };
}