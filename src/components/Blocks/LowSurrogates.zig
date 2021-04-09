// Autogenerated from http://www.unicode.org/Public/UCD/latest/ucd/UCD.zip by running ucd_gen.sh.
// Placeholders:
//    0. Code point type
//    1. Struct name
//    2. Array length
//    3. Highest code point
//    4. Lowest code point
//! Unicode Low Surrogates code points.

const std = @import("std");
const mem = std.mem;

const LowSurrogates = @This();

allocator: *mem.Allocator,
array: []bool,
lo: u21 = 56320,
hi: u21 = 57343,

pub fn init(allocator: *mem.Allocator) !LowSurrogates {
    var instance = LowSurrogates{
        .allocator = allocator,
        .array = try allocator.alloc(bool, 1024),
    };

    mem.set(bool, instance.array, false);

    var index: u21 = 0;
    index = 0;
    while (index <= 1023) : (index += 1) {
        instance.array[index] = true;
    }

    // Placeholder: 0. Struct name
    return instance;
}

pub fn deinit(self: *LowSurrogates) void {
    self.allocator.free(self.array);
}

// isLowSurrogates checks if cp is of the kind Low Surrogates.
pub fn isLowSurrogates(self: LowSurrogates, cp: u21) bool {
    if (cp < self.lo or cp > self.hi) return false;
    const index = cp - self.lo;
    return if (index >= self.array.len) false else self.array[index];
}
