const std = @import("std");
const win = std.os.windows;
const shared = @import("shared.zig");
const mandelbrot = @import("mandelbrot.zig");
const console = @import("console.zig");
const print = console.print;

const c = @cImport({
    @cInclude("windows.h");
});

var buf: []shared.Pixel = undefined;
var buf_bitmap_info: c.BITMAPINFO = undefined;

fn blitScreen(device_context: c.HDC, width: c_long, height: c_long) void {
    _ = c.StretchDIBits(
        device_context,
        0,
        0,
        width,
        height,
        0,
        0,
        shared.WIDTH,
        shared.HEIGHT,
        @ptrCast(buf),
        &buf_bitmap_info,
        c.DIB_RGB_COLORS,
        c.SRCCOPY,
    );
}

export fn mainWindowCallback(
    window: c.HWND,
    msg: c.UINT,
    w_param: c.WPARAM,
    l_param: c.LPARAM,
) c.LRESULT {
    var result: c.LRESULT = undefined;

    switch (msg) {
        c.WM_CLOSE, c.WM_DESTROY => exit(),
        c.WM_SIZE => {},
        c.WM_KEYDOWN, c.WM_SYSKEYDOWN => if (w_param == 'Q') exit(),
        c.WM_PAINT => {
            var paint: c.PAINTSTRUCT = undefined;
            const device_context = c.BeginPaint(window, &paint);
            blitScreen(
                device_context,
                paint.rcPaint.right - paint.rcPaint.left,
                paint.rcPaint.bottom - paint.rcPaint.top,
            );
            _ = c.EndPaint(window, &paint);
        },
        else => {
            result = c.DefWindowProcA(window, msg, w_param, l_param);
        },
    }

    return result;
}

pub export fn wWinMain(
    h_instance: win.HINSTANCE,
    h_prev_instance: ?win.HINSTANCE,
    lp_cmd_line: ?[*:0]u16,
    n_show_cmd: c_int,
) c_int {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    console.init();

    buf = arena.allocator().alignedAlloc(shared.Pixel, std.mem.Alignment.@"32", shared.WIDTH * shared.HEIGHT) catch return console.printErrorAndBounceErrorCode("could not allocate pixel buffer", 1);
    @memset(buf, .{
        .r = 0,
        .g = 0,
        .b = 0,
        .a = 0,
    });

    print("calculating...");
    mandelbrot.fillPixelsWithMandelbrot(buf);
    print("done.\n");

    buf_bitmap_info = .{
        .bmiHeader = .{
            .biSize = @sizeOf(c.BITMAPINFOHEADER),
            .biWidth = shared.WIDTH,
            .biHeight = -shared.HEIGHT,
            .biPlanes = 1,
            .biBitCount = 32,
            .biCompression = c.BI_RGB,
        },
    };

    const window_class: c.WNDCLASSA = .{
        .style = c.CS_OWNDC | c.CS_HREDRAW | c.CS_VREDRAW,
        .lpfnWndProc = mainWindowCallback,
        .hInstance = @ptrCast(@alignCast(h_instance)),
        .lpszClassName = @ptrCast(@alignCast("AyooooTestclassname")),
    };

    if (c.RegisterClassA(&window_class) != 0) {
        const hwnd = c.CreateWindowExA(
            0,
            window_class.lpszClassName,
            "Mandelbrot",
            c.WS_OVERLAPPED | c.WS_SYSMENU | c.WS_VISIBLE,
            c.CW_USEDEFAULT,
            c.CW_USEDEFAULT,
            shared.WIDTH,
            shared.HEIGHT,
            null,
            null,
            @ptrCast(@alignCast(h_instance)),
            null,
        );
        if (hwnd != null) {
            var msg: c.MSG = undefined;
            forever: while (true) {
                const msg_result = c.GetMessageA(
                    &msg,
                    null,
                    0,
                    0,
                );
                if (msg_result > 0) {
                    _ = c.TranslateMessage(&msg);
                    _ = c.DispatchMessageA(&msg);
                } else {
                    break :forever;
                }
            }
        }
    }

    _ = h_prev_instance;
    _ = lp_cmd_line;
    _ = n_show_cmd;
    return 0;
}

fn exit() void {
    c.PostQuitMessage(0);
}
