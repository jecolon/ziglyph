// Autogenerated from http://www.unicode.org/Public/UCD/latest/ucd/UnicodeData.txt by running ucd_gen.
// Placeholders:
//    0. Code point type
//    1. Struct name
//    2. Array length
//    3. Highest code point
//    4. Lowest code point
//! Unicode Ahom code points.

const std = @import("std");
const mem = std.mem;

const Ahom = @This();

allocator: *mem.Allocator,
array: []bool,
lo: u21 = 71424,
hi: u21 = 71487,

pub fn init(allocator: *mem.Allocator) !Ahom {
    var instance = Ahom{
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

pub fn deinit(self: *Ahom) void {
    self.allocator.free(self.array);
}

// isAhom checks if cp is of the kind Ahom.
pub fn isAhom(self: Ahom, cp: u21) bool {
    if (cp < self.lo or cp > self.hi) return false;
    const index = cp - self.lo;
    return if (index >= self.array.len) false else self.array[index];
}
