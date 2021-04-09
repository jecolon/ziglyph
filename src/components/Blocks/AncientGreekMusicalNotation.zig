// Autogenerated from http://www.unicode.org/Public/UCD/latest/ucd/UnicodeData.txt by running ucd_gen.
// Placeholders:
//    0. Code point type
//    1. Struct name
//    2. Array length
//    3. Highest code point
//    4. Lowest code point
//! Unicode Ancient Greek Musical Notation code points.

const std = @import("std");
const mem = std.mem;

const AncientGreekMusicalNotation = @This();

allocator: *mem.Allocator,
array: []bool,
lo: u21 = 119296,
hi: u21 = 119375,

pub fn init(allocator: *mem.Allocator) !AncientGreekMusicalNotation {
    var instance = AncientGreekMusicalNotation{
        .allocator = allocator,
        .array = try allocator.alloc(bool, 80),
    };

    mem.set(bool, instance.array, false);

    var index: u21 = 0;
    index = 0;
    while (index <= 79) : (index += 1) {
        instance.array[index] = true;
    }

    // Placeholder: 0. Struct name
    return instance;
}

pub fn deinit(self: *AncientGreekMusicalNotation) void {
    self.allocator.free(self.array);
}

// isAncientGreekMusicalNotation checks if cp is of the kind Ancient Greek Musical Notation.
pub fn isAncientGreekMusicalNotation(self: AncientGreekMusicalNotation, cp: u21) bool {
    if (cp < self.lo or cp > self.hi) return false;
    const index = cp - self.lo;
    return if (index >= self.array.len) false else self.array[index];
}
