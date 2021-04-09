// Autogenerated from http://www.unicode.org/Public/UCD/latest/ucd/UnicodeData.txt by running ucd_gen.
// Placeholders:
//    0. Code point type
//    1. Struct name
//    2. Array length
//    3. Highest code point
//    4. Lowest code point
//! Unicode Inscriptional Pahlavi code points.

const std = @import("std");
const mem = std.mem;

const InscriptionalPahlavi = @This();

allocator: *mem.Allocator,
array: []bool,
lo: u21 = 68448,
hi: u21 = 68479,

pub fn init(allocator: *mem.Allocator) !InscriptionalPahlavi {
    var instance = InscriptionalPahlavi{
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

pub fn deinit(self: *InscriptionalPahlavi) void {
    self.allocator.free(self.array);
}

// isInscriptionalPahlavi checks if cp is of the kind Inscriptional Pahlavi.
pub fn isInscriptionalPahlavi(self: InscriptionalPahlavi, cp: u21) bool {
    if (cp < self.lo or cp > self.hi) return false;
    const index = cp - self.lo;
    return if (index >= self.array.len) false else self.array[index];
}
