// Autogenerated from http://www.unicode.org/Public/UCD/latest/ucd/UnicodeData.txt by running ucd_gen.
// Placeholders:
//    0. Code point type
//    1. Struct name
//    2. Array length
//    3. Highest code point
//    4. Lowest code point
//! Unicode Newa code points.

const std = @import("std");
const mem = std.mem;

const Newa = @This();

allocator: *mem.Allocator,
array: []bool,
lo: u21 = 70656,
hi: u21 = 70753,

pub fn init(allocator: *mem.Allocator) !Newa {
    var instance = Newa{
        .allocator = allocator,
        .array = try allocator.alloc(bool, 98),
    };

    mem.set(bool, instance.array, false);

    var index: u21 = 0;
    index = 0;
    while (index <= 52) : (index += 1) {
        instance.array[index] = true;
    }
    index = 53;
    while (index <= 55) : (index += 1) {
        instance.array[index] = true;
    }
    index = 56;
    while (index <= 63) : (index += 1) {
        instance.array[index] = true;
    }
    index = 64;
    while (index <= 65) : (index += 1) {
        instance.array[index] = true;
    }
    index = 66;
    while (index <= 68) : (index += 1) {
        instance.array[index] = true;
    }
    instance.array[69] = true;
    instance.array[70] = true;
    index = 71;
    while (index <= 74) : (index += 1) {
        instance.array[index] = true;
    }
    index = 75;
    while (index <= 79) : (index += 1) {
        instance.array[index] = true;
    }
    index = 80;
    while (index <= 89) : (index += 1) {
        instance.array[index] = true;
    }
    index = 90;
    while (index <= 91) : (index += 1) {
        instance.array[index] = true;
    }
    instance.array[93] = true;
    instance.array[94] = true;
    index = 95;
    while (index <= 97) : (index += 1) {
        instance.array[index] = true;
    }

    // Placeholder: 0. Struct name
    return instance;
}

pub fn deinit(self: *Newa) void {
    self.allocator.free(self.array);
}

// isNewa checks if cp is of the kind Newa.
pub fn isNewa(self: Newa, cp: u21) bool {
    if (cp < self.lo or cp > self.hi) return false;
    const index = cp - self.lo;
    return if (index >= self.array.len) false else self.array[index];
}
