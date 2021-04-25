const Builder = @import("std").build.Builder;

pub fn build(b: *Builder) void {
    const mode = b.standardReleaseOptions();
    const lib = b.addStaticLibrary("ziglyph", "src/main.zig");
    lib.setBuildMode(mode);
    lib.install();

    var main_tests = b.addTest("src/main.zig");
    main_tests.setBuildMode(mode);
    var readme_tests = b.addTest("src/readme_tests.zig");
    readme_tests.setBuildMode(mode);
    var zigstr_readme_tests = b.addTest("src/zigstr_readme_tests.zig");
    zigstr_readme_tests.setBuildMode(mode);

    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&main_tests.step);
    test_step.dependOn(&readme_tests.step);
    test_step.dependOn(&zigstr_readme_tests.step);
}
