const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // The `texpack` module — sprite-atlas packer. Consumers (labelle-cli,
    // labelle-gui) depend on this package and import this module. It owns
    // the vendored stb C wiring (PNG decode + encode); the symbols link
    // in transitively, so importers must not compile the stb impl again.
    const mod = b.addModule("texpack", .{
        .root_source_file = b.path("src/texpack.zig"),
        .target = target,
        .optimize = optimize,
    });
    mod.addCSourceFile(.{
        .file = b.path("vendor/stb_image_impl.c"),
        .flags = &.{"-std=c99"},
    });
    mod.addIncludePath(b.path("vendor"));
    mod.link_libc = true;

    const tests = b.addTest(.{ .root_module = mod });
    const run_tests = b.addRunArtifact(tests);
    const test_step = b.step("test", "Run texpack tests");
    test_step.dependOn(&run_tests.step);
}
