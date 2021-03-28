start: u21,
end: u21,

const Range = @This();

pub fn new(start: u21, end: u21) Range {
    return .{
        .start = start,
        .end = end,
    };
}
