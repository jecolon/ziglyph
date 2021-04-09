// Autogenerated from http://www.unicode.org/Public/UCD/latest/ucd/UCD.zip by running ucd_gen.sh.
// Placeholders:
//    0. Code point type
//    1. Struct name
//    2. Array length
//    3. Highest code point
//    4. Lowest code point
//! Unicode Myanmar Extended-B code points.

const std = @import("std");
const mem = std.mem;

const MyanmarExtendedBª = @This();

allocator: *mem.Allocator,
array: []bool,
lo: u21 = 43488,
hi: u21 = 43519,

pub fn init(allocator: *mem.Allocator) !MyanmarExtendedBª {
    var instance = MyanmarExtendedBª{
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

pub fn deinit(self: *MyanmarExtendedBª) void {
    self.allocator.free(self.array);
}

// isMyanmarExtendedBª checks if cp is of the kind Myanmar Extended-B.
pub fn isMyanmarExtendedBª(self: MyanmarExtendedBª, cp: u21) bool {
    if (cp < self.lo or cp > self.hi) return false;
    const index = cp - self.lo;
    return if (index >= self.array.len) false else self.array[index];
}
