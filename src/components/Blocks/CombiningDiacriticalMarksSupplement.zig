// Autogenerated from http://www.unicode.org/Public/UCD/latest/ucd/UCD.zip by running ucd_gen.sh.
// Placeholders:
//    0. Code point type
//    1. Struct name
//    2. Array length
//    3. Highest code point
//    4. Lowest code point
//! Unicode Combining Diacritical Marks Supplement code points.

const std = @import("std");
const mem = std.mem;

const CombiningDiacriticalMarksSupplement = @This();

allocator: *mem.Allocator,
array: []bool,
lo: u21 = 7616,
hi: u21 = 7679,

pub fn init(allocator: *mem.Allocator) !CombiningDiacriticalMarksSupplement {
    var instance = CombiningDiacriticalMarksSupplement{
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

pub fn deinit(self: *CombiningDiacriticalMarksSupplement) void {
    self.allocator.free(self.array);
}

// isCombiningDiacriticalMarksSupplement checks if cp is of the kind Combining Diacritical Marks Supplement.
pub fn isCombiningDiacriticalMarksSupplement(self: CombiningDiacriticalMarksSupplement, cp: u21) bool {
    if (cp < self.lo or cp > self.hi) return false;
    const index = cp - self.lo;
    return if (index >= self.array.len) false else self.array[index];
}
