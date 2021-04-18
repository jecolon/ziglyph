const std = @import("std");
const expect = std.testing.expect;
const expectEqual = std.testing.expectEqual;
const expectEqualSlices = std.testing.expectEqualSlices;

// Import struct.
const DecomposeMap = @import("ziglyph.zig").DecomposeMap;
const Decomposed = DecomposeMap.Decomposed;

test "decomposeTo D" {
    var allocator = std.testing.allocator;
    var z = try DecomposeMap.init(allocator);
    defer z.deinit();

    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    var arena_allocator = &arena.allocator;

    // CD: ox03D3 -> 0x03D2, 0x0301
    var src = [1]Decomposed{.{ .src = '\u{03D3}' }};
    var result = try z.decomposeTo(arena_allocator, .D, &src);
    expectEqual(result.len, 2);
    expectEqual(result[0].same, 0x03D2);
    expectEqual(result[1].same, 0x0301);
}

test "decomposeTo KD" {
    var allocator = std.testing.allocator;
    var z = try DecomposeMap.init(allocator);
    defer z.deinit();

    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    var arena_allocator = &arena.allocator;

    // KD: ox03D3 -> 0x03D2, 0x0301 -> 0x03A5, 0x0301
    var src = [1]Decomposed{.{ .src = '\u{03D3}' }};
    var result = try z.decomposeTo(arena_allocator, .KD, &src);
    expectEqual(result.len, 2);
    expect(result[0] == .same);
    expectEqual(result[0].same, 0x03A5);
    expect(result[1] == .same);
    expectEqual(result[1].same, 0x0301);
}

test "normalizeTo" {
    var allocator = std.testing.allocator;
    var z = try DecomposeMap.init(allocator);
    defer z.deinit();

    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    var arena_allocator = &arena.allocator;

    // Canonical (NFD)
    var input = "Complex char: \u{03D3}";
    var want = "Complex char: \u{03D2}\u{0301}";
    var got = try z.normalizeTo(arena_allocator, .D, input);
    expectEqualSlices(u8, want, got);

    // Compatibility (NFKD)
    input = "Complex char: \u{03D3}";
    want = "Complex char: \u{03A5}\u{0301}";
    got = try z.normalizeTo(arena_allocator, .KD, input);
    expectEqualSlices(u8, want, got);
}
