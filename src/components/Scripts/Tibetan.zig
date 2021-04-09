// Autogenerated from http://www.unicode.org/Public/UCD/latest/ucd/UCD.zip by running ucd_gen.sh.
// Placeholders:
//    0. Code point type
//    1. Struct name
//    2. Array length
//    3. Highest code point
//    4. Lowest code point
//! Unicode Tibetan code points.

const std = @import("std");
const mem = std.mem;

const Tibetan = @This();

allocator: *mem.Allocator,
array: []bool,
lo: u21 = 3840,
hi: u21 = 4058,

pub fn init(allocator: *mem.Allocator) !Tibetan {
    var instance = Tibetan{
        .allocator = allocator,
        .array = try allocator.alloc(bool, 219),
    };

    mem.set(bool, instance.array, false);

    var index: u21 = 0;
    instance.array[0] = true;
    index = 1;
    while (index <= 3) : (index += 1) {
        instance.array[index] = true;
    }
    index = 4;
    while (index <= 18) : (index += 1) {
        instance.array[index] = true;
    }
    instance.array[19] = true;
    instance.array[20] = true;
    index = 21;
    while (index <= 23) : (index += 1) {
        instance.array[index] = true;
    }
    index = 24;
    while (index <= 25) : (index += 1) {
        instance.array[index] = true;
    }
    index = 26;
    while (index <= 31) : (index += 1) {
        instance.array[index] = true;
    }
    index = 32;
    while (index <= 41) : (index += 1) {
        instance.array[index] = true;
    }
    index = 42;
    while (index <= 51) : (index += 1) {
        instance.array[index] = true;
    }
    instance.array[52] = true;
    instance.array[53] = true;
    instance.array[54] = true;
    instance.array[55] = true;
    instance.array[56] = true;
    instance.array[57] = true;
    instance.array[58] = true;
    instance.array[59] = true;
    instance.array[60] = true;
    instance.array[61] = true;
    index = 62;
    while (index <= 63) : (index += 1) {
        instance.array[index] = true;
    }
    index = 64;
    while (index <= 71) : (index += 1) {
        instance.array[index] = true;
    }
    index = 73;
    while (index <= 108) : (index += 1) {
        instance.array[index] = true;
    }
    index = 113;
    while (index <= 126) : (index += 1) {
        instance.array[index] = true;
    }
    instance.array[127] = true;
    index = 128;
    while (index <= 132) : (index += 1) {
        instance.array[index] = true;
    }
    instance.array[133] = true;
    index = 134;
    while (index <= 135) : (index += 1) {
        instance.array[index] = true;
    }
    index = 136;
    while (index <= 140) : (index += 1) {
        instance.array[index] = true;
    }
    index = 141;
    while (index <= 151) : (index += 1) {
        instance.array[index] = true;
    }
    index = 153;
    while (index <= 188) : (index += 1) {
        instance.array[index] = true;
    }
    index = 190;
    while (index <= 197) : (index += 1) {
        instance.array[index] = true;
    }
    instance.array[198] = true;
    index = 199;
    while (index <= 204) : (index += 1) {
        instance.array[index] = true;
    }
    index = 206;
    while (index <= 207) : (index += 1) {
        instance.array[index] = true;
    }
    index = 208;
    while (index <= 212) : (index += 1) {
        instance.array[index] = true;
    }
    index = 217;
    while (index <= 218) : (index += 1) {
        instance.array[index] = true;
    }

    // Placeholder: 0. Struct name
    return instance;
}

pub fn deinit(self: *Tibetan) void {
    self.allocator.free(self.array);
}

// isTibetan checks if cp is of the kind Tibetan.
pub fn isTibetan(self: Tibetan, cp: u21) bool {
    if (cp < self.lo or cp > self.hi) return false;
    const index = cp - self.lo;
    return if (index >= self.array.len) false else self.array[index];
}
