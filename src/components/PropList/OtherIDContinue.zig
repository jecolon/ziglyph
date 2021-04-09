// Autogenerated from http://www.unicode.org/Public/UCD/latest/ucd/UCD.zip by running ucd_gen.sh.
// Placeholders:
//    0. Code point type
//    1. Struct name
//    2. Array length
//    3. Highest code point
//    4. Lowest code point
//! Unicode Other_ID_Continue code points.

const std = @import("std");
const mem = std.mem;

const OtherIDContinue = @This();

allocator: *mem.Allocator,
array: []bool,
lo: u21 = 183,
hi: u21 = 6618,

pub fn init(allocator: *mem.Allocator) !OtherIDContinue {
    var instance = OtherIDContinue{
        .allocator = allocator,
        .array = try allocator.alloc(bool, 6436),
    };

    mem.set(bool, instance.array, false);

    var index: u21 = 0;
    instance.array[0] = true;
    instance.array[720] = true;
    index = 4786;
    while (index <= 4794) : (index += 1) {
        instance.array[index] = true;
    }
    instance.array[6435] = true;

    // Placeholder: 0. Struct name
    return instance;
}

pub fn deinit(self: *OtherIDContinue) void {
    self.allocator.free(self.array);
}

// isOtherIDContinue checks if cp is of the kind Other_ID_Continue.
pub fn isOtherIDContinue(self: OtherIDContinue, cp: u21) bool {
    if (cp < self.lo or cp > self.hi) return false;
    const index = cp - self.lo;
    return if (index >= self.array.len) false else self.array[index];
}
