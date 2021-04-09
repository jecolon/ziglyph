// Autogenerated from http://www.unicode.org/Public/UCD/latest/ucd/UCD.zip by running ucd_gen.sh.
// Placeholders:
//    0. Code point type
//    1. Struct name
//    2. Array length
//    3. Highest code point
//    4. Lowest code point
//! Unicode Hebrew code points.

const std = @import("std");
const mem = std.mem;

const Hebrew = @This();

allocator: *mem.Allocator,
array: []bool,
lo: u21 = 1425,
hi: u21 = 64335,

pub fn init(allocator: *mem.Allocator) !Hebrew {
    var instance = Hebrew{
        .allocator = allocator,
        .array = try allocator.alloc(bool, 62911),
    };

    mem.set(bool, instance.array, false);

    var index: u21 = 0;
    index = 0;
    while (index <= 44) : (index += 1) {
        instance.array[index] = true;
    }
    instance.array[45] = true;
    instance.array[46] = true;
    instance.array[47] = true;
    index = 48;
    while (index <= 49) : (index += 1) {
        instance.array[index] = true;
    }
    instance.array[50] = true;
    index = 51;
    while (index <= 52) : (index += 1) {
        instance.array[index] = true;
    }
    instance.array[53] = true;
    instance.array[54] = true;
    index = 63;
    while (index <= 89) : (index += 1) {
        instance.array[index] = true;
    }
    index = 94;
    while (index <= 97) : (index += 1) {
        instance.array[index] = true;
    }
    index = 98;
    while (index <= 99) : (index += 1) {
        instance.array[index] = true;
    }
    instance.array[62860] = true;
    instance.array[62861] = true;
    index = 62862;
    while (index <= 62871) : (index += 1) {
        instance.array[index] = true;
    }
    instance.array[62872] = true;
    index = 62873;
    while (index <= 62885) : (index += 1) {
        instance.array[index] = true;
    }
    index = 62887;
    while (index <= 62891) : (index += 1) {
        instance.array[index] = true;
    }
    instance.array[62893] = true;
    index = 62895;
    while (index <= 62896) : (index += 1) {
        instance.array[index] = true;
    }
    index = 62898;
    while (index <= 62899) : (index += 1) {
        instance.array[index] = true;
    }
    index = 62901;
    while (index <= 62910) : (index += 1) {
        instance.array[index] = true;
    }

    // Placeholder: 0. Struct name
    return instance;
}

pub fn deinit(self: *Hebrew) void {
    self.allocator.free(self.array);
}

// isHebrew checks if cp is of the kind Hebrew.
pub fn isHebrew(self: Hebrew, cp: u21) bool {
    if (cp < self.lo or cp > self.hi) return false;
    const index = cp - self.lo;
    return if (index >= self.array.len) false else self.array[index];
}
