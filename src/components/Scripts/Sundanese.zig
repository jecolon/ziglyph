// Autogenerated from http://www.unicode.org/Public/UCD/latest/ucd/UnicodeData.txt by running ucd_gen.
// Placeholders:
//    0. Code point type
//    1. Struct name
//    2. Array length
//    3. Highest code point
//    4. Lowest code point
//! Unicode Sundanese code points.

const std = @import("std");
const mem = std.mem;

const Sundanese = @This();

allocator: *mem.Allocator,
array: []bool,
lo: u21 = 7040,
hi: u21 = 7367,

pub fn init(allocator: *mem.Allocator) !Sundanese {
    var instance = Sundanese{
        .allocator = allocator,
        .array = try allocator.alloc(bool, 328),
    };

    mem.set(bool, instance.array, false);

    var index: u21 = 0;
    index = 0;
    while (index <= 1) : (index += 1) {
        instance.array[index] = true;
    }
    instance.array[2] = true;
    index = 3;
    while (index <= 32) : (index += 1) {
        instance.array[index] = true;
    }
    instance.array[33] = true;
    index = 34;
    while (index <= 37) : (index += 1) {
        instance.array[index] = true;
    }
    index = 38;
    while (index <= 39) : (index += 1) {
        instance.array[index] = true;
    }
    index = 40;
    while (index <= 41) : (index += 1) {
        instance.array[index] = true;
    }
    instance.array[42] = true;
    index = 43;
    while (index <= 45) : (index += 1) {
        instance.array[index] = true;
    }
    index = 46;
    while (index <= 47) : (index += 1) {
        instance.array[index] = true;
    }
    index = 48;
    while (index <= 57) : (index += 1) {
        instance.array[index] = true;
    }
    index = 58;
    while (index <= 63) : (index += 1) {
        instance.array[index] = true;
    }
    index = 320;
    while (index <= 327) : (index += 1) {
        instance.array[index] = true;
    }

    // Placeholder: 0. Struct name
    return instance;
}

pub fn deinit(self: *Sundanese) void {
    self.allocator.free(self.array);
}

// isSundanese checks if cp is of the kind Sundanese.
pub fn isSundanese(self: Sundanese, cp: u21) bool {
    if (cp < self.lo or cp > self.hi) return false;
    const index = cp - self.lo;
    return if (index >= self.array.len) false else self.array[index];
}
