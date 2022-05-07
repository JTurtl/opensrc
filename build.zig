const std = @import("std");

pub fn build(b: *std.build.Builder) void {
    const mode = b.standardReleaseOptions();
    const target = b.standardTargetOptions(.{});

    const slib = b.addStaticLibrary("opensrc", "src/staticlib.zig");
    slib.linkLibC();
    slib.addPackagePath("ezdxt", "./lib/ezdxt/src/main.zig");
    slib.setBuildMode(mode);
    slib.setTarget(target);
    slib.install();

    const vpk_tests = b.addTest("src/vpk/tests.zig");
    vpk_tests.setBuildMode(mode);

    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&vpk_tests.step);

    //TODO: example_step: build/run programs in ./examples/
}
