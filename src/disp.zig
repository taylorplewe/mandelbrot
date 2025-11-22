const std = @import("std");

var stdout_buf: [1024]u8 = undefined;
var stdout_writer: std.fs.File.Writer = undefined;
var stdout: *std.io.Writer = undefined;

pub fn init() void {
    stdout_writer = std.fs.File.stdout().writer(&stdout_buf);
    stdout = &stdout_writer.interface;
}

pub fn print(comptime msg: []const u8) void {
    stdout.print(msg, .{}) catch unreachable;
    stdout.flush() catch unreachable;
}
