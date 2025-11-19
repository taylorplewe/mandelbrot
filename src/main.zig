const std = @import("std");
const win = std.os.windows;

const c = @cImport({
    @cInclude("windows.h");
});

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

    _ = c.MessageBoxA(null, "ayooooo", "noooooo", c.MB_OK);

    _ = hInstance;
    _ = hPrevInstance;
    _ = lpCmdLine;
    _ = nShowCmd;
    return 0;
}
