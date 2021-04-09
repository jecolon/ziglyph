// Autogenerated from http://www.unicode.org/Public/UCD/latest/ucd/UCD.zip by running ucd_gen.sh.
// Placeholders:
//    0. Code point type
//    1. Struct name
//    2. Array length
//    3. Highest code point
//    4. Lowest code point
//! Unicode Egyptian Hieroglyph Format Controls code points.

const std = @import("std");
const mem = std.mem;

const EgyptianHieroglyphFormatControls = @This();

allocator: *mem.Allocator,
array: []bool,
lo: u21 = 78896,
hi: u21 = 78911,

pub fn init(allocator: *mem.Allocator) !EgyptianHieroglyphFormatControls {
    var instance = EgyptianHieroglyphFormatControls{
        .allocator = allocator,
        .array = try allocator.alloc(bool, 16),
    };

    mem.set(bool, instance.array, false);

    var index: u21 = 0;
    index = 0;
    while (index <= 15) : (index += 1) {
        instance.array[index] = true;
    }

    // Placeholder: 0. Struct name
    return instance;
}

pub fn deinit(self: *EgyptianHieroglyphFormatControls) void {
    self.allocator.free(self.array);
}

// isEgyptianHieroglyphFormatControls checks if cp is of the kind Egyptian Hieroglyph Format Controls.
pub fn isEgyptianHieroglyphFormatControls(self: EgyptianHieroglyphFormatControls, cp: u21) bool {
    if (cp < self.lo or cp > self.hi) return false;
    const index = cp - self.lo;
    return if (index >= self.array.len) false else self.array[index];
}
