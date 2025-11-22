const std = @import("std");

var buf: [1024]u8 = undefined;

var stdout_writer: std.fs.File.Writer = undefined;
var stdout: *std.io.Writer = undefined;

var stderr_writer: std.fs.File.Writer = undefined;
var stderr: *std.io.Writer = undefined;

pub fn init() void {
    stdout_writer = std.fs.File.stdout().writer(&buf);
    stdout = &stdout_writer.interface;
    stderr_writer = std.fs.File.stderr().writer(&buf);
    stderr = &stderr_writer.interface;
}

pub fn print(comptime msg: []const u8) void {
    defer stdout.flush() catch unreachable;
    stdout.print(msg, .{}) catch unreachable;
}

pub fn printErrorAndBounceErrorCode(comptime msg: []const u8, comptime err_code: i32) i32 {
    defer stderr.flush() catch unreachable;
    stderr.print("\x1b[31merror\x1b[0m - {s}\n", .{msg}) catch unreachable;
    return err_code;
}
