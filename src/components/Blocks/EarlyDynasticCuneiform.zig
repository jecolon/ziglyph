// Autogenerated from http://www.unicode.org/Public/UCD/latest/ucd/UCD.zip by running ucd_gen.sh.
// Placeholders:
//    0. Code point type
//    1. Struct name
//    2. Array length
//    3. Highest code point
//    4. Lowest code point
//! Unicode Early Dynastic Cuneiform code points.

const std = @import("std");
const mem = std.mem;

const EarlyDynasticCuneiform = @This();

allocator: *mem.Allocator,
array: []bool,
lo: u21 = 74880,
hi: u21 = 75087,

pub fn init(allocator: *mem.Allocator) !EarlyDynasticCuneiform {
    var instance = EarlyDynasticCuneiform{
        .allocator = allocator,
        .array = try allocator.alloc(bool, 208),
    };

    mem.set(bool, instance.array, false);

    var index: u21 = 0;
    index = 0;
    while (index <= 207) : (index += 1) {
        instance.array[index] = true;
    }

    // Placeholder: 0. Struct name
    return instance;
}

pub fn deinit(self: *EarlyDynasticCuneiform) void {
    self.allocator.free(self.array);
}

// isEarlyDynasticCuneiform checks if cp is of the kind Early Dynastic Cuneiform.
pub fn isEarlyDynasticCuneiform(self: EarlyDynasticCuneiform, cp: u21) bool {
    if (cp < self.lo or cp > self.hi) return false;
    const index = cp - self.lo;
    return if (index >= self.array.len) false else self.array[index];
}
