// Autogenerated from http://www.unicode.org/Public/UCD/latest/ucd/UCD.zip by running ucd_gen.sh.
// Placeholders:
//    0. Code point type
//    1. Struct name
//    2. Array length
//    3. Highest code point
//    4. Lowest code point
//! Unicode Makasar code points.

const std = @import("std");
const mem = std.mem;

const Makasar = @This();

allocator: *mem.Allocator,
array: []bool,
lo: u21 = 73440,
hi: u21 = 73471,

pub fn init(allocator: *mem.Allocator) !Makasar {
    var instance = Makasar{
        .allocator = allocator,
        .array = try allocator.alloc(bool, 32),
    };

    mem.set(bool, instance.array, false);

    var index: u21 = 0;
    index = 0;
    while (index <= 31) : (index += 1) {
        instance.array[index] = true;
    }

    // Placeholder: 0. Struct name
    return instance;
}

pub fn deinit(self: *Makasar) void {
    self.allocator.free(self.array);
}

// isMakasar checks if cp is of the kind Makasar.
pub fn isMakasar(self: Makasar, cp: u21) bool {
    if (cp < self.lo or cp > self.hi) return false;
    const index = cp - self.lo;
    return if (index >= self.array.len) false else self.array[index];
}
