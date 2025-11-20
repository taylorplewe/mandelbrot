const std = @import("std");
const win = std.os.windows;

const c = @cImport({
    @cInclude("windows.h");
});

const WIDTH = 600;
const HEIGHT = 400;

const Pixel = packed struct {
    b: u8,
    g: u8,
    r: u8,
    a: u8,
};

var is_running = true;
var buf: []Pixel = undefined;
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
        WIDTH,
        HEIGHT,
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
    hInstance: win.HINSTANCE,
    hPrevInstance: ?win.HINSTANCE,
    lpCmdLine: ?[*:0]u16,
    nShowCmd: c_int,
) c_int {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    buf = arena.allocator().alignedAlloc(Pixel, std.mem.Alignment.@"32", WIDTH * HEIGHT) catch {
        var stderr_buf: [1024]u8 = undefined;
        var stderr_writer = std.fs.File.stderr().writer(&stderr_buf);
        const stderr = &stderr_writer.interface;
        defer stderr.flush() catch unreachable;
        stderr.print("\x1b[31merror\x1b[0m - could not allocate pixel buffer\n", .{}) catch unreachable;
        return 1;
    };
    @memset(buf, .{
        .r = 0,
        .g = 0,
        .b = 0,
        .a = 0,
    });

    buf[((HEIGHT / 2) * WIDTH) + (WIDTH / 2)] = .{
        .r = 0,
        .g = 0xff,
        .b = 0,
        .a = 0,
    };

    buf_bitmap_info = .{
        .bmiHeader = .{
            .biSize = @sizeOf(c.BITMAPINFOHEADER),
            .biWidth = WIDTH,
            .biHeight = -HEIGHT,
            .biPlanes = 1,
            .biBitCount = 32,
            .biCompression = c.BI_RGB,
        },
    };

    const window_class: c.WNDCLASSA = .{
        .style = c.CS_OWNDC | c.CS_HREDRAW | c.CS_VREDRAW,
        .lpfnWndProc = mainWindowCallback,
        .hInstance = @ptrCast(@alignCast(hInstance)),
        .lpszClassName = @ptrCast(@alignCast("AyooooTestclassname")),
    };

    if (c.RegisterClassA(&window_class) != 0) {
        const hwnd = c.CreateWindowExA(
            0,
            window_class.lpszClassName,
            "Taylors Test",
            c.WS_OVERLAPPED | c.WS_SYSMENU | c.WS_VISIBLE,
            c.CW_USEDEFAULT,
            c.CW_USEDEFAULT,
            c.CW_USEDEFAULT,
            c.CW_USEDEFAULT,
            null,
            null,
            @ptrCast(@alignCast(hInstance)),
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

    _ = hPrevInstance;
    _ = lpCmdLine;
    _ = nShowCmd;
    return 0;
}

fn exit() void {
    c.PostQuitMessage(0);
}
