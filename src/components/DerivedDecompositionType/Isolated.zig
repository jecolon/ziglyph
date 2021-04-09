// Autogenerated from http://www.unicode.org/Public/UCD/latest/ucd/UnicodeData.txt by running ucd_gen.
// Placeholders:
//    0. Code point type
//    1. Struct name
//    2. Array length
//    3. Highest code point
//    4. Lowest code point
//! Unicode Isolated code points.

const std = @import("std");
const mem = std.mem;

const Isolated = @This();

allocator: *mem.Allocator,
array: []bool,
lo: u21 = 64336,
hi: u21 = 65275,

pub fn init(allocator: *mem.Allocator) !Isolated {
    var instance = Isolated{
        .allocator = allocator,
        .array = try allocator.alloc(bool, 940),
    };

    mem.set(bool, instance.array, false);

    var index: u21 = 0;
    instance.array[0] = true;
    instance.array[2] = true;
    instance.array[6] = true;
    instance.array[10] = true;
    instance.array[14] = true;
    instance.array[18] = true;
    instance.array[22] = true;
    instance.array[26] = true;
    instance.array[30] = true;
    instance.array[34] = true;
    instance.array[38] = true;
    instance.array[42] = true;
    instance.array[46] = true;
    instance.array[50] = true;
    instance.array[52] = true;
    instance.array[54] = true;
    instance.array[56] = true;
    instance.array[58] = true;
    instance.array[60] = true;
    instance.array[62] = true;
    instance.array[66] = true;
    instance.array[70] = true;
    instance.array[74] = true;
    instance.array[78] = true;
    instance.array[80] = true;
    instance.array[84] = true;
    instance.array[86] = true;
    instance.array[90] = true;
    instance.array[94] = true;
    instance.array[96] = true;
    instance.array[131] = true;
    instance.array[135] = true;
    instance.array[137] = true;
    instance.array[139] = true;
    index = 141;
    while (index <= 142) : (index += 1) {
        instance.array[index] = true;
    }
    instance.array[144] = true;
    instance.array[146] = true;
    instance.array[148] = true;
    instance.array[154] = true;
    instance.array[156] = true;
    instance.array[158] = true;
    instance.array[160] = true;
    instance.array[162] = true;
    instance.array[164] = true;
    instance.array[166] = true;
    instance.array[169] = true;
    instance.array[172] = true;
    index = 176;
    while (index <= 275) : (index += 1) {
        instance.array[index] = true;
    }
    index = 421;
    while (index <= 448) : (index += 1) {
        instance.array[index] = true;
    }
    instance.array[493] = true;
    index = 672;
    while (index <= 683) : (index += 1) {
        instance.array[index] = true;
    }
    instance.array[684] = true;
    instance.array[800] = true;
    instance.array[802] = true;
    instance.array[804] = true;
    instance.array[806] = true;
    instance.array[808] = true;
    instance.array[810] = true;
    instance.array[812] = true;
    instance.array[814] = true;
    index = 816;
    while (index <= 817) : (index += 1) {
        instance.array[index] = true;
    }
    instance.array[819] = true;
    instance.array[821] = true;
    instance.array[823] = true;
    instance.array[825] = true;
    instance.array[829] = true;
    instance.array[831] = true;
    instance.array[835] = true;
    instance.array[837] = true;
    instance.array[841] = true;
    instance.array[845] = true;
    instance.array[849] = true;
    instance.array[853] = true;
    instance.array[857] = true;
    instance.array[859] = true;
    instance.array[861] = true;
    instance.array[863] = true;
    instance.array[865] = true;
    instance.array[869] = true;
    instance.array[873] = true;
    instance.array[877] = true;
    instance.array[881] = true;
    instance.array[885] = true;
    instance.array[889] = true;
    instance.array[893] = true;
    instance.array[897] = true;
    instance.array[901] = true;
    instance.array[905] = true;
    instance.array[909] = true;
    instance.array[913] = true;
    instance.array[917] = true;
    instance.array[921] = true;
    instance.array[925] = true;
    instance.array[927] = true;
    instance.array[929] = true;
    instance.array[933] = true;
    instance.array[935] = true;
    instance.array[937] = true;
    instance.array[939] = true;

    // Placeholder: 0. Struct name
    return instance;
}

pub fn deinit(self: *Isolated) void {
    self.allocator.free(self.array);
}

// isIsolated checks if cp is of the kind Isolated.
pub fn isIsolated(self: Isolated, cp: u21) bool {
    if (cp < self.lo or cp > self.hi) return false;
    const index = cp - self.lo;
    return if (index >= self.array.len) false else self.array[index];
}
