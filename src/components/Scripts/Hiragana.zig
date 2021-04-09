// Autogenerated from http://www.unicode.org/Public/UCD/latest/ucd/UnicodeData.txt by running ucd_gen.
// Placeholders:
//    0. Code point type
//    1. Struct name
//    2. Array length
//    3. Highest code point
//    4. Lowest code point
//! Unicode Hiragana code points.

const std = @import("std");
const mem = std.mem;

const Hiragana = @This();

allocator: *mem.Allocator,
array: []bool,
lo: u21 = 12353,
hi: u21 = 127488,

pub fn init(allocator: *mem.Allocator) !Hiragana {
    var instance = Hiragana{
        .allocator = allocator,
        .array = try allocator.alloc(bool, 115136),
    };

    mem.set(bool, instance.array, false);

    var index: u21 = 0;
    index = 0;
    while (index <= 85) : (index += 1) {
        instance.array[index] = true;
    }
    index = 92;
    while (index <= 93) : (index += 1) {
        instance.array[index] = true;
    }
    instance.array[94] = true;
    index = 98240;
    while (index <= 98525) : (index += 1) {
        instance.array[index] = true;
    }
    index = 98575;
    while (index <= 98577) : (index += 1) {
        instance.array[index] = true;
    }
    instance.array[115135] = true;

    // Placeholder: 0. Struct name
    return instance;
}

pub fn deinit(self: *Hiragana) void {
    self.allocator.free(self.array);
}

// isHiragana checks if cp is of the kind Hiragana.
pub fn isHiragana(self: Hiragana, cp: u21) bool {
    if (cp < self.lo or cp > self.hi) return false;
    const index = cp - self.lo;
    return if (index >= self.array.len) false else self.array[index];
}
