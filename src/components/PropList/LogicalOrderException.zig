// Autogenerated from http://www.unicode.org/Public/UCD/latest/ucd/UnicodeData.txt by running ucd_gen.
// Placeholders:
//    0. Code point type
//    1. Struct name
//    2. Array length
//    3. Highest code point
//    4. Lowest code point
//! Unicode Logical_Order_Exception code points.

const std = @import("std");
const mem = std.mem;

const LogicalOrderException = @This();

allocator: *mem.Allocator,
array: []bool,
lo: u21 = 3648,
hi: u21 = 43708,

pub fn init(allocator: *mem.Allocator) !LogicalOrderException {
    var instance = LogicalOrderException{
        .allocator = allocator,
        .array = try allocator.alloc(bool, 40061),
    };

    mem.set(bool, instance.array, false);

    var index: u21 = 0;
    index = 0;
    while (index <= 4) : (index += 1) {
        instance.array[index] = true;
    }
    index = 128;
    while (index <= 132) : (index += 1) {
        instance.array[index] = true;
    }
    index = 2933;
    while (index <= 2935) : (index += 1) {
        instance.array[index] = true;
    }
    instance.array[2938] = true;
    index = 40053;
    while (index <= 40054) : (index += 1) {
        instance.array[index] = true;
    }
    instance.array[40057] = true;
    index = 40059;
    while (index <= 40060) : (index += 1) {
        instance.array[index] = true;
    }

    // Placeholder: 0. Struct name
    return instance;
}

pub fn deinit(self: *LogicalOrderException) void {
    self.allocator.free(self.array);
}

// isLogicalOrderException checks if cp is of the kind Logical_Order_Exception.
pub fn isLogicalOrderException(self: LogicalOrderException, cp: u21) bool {
    if (cp < self.lo or cp > self.hi) return false;
    const index = cp - self.lo;
    return if (index >= self.array.len) false else self.array[index];
}
