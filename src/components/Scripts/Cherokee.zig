// Autogenerated from http://www.unicode.org/Public/UCD/latest/ucd/UnicodeData.txt by running ucd_gen.
// Placeholders:
//    0. Code point type
//    1. Struct name
//    2. Array length
//    3. Highest code point
//    4. Lowest code point
//! Unicode Cherokee code points.

const std = @import("std");
const mem = std.mem;

const Cherokee = @This();

allocator: *mem.Allocator,
array: []bool,
lo: u21 = 5024,
hi: u21 = 43967,

pub fn init(allocator: *mem.Allocator) !Cherokee {
    var instance = Cherokee{
        .allocator = allocator,
        .array = try allocator.alloc(bool, 38944),
    };

    mem.set(bool, instance.array, false);

    var index: u21 = 0;
    index = 0;
    while (index <= 85) : (index += 1) {
        instance.array[index] = true;
    }
    index = 88;
    while (index <= 93) : (index += 1) {
        instance.array[index] = true;
    }
    index = 38864;
    while (index <= 38943) : (index += 1) {
        instance.array[index] = true;
    }

    // Placeholder: 0. Struct name
    return instance;
}

pub fn deinit(self: *Cherokee) void {
    self.allocator.free(self.array);
}

// isCherokee checks if cp is of the kind Cherokee.
pub fn isCherokee(self: Cherokee, cp: u21) bool {
    if (cp < self.lo or cp > self.hi) return false;
    const index = cp - self.lo;
    return if (index >= self.array.len) false else self.array[index];
}
