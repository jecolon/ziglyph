// Autogenerated from http://www.unicode.org/Public/UCD/latest/ucd/UCD.zip by running ucd_gen.sh.
// Placeholders:
//    0. Code point type
//    1. Struct name
//    2. Array length
//    3. Highest code point
//    4. Lowest code point
//! Unicode Math_Symbol code points.

const std = @import("std");
const mem = std.mem;

const MathSymbol = @This();

allocator: *mem.Allocator,
array: []bool,
lo: u21 = 43,
hi: u21 = 126705,

pub fn init(allocator: *mem.Allocator) !MathSymbol {
    var instance = MathSymbol{
        .allocator = allocator,
        .array = try allocator.alloc(bool, 126663),
    };

    mem.set(bool, instance.array, false);

    var index: u21 = 0;
    instance.array[0] = true;
    index = 17;
    while (index <= 19) : (index += 1) {
        instance.array[index] = true;
    }
    instance.array[81] = true;
    instance.array[83] = true;
    instance.array[129] = true;
    instance.array[134] = true;
    instance.array[172] = true;
    instance.array[204] = true;
    instance.array[971] = true;
    index = 1499;
    while (index <= 1501) : (index += 1) {
        instance.array[index] = true;
    }
    instance.array[8217] = true;
    instance.array[8231] = true;
    index = 8271;
    while (index <= 8273) : (index += 1) {
        instance.array[index] = true;
    }
    index = 8287;
    while (index <= 8289) : (index += 1) {
        instance.array[index] = true;
    }
    instance.array[8429] = true;
    index = 8469;
    while (index <= 8473) : (index += 1) {
        instance.array[index] = true;
    }
    instance.array[8480] = true;
    index = 8549;
    while (index <= 8553) : (index += 1) {
        instance.array[index] = true;
    }
    index = 8559;
    while (index <= 8560) : (index += 1) {
        instance.array[index] = true;
    }
    instance.array[8565] = true;
    instance.array[8568] = true;
    instance.array[8571] = true;
    instance.array[8579] = true;
    index = 8611;
    while (index <= 8612) : (index += 1) {
        instance.array[index] = true;
    }
    instance.array[8615] = true;
    instance.array[8617] = true;
    index = 8649;
    while (index <= 8916) : (index += 1) {
        instance.array[index] = true;
    }
    index = 8949;
    while (index <= 8950) : (index += 1) {
        instance.array[index] = true;
    }
    instance.array[9041] = true;
    index = 9072;
    while (index <= 9096) : (index += 1) {
        instance.array[index] = true;
    }
    index = 9137;
    while (index <= 9142) : (index += 1) {
        instance.array[index] = true;
    }
    instance.array[9612] = true;
    instance.array[9622] = true;
    index = 9677;
    while (index <= 9684) : (index += 1) {
        instance.array[index] = true;
    }
    instance.array[9796] = true;
    index = 10133;
    while (index <= 10137) : (index += 1) {
        instance.array[index] = true;
    }
    index = 10140;
    while (index <= 10170) : (index += 1) {
        instance.array[index] = true;
    }
    index = 10181;
    while (index <= 10196) : (index += 1) {
        instance.array[index] = true;
    }
    index = 10453;
    while (index <= 10583) : (index += 1) {
        instance.array[index] = true;
    }
    index = 10606;
    while (index <= 10668) : (index += 1) {
        instance.array[index] = true;
    }
    index = 10673;
    while (index <= 10704) : (index += 1) {
        instance.array[index] = true;
    }
    index = 10707;
    while (index <= 10964) : (index += 1) {
        instance.array[index] = true;
    }
    index = 11013;
    while (index <= 11033) : (index += 1) {
        instance.array[index] = true;
    }
    index = 11036;
    while (index <= 11041) : (index += 1) {
        instance.array[index] = true;
    }
    instance.array[64254] = true;
    instance.array[65079] = true;
    index = 65081;
    while (index <= 65083) : (index += 1) {
        instance.array[index] = true;
    }
    instance.array[65248] = true;
    index = 65265;
    while (index <= 65267) : (index += 1) {
        instance.array[index] = true;
    }
    instance.array[65329] = true;
    instance.array[65331] = true;
    instance.array[65463] = true;
    index = 65470;
    while (index <= 65473) : (index += 1) {
        instance.array[index] = true;
    }
    instance.array[120470] = true;
    instance.array[120496] = true;
    instance.array[120528] = true;
    instance.array[120554] = true;
    instance.array[120586] = true;
    instance.array[120612] = true;
    instance.array[120644] = true;
    instance.array[120670] = true;
    instance.array[120702] = true;
    instance.array[120728] = true;
    index = 126661;
    while (index <= 126662) : (index += 1) {
        instance.array[index] = true;
    }

    // Placeholder: 0. Struct name
    return instance;
}

pub fn deinit(self: *MathSymbol) void {
    self.allocator.free(self.array);
}

// isMathSymbol checks if cp is of the kind Math_Symbol.
pub fn isMathSymbol(self: MathSymbol, cp: u21) bool {
    if (cp < self.lo or cp > self.hi) return false;
    const index = cp - self.lo;
    return if (index >= self.array.len) false else self.array[index];
}
