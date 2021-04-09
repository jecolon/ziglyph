// Autogenerated from http://www.unicode.org/Public/UCD/latest/ucd/UnicodeData.txt by running ucd_gen.
// Placeholders:
//    0. Code point type
//    1. Struct name
//    2. Array length
//    3. Highest code point
//    4. Lowest code point
//! Unicode Anatolian_Hieroglyphs code points.

const std = @import("std");
const mem = std.mem;

const AnatolianHieroglyphs = @This();

allocator: *mem.Allocator,
array: []bool,
lo: u21 = 82944,
hi: u21 = 83526,

pub fn init(allocator: *mem.Allocator) !AnatolianHieroglyphs {
    var instance = AnatolianHieroglyphs{
        .allocator = allocator,
        .array = try allocator.alloc(bool, 583),
    };

    mem.set(bool, instance.array, false);

    var index: u21 = 0;
    index = 0;
    while (index <= 582) : (index += 1) {
        instance.array[index] = true;
    }

    // Placeholder: 0. Struct name
    return instance;
}

pub fn deinit(self: *AnatolianHieroglyphs) void {
    self.allocator.free(self.array);
}

// isAnatolianHieroglyphs checks if cp is of the kind Anatolian_Hieroglyphs.
pub fn isAnatolianHieroglyphs(self: AnatolianHieroglyphs, cp: u21) bool {
    if (cp < self.lo or cp > self.hi) return false;
    const index = cp - self.lo;
    return if (index >= self.array.len) false else self.array[index];
}
