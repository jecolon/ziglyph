// Autogenerated from http://www.unicode.org/Public/UCD/latest/ucd/UCD.zip by running ucd_gen.sh.
// Placeholders:
//    0. Code point type
//    1. Struct name
//    2. Array length
//    3. Highest code point
//    4. Lowest code point
//! Unicode Nobreak code points.

const std = @import("std");
const mem = std.mem;

const Nobreak = @This();

allocator: *mem.Allocator,
array: []bool,
lo: u21 = 160,
hi: u21 = 8239,

pub fn init(allocator: *mem.Allocator) !Nobreak {
    var instance = Nobreak{
        .allocator = allocator,
        .array = try allocator.alloc(bool, 8080),
    };

    mem.set(bool, instance.array, false);

    var index: u21 = 0;
    instance.array[0] = true;
    instance.array[3692] = true;
    instance.array[8039] = true;
    instance.array[8049] = true;
    instance.array[8079] = true;

    // Placeholder: 0. Struct name
    return instance;
}

pub fn deinit(self: *Nobreak) void {
    self.allocator.free(self.array);
}

// isNobreak checks if cp is of the kind Nobreak.
pub fn isNobreak(self: Nobreak, cp: u21) bool {
    if (cp < self.lo or cp > self.hi) return false;
    const index = cp - self.lo;
    return if (index >= self.array.len) false else self.array[index];
}
