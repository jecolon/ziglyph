// Autogenerated from http://www.unicode.org/Public/UCD/latest/ucd/UCD.zip by running ucd_gen.sh.
// Placeholders:
//    0. Code point type
//    1. Struct name
//    2. Array length
//    3. Highest code point
//    4. Lowest code point
//! Unicode Small Form Variants code points.

const std = @import("std");
const mem = std.mem;

const SmallFormVariants = @This();

allocator: *mem.Allocator,
array: []bool,
lo: u21 = 65104,
hi: u21 = 65135,

pub fn init(allocator: *mem.Allocator) !SmallFormVariants {
    var instance = SmallFormVariants{
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

pub fn deinit(self: *SmallFormVariants) void {
    self.allocator.free(self.array);
}

// isSmallFormVariants checks if cp is of the kind Small Form Variants.
pub fn isSmallFormVariants(self: SmallFormVariants, cp: u21) bool {
    if (cp < self.lo or cp > self.hi) return false;
    const index = cp - self.lo;
    return if (index >= self.array.len) false else self.array[index];
}
