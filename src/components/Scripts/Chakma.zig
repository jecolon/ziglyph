// Autogenerated from http://www.unicode.org/Public/UCD/latest/ucd/UnicodeData.txt by running ucd_gen.
// Placeholders:
//    0. Code point type
//    1. Struct name
//    2. Array length
//    3. Highest code point
//    4. Lowest code point
//! Unicode Chakma code points.

const std = @import("std");
const mem = std.mem;

const Chakma = @This();

allocator: *mem.Allocator,
array: []bool,
lo: u21 = 69888,
hi: u21 = 69959,

pub fn init(allocator: *mem.Allocator) !Chakma {
    var instance = Chakma{
        .allocator = allocator,
        .array = try allocator.alloc(bool, 72),
    };

    mem.set(bool, instance.array, false);

    var index: u21 = 0;
    index = 0;
    while (index <= 2) : (index += 1) {
        instance.array[index] = true;
    }
    index = 3;
    while (index <= 38) : (index += 1) {
        instance.array[index] = true;
    }
    index = 39;
    while (index <= 43) : (index += 1) {
        instance.array[index] = true;
    }
    instance.array[44] = true;
    index = 45;
    while (index <= 52) : (index += 1) {
        instance.array[index] = true;
    }
    index = 54;
    while (index <= 63) : (index += 1) {
        instance.array[index] = true;
    }
    index = 64;
    while (index <= 67) : (index += 1) {
        instance.array[index] = true;
    }
    instance.array[68] = true;
    index = 69;
    while (index <= 70) : (index += 1) {
        instance.array[index] = true;
    }
    instance.array[71] = true;

    // Placeholder: 0. Struct name
    return instance;
}

pub fn deinit(self: *Chakma) void {
    self.allocator.free(self.array);
}

// isChakma checks if cp is of the kind Chakma.
pub fn isChakma(self: Chakma, cp: u21) bool {
    if (cp < self.lo or cp > self.hi) return false;
    const index = cp - self.lo;
    return if (index >= self.array.len) false else self.array[index];
}
