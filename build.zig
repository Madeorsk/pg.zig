const std = @import("std");

const ModuleMap = std.StringArrayHashMap(*std.Build.Module);
var gpa = std.heap.GeneralPurposeAllocator(.{}){};

pub fn build(b: *std.Build) !void {
	const target = b.standardTargetOptions(.{});
	const optimize = b.standardOptimizeOption(.{});

	_ = b.addModule("pg", .{
		.source_file = .{ .path = "src/pg.zig" },
	});

	const dep_opts = .{.target = target,.optimize = optimize};
	const allocator = gpa.allocator();

	var modules = ModuleMap.init(allocator);
	defer modules.deinit();

	try modules.put("buffer", b.dependency("buffer", dep_opts).module("buffer"));

	const lib_test = b.addTest(.{
		.root_source_file = .{ .path = "src/pg.zig" },
		.target = target,
		.optimize = optimize,
		// .filter = "type support",
		// .test_runner = "test_runner.zig",
	});
	try addLibs(lib_test, modules);

	const run_test = b.addRunArtifact(lib_test);
	run_test.has_side_effects = true;

	const test_step = b.step("test", "Run unit tests");
	test_step.dependOn(&run_test.step);
}

fn addLibs(step: *std.Build.CompileStep, modules: ModuleMap) !void {
	var it = modules.iterator();
	while (it.next()) |m| {
		step.addModule(m.key_ptr.*, m.value_ptr.*);
	}
}