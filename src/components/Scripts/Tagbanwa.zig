// Autogenerated from http://www.unicode.org/Public/UCD/latest/ucd/UCD.zip by running ucd_gen.sh.
// Placeholders:
//    0. Code point type
//    1. Struct name
//    2. Array length
//    3. Highest code point
//    4. Lowest code point
//! Unicode Tagbanwa code points.

const std = @import("std");
const mem = std.mem;

const Tagbanwa = @This();

allocator: *mem.Allocator,
array: []bool,
lo: u21 = 5984,
hi: u21 = 6003,

pub fn init(allocator: *mem.Allocator) !Tagbanwa {
    var instance = Tagbanwa{
        .allocator = allocator,
        .array = try allocator.alloc(bool, 20),
    };

    mem.set(bool, instance.array, false);

    var index: u21 = 0;
    index = 0;
    while (index <= 12) : (index += 1) {
        instance.array[index] = true;
    }
    index = 14;
    while (index <= 16) : (index += 1) {
        instance.array[index] = true;
    }
    index = 18;
    while (index <= 19) : (index += 1) {
        instance.array[index] = true;
    }

    // Placeholder: 0. Struct name
    return instance;
}

pub fn deinit(self: *Tagbanwa) void {
    self.allocator.free(self.array);
}

// isTagbanwa checks if cp is of the kind Tagbanwa.
pub fn isTagbanwa(self: Tagbanwa, cp: u21) bool {
    if (cp < self.lo or cp > self.hi) return false;
    const index = cp - self.lo;
    return if (index >= self.array.len) false else self.array[index];
}
