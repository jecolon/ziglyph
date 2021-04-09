// Autogenerated from http://www.unicode.org/Public/UCD/latest/ucd/UnicodeData.txt by running ucd_gen.
// Placeholders:
//    0. Code point type
//    1. Struct name
//    2. Array length
//    3. Highest code point
//    4. Lowest code point
//! Unicode Avestan code points.

const std = @import("std");
const mem = std.mem;

const Avestan = @This();

allocator: *mem.Allocator,
array: []bool,
lo: u21 = 68352,
hi: u21 = 68415,

pub fn init(allocator: *mem.Allocator) !Avestan {
    var instance = Avestan{
        .allocator = allocator,
        .array = try allocator.alloc(bool, 64),
    };

    mem.set(bool, instance.array, false);

    var index: u21 = 0;
    index = 0;
    while (index <= 53) : (index += 1) {
        instance.array[index] = true;
    }
    index = 57;
    while (index <= 63) : (index += 1) {
        instance.array[index] = true;
    }

    // Placeholder: 0. Struct name
    return instance;
}

pub fn deinit(self: *Avestan) void {
    self.allocator.free(self.array);
}

// isAvestan checks if cp is of the kind Avestan.
pub fn isAvestan(self: Avestan, cp: u21) bool {
    if (cp < self.lo or cp > self.hi) return false;
    const index = cp - self.lo;
    return if (index >= self.array.len) false else self.array[index];
}
