// Autogenerated from http://www.unicode.org/Public/UCD/latest/ucd/UnicodeData.txt by running ucd_gen.
// Placeholders:
//    0. Code point type
//    1. Struct name
//    2. Array length
//    3. Highest code point
//    4. Lowest code point
//! Unicode Bhaiksuki code points.

const std = @import("std");
const mem = std.mem;

const Bhaiksuki = @This();

allocator: *mem.Allocator,
array: []bool,
lo: u21 = 72704,
hi: u21 = 72812,

pub fn init(allocator: *mem.Allocator) !Bhaiksuki {
    var instance = Bhaiksuki{
        .allocator = allocator,
        .array = try allocator.alloc(bool, 109),
    };

    mem.set(bool, instance.array, false);

    var index: u21 = 0;
    index = 0;
    while (index <= 8) : (index += 1) {
        instance.array[index] = true;
    }
    index = 10;
    while (index <= 46) : (index += 1) {
        instance.array[index] = true;
    }
    instance.array[47] = true;
    index = 48;
    while (index <= 54) : (index += 1) {
        instance.array[index] = true;
    }
    index = 56;
    while (index <= 61) : (index += 1) {
        instance.array[index] = true;
    }
    instance.array[62] = true;
    instance.array[63] = true;
    instance.array[64] = true;
    index = 65;
    while (index <= 69) : (index += 1) {
        instance.array[index] = true;
    }
    index = 80;
    while (index <= 89) : (index += 1) {
        instance.array[index] = true;
    }
    index = 90;
    while (index <= 108) : (index += 1) {
        instance.array[index] = true;
    }

    // Placeholder: 0. Struct name
    return instance;
}

pub fn deinit(self: *Bhaiksuki) void {
    self.allocator.free(self.array);
}

// isBhaiksuki checks if cp is of the kind Bhaiksuki.
pub fn isBhaiksuki(self: Bhaiksuki, cp: u21) bool {
    if (cp < self.lo or cp > self.hi) return false;
    const index = cp - self.lo;
    return if (index >= self.array.len) false else self.array[index];
}
