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
    wireStb(b, mod);

    // Tests use zspec. It's a dev-only dependency: wired into the test
    // module below, NOT into the public `texpack` module — consumers
    // never pull zspec. The `@import("zspec")` in the source files is
    // referenced only from `test` blocks, so non-test builds (a consumer
    // compiling `texpack`) never resolve it.
    const zspec_dep = b.dependency("zspec", .{ .target = target, .optimize = optimize });
    const test_mod = b.createModule(.{
        .root_source_file = b.path("src/texpack.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{ .name = "zspec", .module = zspec_dep.module("zspec") },
        },
    });
    wireStb(b, test_mod);

    const tests = b.addTest(.{ .root_module = test_mod });
    const run_tests = b.addRunArtifact(tests);
    const test_step = b.step("test", "Run texpack tests");
    test_step.dependOn(&run_tests.step);
}

/// Attach the vendored stb C implementation + header include path.
fn wireStb(b: *std.Build, mod: *std.Build.Module) void {
    mod.addCSourceFile(.{
        .file = b.path("vendor/stb_image_impl.c"),
        .flags = &.{"-std=c99"},
    });
    mod.addIncludePath(b.path("vendor"));
    mod.link_libc = true;
}
