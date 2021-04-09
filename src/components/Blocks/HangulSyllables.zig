// Autogenerated from http://www.unicode.org/Public/UCD/latest/ucd/UnicodeData.txt by running ucd_gen.
// Placeholders:
//    0. Code point type
//    1. Struct name
//    2. Array length
//    3. Highest code point
//    4. Lowest code point
//! Unicode Hangul Syllables code points.

const std = @import("std");
const mem = std.mem;

const HangulSyllables = @This();

allocator: *mem.Allocator,
array: []bool,
lo: u21 = 44032,
hi: u21 = 55215,

pub fn init(allocator: *mem.Allocator) !HangulSyllables {
    var instance = HangulSyllables{
        .allocator = allocator,
        .array = try allocator.alloc(bool, 11184),
    };

    mem.set(bool, instance.array, false);

    var index: u21 = 0;
    index = 0;
    while (index <= 11183) : (index += 1) {
        instance.array[index] = true;
    }

    // Placeholder: 0. Struct name
    return instance;
}

pub fn deinit(self: *HangulSyllables) void {
    self.allocator.free(self.array);
}

// isHangulSyllables checks if cp is of the kind Hangul Syllables.
pub fn isHangulSyllables(self: HangulSyllables, cp: u21) bool {
    if (cp < self.lo or cp > self.hi) return false;
    const index = cp - self.lo;
    return if (index >= self.array.len) false else self.array[index];
}
