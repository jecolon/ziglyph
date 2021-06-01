// Autogenerated from http://www.unicode.org/Public/UCD/latest/ucd/UCD.zip by running ucd_gen.sh.
// Placeholders:
//    0. Struct name
//    1. Lowest code point
//    2. Highest code point
//! Unicode IDContinue code points.

const lo: u21 = 0x30;
const hi: u21 = 0xe01ef;

pub fn isIDContinue(cp: u21) bool {
    if (cp < lo or cp > hi) return false;
    return switch (cp) {
        0x30...0x39 => true,
        0x41...0x5a => true,
        0x5f => true,
        0x61...0x7a => true,
        0xaa => true,
        0xb5 => true,
        0xb7 => true,
        0xba => true,
        0xc0...0xd6 => true,
        0xd8...0xf6 => true,
        0xf8...0x1ba => true,
        0x1bb => true,
        0x1bc...0x1bf => true,
        0x1c0...0x1c3 => true,
        0x1c4...0x293 => true,
        0x294 => true,
        0x295...0x2af => true,
        0x2b0...0x2c1 => true,
        0x2c6...0x2d1 => true,
        0x2e0...0x2e4 => true,
        0x2ec => true,
        0x2ee => true,
        0x300...0x36f => true,
        0x370...0x373 => true,
        0x374 => true,
        0x376...0x377 => true,
        0x37a => true,
        0x37b...0x37d => true,
        0x37f => true,
        0x386 => true,
        0x387 => true,
        0x388...0x38a => true,
        0x38c => true,
        0x38e...0x3a1 => true,
        0x3a3...0x3f5 => true,
        0x3f7...0x481 => true,
        0x483...0x487 => true,
        0x48a...0x52f => true,
        0x531...0x556 => true,
        0x559 => true,
        0x560...0x588 => true,
        0x591...0x5bd => true,
        0x5bf => true,
        0x5c1...0x5c2 => true,
        0x5c4...0x5c5 => true,
        0x5c7 => true,
        0x5d0...0x5ea => true,
        0x5ef...0x5f2 => true,
        0x610...0x61a => true,
        0x620...0x63f => true,
        0x640 => true,
        0x641...0x64a => true,
        0x64b...0x65f => true,
        0x660...0x669 => true,
        0x66e...0x66f => true,
        0x670 => true,
        0x671...0x6d3 => true,
        0x6d5 => true,
        0x6d6...0x6dc => true,
        0x6df...0x6e4 => true,
        0x6e5...0x6e6 => true,
        0x6e7...0x6e8 => true,
        0x6ea...0x6ed => true,
        0x6ee...0x6ef => true,
        0x6f0...0x6f9 => true,
        0x6fa...0x6fc => true,
        0x6ff => true,
        0x710 => true,
        0x711 => true,
        0x712...0x72f => true,
        0x730...0x74a => true,
        0x74d...0x7a5 => true,
        0x7a6...0x7b0 => true,
        0x7b1 => true,
        0x7c0...0x7c9 => true,
        0x7ca...0x7ea => true,
        0x7eb...0x7f3 => true,
        0x7f4...0x7f5 => true,
        0x7fa => true,
        0x7fd => true,
        0x800...0x815 => true,
        0x816...0x819 => true,
        0x81a => true,
        0x81b...0x823 => true,
        0x824 => true,
        0x825...0x827 => true,
        0x828 => true,
        0x829...0x82d => true,
        0x840...0x858 => true,
        0x859...0x85b => true,
        0x860...0x86a => true,
        0x8a0...0x8b4 => true,
        0x8b6...0x8c7 => true,
        0x8d3...0x8e1 => true,
        0x8e3...0x902 => true,
        0x903 => true,
        0x904...0x939 => true,
        0x93a => true,
        0x93b => true,
        0x93c => true,
        0x93d => true,
        0x93e...0x940 => true,
        0x941...0x948 => true,
        0x949...0x94c => true,
        0x94d => true,
        0x94e...0x94f => true,
        0x950 => true,
        0x951...0x957 => true,
        0x958...0x961 => true,
        0x962...0x963 => true,
        0x966...0x96f => true,
        0x971 => true,
        0x972...0x980 => true,
        0x981 => true,
        0x982...0x983 => true,
        0x985...0x98c => true,
        0x98f...0x990 => true,
        0x993...0x9a8 => true,
        0x9aa...0x9b0 => true,
        0x9b2 => true,
        0x9b6...0x9b9 => true,
        0x9bc => true,
        0x9bd => true,
        0x9be...0x9c0 => true,
        0x9c1...0x9c4 => true,
        0x9c7...0x9c8 => true,
        0x9cb...0x9cc => true,
        0x9cd => true,
        0x9ce => true,
        0x9d7 => true,
        0x9dc...0x9dd => true,
        0x9df...0x9e1 => true,
        0x9e2...0x9e3 => true,
        0x9e6...0x9ef => true,
        0x9f0...0x9f1 => true,
        0x9fc => true,
        0x9fe => true,
        0xa01...0xa02 => true,
        0xa03 => true,
        0xa05...0xa0a => true,
        0xa0f...0xa10 => true,
        0xa13...0xa28 => true,
        0xa2a...0xa30 => true,
        0xa32...0xa33 => true,
        0xa35...0xa36 => true,
        0xa38...0xa39 => true,
        0xa3c => true,
        0xa3e...0xa40 => true,
        0xa41...0xa42 => true,
        0xa47...0xa48 => true,
        0xa4b...0xa4d => true,
        0xa51 => true,
        0xa59...0xa5c => true,
        0xa5e => true,
        0xa66...0xa6f => true,
        0xa70...0xa71 => true,
        0xa72...0xa74 => true,
        0xa75 => true,
        0xa81...0xa82 => true,
        0xa83 => true,
        0xa85...0xa8d => true,
        0xa8f...0xa91 => true,
        0xa93...0xaa8 => true,
        0xaaa...0xab0 => true,
        0xab2...0xab3 => true,
        0xab5...0xab9 => true,
        0xabc => true,
        0xabd => true,
        0xabe...0xac0 => true,
        0xac1...0xac5 => true,
        0xac7...0xac8 => true,
        0xac9 => true,
        0xacb...0xacc => true,
        0xacd => true,
        0xad0 => true,
        0xae0...0xae1 => true,
        0xae2...0xae3 => true,
        0xae6...0xaef => true,
        0xaf9 => true,
        0xafa...0xaff => true,
        0xb01 => true,
        0xb02...0xb03 => true,
        0xb05...0xb0c => true,
        0xb0f...0xb10 => true,
        0xb13...0xb28 => true,
        0xb2a...0xb30 => true,
        0xb32...0xb33 => true,
        0xb35...0xb39 => true,
        0xb3c => true,
        0xb3d => true,
        0xb3e => true,
        0xb3f => true,
        0xb40 => true,
        0xb41...0xb44 => true,
        0xb47...0xb48 => true,
        0xb4b...0xb4c => true,
        0xb4d => true,
        0xb55...0xb56 => true,
        0xb57 => true,
        0xb5c...0xb5d => true,
        0xb5f...0xb61 => true,
        0xb62...0xb63 => true,
        0xb66...0xb6f => true,
        0xb71 => true,
        0xb82 => true,
        0xb83 => true,
        0xb85...0xb8a => true,
        0xb8e...0xb90 => true,
        0xb92...0xb95 => true,
        0xb99...0xb9a => true,
        0xb9c => true,
        0xb9e...0xb9f => true,
        0xba3...0xba4 => true,
        0xba8...0xbaa => true,
        0xbae...0xbb9 => true,
        0xbbe...0xbbf => true,
        0xbc0 => true,
        0xbc1...0xbc2 => true,
        0xbc6...0xbc8 => true,
        0xbca...0xbcc => true,
        0xbcd => true,
        0xbd0 => true,
        0xbd7 => true,
        0xbe6...0xbef => true,
        0xc00 => true,
        0xc01...0xc03 => true,
        0xc04 => true,
        0xc05...0xc0c => true,
        0xc0e...0xc10 => true,
        0xc12...0xc28 => true,
        0xc2a...0xc39 => true,
        0xc3d => true,
        0xc3e...0xc40 => true,
        0xc41...0xc44 => true,
        0xc46...0xc48 => true,
        0xc4a...0xc4d => true,
        0xc55...0xc56 => true,
        0xc58...0xc5a => true,
        0xc60...0xc61 => true,
        0xc62...0xc63 => true,
        0xc66...0xc6f => true,
        0xc80 => true,
        0xc81 => true,
        0xc82...0xc83 => true,
        0xc85...0xc8c => true,
        0xc8e...0xc90 => true,
        0xc92...0xca8 => true,
        0xcaa...0xcb3 => true,
        0xcb5...0xcb9 => true,
        0xcbc => true,
        0xcbd => true,
        0xcbe => true,
        0xcbf => true,
        0xcc0...0xcc4 => true,
        0xcc6 => true,
        0xcc7...0xcc8 => true,
        0xcca...0xccb => true,
        0xccc...0xccd => true,
        0xcd5...0xcd6 => true,
        0xcde => true,
        0xce0...0xce1 => true,
        0xce2...0xce3 => true,
        0xce6...0xcef => true,
        0xcf1...0xcf2 => true,
        0xd00...0xd01 => true,
        0xd02...0xd03 => true,
        0xd04...0xd0c => true,
        0xd0e...0xd10 => true,
        0xd12...0xd3a => true,
        0xd3b...0xd3c => true,
        0xd3d => true,
        0xd3e...0xd40 => true,
        0xd41...0xd44 => true,
        0xd46...0xd48 => true,
        0xd4a...0xd4c => true,
        0xd4d => true,
        0xd4e => true,
        0xd54...0xd56 => true,
        0xd57 => true,
        0xd5f...0xd61 => true,
        0xd62...0xd63 => true,
        0xd66...0xd6f => true,
        0xd7a...0xd7f => true,
        0xd81 => true,
        0xd82...0xd83 => true,
        0xd85...0xd96 => true,
        0xd9a...0xdb1 => true,
        0xdb3...0xdbb => true,
        0xdbd => true,
        0xdc0...0xdc6 => true,
        0xdca => true,
        0xdcf...0xdd1 => true,
        0xdd2...0xdd4 => true,
        0xdd6 => true,
        0xdd8...0xddf => true,
        0xde6...0xdef => true,
        0xdf2...0xdf3 => true,
        0xe01...0xe30 => true,
        0xe31 => true,
        0xe32...0xe33 => true,
        0xe34...0xe3a => true,
        0xe40...0xe45 => true,
        0xe46 => true,
        0xe47...0xe4e => true,
        0xe50...0xe59 => true,
        0xe81...0xe82 => true,
        0xe84 => true,
        0xe86...0xe8a => true,
        0xe8c...0xea3 => true,
        0xea5 => true,
        0xea7...0xeb0 => true,
        0xeb1 => true,
        0xeb2...0xeb3 => true,
        0xeb4...0xebc => true,
        0xebd => true,
        0xec0...0xec4 => true,
        0xec6 => true,
        0xec8...0xecd => true,
        0xed0...0xed9 => true,
        0xedc...0xedf => true,
        0xf00 => true,
        0xf18...0xf19 => true,
        0xf20...0xf29 => true,
        0xf35 => true,
        0xf37 => true,
        0xf39 => true,
        0xf3e...0xf3f => true,
        0xf40...0xf47 => true,
        0xf49...0xf6c => true,
        0xf71...0xf7e => true,
        0xf7f => true,
        0xf80...0xf84 => true,
        0xf86...0xf87 => true,
        0xf88...0xf8c => true,
        0xf8d...0xf97 => true,
        0xf99...0xfbc => true,
        0xfc6 => true,
        0x1000...0x102a => true,
        0x102b...0x102c => true,
        0x102d...0x1030 => true,
        0x1031 => true,
        0x1032...0x1037 => true,
        0x1038 => true,
        0x1039...0x103a => true,
        0x103b...0x103c => true,
        0x103d...0x103e => true,
        0x103f => true,
        0x1040...0x1049 => true,
        0x1050...0x1055 => true,
        0x1056...0x1057 => true,
        0x1058...0x1059 => true,
        0x105a...0x105d => true,
        0x105e...0x1060 => true,
        0x1061 => true,
        0x1062...0x1064 => true,
        0x1065...0x1066 => true,
        0x1067...0x106d => true,
        0x106e...0x1070 => true,
        0x1071...0x1074 => true,
        0x1075...0x1081 => true,
        0x1082 => true,
        0x1083...0x1084 => true,
        0x1085...0x1086 => true,
        0x1087...0x108c => true,
        0x108d => true,
        0x108e => true,
        0x108f => true,
        0x1090...0x1099 => true,
        0x109a...0x109c => true,
        0x109d => true,
        0x10a0...0x10c5 => true,
        0x10c7 => true,
        0x10cd => true,
        0x10d0...0x10fa => true,
        0x10fc => true,
        0x10fd...0x10ff => true,
        0x1100...0x1248 => true,
        0x124a...0x124d => true,
        0x1250...0x1256 => true,
        0x1258 => true,
        0x125a...0x125d => true,
        0x1260...0x1288 => true,
        0x128a...0x128d => true,
        0x1290...0x12b0 => true,
        0x12b2...0x12b5 => true,
        0x12b8...0x12be => true,
        0x12c0 => true,
        0x12c2...0x12c5 => true,
        0x12c8...0x12d6 => true,
        0x12d8...0x1310 => true,
        0x1312...0x1315 => true,
        0x1318...0x135a => true,
        0x135d...0x135f => true,
        0x1369...0x1371 => true,
        0x1380...0x138f => true,
        0x13a0...0x13f5 => true,
        0x13f8...0x13fd => true,
        0x1401...0x166c => true,
        0x166f...0x167f => true,
        0x1681...0x169a => true,
        0x16a0...0x16ea => true,
        0x16ee...0x16f0 => true,
        0x16f1...0x16f8 => true,
        0x1700...0x170c => true,
        0x170e...0x1711 => true,
        0x1712...0x1714 => true,
        0x1720...0x1731 => true,
        0x1732...0x1734 => true,
        0x1740...0x1751 => true,
        0x1752...0x1753 => true,
        0x1760...0x176c => true,
        0x176e...0x1770 => true,
        0x1772...0x1773 => true,
        0x1780...0x17b3 => true,
        0x17b4...0x17b5 => true,
        0x17b6 => true,
        0x17b7...0x17bd => true,
        0x17be...0x17c5 => true,
        0x17c6 => true,
        0x17c7...0x17c8 => true,
        0x17c9...0x17d3 => true,
        0x17d7 => true,
        0x17dc => true,
        0x17dd => true,
        0x17e0...0x17e9 => true,
        0x180b...0x180d => true,
        0x1810...0x1819 => true,
        0x1820...0x1842 => true,
        0x1843 => true,
        0x1844...0x1878 => true,
        0x1880...0x1884 => true,
        0x1885...0x1886 => true,
        0x1887...0x18a8 => true,
        0x18a9 => true,
        0x18aa => true,
        0x18b0...0x18f5 => true,
        0x1900...0x191e => true,
        0x1920...0x1922 => true,
        0x1923...0x1926 => true,
        0x1927...0x1928 => true,
        0x1929...0x192b => true,
        0x1930...0x1931 => true,
        0x1932 => true,
        0x1933...0x1938 => true,
        0x1939...0x193b => true,
        0x1946...0x194f => true,
        0x1950...0x196d => true,
        0x1970...0x1974 => true,
        0x1980...0x19ab => true,
        0x19b0...0x19c9 => true,
        0x19d0...0x19d9 => true,
        0x19da => true,
        0x1a00...0x1a16 => true,
        0x1a17...0x1a18 => true,
        0x1a19...0x1a1a => true,
        0x1a1b => true,
        0x1a20...0x1a54 => true,
        0x1a55 => true,
        0x1a56 => true,
        0x1a57 => true,
        0x1a58...0x1a5e => true,
        0x1a60 => true,
        0x1a61 => true,
        0x1a62 => true,
        0x1a63...0x1a64 => true,
        0x1a65...0x1a6c => true,
        0x1a6d...0x1a72 => true,
        0x1a73...0x1a7c => true,
        0x1a7f => true,
        0x1a80...0x1a89 => true,
        0x1a90...0x1a99 => true,
        0x1aa7 => true,
        0x1ab0...0x1abd => true,
        0x1abf...0x1ac0 => true,
        0x1b00...0x1b03 => true,
        0x1b04 => true,
        0x1b05...0x1b33 => true,
        0x1b34 => true,
        0x1b35 => true,
        0x1b36...0x1b3a => true,
        0x1b3b => true,
        0x1b3c => true,
        0x1b3d...0x1b41 => true,
        0x1b42 => true,
        0x1b43...0x1b44 => true,
        0x1b45...0x1b4b => true,
        0x1b50...0x1b59 => true,
        0x1b6b...0x1b73 => true,
        0x1b80...0x1b81 => true,
        0x1b82 => true,
        0x1b83...0x1ba0 => true,
        0x1ba1 => true,
        0x1ba2...0x1ba5 => true,
        0x1ba6...0x1ba7 => true,
        0x1ba8...0x1ba9 => true,
        0x1baa => true,
        0x1bab...0x1bad => true,
        0x1bae...0x1baf => true,
        0x1bb0...0x1bb9 => true,
        0x1bba...0x1be5 => true,
        0x1be6 => true,
        0x1be7 => true,
        0x1be8...0x1be9 => true,
        0x1bea...0x1bec => true,
        0x1bed => true,
        0x1bee => true,
        0x1bef...0x1bf1 => true,
        0x1bf2...0x1bf3 => true,
        0x1c00...0x1c23 => true,
        0x1c24...0x1c2b => true,
        0x1c2c...0x1c33 => true,
        0x1c34...0x1c35 => true,
        0x1c36...0x1c37 => true,
        0x1c40...0x1c49 => true,
        0x1c4d...0x1c4f => true,
        0x1c50...0x1c59 => true,
        0x1c5a...0x1c77 => true,
        0x1c78...0x1c7d => true,
        0x1c80...0x1c88 => true,
        0x1c90...0x1cba => true,
        0x1cbd...0x1cbf => true,
        0x1cd0...0x1cd2 => true,
        0x1cd4...0x1ce0 => true,
        0x1ce1 => true,
        0x1ce2...0x1ce8 => true,
        0x1ce9...0x1cec => true,
        0x1ced => true,
        0x1cee...0x1cf3 => true,
        0x1cf4 => true,
        0x1cf5...0x1cf6 => true,
        0x1cf7 => true,
        0x1cf8...0x1cf9 => true,
        0x1cfa => true,
        0x1d00...0x1d2b => true,
        0x1d2c...0x1d6a => true,
        0x1d6b...0x1d77 => true,
        0x1d78 => true,
        0x1d79...0x1d9a => true,
        0x1d9b...0x1dbf => true,
        0x1dc0...0x1df9 => true,
        0x1dfb...0x1dff => true,
        0x1e00...0x1f15 => true,
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
        0x203f...0x2040 => true,
        0x2054 => true,
        0x2071 => true,
        0x207f => true,
        0x2090...0x209c => true,
        0x20d0...0x20dc => true,
        0x20e1 => true,
        0x20e5...0x20f0 => true,
        0x2102 => true,
        0x2107 => true,
        0x210a...0x2113 => true,
        0x2115 => true,
        0x2118 => true,
        0x2119...0x211d => true,
        0x2124 => true,
        0x2126 => true,
        0x2128 => true,
        0x212a...0x212d => true,
        0x212e => true,
        0x212f...0x2134 => true,
        0x2135...0x2138 => true,
        0x2139 => true,
        0x213c...0x213f => true,
        0x2145...0x2149 => true,
        0x214e => true,
        0x2160...0x2182 => true,
        0x2183...0x2184 => true,
        0x2185...0x2188 => true,
        0x2c00...0x2c2e => true,
        0x2c30...0x2c5e => true,
        0x2c60...0x2c7b => true,
        0x2c7c...0x2c7d => true,
        0x2c7e...0x2ce4 => true,
        0x2ceb...0x2cee => true,
        0x2cef...0x2cf1 => true,
        0x2cf2...0x2cf3 => true,
        0x2d00...0x2d25 => true,
        0x2d27 => true,
        0x2d2d => true,
        0x2d30...0x2d67 => true,
        0x2d6f => true,
        0x2d7f => true,
        0x2d80...0x2d96 => true,
        0x2da0...0x2da6 => true,
        0x2da8...0x2dae => true,
        0x2db0...0x2db6 => true,
        0x2db8...0x2dbe => true,
        0x2dc0...0x2dc6 => true,
        0x2dc8...0x2dce => true,
        0x2dd0...0x2dd6 => true,
        0x2dd8...0x2dde => true,
        0x2de0...0x2dff => true,
        0x3005 => true,
        0x3006 => true,
        0x3007 => true,
        0x3021...0x3029 => true,
        0x302a...0x302d => true,
        0x302e...0x302f => true,
        0x3031...0x3035 => true,
        0x3038...0x303a => true,
        0x303b => true,
        0x303c => true,
        0x3041...0x3096 => true,
        0x3099...0x309a => true,
        0x309b...0x309c => true,
        0x309d...0x309e => true,
        0x309f => true,
        0x30a1...0x30fa => true,
        0x30fc...0x30fe => true,
        0x30ff => true,
        0x3105...0x312f => true,
        0x3131...0x318e => true,
        0x31a0...0x31bf => true,
        0x31f0...0x31ff => true,
        0x3400...0x4dbf => true,
        0x4e00...0x9ffc => true,
        0xa000...0xa014 => true,
        0xa015 => true,
        0xa016...0xa48c => true,
        0xa4d0...0xa4f7 => true,
        0xa4f8...0xa4fd => true,
        0xa500...0xa60b => true,
        0xa60c => true,
        0xa610...0xa61f => true,
        0xa620...0xa629 => true,
        0xa62a...0xa62b => true,
        0xa640...0xa66d => true,
        0xa66e => true,
        0xa66f => true,
        0xa674...0xa67d => true,
        0xa67f => true,
        0xa680...0xa69b => true,
        0xa69c...0xa69d => true,
        0xa69e...0xa69f => true,
        0xa6a0...0xa6e5 => true,
        0xa6e6...0xa6ef => true,
        0xa6f0...0xa6f1 => true,
        0xa717...0xa71f => true,
        0xa722...0xa76f => true,
        0xa770 => true,
        0xa771...0xa787 => true,
        0xa788 => true,
        0xa78b...0xa78e => true,
        0xa78f => true,
        0xa790...0xa7bf => true,
        0xa7c2...0xa7ca => true,
        0xa7f5...0xa7f6 => true,
        0xa7f7 => true,
        0xa7f8...0xa7f9 => true,
        0xa7fa => true,
        0xa7fb...0xa801 => true,
        0xa802 => true,
        0xa803...0xa805 => true,
        0xa806 => true,
        0xa807...0xa80a => true,
        0xa80b => true,
        0xa80c...0xa822 => true,
        0xa823...0xa824 => true,
        0xa825...0xa826 => true,
        0xa827 => true,
        0xa82c => true,
        0xa840...0xa873 => true,
        0xa880...0xa881 => true,
        0xa882...0xa8b3 => true,
        0xa8b4...0xa8c3 => true,
        0xa8c4...0xa8c5 => true,
        0xa8d0...0xa8d9 => true,
        0xa8e0...0xa8f1 => true,
        0xa8f2...0xa8f7 => true,
        0xa8fb => true,
        0xa8fd...0xa8fe => true,
        0xa8ff => true,
        0xa900...0xa909 => true,
        0xa90a...0xa925 => true,
        0xa926...0xa92d => true,
        0xa930...0xa946 => true,
        0xa947...0xa951 => true,
        0xa952...0xa953 => true,
        0xa960...0xa97c => true,
        0xa980...0xa982 => true,
        0xa983 => true,
        0xa984...0xa9b2 => true,
        0xa9b3 => true,
        0xa9b4...0xa9b5 => true,
        0xa9b6...0xa9b9 => true,
        0xa9ba...0xa9bb => true,
        0xa9bc...0xa9bd => true,
        0xa9be...0xa9c0 => true,
        0xa9cf => true,
        0xa9d0...0xa9d9 => true,
        0xa9e0...0xa9e4 => true,
        0xa9e5 => true,
        0xa9e6 => true,
        0xa9e7...0xa9ef => true,
        0xa9f0...0xa9f9 => true,
        0xa9fa...0xa9fe => true,
        0xaa00...0xaa28 => true,
        0xaa29...0xaa2e => true,
        0xaa2f...0xaa30 => true,
        0xaa31...0xaa32 => true,
        0xaa33...0xaa34 => true,
        0xaa35...0xaa36 => true,
        0xaa40...0xaa42 => true,
        0xaa43 => true,
        0xaa44...0xaa4b => true,
        0xaa4c => true,
        0xaa4d => true,
        0xaa50...0xaa59 => true,
        0xaa60...0xaa6f => true,
        0xaa70 => true,
        0xaa71...0xaa76 => true,
        0xaa7a => true,
        0xaa7b => true,
        0xaa7c => true,
        0xaa7d => true,
        0xaa7e...0xaaaf => true,
        0xaab0 => true,
        0xaab1 => true,
        0xaab2...0xaab4 => true,
        0xaab5...0xaab6 => true,
        0xaab7...0xaab8 => true,
        0xaab9...0xaabd => true,
        0xaabe...0xaabf => true,
        0xaac0 => true,
        0xaac1 => true,
        0xaac2 => true,
        0xaadb...0xaadc => true,
        0xaadd => true,
        0xaae0...0xaaea => true,
        0xaaeb => true,
        0xaaec...0xaaed => true,
        0xaaee...0xaaef => true,
        0xaaf2 => true,
        0xaaf3...0xaaf4 => true,
        0xaaf5 => true,
        0xaaf6 => true,
        0xab01...0xab06 => true,
        0xab09...0xab0e => true,
        0xab11...0xab16 => true,
        0xab20...0xab26 => true,
        0xab28...0xab2e => true,
        0xab30...0xab5a => true,
        0xab5c...0xab5f => true,
        0xab60...0xab68 => true,
        0xab69 => true,
        0xab70...0xabbf => true,
        0xabc0...0xabe2 => true,
        0xabe3...0xabe4 => true,
        0xabe5 => true,
        0xabe6...0xabe7 => true,
        0xabe8 => true,
        0xabe9...0xabea => true,
        0xabec => true,
        0xabed => true,
        0xabf0...0xabf9 => true,
        0xac00...0xd7a3 => true,
        0xd7b0...0xd7c6 => true,
        0xd7cb...0xd7fb => true,
        0xf900...0xfa6d => true,
        0xfa70...0xfad9 => true,
        0xfb00...0xfb06 => true,
        0xfb13...0xfb17 => true,
        0xfb1d => true,
        0xfb1e => true,
        0xfb1f...0xfb28 => true,
        0xfb2a...0xfb36 => true,
        0xfb38...0xfb3c => true,
        0xfb3e => true,
        0xfb40...0xfb41 => true,
        0xfb43...0xfb44 => true,
        0xfb46...0xfbb1 => true,
        0xfbd3...0xfd3d => true,
        0xfd50...0xfd8f => true,
        0xfd92...0xfdc7 => true,
        0xfdf0...0xfdfb => true,
        0xfe00...0xfe0f => true,
        0xfe20...0xfe2f => true,
        0xfe33...0xfe34 => true,
        0xfe4d...0xfe4f => true,
        0xfe70...0xfe74 => true,
        0xfe76...0xfefc => true,
        0xff10...0xff19 => true,
        0xff21...0xff3a => true,
        0xff3f => true,
        0xff41...0xff5a => true,
        0xff66...0xff6f => true,
        0xff70 => true,
        0xff71...0xff9d => true,
        0xff9e...0xff9f => true,
        0xffa0...0xffbe => true,
        0xffc2...0xffc7 => true,
        0xffca...0xffcf => true,
        0xffd2...0xffd7 => true,
        0xffda...0xffdc => true,
        0x10000...0x1000b => true,
        0x1000d...0x10026 => true,
        0x10028...0x1003a => true,
        0x1003c...0x1003d => true,
        0x1003f...0x1004d => true,
        0x10050...0x1005d => true,
        0x10080...0x100fa => true,
        0x10140...0x10174 => true,
        0x101fd => true,
        0x10280...0x1029c => true,
        0x102a0...0x102d0 => true,
        0x102e0 => true,
        0x10300...0x1031f => true,
        0x1032d...0x10340 => true,
        0x10341 => true,
        0x10342...0x10349 => true,
        0x1034a => true,
        0x10350...0x10375 => true,
        0x10376...0x1037a => true,
        0x10380...0x1039d => true,
        0x103a0...0x103c3 => true,
        0x103c8...0x103cf => true,
        0x103d1...0x103d5 => true,
        0x10400...0x1044f => true,
        0x10450...0x1049d => true,
        0x104a0...0x104a9 => true,
        0x104b0...0x104d3 => true,
        0x104d8...0x104fb => true,
        0x10500...0x10527 => true,
        0x10530...0x10563 => true,
        0x10600...0x10736 => true,
        0x10740...0x10755 => true,
        0x10760...0x10767 => true,
        0x10800...0x10805 => true,
        0x10808 => true,
        0x1080a...0x10835 => true,
        0x10837...0x10838 => true,
        0x1083c => true,
        0x1083f...0x10855 => true,
        0x10860...0x10876 => true,
        0x10880...0x1089e => true,
        0x108e0...0x108f2 => true,
        0x108f4...0x108f5 => true,
        0x10900...0x10915 => true,
        0x10920...0x10939 => true,
        0x10980...0x109b7 => true,
        0x109be...0x109bf => true,
        0x10a00 => true,
        0x10a01...0x10a03 => true,
        0x10a05...0x10a06 => true,
        0x10a0c...0x10a0f => true,
        0x10a10...0x10a13 => true,
        0x10a15...0x10a17 => true,
        0x10a19...0x10a35 => true,
        0x10a38...0x10a3a => true,
        0x10a3f => true,
        0x10a60...0x10a7c => true,
        0x10a80...0x10a9c => true,
        0x10ac0...0x10ac7 => true,
        0x10ac9...0x10ae4 => true,
        0x10ae5...0x10ae6 => true,
        0x10b00...0x10b35 => true,
        0x10b40...0x10b55 => true,
        0x10b60...0x10b72 => true,
        0x10b80...0x10b91 => true,
        0x10c00...0x10c48 => true,
        0x10c80...0x10cb2 => true,
        0x10cc0...0x10cf2 => true,
        0x10d00...0x10d23 => true,
        0x10d24...0x10d27 => true,
        0x10d30...0x10d39 => true,
        0x10e80...0x10ea9 => true,
        0x10eab...0x10eac => true,
        0x10eb0...0x10eb1 => true,
        0x10f00...0x10f1c => true,
        0x10f27 => true,
        0x10f30...0x10f45 => true,
        0x10f46...0x10f50 => true,
        0x10fb0...0x10fc4 => true,
        0x10fe0...0x10ff6 => true,
        0x11000 => true,
        0x11001 => true,
        0x11002 => true,
        0x11003...0x11037 => true,
        0x11038...0x11046 => true,
        0x11066...0x1106f => true,
        0x1107f...0x11081 => true,
        0x11082 => true,
        0x11083...0x110af => true,
        0x110b0...0x110b2 => true,
        0x110b3...0x110b6 => true,
        0x110b7...0x110b8 => true,
        0x110b9...0x110ba => true,
        0x110d0...0x110e8 => true,
        0x110f0...0x110f9 => true,
        0x11100...0x11102 => true,
        0x11103...0x11126 => true,
        0x11127...0x1112b => true,
        0x1112c => true,
        0x1112d...0x11134 => true,
        0x11136...0x1113f => true,
        0x11144 => true,
        0x11145...0x11146 => true,
        0x11147 => true,
        0x11150...0x11172 => true,
        0x11173 => true,
        0x11176 => true,
        0x11180...0x11181 => true,
        0x11182 => true,
        0x11183...0x111b2 => true,
        0x111b3...0x111b5 => true,
        0x111b6...0x111be => true,
        0x111bf...0x111c0 => true,
        0x111c1...0x111c4 => true,
        0x111c9...0x111cc => true,
        0x111ce => true,
        0x111cf => true,
        0x111d0...0x111d9 => true,
        0x111da => true,
        0x111dc => true,
        0x11200...0x11211 => true,
        0x11213...0x1122b => true,
        0x1122c...0x1122e => true,
        0x1122f...0x11231 => true,
        0x11232...0x11233 => true,
        0x11234 => true,
        0x11235 => true,
        0x11236...0x11237 => true,
        0x1123e => true,
        0x11280...0x11286 => true,
        0x11288 => true,
        0x1128a...0x1128d => true,
        0x1128f...0x1129d => true,
        0x1129f...0x112a8 => true,
        0x112b0...0x112de => true,
        0x112df => true,
        0x112e0...0x112e2 => true,
        0x112e3...0x112ea => true,
        0x112f0...0x112f9 => true,
        0x11300...0x11301 => true,
        0x11302...0x11303 => true,
        0x11305...0x1130c => true,
        0x1130f...0x11310 => true,
        0x11313...0x11328 => true,
        0x1132a...0x11330 => true,
        0x11332...0x11333 => true,
        0x11335...0x11339 => true,
        0x1133b...0x1133c => true,
        0x1133d => true,
        0x1133e...0x1133f => true,
        0x11340 => true,
        0x11341...0x11344 => true,
        0x11347...0x11348 => true,
        0x1134b...0x1134d => true,
        0x11350 => true,
        0x11357 => true,
        0x1135d...0x11361 => true,
        0x11362...0x11363 => true,
        0x11366...0x1136c => true,
        0x11370...0x11374 => true,
        0x11400...0x11434 => true,
        0x11435...0x11437 => true,
        0x11438...0x1143f => true,
        0x11440...0x11441 => true,
        0x11442...0x11444 => true,
        0x11445 => true,
        0x11446 => true,
        0x11447...0x1144a => true,
        0x11450...0x11459 => true,
        0x1145e => true,
        0x1145f...0x11461 => true,
        0x11480...0x114af => true,
        0x114b0...0x114b2 => true,
        0x114b3...0x114b8 => true,
        0x114b9 => true,
        0x114ba => true,
        0x114bb...0x114be => true,
        0x114bf...0x114c0 => true,
        0x114c1 => true,
        0x114c2...0x114c3 => true,
        0x114c4...0x114c5 => true,
        0x114c7 => true,
        0x114d0...0x114d9 => true,
        0x11580...0x115ae => true,
        0x115af...0x115b1 => true,
        0x115b2...0x115b5 => true,
        0x115b8...0x115bb => true,
        0x115bc...0x115bd => true,
        0x115be => true,
        0x115bf...0x115c0 => true,
        0x115d8...0x115db => true,
        0x115dc...0x115dd => true,
        0x11600...0x1162f => true,
        0x11630...0x11632 => true,
        0x11633...0x1163a => true,
        0x1163b...0x1163c => true,
        0x1163d => true,
        0x1163e => true,
        0x1163f...0x11640 => true,
        0x11644 => true,
        0x11650...0x11659 => true,
        0x11680...0x116aa => true,
        0x116ab => true,
        0x116ac => true,
        0x116ad => true,
        0x116ae...0x116af => true,
        0x116b0...0x116b5 => true,
        0x116b6 => true,
        0x116b7 => true,
        0x116b8 => true,
        0x116c0...0x116c9 => true,
        0x11700...0x1171a => true,
        0x1171d...0x1171f => true,
        0x11720...0x11721 => true,
        0x11722...0x11725 => true,
        0x11726 => true,
        0x11727...0x1172b => true,
        0x11730...0x11739 => true,
        0x11800...0x1182b => true,
        0x1182c...0x1182e => true,
        0x1182f...0x11837 => true,
        0x11838 => true,
        0x11839...0x1183a => true,
        0x118a0...0x118df => true,
        0x118e0...0x118e9 => true,
        0x118ff...0x11906 => true,
        0x11909 => true,
        0x1190c...0x11913 => true,
        0x11915...0x11916 => true,
        0x11918...0x1192f => true,
        0x11930...0x11935 => true,
        0x11937...0x11938 => true,
        0x1193b...0x1193c => true,
        0x1193d => true,
        0x1193e => true,
        0x1193f => true,
        0x11940 => true,
        0x11941 => true,
        0x11942 => true,
        0x11943 => true,
        0x11950...0x11959 => true,
        0x119a0...0x119a7 => true,
        0x119aa...0x119d0 => true,
        0x119d1...0x119d3 => true,
        0x119d4...0x119d7 => true,
        0x119da...0x119db => true,
        0x119dc...0x119df => true,
        0x119e0 => true,
        0x119e1 => true,
        0x119e3 => true,
        0x119e4 => true,
        0x11a00 => true,
        0x11a01...0x11a0a => true,
        0x11a0b...0x11a32 => true,
        0x11a33...0x11a38 => true,
        0x11a39 => true,
        0x11a3a => true,
        0x11a3b...0x11a3e => true,
        0x11a47 => true,
        0x11a50 => true,
        0x11a51...0x11a56 => true,
        0x11a57...0x11a58 => true,
        0x11a59...0x11a5b => true,
        0x11a5c...0x11a89 => true,
        0x11a8a...0x11a96 => true,
        0x11a97 => true,
        0x11a98...0x11a99 => true,
        0x11a9d => true,
        0x11ac0...0x11af8 => true,
        0x11c00...0x11c08 => true,
        0x11c0a...0x11c2e => true,
        0x11c2f => true,
        0x11c30...0x11c36 => true,
        0x11c38...0x11c3d => true,
        0x11c3e => true,
        0x11c3f => true,
        0x11c40 => true,
        0x11c50...0x11c59 => true,
        0x11c72...0x11c8f => true,
        0x11c92...0x11ca7 => true,
        0x11ca9 => true,
        0x11caa...0x11cb0 => true,
        0x11cb1 => true,
        0x11cb2...0x11cb3 => true,
        0x11cb4 => true,
        0x11cb5...0x11cb6 => true,
        0x11d00...0x11d06 => true,
        0x11d08...0x11d09 => true,
        0x11d0b...0x11d30 => true,
        0x11d31...0x11d36 => true,
        0x11d3a => true,
        0x11d3c...0x11d3d => true,
        0x11d3f...0x11d45 => true,
        0x11d46 => true,
        0x11d47 => true,
        0x11d50...0x11d59 => true,
        0x11d60...0x11d65 => true,
        0x11d67...0x11d68 => true,
        0x11d6a...0x11d89 => true,
        0x11d8a...0x11d8e => true,
        0x11d90...0x11d91 => true,
        0x11d93...0x11d94 => true,
        0x11d95 => true,
        0x11d96 => true,
        0x11d97 => true,
        0x11d98 => true,
        0x11da0...0x11da9 => true,
        0x11ee0...0x11ef2 => true,
        0x11ef3...0x11ef4 => true,
        0x11ef5...0x11ef6 => true,
        0x11fb0 => true,
        0x12000...0x12399 => true,
        0x12400...0x1246e => true,
        0x12480...0x12543 => true,
        0x13000...0x1342e => true,
        0x14400...0x14646 => true,
        0x16800...0x16a38 => true,
        0x16a40...0x16a5e => true,
        0x16a60...0x16a69 => true,
        0x16ad0...0x16aed => true,
        0x16af0...0x16af4 => true,
        0x16b00...0x16b2f => true,
        0x16b30...0x16b36 => true,
        0x16b40...0x16b43 => true,
        0x16b50...0x16b59 => true,
        0x16b63...0x16b77 => true,
        0x16b7d...0x16b8f => true,
        0x16e40...0x16e7f => true,
        0x16f00...0x16f4a => true,
        0x16f4f => true,
        0x16f50 => true,
        0x16f51...0x16f87 => true,
        0x16f8f...0x16f92 => true,
        0x16f93...0x16f9f => true,
        0x16fe0...0x16fe1 => true,
        0x16fe3 => true,
        0x16fe4 => true,
        0x16ff0...0x16ff1 => true,
        0x17000...0x187f7 => true,
        0x18800...0x18cd5 => true,
        0x18d00...0x18d08 => true,
        0x1b000...0x1b11e => true,
        0x1b150...0x1b152 => true,
        0x1b164...0x1b167 => true,
        0x1b170...0x1b2fb => true,
        0x1bc00...0x1bc6a => true,
        0x1bc70...0x1bc7c => true,
        0x1bc80...0x1bc88 => true,
        0x1bc90...0x1bc99 => true,
        0x1bc9d...0x1bc9e => true,
        0x1d165...0x1d166 => true,
        0x1d167...0x1d169 => true,
        0x1d16d...0x1d172 => true,
        0x1d17b...0x1d182 => true,
        0x1d185...0x1d18b => true,
        0x1d1aa...0x1d1ad => true,
        0x1d242...0x1d244 => true,
        0x1d400...0x1d454 => true,
        0x1d456...0x1d49c => true,
        0x1d49e...0x1d49f => true,
        0x1d4a2 => true,
        0x1d4a5...0x1d4a6 => true,
        0x1d4a9...0x1d4ac => true,
        0x1d4ae...0x1d4b9 => true,
        0x1d4bb => true,
        0x1d4bd...0x1d4c3 => true,
        0x1d4c5...0x1d505 => true,
        0x1d507...0x1d50a => true,
        0x1d50d...0x1d514 => true,
        0x1d516...0x1d51c => true,
        0x1d51e...0x1d539 => true,
        0x1d53b...0x1d53e => true,
        0x1d540...0x1d544 => true,
        0x1d546 => true,
        0x1d54a...0x1d550 => true,
        0x1d552...0x1d6a5 => true,
        0x1d6a8...0x1d6c0 => true,
        0x1d6c2...0x1d6da => true,
        0x1d6dc...0x1d6fa => true,
        0x1d6fc...0x1d714 => true,
        0x1d716...0x1d734 => true,
        0x1d736...0x1d74e => true,
        0x1d750...0x1d76e => true,
        0x1d770...0x1d788 => true,
        0x1d78a...0x1d7a8 => true,
        0x1d7aa...0x1d7c2 => true,
        0x1d7c4...0x1d7cb => true,
        0x1d7ce...0x1d7ff => true,
        0x1da00...0x1da36 => true,
        0x1da3b...0x1da6c => true,
        0x1da75 => true,
        0x1da84 => true,
        0x1da9b...0x1da9f => true,
        0x1daa1...0x1daaf => true,
        0x1e000...0x1e006 => true,
        0x1e008...0x1e018 => true,
        0x1e01b...0x1e021 => true,
        0x1e023...0x1e024 => true,
        0x1e026...0x1e02a => true,
        0x1e100...0x1e12c => true,
        0x1e130...0x1e136 => true,
        0x1e137...0x1e13d => true,
        0x1e140...0x1e149 => true,
        0x1e14e => true,
        0x1e2c0...0x1e2eb => true,
        0x1e2ec...0x1e2ef => true,
        0x1e2f0...0x1e2f9 => true,
        0x1e800...0x1e8c4 => true,
        0x1e8d0...0x1e8d6 => true,
        0x1e900...0x1e943 => true,
        0x1e944...0x1e94a => true,
        0x1e94b => true,
        0x1e950...0x1e959 => true,
        0x1ee00...0x1ee03 => true,
        0x1ee05...0x1ee1f => true,
        0x1ee21...0x1ee22 => true,
        0x1ee24 => true,
        0x1ee27 => true,
        0x1ee29...0x1ee32 => true,
        0x1ee34...0x1ee37 => true,
        0x1ee39 => true,
        0x1ee3b => true,
        0x1ee42 => true,
        0x1ee47 => true,
        0x1ee49 => true,
        0x1ee4b => true,
        0x1ee4d...0x1ee4f => true,
        0x1ee51...0x1ee52 => true,
        0x1ee54 => true,
        0x1ee57 => true,
        0x1ee59 => true,
        0x1ee5b => true,
        0x1ee5d => true,
        0x1ee5f => true,
        0x1ee61...0x1ee62 => true,
        0x1ee64 => true,
        0x1ee67...0x1ee6a => true,
        0x1ee6c...0x1ee72 => true,
        0x1ee74...0x1ee77 => true,
        0x1ee79...0x1ee7c => true,
        0x1ee7e => true,
        0x1ee80...0x1ee89 => true,
        0x1ee8b...0x1ee9b => true,
        0x1eea1...0x1eea3 => true,
        0x1eea5...0x1eea9 => true,
        0x1eeab...0x1eebb => true,
        0x1fbf0...0x1fbf9 => true,
        0x20000...0x2a6dd => true,
        0x2a700...0x2b734 => true,
        0x2b740...0x2b81d => true,
        0x2b820...0x2cea1 => true,
        0x2ceb0...0x2ebe0 => true,
        0x2f800...0x2fa1d => true,
        0x30000...0x3134a => true,
        0xe0100...0xe01ef => true,
        else => false,
    };
}