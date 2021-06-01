// Autogenerated from http://www.unicode.org/Public/UCD/latest/ucd/UCD.zip by running ucd_gen.sh.
// Placeholders:
//    0. Struct name
//    1. Lowest code point
//    2. Highest code point
//! Unicode Emoji code points.

const lo: u21 = 0x23;
const hi: u21 = 0x1fad6;

pub fn isEmoji(cp: u21) bool {
    if (cp < lo or cp > hi) return false;
    return switch (cp) {
        0x23 => true,
        0x2a => true,
        0x30...0x39 => true,
        0xa9 => true,
        0xae => true,
        0x203c => true,
        0x2049 => true,
        0x2122 => true,
        0x2139 => true,
        0x2194...0x2199 => true,
        0x21a9...0x21aa => true,
        0x231a...0x231b => true,
        0x2328 => true,
        0x23cf => true,
        0x23e9...0x23ec => true,
        0x23ed...0x23ee => true,
        0x23ef => true,
        0x23f0 => true,
        0x23f1...0x23f2 => true,
        0x23f3 => true,
        0x23f8...0x23fa => true,
        0x24c2 => true,
        0x25aa...0x25ab => true,
        0x25b6 => true,
        0x25c0 => true,
        0x25fb...0x25fe => true,
        0x2600...0x2601 => true,
        0x2602...0x2603 => true,
        0x2604 => true,
        0x260e => true,
        0x2611 => true,
        0x2614...0x2615 => true,
        0x2618 => true,
        0x261d => true,
        0x2620 => true,
        0x2622...0x2623 => true,
        0x2626 => true,
        0x262a => true,
        0x262e => true,
        0x262f => true,
        0x2638...0x2639 => true,
        0x263a => true,
        0x2640 => true,
        0x2642 => true,
        0x2648...0x2653 => true,
        0x265f => true,
        0x2660 => true,
        0x2663 => true,
        0x2665...0x2666 => true,
        0x2668 => true,
        0x267b => true,
        0x267e => true,
        0x267f => true,
        0x2692 => true,
        0x2693 => true,
        0x2694 => true,
        0x2695 => true,
        0x2696...0x2697 => true,
        0x2699 => true,
        0x269b...0x269c => true,
        0x26a0...0x26a1 => true,
        0x26a7 => true,
        0x26aa...0x26ab => true,
        0x26b0...0x26b1 => true,
        0x26bd...0x26be => true,
        0x26c4...0x26c5 => true,
        0x26c8 => true,
        0x26ce => true,
        0x26cf => true,
        0x26d1 => true,
        0x26d3 => true,
        0x26d4 => true,
        0x26e9 => true,
        0x26ea => true,
        0x26f0...0x26f1 => true,
        0x26f2...0x26f3 => true,
        0x26f4 => true,
        0x26f5 => true,
        0x26f7...0x26f9 => true,
        0x26fa => true,
        0x26fd => true,
        0x2702 => true,
        0x2705 => true,
        0x2708...0x270c => true,
        0x270d => true,
        0x270f => true,
        0x2712 => true,
        0x2714 => true,
        0x2716 => true,
        0x271d => true,
        0x2721 => true,
        0x2728 => true,
        0x2733...0x2734 => true,
        0x2744 => true,
        0x2747 => true,
        0x274c => true,
        0x274e => true,
        0x2753...0x2755 => true,
        0x2757 => true,
        0x2763 => true,
        0x2764 => true,
        0x2795...0x2797 => true,
        0x27a1 => true,
        0x27b0 => true,
        0x27bf => true,
        0x2934...0x2935 => true,
        0x2b05...0x2b07 => true,
        0x2b1b...0x2b1c => true,
        0x2b50 => true,
        0x2b55 => true,
        0x3030 => true,
        0x303d => true,
        0x3297 => true,
        0x3299 => true,
        0x1f004 => true,
        0x1f0cf => true,
        0x1f170...0x1f171 => true,
        0x1f17e...0x1f17f => true,
        0x1f18e => true,
        0x1f191...0x1f19a => true,
        0x1f1e6...0x1f1ff => true,
        0x1f201...0x1f202 => true,
        0x1f21a => true,
        0x1f22f => true,
        0x1f232...0x1f23a => true,
        0x1f250...0x1f251 => true,
        0x1f300...0x1f30c => true,
        0x1f30d...0x1f30e => true,
        0x1f30f => true,
        0x1f310 => true,
        0x1f311 => true,
        0x1f312 => true,
        0x1f313...0x1f315 => true,
        0x1f316...0x1f318 => true,
        0x1f319 => true,
        0x1f31a => true,
        0x1f31b => true,
        0x1f31c => true,
        0x1f31d...0x1f31e => true,
        0x1f31f...0x1f320 => true,
        0x1f321 => true,
        0x1f324...0x1f32c => true,
        0x1f32d...0x1f32f => true,
        0x1f330...0x1f331 => true,
        0x1f332...0x1f333 => true,
        0x1f334...0x1f335 => true,
        0x1f336 => true,
        0x1f337...0x1f34a => true,
        0x1f34b => true,
        0x1f34c...0x1f34f => true,
        0x1f350 => true,
        0x1f351...0x1f37b => true,
        0x1f37c => true,
        0x1f37d => true,
        0x1f37e...0x1f37f => true,
        0x1f380...0x1f393 => true,
        0x1f396...0x1f397 => true,
        0x1f399...0x1f39b => true,
        0x1f39e...0x1f39f => true,
        0x1f3a0...0x1f3c4 => true,
        0x1f3c5 => true,
        0x1f3c6 => true,
        0x1f3c7 => true,
        0x1f3c8 => true,
        0x1f3c9 => true,
        0x1f3ca => true,
        0x1f3cb...0x1f3ce => true,
        0x1f3cf...0x1f3d3 => true,
        0x1f3d4...0x1f3df => true,
        0x1f3e0...0x1f3e3 => true,
        0x1f3e4 => true,
        0x1f3e5...0x1f3f0 => true,
        0x1f3f3 => true,
        0x1f3f4 => true,
        0x1f3f5 => true,
        0x1f3f7 => true,
        0x1f3f8...0x1f407 => true,
        0x1f408 => true,
        0x1f409...0x1f40b => true,
        0x1f40c...0x1f40e => true,
        0x1f40f...0x1f410 => true,
        0x1f411...0x1f412 => true,
        0x1f413 => true,
        0x1f414 => true,
        0x1f415 => true,
        0x1f416 => true,
        0x1f417...0x1f429 => true,
        0x1f42a => true,
        0x1f42b...0x1f43e => true,
        0x1f43f => true,
        0x1f440 => true,
        0x1f441 => true,
        0x1f442...0x1f464 => true,
        0x1f465 => true,
        0x1f466...0x1f46b => true,
        0x1f46c...0x1f46d => true,
        0x1f46e...0x1f4ac => true,
        0x1f4ad => true,
        0x1f4ae...0x1f4b5 => true,
        0x1f4b6...0x1f4b7 => true,
        0x1f4b8...0x1f4eb => true,
        0x1f4ec...0x1f4ed => true,
        0x1f4ee => true,
        0x1f4ef => true,
        0x1f4f0...0x1f4f4 => true,
        0x1f4f5 => true,
        0x1f4f6...0x1f4f7 => true,
        0x1f4f8 => true,
        0x1f4f9...0x1f4fc => true,
        0x1f4fd => true,
        0x1f4ff...0x1f502 => true,
        0x1f503 => true,
        0x1f504...0x1f507 => true,
        0x1f508 => true,
        0x1f509 => true,
        0x1f50a...0x1f514 => true,
        0x1f515 => true,
        0x1f516...0x1f52b => true,
        0x1f52c...0x1f52d => true,
        0x1f52e...0x1f53d => true,
        0x1f549...0x1f54a => true,
        0x1f54b...0x1f54e => true,
        0x1f550...0x1f55b => true,
        0x1f55c...0x1f567 => true,
        0x1f56f...0x1f570 => true,
        0x1f573...0x1f579 => true,
        0x1f57a => true,
        0x1f587 => true,
        0x1f58a...0x1f58d => true,
        0x1f590 => true,
        0x1f595...0x1f596 => true,
        0x1f5a4 => true,
        0x1f5a5 => true,
        0x1f5a8 => true,
        0x1f5b1...0x1f5b2 => true,
        0x1f5bc => true,
        0x1f5c2...0x1f5c4 => true,
        0x1f5d1...0x1f5d3 => true,
        0x1f5dc...0x1f5de => true,
        0x1f5e1 => true,
        0x1f5e3 => true,
        0x1f5e8 => true,
        0x1f5ef => true,
        0x1f5f3 => true,
        0x1f5fa => true,
        0x1f5fb...0x1f5ff => true,
        0x1f600 => true,
        0x1f601...0x1f606 => true,
        0x1f607...0x1f608 => true,
        0x1f609...0x1f60d => true,
        0x1f60e => true,
        0x1f60f => true,
        0x1f610 => true,
        0x1f611 => true,
        0x1f612...0x1f614 => true,
        0x1f615 => true,
        0x1f616 => true,
        0x1f617 => true,
        0x1f618 => true,
        0x1f619 => true,
        0x1f61a => true,
        0x1f61b => true,
        0x1f61c...0x1f61e => true,
        0x1f61f => true,
        0x1f620...0x1f625 => true,
        0x1f626...0x1f627 => true,
        0x1f628...0x1f62b => true,
        0x1f62c => true,
        0x1f62d => true,
        0x1f62e...0x1f62f => true,
        0x1f630...0x1f633 => true,
        0x1f634 => true,
        0x1f635 => true,
        0x1f636 => true,
        0x1f637...0x1f640 => true,
        0x1f641...0x1f644 => true,
        0x1f645...0x1f64f => true,
        0x1f680 => true,
        0x1f681...0x1f682 => true,
        0x1f683...0x1f685 => true,
        0x1f686 => true,
        0x1f687 => true,
        0x1f688 => true,
        0x1f689 => true,
        0x1f68a...0x1f68b => true,
        0x1f68c => true,
        0x1f68d => true,
        0x1f68e => true,
        0x1f68f => true,
        0x1f690 => true,
        0x1f691...0x1f693 => true,
        0x1f694 => true,
        0x1f695 => true,
        0x1f696 => true,
        0x1f697 => true,
        0x1f698 => true,
        0x1f699...0x1f69a => true,
        0x1f69b...0x1f6a1 => true,
        0x1f6a2 => true,
        0x1f6a3 => true,
        0x1f6a4...0x1f6a5 => true,
        0x1f6a6 => true,
        0x1f6a7...0x1f6ad => true,
        0x1f6ae...0x1f6b1 => true,
        0x1f6b2 => true,
        0x1f6b3...0x1f6b5 => true,
        0x1f6b6 => true,
        0x1f6b7...0x1f6b8 => true,
        0x1f6b9...0x1f6be => true,
        0x1f6bf => true,
        0x1f6c0 => true,
        0x1f6c1...0x1f6c5 => true,
        0x1f6cb => true,
        0x1f6cc => true,
        0x1f6cd...0x1f6cf => true,
        0x1f6d0 => true,
        0x1f6d1...0x1f6d2 => true,
        0x1f6d5 => true,
        0x1f6d6...0x1f6d7 => true,
        0x1f6e0...0x1f6e5 => true,
        0x1f6e9 => true,
        0x1f6eb...0x1f6ec => true,
        0x1f6f0 => true,
        0x1f6f3 => true,
        0x1f6f4...0x1f6f6 => true,
        0x1f6f7...0x1f6f8 => true,
        0x1f6f9 => true,
        0x1f6fa => true,
        0x1f6fb...0x1f6fc => true,
        0x1f7e0...0x1f7eb => true,
        0x1f90c => true,
        0x1f90d...0x1f90f => true,
        0x1f910...0x1f918 => true,
        0x1f919...0x1f91e => true,
        0x1f91f => true,
        0x1f920...0x1f927 => true,
        0x1f928...0x1f92f => true,
        0x1f930 => true,
        0x1f931...0x1f932 => true,
        0x1f933...0x1f93a => true,
        0x1f93c...0x1f93e => true,
        0x1f93f => true,
        0x1f940...0x1f945 => true,
        0x1f947...0x1f94b => true,
        0x1f94c => true,
        0x1f94d...0x1f94f => true,
        0x1f950...0x1f95e => true,
        0x1f95f...0x1f96b => true,
        0x1f96c...0x1f970 => true,
        0x1f971 => true,
        0x1f972 => true,
        0x1f973...0x1f976 => true,
        0x1f977...0x1f978 => true,
        0x1f97a => true,
        0x1f97b => true,
        0x1f97c...0x1f97f => true,
        0x1f980...0x1f984 => true,
        0x1f985...0x1f991 => true,
        0x1f992...0x1f997 => true,
        0x1f998...0x1f9a2 => true,
        0x1f9a3...0x1f9a4 => true,
        0x1f9a5...0x1f9aa => true,
        0x1f9ab...0x1f9ad => true,
        0x1f9ae...0x1f9af => true,
        0x1f9b0...0x1f9b9 => true,
        0x1f9ba...0x1f9bf => true,
        0x1f9c0 => true,
        0x1f9c1...0x1f9c2 => true,
        0x1f9c3...0x1f9ca => true,
        0x1f9cb => true,
        0x1f9cd...0x1f9cf => true,
        0x1f9d0...0x1f9e6 => true,
        0x1f9e7...0x1f9ff => true,
        0x1fa70...0x1fa73 => true,
        0x1fa74 => true,
        0x1fa78...0x1fa7a => true,
        0x1fa80...0x1fa82 => true,
        0x1fa83...0x1fa86 => true,
        0x1fa90...0x1fa95 => true,
        0x1fa96...0x1faa8 => true,
        0x1fab0...0x1fab6 => true,
        0x1fac0...0x1fac2 => true,
        0x1fad0...0x1fad6 => true,
        else => false,
    };
}