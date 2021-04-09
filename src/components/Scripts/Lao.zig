// Autogenerated from http://www.unicode.org/Public/UCD/latest/ucd/UnicodeData.txt by running ucd_gen.
// Placeholders:
//    0. Code point type
//    1. Struct name
//    2. Array length
//    3. Highest code point
//    4. Lowest code point
//! Unicode Lao code points.

const std = @import("std");
const mem = std.mem;

const Lao = @This();

allocator: *mem.Allocator,
array: []bool,
lo: u21 = 3713,
hi: u21 = 3807,

pub fn init(allocator: *mem.Allocator) !Lao {
    var instance = Lao{
        .allocator = allocator,
        .array = try allocator.alloc(bool, 95),
    };

    mem.set(bool, instance.array, false);

    var index: u21 = 0;
    index = 0;
    while (index <= 1) : (index += 1) {
        instance.array[index] = true;
    }
    instance.array[3] = true;
    index = 5;
    while (index <= 9) : (index += 1) {
        instance.array[index] = true;
    }
    index = 11;
    while (index <= 34) : (index += 1) {
        instance.array[index] = true;
    }
    instance.array[36] = true;
    index = 38;
    while (index <= 47) : (index += 1) {
        instance.array[index] = true;
    }
    instance.array[48] = true;
    index = 49;
    while (index <= 50) : (index += 1) {
        instance.array[index] = true;
    }
    index = 51;
    while (index <= 59) : (index += 1) {
        instance.array[index] = true;
    }
    instance.array[60] = true;
    index = 63;
    while (index <= 67) : (index += 1) {
        instance.array[index] = true;
    }
    instance.array[69] = true;
    index = 71;
    while (index <= 76) : (index += 1) {
        instance.array[index] = true;
    }
    index = 79;
    while (index <= 88) : (index += 1) {
        instance.array[index] = true;
    }
    index = 91;
    while (index <= 94) : (index += 1) {
        instance.array[index] = true;
    }

    // Placeholder: 0. Struct name
    return instance;
}

pub fn deinit(self: *Lao) void {
    self.allocator.free(self.array);
}

// isLao checks if cp is of the kind Lao.
pub fn isLao(self: Lao, cp: u21) bool {
    if (cp < self.lo or cp > self.hi) return false;
    const index = cp - self.lo;
    return if (index >= self.array.len) false else self.array[index];
}
