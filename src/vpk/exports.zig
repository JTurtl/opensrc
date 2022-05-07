const std = @import("std");
const vpk = @import("vpk.zig");
pub usingnamespace vpk;

pub const ReadResult = extern struct {
    err: ReadError,
    result: vpk.Dir,
};

pub const ReadError = enum(c_int) {
    Ok,
    TooSmall,
    BadSignature,
    BadVersion,
    OutOfMemory,
    FileNotFound,
    SomethingElse, //TODO
};

pub export fn osrc_vpk_read(path: [*c]const u8) ReadResult {
    var path_as_slice: []const u8 = undefined;
    path_as_slice.ptr = path;
    path_as_slice.len = std.mem.len(path);

    const dir = vpk.read(std.heap.c_allocator, path_as_slice) catch |err| {
        return ReadResult {
            .result = undefined,
            .err = switch (err) {
                error.TooSmall => .TooSmall,
                error.BadSignature => .BadSignature,
                error.OutOfMemory => .OutOfMemory,
                error.FileNotFound => .FileNotFound,
                else => .SomethingElse,
            }
        };
    };
    return ReadResult {
        .err = .Ok,
        .result = dir,
    };
}

pub export fn osrc_vpk_free(dir: vpk.Dir) void {
    dir.deinit(std.heap.c_allocator);
}
