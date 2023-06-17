const Build = @import("std").Build;

pub fn build(b: *Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    _ = b.addModule("ziglyph", .{
        .source_file = .{ .path = "src/ziglyph.zig" },
    });

    const lib = b.addStaticLibrary(.{
        .name = "ziglyph",
        .root_source_file = .{ .path = "src/ziglyph.zig" },
        .target = target,
        .optimize = optimize,
    });
    b.installArtifact(lib);

    var main_tests = b.addTest(.{
        .root_source_file = .{ .path = "src/tests.zig" },
        .target = target,
        .optimize = optimize,
    });

    const run_tests = b.addRunArtifact(main_tests);
    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&run_tests.step);
}
