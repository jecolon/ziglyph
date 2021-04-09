// Autogenerated from http://www.unicode.org/Public/UCD/latest/ucd/UnicodeData.txt by running ucd_gen.
// Placeholders:
//    0. Code point type
//    1. Struct name
//    2. Array length
//    3. Highest code point
//    4. Lowest code point
//! Unicode Small Kana Extension code points.

const std = @import("std");
const mem = std.mem;

const SmallKanaExtension = @This();

allocator: *mem.Allocator,
array: []bool,
lo: u21 = 110896,
hi: u21 = 110959,

pub fn init(allocator: *mem.Allocator) !SmallKanaExtension {
    var instance = SmallKanaExtension{
        .allocator = allocator,
        .array = try allocator.alloc(bool, 64),
    };

    mem.set(bool, instance.array, false);

    var index: u21 = 0;
    index = 0;
    while (index <= 63) : (index += 1) {
        instance.array[index] = true;
    }

    // Placeholder: 0. Struct name
    return instance;
}

pub fn deinit(self: *SmallKanaExtension) void {
    self.allocator.free(self.array);
}

// isSmallKanaExtension checks if cp is of the kind Small Kana Extension.
pub fn isSmallKanaExtension(self: SmallKanaExtension, cp: u21) bool {
    if (cp < self.lo or cp > self.hi) return false;
    const index = cp - self.lo;
    return if (index >= self.array.len) false else self.array[index];
}
