// Autogenerated from http://www.unicode.org/Public/UCD/latest/ucd/UCD.zip by running ucd_gen.sh.
// Placeholders:
//    0. Code point type
//    1. Struct name
//    2. Array length
//    3. Highest code point
//    4. Lowest code point
//! Unicode Tirhuta code points.

const std = @import("std");
const mem = std.mem;

const Tirhuta = @This();

allocator: *mem.Allocator,
array: []bool,
lo: u21 = 70784,
hi: u21 = 70873,

pub fn init(allocator: *mem.Allocator) !Tirhuta {
    var instance = Tirhuta{
        .allocator = allocator,
        .array = try allocator.alloc(bool, 90),
    };

    mem.set(bool, instance.array, false);

    var index: u21 = 0;
    index = 0;
    while (index <= 47) : (index += 1) {
        instance.array[index] = true;
    }
    index = 48;
    while (index <= 50) : (index += 1) {
        instance.array[index] = true;
    }
    index = 51;
    while (index <= 56) : (index += 1) {
        instance.array[index] = true;
    }
    instance.array[57] = true;
    instance.array[58] = true;
    index = 59;
    while (index <= 62) : (index += 1) {
        instance.array[index] = true;
    }
    index = 63;
    while (index <= 64) : (index += 1) {
        instance.array[index] = true;
    }
    instance.array[65] = true;
    index = 66;
    while (index <= 67) : (index += 1) {
        instance.array[index] = true;
    }
    index = 68;
    while (index <= 69) : (index += 1) {
        instance.array[index] = true;
    }
    instance.array[70] = true;
    instance.array[71] = true;
    index = 80;
    while (index <= 89) : (index += 1) {
        instance.array[index] = true;
    }

    // Placeholder: 0. Struct name
    return instance;
}

pub fn deinit(self: *Tirhuta) void {
    self.allocator.free(self.array);
}

// isTirhuta checks if cp is of the kind Tirhuta.
pub fn isTirhuta(self: Tirhuta, cp: u21) bool {
    if (cp < self.lo or cp > self.hi) return false;
    const index = cp - self.lo;
    return if (index >= self.array.len) false else self.array[index];
}
