const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const strip = b.option(bool, "strip", "Omit debug information");
    const optimize = b.standardOptimizeOption(.{});

    _ = b.addModule("CasNumber", .{
        .fuzz = true,
        .root_source_file = b.path("src/CasNumber.zig"),
        .target = target,
        .optimize = optimize,
        .strip = strip,
    });

    const unit_tests = b.addTest(.{
        .root_source_file = b.path("src/CasNumber.zig"),
        .target = target,
        .optimize = optimize,
    });

    const run_tests = b.addRunArtifact(unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_tests.step);
}
