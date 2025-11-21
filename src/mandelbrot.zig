const std = @import("std");
const graphics = @import("graphics.zig");
const MAX_NUM_ITERATIONS = 1_000;
const OFFSET_X = graphics.WIDTH / 2;
const OFFSET_Y = graphics.HEIGHT / 2;
const SCALE_FACTOR: comptime_float = 4.0;
const SCALE = 1.0 / (@as(comptime_float, @floatFromInt(graphics.WIDTH)) / SCALE_FACTOR);

// z = z^2 + c
// z0 = 0
// z1 = 0 + x + iy
// z2 = (x + iy)(x + iy) + x + iy
//    = x^2 + ixy + ixy + i^2*y^2 + x + iy
//                        i^2 == -1
//    = x^2 + 2ixy - y^2 + x + iy
//    = x^2 - y^2 + 2ixy
//
// x = x^2 - y^2 + x0
// y = 2xy + y0

// https://en.wikipedia.org/wiki/Plotting_algorithms_for_the_Mandelbrot_set#Optimized_escape_time_algorithms
pub fn fillPixelsWithMandelbrot(buf: []graphics.Pixel) void {
    for (0..graphics.HEIGHT) |y_int| {
        for (0..graphics.WIDTH) |x_int| {
            // set starting vars
            var x: f64 = @floatFromInt(x_int);
            var y: f64 = @floatFromInt(y_int);
            x -= @floatFromInt(OFFSET_X);
            y -= @floatFromInt(OFFSET_Y);
            x *= SCALE;
            y *= SCALE;
            const x0 = x;
            const y0 = y;
            var x2 = x * x;
            var y2 = y * y;

            // actual loop
            var iterations: u16 = 0;
            while ((iterations < MAX_NUM_ITERATIONS) and (x2 + y2 <= 4.0)) : (iterations += 1) {
                y = ((x + x) * y) + y0; // 2xy == (x + x)y (thus removing a mul) (see Wikipedia link)
                x = (x2 - y2) + x0;
                x2 = x * x;
                y2 = y * y;
            }

            const col = calculateColor(iterations);

            // draw pixel
            const pixel_ind: usize = (y_int * graphics.WIDTH) + x_int;
            std.debug.assert(pixel_ind < buf.len);
            buf[pixel_ind] = .{
                .r = col,
                .g = col,
                .b = col,
                .a = 255,
            };
        }
    }
}

// generates (1 - (1 / x)) * 255
fn calculateColor(iterations: u16) u8 {
    // const FACTOR = 256.0;

    const max: f32 = @floatFromInt(MAX_NUM_ITERATIONS);
    const iters: f32 = @floatFromInt(iterations);
    var val = iters / max;
    val = std.math.pow(f32, val, 2);
    val *= 255.0;
    val = std.math.pow(f32, val, 1.5);
    val = if (val != 0) @mod(val, 255.0) else 0;

    // calculate color
    // const max: f32 = @floatFromInt(MAX_NUM_ITERATIONS);
    // const iters: f32 = @floatFromInt(iterations);
    // const flipped = max - iters; // MAX_NUM_ITERATIONS - iterations
    // const x = flipped * (1.0 / max);

    // const x_plus_factor_frac = x + (1.0 / FACTOR);
    // const denominator = FACTOR * x_plus_factor_frac;
    // const one_over_x = 1.0 / denominator;
    // const one_minus = 1.0 - one_over_x;

    // const col: u8 = @intFromFloat(one_minus * 255.0);
    const col: u8 = @intFromFloat(val);
    return col;

    // const iterations_f: f32 = @floatFromInt(iterations);
    // const frac = iterations_f / @as(f32, @floatFromInt(MAX_NUM_ITERATIONS));
    // const col_f: f32 = 255.0 - ((iterations_f / @as(f32, @floatFromInt(MAX_NUM_ITERATIONS))) * 255.0);
    // const col: u8 = @intFromFloat(col_f);
    // return col;
}
