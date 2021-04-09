// Autogenerated from http://www.unicode.org/Public/UCD/latest/ucd/UnicodeData.txt by running ucd_gen.
// Placeholders:
//    0. Code point type
//    1. Struct name
//    2. Array length
//    3. Highest code point
//    4. Lowest code point
//! Unicode Adlam code points.

const std = @import("std");
const mem = std.mem;

const Adlam = @This();

allocator: *mem.Allocator,
array: []bool,
lo: u21 = 125184,
hi: u21 = 125279,

pub fn init(allocator: *mem.Allocator) !Adlam {
    var instance = Adlam{
        .allocator = allocator,
        .array = try allocator.alloc(bool, 96),
    };

    mem.set(bool, instance.array, false);

    var index: u21 = 0;
    index = 0;
    while (index <= 67) : (index += 1) {
        instance.array[index] = true;
    }
    index = 68;
    while (index <= 74) : (index += 1) {
        instance.array[index] = true;
    }
    instance.array[75] = true;
    index = 80;
    while (index <= 89) : (index += 1) {
        instance.array[index] = true;
    }
    index = 94;
    while (index <= 95) : (index += 1) {
        instance.array[index] = true;
    }

    // Placeholder: 0. Struct name
    return instance;
}

pub fn deinit(self: *Adlam) void {
    self.allocator.free(self.array);
}

// isAdlam checks if cp is of the kind Adlam.
pub fn isAdlam(self: Adlam, cp: u21) bool {
    if (cp < self.lo or cp > self.hi) return false;
    const index = cp - self.lo;
    return if (index >= self.array.len) false else self.array[index];
}
