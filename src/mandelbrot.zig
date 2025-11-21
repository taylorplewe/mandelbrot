const std = @import("std");
const graphics = @import("graphics.zig");
const MAX_NUM_ITERATIONS = 1_000;
const OFFSET_X: comptime_float = graphics.WIDTH / 2;
const OFFSET_Y: comptime_float = graphics.HEIGHT / 2;
const SCALE: comptime_float = 1.0 / OFFSET_X;

// z = z^2 + c
// z0 = 0
// z1 = 0 + x + iy
// z2 = (x + iy)(x + iy) + x + iy
//    = x^2 + ixy + ixy + i^2*y^2 + x + iy
//    = x^2 + 2ixy - y^2 + x + iy
//    = x^2 - y^2 + 2ixy
//
// x = x^2 - y^2
// y = 2xy

// https://en.wikipedia.org/wiki/Plotting_algorithms_for_the_Mandelbrot_set#Optimized_escape_time_algorithms
pub fn fillPixelsWithMandelbrot(buf: []graphics.Pixel) void {
    for (0..graphics.HEIGHT) |y_int| {
        for (0..graphics.WIDTH) |x_int| {
            var x: f64 = @floatFromInt(x_int);
            var y: f64 = @floatFromInt(y_int);
            x = (x - OFFSET_X) * SCALE;
            y = (x - OFFSET_Y) * SCALE;
            var x2 = x * x;
            var y2 = y * y;
            var iterations: u16 = 0;
            while ((iterations < MAX_NUM_ITERATIONS) and (x2 + y2 <= 4.0)) : (iterations += 1) {
                y = (x + x) * y; // 2xy == (x + x)y (thus removing a mul) (see Wikipedia link)
                x = x2 - y2;
                x2 = x * x;
                y2 = y * y;
            }

            const iterations_f: f32 = @floatFromInt(iterations);
            const col_f: f32 = 255.0 - ((iterations_f / @as(f32, @floatFromInt(MAX_NUM_ITERATIONS))) * 255.0);
            const col: u8 = @intFromFloat(col_f);
            if (x_int % 128 == 0 and y_int % 128 == 0) {
                std.debug.print("col: {}\n", .{col});
            }
            // _ = col;
            const pixel_ind: usize = (y_int * graphics.WIDTH) + x_int;
            // if (pixel_ind < buf.len) {
            std.debug.assert(pixel_ind < buf.len);
            buf[pixel_ind] = .{
                .r = col,
                .g = col,
                .b = col,
                .a = 255,
            };
            // }
        }
    }
}
