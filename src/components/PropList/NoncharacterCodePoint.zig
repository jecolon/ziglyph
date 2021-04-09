// Autogenerated from http://www.unicode.org/Public/UCD/latest/ucd/UnicodeData.txt by running ucd_gen.
// Placeholders:
//    0. Code point type
//    1. Struct name
//    2. Array length
//    3. Highest code point
//    4. Lowest code point
//! Unicode Noncharacter_Code_Point code points.

const std = @import("std");
const mem = std.mem;

const NoncharacterCodePoint = @This();

allocator: *mem.Allocator,
array: []bool,
lo: u21 = 64976,
hi: u21 = 1114111,

pub fn init(allocator: *mem.Allocator) !NoncharacterCodePoint {
    var instance = NoncharacterCodePoint{
        .allocator = allocator,
        .array = try allocator.alloc(bool, 1049136),
    };

    mem.set(bool, instance.array, false);

    var index: u21 = 0;
    index = 0;
    while (index <= 31) : (index += 1) {
        instance.array[index] = true;
    }
    index = 558;
    while (index <= 559) : (index += 1) {
        instance.array[index] = true;
    }
    index = 66094;
    while (index <= 66095) : (index += 1) {
        instance.array[index] = true;
    }
    index = 131630;
    while (index <= 131631) : (index += 1) {
        instance.array[index] = true;
    }
    index = 197166;
    while (index <= 197167) : (index += 1) {
        instance.array[index] = true;
    }
    index = 262702;
    while (index <= 262703) : (index += 1) {
        instance.array[index] = true;
    }
    index = 328238;
    while (index <= 328239) : (index += 1) {
        instance.array[index] = true;
    }
    index = 393774;
    while (index <= 393775) : (index += 1) {
        instance.array[index] = true;
    }
    index = 459310;
    while (index <= 459311) : (index += 1) {
        instance.array[index] = true;
    }
    index = 524846;
    while (index <= 524847) : (index += 1) {
        instance.array[index] = true;
    }
    index = 590382;
    while (index <= 590383) : (index += 1) {
        instance.array[index] = true;
    }
    index = 655918;
    while (index <= 655919) : (index += 1) {
        instance.array[index] = true;
    }
    index = 721454;
    while (index <= 721455) : (index += 1) {
        instance.array[index] = true;
    }
    index = 786990;
    while (index <= 786991) : (index += 1) {
        instance.array[index] = true;
    }
    index = 852526;
    while (index <= 852527) : (index += 1) {
        instance.array[index] = true;
    }
    index = 918062;
    while (index <= 918063) : (index += 1) {
        instance.array[index] = true;
    }
    index = 983598;
    while (index <= 983599) : (index += 1) {
        instance.array[index] = true;
    }
    index = 1049134;
    while (index <= 1049135) : (index += 1) {
        instance.array[index] = true;
    }

    // Placeholder: 0. Struct name
    return instance;
}

pub fn deinit(self: *NoncharacterCodePoint) void {
    self.allocator.free(self.array);
}

// isNoncharacterCodePoint checks if cp is of the kind Noncharacter_Code_Point.
pub fn isNoncharacterCodePoint(self: NoncharacterCodePoint, cp: u21) bool {
    if (cp < self.lo or cp > self.hi) return false;
    const index = cp - self.lo;
    return if (index >= self.array.len) false else self.array[index];
}
