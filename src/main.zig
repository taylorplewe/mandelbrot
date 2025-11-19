const std = @import("std");
const win = std.os.windows;

const c = @cImport({
    @cInclude("windows.h");
});

export fn mainWindowCallback(window: c.HWND, msg: c.UINT, w_param: c.WPARAM, l_param: c.LPARAM) c.LRESULT {
    var result: c.LRESULT = undefined;

    switch (msg) {
        c.WM_SIZE => {},
        else => {
            result = c.DefWindowProcA(window, msg, w_param, l_param);
        },
    }

    return result;
}

pub export fn wWinMain(hInstance: win.HINSTANCE, hPrevInstance: ?win.HINSTANCE, lpCmdLine: ?[*:0]u16, nShowCmd: c_int) c_int {
    // c.CreateWindowExA(dwExStyle: c_ulong,
    //   lpClassName: [*c]const u8,
    //   lpWindowName: [*c]const u8,
    //   dwStyle: c_ulong,
    //   X: c_int,
    //   Y: c_int,
    //   nWidth: c_int,
    //   nHeight: c_int,
    //   hWndParent: [*c]struct_HWND__,
    //   hMenu: [*c]struct_HMENU__,
    //   hInstance: [*c]struct_HINSTANCE__,
    //   lpParam: ?*anyopaque)

    const window_class: c.WNDCLASSA = .{
        .style = c.CS_OWNDC | c.CS_HREDRAW | c.CS_VREDRAW,
        .lpfnWndProc = mainWindowCallback,
        .hInstance = @ptrCast(@alignCast(hInstance)),
        .lpszClassName = @ptrCast(@alignCast("AyooooTestclassname")),
    };

    if (c.RegisterClassA(&window_class) != 0) {
        const hwnd = c.CreateWindowExA(0, window_class.lpszClassName, "Taylors Test", c.WS_OVERLAPPEDWINDOW | c.WS_VISIBLE, c.CW_USEDEFAULT, c.CW_USEDEFAULT, c.CW_USEDEFAULT, c.CW_USEDEFAULT, null, null, @ptrCast(@alignCast(hInstance)), null);
        if (hwnd != null) {
            var msg: c.MSG = undefined;
            while (true) {
                const msg_result = c.GetMessageA(&msg, null, 0, 0);
                if (msg_result != 0) {
                    _ = c.TranslateMessage(&msg);
                    _ = c.DispatchMessageA(&msg);
                }
            }
        }
    }

    _ = hPrevInstance;
    _ = lpCmdLine;
    _ = nShowCmd;
    return 0;
}
