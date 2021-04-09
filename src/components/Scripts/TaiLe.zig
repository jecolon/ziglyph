// Autogenerated from http://www.unicode.org/Public/UCD/latest/ucd/UnicodeData.txt by running ucd_gen.
// Placeholders:
//    0. Code point type
//    1. Struct name
//    2. Array length
//    3. Highest code point
//    4. Lowest code point
//! Unicode Tai_Le code points.

const std = @import("std");
const mem = std.mem;

const TaiLe = @This();

allocator: *mem.Allocator,
array: []bool,
lo: u21 = 6480,
hi: u21 = 6516,

pub fn init(allocator: *mem.Allocator) !TaiLe {
    var instance = TaiLe{
        .allocator = allocator,
        .array = try allocator.alloc(bool, 37),
    };

    mem.set(bool, instance.array, false);

    var index: u21 = 0;
    index = 0;
    while (index <= 29) : (index += 1) {
        instance.array[index] = true;
    }
    index = 32;
    while (index <= 36) : (index += 1) {
        instance.array[index] = true;
    }

    // Placeholder: 0. Struct name
    return instance;
}

pub fn deinit(self: *TaiLe) void {
    self.allocator.free(self.array);
}

// isTaiLe checks if cp is of the kind Tai_Le.
pub fn isTaiLe(self: TaiLe, cp: u21) bool {
    if (cp < self.lo or cp > self.hi) return false;
    const index = cp - self.lo;
    return if (index >= self.array.len) false else self.array[index];
}
