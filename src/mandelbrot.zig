const std = @import("std");
const shared = @import("shared.zig");
const MAX_NUM_ITERATIONS = 128;
const OFFSET_X = shared.WIDTH / 2;
const OFFSET_Y = shared.HEIGHT / 2;
const SCALE_FACTOR: comptime_float = 4.0;
const SCALE = 1.0 / (@as(comptime_float, @floatFromInt(shared.WIDTH)) / SCALE_FACTOR);

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
pub fn fillPixelsWithMandelbrot(buf: []shared.Pixel) void {
    for (0..shared.HEIGHT) |y_int| {
        for (0..shared.WIDTH) |x_int| {
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
            var iterations: u16 = 1;
            while ((iterations < MAX_NUM_ITERATIONS) and (x2 + y2 <= 4.0)) : (iterations += 1) {
                y = ((x + x) * y) + y0; // 2xy == (x + x)y (thus removing a mul) (see Wikipedia link)
                x = (x2 - y2) + x0;
                x2 = x * x;
                y2 = y * y;
            }

            const col = calculateColor(iterations);

            // draw pixel
            const pixel_ind: usize = (y_int * shared.WIDTH) + x_int;
            std.debug.assert(pixel_ind < buf.len);
            buf[pixel_ind] = col;
        }
    }
}

// generates (1 - (1 / x)) * 255
fn calculateColor(iterations: u16) shared.Pixel {
    const max: f32 = @floatFromInt(MAX_NUM_ITERATIONS);
    const iters: f32 = @floatFromInt(iterations);

    // black and white
    const val_f = (iters / max) * 255.0;
    var val: u8 = @intFromFloat(val_f);
    val ^= 0xff;
    return .{
        .r = val,
        .g = val,
        .b = val,
        .a = 0xff,
    };

    // produces colored output, imo less pretty than the B&W.
    // modified version of ChatGPT's code.

    // if (iterations == MAX_NUM_ITERATIONS) return .{
    //     .r = 0,
    //     .g = 0,
    //     .b = 0,
    //     .a = 0xff,
    // };
    // const h: f32 = (iters / max) * 360.0;
    // const x = 1 - @abs(@mod(h / 60.0, 2) - 1);
    // var r: f32 = 0;
    // var g: f32 = 0;
    // var b: f32 = 0;

    // if (h < 60) {
    //     b = 1;
    //     g = x;
    //     r = 0;
    // } else if (h < 120) {
    //     b = x;
    //     g = 1;
    //     r = 0;
    // } else if (h < 180) {
    //     b = 0;
    //     g = 1;
    //     r = x;
    // } else if (h < 240) {
    //     b = 0;
    //     g = x;
    //     r = 1;
    // } else if (h < 300) {
    //     b = x;
    //     g = 0;
    //     r = 1;
    // } else {
    //     b = 1;
    //     g = 0;
    //     r = x;
    // }
    // return .{
    //     .r = @intFromFloat(r * 255),
    //     .g = @intFromFloat(g * 255),
    //     .b = @intFromFloat(b * 255),
    //     .a = 0xff,
    // };
}
