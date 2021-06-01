// Autogenerated from http://www.unicode.org/Public/UCD/latest/ucd/UCD.zip by running ucd_gen.sh.
// Placeholders:
//    0. Struct name
//    1. Lowest code point
//    2. Highest code point
//! Unicode TerminalPunctuation code points.

const lo: u21 = 0x21;
const hi: u21 = 0x1da8a;

pub fn isTerminalPunctuation(cp: u21) bool {
    if (cp < lo or cp > hi) return false;
    return switch (cp) {
        0x21 => true,
        0x2c => true,
        0x2e => true,
        0x3a...0x3b => true,
        0x3f => true,
        0x37e => true,
        0x387 => true,
        0x589 => true,
        0x5c3 => true,
        0x60c => true,
        0x61b => true,
        0x61e...0x61f => true,
        0x6d4 => true,
        0x700...0x70a => true,
        0x70c => true,
        0x7f8...0x7f9 => true,
        0x830...0x83e => true,
        0x85e => true,
        0x964...0x965 => true,
        0xe5a...0xe5b => true,
        0xf08 => true,
        0xf0d...0xf12 => true,
        0x104a...0x104b => true,
        0x1361...0x1368 => true,
        0x166e => true,
        0x16eb...0x16ed => true,
        0x1735...0x1736 => true,
        0x17d4...0x17d6 => true,
        0x17da => true,
        0x1802...0x1805 => true,
        0x1808...0x1809 => true,
        0x1944...0x1945 => true,
        0x1aa8...0x1aab => true,
        0x1b5a...0x1b5b => true,
        0x1b5d...0x1b5f => true,
        0x1c3b...0x1c3f => true,
        0x1c7e...0x1c7f => true,
        0x203c...0x203d => true,
        0x2047...0x2049 => true,
        0x2e2e => true,
        0x2e3c => true,
        0x2e41 => true,
        0x2e4c => true,
        0x2e4e...0x2e4f => true,
        0x3001...0x3002 => true,
        0xa4fe...0xa4ff => true,
        0xa60d...0xa60f => true,
        0xa6f3...0xa6f7 => true,
        0xa876...0xa877 => true,
        0xa8ce...0xa8cf => true,
        0xa92f => true,
        0xa9c7...0xa9c9 => true,
        0xaa5d...0xaa5f => true,
        0xaadf => true,
        0xaaf0...0xaaf1 => true,
        0xabeb => true,
        0xfe50...0xfe52 => true,
        0xfe54...0xfe57 => true,
        0xff01 => true,
        0xff0c => true,
        0xff0e => true,
        0xff1a...0xff1b => true,
        0xff1f => true,
        0xff61 => true,
        0xff64 => true,
        0x1039f => true,
        0x103d0 => true,
        0x10857 => true,
        0x1091f => true,
        0x10a56...0x10a57 => true,
        0x10af0...0x10af5 => true,
        0x10b3a...0x10b3f => true,
        0x10b99...0x10b9c => true,
        0x10f55...0x10f59 => true,
        0x11047...0x1104d => true,
        0x110be...0x110c1 => true,
        0x11141...0x11143 => true,
        0x111c5...0x111c6 => true,
        0x111cd => true,
        0x111de...0x111df => true,
        0x11238...0x1123c => true,
        0x112a9 => true,
        0x1144b...0x1144d => true,
        0x1145a...0x1145b => true,
        0x115c2...0x115c5 => true,
        0x115c9...0x115d7 => true,
        0x11641...0x11642 => true,
        0x1173c...0x1173e => true,
        0x11944 => true,
        0x11946 => true,
        0x11a42...0x11a43 => true,
        0x11a9b...0x11a9c => true,
        0x11aa1...0x11aa2 => true,
        0x11c41...0x11c43 => true,
        0x11c71 => true,
        0x11ef7...0x11ef8 => true,
        0x12470...0x12474 => true,
        0x16a6e...0x16a6f => true,
        0x16af5 => true,
        0x16b37...0x16b39 => true,
        0x16b44 => true,
        0x16e97...0x16e98 => true,
        0x1bc9f => true,
        0x1da87...0x1da8a => true,
        else => false,
    };
}