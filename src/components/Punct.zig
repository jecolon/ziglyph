// Autogenerated from http://www.unicode.org/Public/UCD/latest/ucd/UnicodeData.txt by running ucd_gen.
// Placeholders:
//    0. Struct name
//    1. Array length
//    2. Highest code point
//    3. Lowest code point
//! Unicode Punct category code points data.

const std = @import("std");
const mem = std.mem;
const Range = @import("../Range.zig");
const ascii = @import("../ascii.zig"); // Pending std.ascii fix.

const Punct = @This();

allocator: *mem.Allocator,
array: []bool,
lo: u21 = 33,
hi: u21 = 125279,

pub fn init(allocator: *mem.Allocator) !Punct {
    var instance = Punct{
        .allocator = allocator,
        .array = try allocator.alloc(bool, 125247),
    };

    for (instance.array) |*item| {
        item.* = false;
    }

    instance.array[62] = true;
    instance.array[90] = true;
    instance.array[92] = true;
    instance.array[128] = true;
    instance.array[134] = true;
    instance.array[138] = true;
    instance.array[154] = true;
    instance.array[158] = true;
    instance.array[861] = true;
    instance.array[870] = true;
    instance.array[1437] = true;
    instance.array[1439] = true;
    instance.array[1442] = true;
    instance.array[1445] = true;
    instance.array[1530] = true;
    instance.array[1715] = true;
    instance.array[2109] = true;
    instance.array[2383] = true;
    instance.array[2524] = true;
    instance.array[2645] = true;
    instance.array[2767] = true;
    instance.array[3158] = true;
    instance.array[3171] = true;
    instance.array[3539] = true;
    instance.array[3630] = true;
    instance.array[3827] = true;
    instance.array[3940] = true;
    instance.array[4314] = true;
    instance.array[5087] = true;
    instance.array[5709] = true;
    instance.array[7346] = true;
    instance.array[11599] = true;
    instance.array[11825] = true;
    instance.array[12303] = true;
    instance.array[12316] = true;
    instance.array[12415] = true;
    instance.array[12506] = true;
    instance.array[42578] = true;
    instance.array[42589] = true;
    instance.array[43227] = true;
    instance.array[43326] = true;
    instance.array[43978] = true;
    instance.array[65090] = true;
    instance.array[65095] = true;
    instance.array[65310] = true;
    instance.array[65338] = true;
    instance.array[65340] = true;
    instance.array[66430] = true;
    instance.array[66479] = true;
    instance.array[66894] = true;
    instance.array[67638] = true;
    instance.array[67838] = true;
    instance.array[67870] = true;
    instance.array[68190] = true;
    instance.array[69260] = true;
    instance.array[70060] = true;
    instance.array[70074] = true;
    instance.array[70280] = true;
    instance.array[70716] = true;
    instance.array[70821] = true;
    instance.array[71706] = true;
    instance.array[72129] = true;
    instance.array[73694] = true;
    instance.array[92884] = true;
    instance.array[92963] = true;
    instance.array[94145] = true;
    instance.array[113790] = true;
    instance.array[125245] = true;

    var index: u21 = 0;
    index = 0;
    while (index <= 2) : (index += 1) {
        instance.array[index] = true;
    }
    index = 4;
    while (index <= 9) : (index += 1) {
        instance.array[index] = true;
    }
    index = 11;
    while (index <= 14) : (index += 1) {
        instance.array[index] = true;
    }
    index = 25;
    while (index <= 26) : (index += 1) {
        instance.array[index] = true;
    }
    index = 30;
    while (index <= 31) : (index += 1) {
        instance.array[index] = true;
    }
    index = 58;
    while (index <= 60) : (index += 1) {
        instance.array[index] = true;
    }
    index = 149;
    while (index <= 150) : (index += 1) {
        instance.array[index] = true;
    }
    index = 1337;
    while (index <= 1342) : (index += 1) {
        instance.array[index] = true;
    }
    index = 1384;
    while (index <= 1385) : (index += 1) {
        instance.array[index] = true;
    }
    index = 1490;
    while (index <= 1491) : (index += 1) {
        instance.array[index] = true;
    }
    index = 1512;
    while (index <= 1513) : (index += 1) {
        instance.array[index] = true;
    }
    index = 1515;
    while (index <= 1516) : (index += 1) {
        instance.array[index] = true;
    }
    index = 1533;
    while (index <= 1534) : (index += 1) {
        instance.array[index] = true;
    }
    index = 1609;
    while (index <= 1612) : (index += 1) {
        instance.array[index] = true;
    }
    index = 1759;
    while (index <= 1772) : (index += 1) {
        instance.array[index] = true;
    }
    index = 2006;
    while (index <= 2008) : (index += 1) {
        instance.array[index] = true;
    }
    index = 2063;
    while (index <= 2077) : (index += 1) {
        instance.array[index] = true;
    }
    index = 2371;
    while (index <= 2372) : (index += 1) {
        instance.array[index] = true;
    }
    index = 3641;
    while (index <= 3642) : (index += 1) {
        instance.array[index] = true;
    }
    index = 3811;
    while (index <= 3825) : (index += 1) {
        instance.array[index] = true;
    }
    index = 3865;
    while (index <= 3868) : (index += 1) {
        instance.array[index] = true;
    }
    index = 4015;
    while (index <= 4019) : (index += 1) {
        instance.array[index] = true;
    }
    index = 4024;
    while (index <= 4025) : (index += 1) {
        instance.array[index] = true;
    }
    index = 4137;
    while (index <= 4142) : (index += 1) {
        instance.array[index] = true;
    }
    index = 4927;
    while (index <= 4935) : (index += 1) {
        instance.array[index] = true;
    }
    index = 5754;
    while (index <= 5755) : (index += 1) {
        instance.array[index] = true;
    }
    index = 5834;
    while (index <= 5836) : (index += 1) {
        instance.array[index] = true;
    }
    index = 5908;
    while (index <= 5909) : (index += 1) {
        instance.array[index] = true;
    }
    index = 6067;
    while (index <= 6069) : (index += 1) {
        instance.array[index] = true;
    }
    index = 6071;
    while (index <= 6073) : (index += 1) {
        instance.array[index] = true;
    }
    index = 6111;
    while (index <= 6121) : (index += 1) {
        instance.array[index] = true;
    }
    index = 6435;
    while (index <= 6436) : (index += 1) {
        instance.array[index] = true;
    }
    index = 6653;
    while (index <= 6654) : (index += 1) {
        instance.array[index] = true;
    }
    index = 6783;
    while (index <= 6789) : (index += 1) {
        instance.array[index] = true;
    }
    index = 6791;
    while (index <= 6796) : (index += 1) {
        instance.array[index] = true;
    }
    index = 6969;
    while (index <= 6975) : (index += 1) {
        instance.array[index] = true;
    }
    index = 7131;
    while (index <= 7134) : (index += 1) {
        instance.array[index] = true;
    }
    index = 7194;
    while (index <= 7198) : (index += 1) {
        instance.array[index] = true;
    }
    index = 7261;
    while (index <= 7262) : (index += 1) {
        instance.array[index] = true;
    }
    index = 7327;
    while (index <= 7334) : (index += 1) {
        instance.array[index] = true;
    }
    index = 8175;
    while (index <= 8198) : (index += 1) {
        instance.array[index] = true;
    }
    index = 8207;
    while (index <= 8226) : (index += 1) {
        instance.array[index] = true;
    }
    index = 8228;
    while (index <= 8240) : (index += 1) {
        instance.array[index] = true;
    }
    index = 8242;
    while (index <= 8253) : (index += 1) {
        instance.array[index] = true;
    }
    index = 8284;
    while (index <= 8285) : (index += 1) {
        instance.array[index] = true;
    }
    index = 8300;
    while (index <= 8301) : (index += 1) {
        instance.array[index] = true;
    }
    index = 8935;
    while (index <= 8938) : (index += 1) {
        instance.array[index] = true;
    }
    index = 8968;
    while (index <= 8969) : (index += 1) {
        instance.array[index] = true;
    }
    index = 10055;
    while (index <= 10068) : (index += 1) {
        instance.array[index] = true;
    }
    index = 10148;
    while (index <= 10149) : (index += 1) {
        instance.array[index] = true;
    }
    index = 10181;
    while (index <= 10190) : (index += 1) {
        instance.array[index] = true;
    }
    index = 10594;
    while (index <= 10615) : (index += 1) {
        instance.array[index] = true;
    }
    index = 10679;
    while (index <= 10682) : (index += 1) {
        instance.array[index] = true;
    }
    index = 10715;
    while (index <= 10716) : (index += 1) {
        instance.array[index] = true;
    }
    index = 11480;
    while (index <= 11483) : (index += 1) {
        instance.array[index] = true;
    }
    index = 11485;
    while (index <= 11486) : (index += 1) {
        instance.array[index] = true;
    }
    index = 11743;
    while (index <= 11789) : (index += 1) {
        instance.array[index] = true;
    }
    index = 11791;
    while (index <= 11822) : (index += 1) {
        instance.array[index] = true;
    }
    index = 12256;
    while (index <= 12258) : (index += 1) {
        instance.array[index] = true;
    }
    index = 12263;
    while (index <= 12272) : (index += 1) {
        instance.array[index] = true;
    }
    index = 12275;
    while (index <= 12286) : (index += 1) {
        instance.array[index] = true;
    }
    index = 42205;
    while (index <= 42206) : (index += 1) {
        instance.array[index] = true;
    }
    index = 42476;
    while (index <= 42478) : (index += 1) {
        instance.array[index] = true;
    }
    index = 42705;
    while (index <= 42710) : (index += 1) {
        instance.array[index] = true;
    }
    index = 43091;
    while (index <= 43094) : (index += 1) {
        instance.array[index] = true;
    }
    index = 43181;
    while (index <= 43182) : (index += 1) {
        instance.array[index] = true;
    }
    index = 43223;
    while (index <= 43225) : (index += 1) {
        instance.array[index] = true;
    }
    index = 43277;
    while (index <= 43278) : (index += 1) {
        instance.array[index] = true;
    }
    index = 43424;
    while (index <= 43436) : (index += 1) {
        instance.array[index] = true;
    }
    index = 43453;
    while (index <= 43454) : (index += 1) {
        instance.array[index] = true;
    }
    index = 43579;
    while (index <= 43582) : (index += 1) {
        instance.array[index] = true;
    }
    index = 43709;
    while (index <= 43710) : (index += 1) {
        instance.array[index] = true;
    }
    index = 43727;
    while (index <= 43728) : (index += 1) {
        instance.array[index] = true;
    }
    index = 64797;
    while (index <= 64798) : (index += 1) {
        instance.array[index] = true;
    }
    index = 65007;
    while (index <= 65016) : (index += 1) {
        instance.array[index] = true;
    }
    index = 65039;
    while (index <= 65073) : (index += 1) {
        instance.array[index] = true;
    }
    index = 65075;
    while (index <= 65088) : (index += 1) {
        instance.array[index] = true;
    }
    index = 65097;
    while (index <= 65098) : (index += 1) {
        instance.array[index] = true;
    }
    index = 65248;
    while (index <= 65250) : (index += 1) {
        instance.array[index] = true;
    }
    index = 65252;
    while (index <= 65257) : (index += 1) {
        instance.array[index] = true;
    }
    index = 65259;
    while (index <= 65262) : (index += 1) {
        instance.array[index] = true;
    }
    index = 65273;
    while (index <= 65274) : (index += 1) {
        instance.array[index] = true;
    }
    index = 65278;
    while (index <= 65279) : (index += 1) {
        instance.array[index] = true;
    }
    index = 65306;
    while (index <= 65308) : (index += 1) {
        instance.array[index] = true;
    }
    index = 65342;
    while (index <= 65348) : (index += 1) {
        instance.array[index] = true;
    }
    index = 65759;
    while (index <= 65761) : (index += 1) {
        instance.array[index] = true;
    }
    index = 68143;
    while (index <= 68151) : (index += 1) {
        instance.array[index] = true;
    }
    index = 68303;
    while (index <= 68309) : (index += 1) {
        instance.array[index] = true;
    }
    index = 68376;
    while (index <= 68382) : (index += 1) {
        instance.array[index] = true;
    }
    index = 68472;
    while (index <= 68475) : (index += 1) {
        instance.array[index] = true;
    }
    index = 69428;
    while (index <= 69432) : (index += 1) {
        instance.array[index] = true;
    }
    index = 69670;
    while (index <= 69676) : (index += 1) {
        instance.array[index] = true;
    }
    index = 69786;
    while (index <= 69787) : (index += 1) {
        instance.array[index] = true;
    }
    index = 69789;
    while (index <= 69792) : (index += 1) {
        instance.array[index] = true;
    }
    index = 69919;
    while (index <= 69922) : (index += 1) {
        instance.array[index] = true;
    }
    index = 69971;
    while (index <= 69972) : (index += 1) {
        instance.array[index] = true;
    }
    index = 70052;
    while (index <= 70055) : (index += 1) {
        instance.array[index] = true;
    }
    index = 70076;
    while (index <= 70078) : (index += 1) {
        instance.array[index] = true;
    }
    index = 70167;
    while (index <= 70172) : (index += 1) {
        instance.array[index] = true;
    }
    index = 70698;
    while (index <= 70702) : (index += 1) {
        instance.array[index] = true;
    }
    index = 70713;
    while (index <= 70714) : (index += 1) {
        instance.array[index] = true;
    }
    index = 71072;
    while (index <= 71094) : (index += 1) {
        instance.array[index] = true;
    }
    index = 71200;
    while (index <= 71202) : (index += 1) {
        instance.array[index] = true;
    }
    index = 71231;
    while (index <= 71243) : (index += 1) {
        instance.array[index] = true;
    }
    index = 71451;
    while (index <= 71453) : (index += 1) {
        instance.array[index] = true;
    }
    index = 71971;
    while (index <= 71973) : (index += 1) {
        instance.array[index] = true;
    }
    index = 72222;
    while (index <= 72229) : (index += 1) {
        instance.array[index] = true;
    }
    index = 72313;
    while (index <= 72315) : (index += 1) {
        instance.array[index] = true;
    }
    index = 72317;
    while (index <= 72321) : (index += 1) {
        instance.array[index] = true;
    }
    index = 72736;
    while (index <= 72740) : (index += 1) {
        instance.array[index] = true;
    }
    index = 72783;
    while (index <= 72784) : (index += 1) {
        instance.array[index] = true;
    }
    index = 73430;
    while (index <= 73431) : (index += 1) {
        instance.array[index] = true;
    }
    index = 74831;
    while (index <= 74835) : (index += 1) {
        instance.array[index] = true;
    }
    index = 92749;
    while (index <= 92750) : (index += 1) {
        instance.array[index] = true;
    }
    index = 92950;
    while (index <= 92954) : (index += 1) {
        instance.array[index] = true;
    }
    index = 93814;
    while (index <= 93817) : (index += 1) {
        instance.array[index] = true;
    }
    index = 121446;
    while (index <= 121450) : (index += 1) {
        instance.array[index] = true;
    }

    // Placeholder: 0. Struct name, 1. ASCII optimization.
    return instance;
}

pub fn deinit(self: *Punct) void {
    self.allocator.free(self.array);
}

// ASCII optimization.
fn ascii_opt(self: Punct, cp: u21) ?bool {
    if (cp < 128) {
        return ascii.isPunct(@intCast(u8, cp));
    } else {
        return null;
    }
}

pub fn isPunct(self: Punct, cp: u21) bool {
    if (self.ascii_opt(cp)) |acp| return acp;
    if (cp < self.lo or cp > self.hi) return false;
    const index = cp - self.lo;
    return if (index >= self.array.len) false else self.array[index];
}
