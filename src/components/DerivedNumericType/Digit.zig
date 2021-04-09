// Autogenerated from http://www.unicode.org/Public/UCD/latest/ucd/UnicodeData.txt by running ucd_gen.
// Placeholders:
//    0. Code point type
//    1. Struct name
//    2. Array length
//    3. Highest code point
//    4. Lowest code point
//! Unicode Digit code points.

const std = @import("std");
const mem = std.mem;

const Digit = @This();

allocator: *mem.Allocator,
array: []bool,
lo: u21 = 178,
hi: u21 = 127242,

pub fn init(allocator: *mem.Allocator) !Digit {
    var instance = Digit{
        .allocator = allocator,
        .array = try allocator.alloc(bool, 127065),
    };

    mem.set(bool, instance.array, false);

    var index: u21 = 0;
    index = 0;
    while (index <= 1) : (index += 1) {
        instance.array[index] = true;
    }
    instance.array[7] = true;
    index = 4791;
    while (index <= 4799) : (index += 1) {
        instance.array[index] = true;
    }
    instance.array[6440] = true;
    instance.array[8126] = true;
    index = 8130;
    while (index <= 8135) : (index += 1) {
        instance.array[index] = true;
    }
    index = 8142;
    while (index <= 8151) : (index += 1) {
        instance.array[index] = true;
    }
    index = 9134;
    while (index <= 9142) : (index += 1) {
        instance.array[index] = true;
    }
    index = 9154;
    while (index <= 9162) : (index += 1) {
        instance.array[index] = true;
    }
    index = 9174;
    while (index <= 9182) : (index += 1) {
        instance.array[index] = true;
    }
    instance.array[9272] = true;
    index = 9283;
    while (index <= 9291) : (index += 1) {
        instance.array[index] = true;
    }
    instance.array[9293] = true;
    index = 9924;
    while (index <= 9932) : (index += 1) {
        instance.array[index] = true;
    }
    index = 9934;
    while (index <= 9942) : (index += 1) {
        instance.array[index] = true;
    }
    index = 9944;
    while (index <= 9952) : (index += 1) {
        instance.array[index] = true;
    }
    index = 67982;
    while (index <= 67985) : (index += 1) {
        instance.array[index] = true;
    }
    index = 69038;
    while (index <= 69046) : (index += 1) {
        instance.array[index] = true;
    }
    index = 69536;
    while (index <= 69544) : (index += 1) {
        instance.array[index] = true;
    }
    index = 127054;
    while (index <= 127064) : (index += 1) {
        instance.array[index] = true;
    }

    // Placeholder: 0. Struct name
    return instance;
}

pub fn deinit(self: *Digit) void {
    self.allocator.free(self.array);
}

// isDigit checks if cp is of the kind Digit.
pub fn isDigit(self: Digit, cp: u21) bool {
    if (cp < self.lo or cp > self.hi) return false;
    const index = cp - self.lo;
    return if (index >= self.array.len) false else self.array[index];
}
