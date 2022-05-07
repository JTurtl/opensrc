const std = @import("std");
const vtf = @import("vtf.zig");

const use_c_allocator = false;

var gpa: if (use_c_allocator) void else std.heap.GeneralPurposeAllocator(.{}) = .{};

const allocator = if (use_c_allocator)
        std.heap.c_allocator
    else
        gpa.allocator();

const Texture = extern struct {
    mipmaps_ptr: [*]MipMap,
    mipmaps_len: usize,
    flags: vtf.Flags,
    reflectivity: [3]f32,
    bumpmap_scale: f32,
    width: u16, height: u16,
    thumbnail: Image,
    version_minor: u8,

    pub fn fromInternal(tex: vtf.Texture) !@This() {
        //todo: use extern structs in vtf.zig so that no extra allocs are needed.
        // not the biggest of concerns, but it's there. Mocking me. Laughing.
        // @andrewrk  make slices compatible with extern structs.
        // standardize the fact that a slice is equivalent to
        // `extern struct { ptr: [*]T, len: usize }`
        // and all will be well. Please?
        const mips = try allocator.alloc(MipMap, tex.mipmaps.len);
        errdefer allocator.free(mips);

        for (tex.mipmaps) |mip, i| {
            const frames = try allocator.alloc(Image, mip.frames.len);
            errdefer allocator.free(frames);

            for (mip.frames) |frame, j| {
                frames[j] = Image.fromInternal(frame);
            }

            mips[i].frames_ptr = frames.ptr;
            mips[i].frames_len = frames.len;

            allocator.free(mip.frames);
        }
        allocator.free(tex.mipmaps);

        return @This() {
            .mipmaps_ptr = mips.ptr,
            .mipmaps_len = mips.len,
            .flags = tex.flags,
            .reflectivity = tex.reflectivity,
            .bumpmap_scale = tex.bumpmap_scale,
            .width = tex.width,
            .height = tex.height,
            .thumbnail = Image.fromInternal(tex.thumbnail),
            .version_minor = @intCast(u8, tex.version.minor),
        };
    }
};

const MipMap = extern struct {
    frames_ptr: [*]Image,
    frames_len: usize,
    
    pub fn fromInternal(mip: vtf.MipMap) @This() {
        return .{
            .frames_ptr = mip.frames.ptr,
            .frames_len = mip.frames.len,
        };
    }

    pub fn free(self: @This()) void {
        var frames: []Image = undefined;
        frames.ptr = self.frames_ptr;
        frames.len = self.frames_len;

        for (frames) |frame| {
            frame.free();
        }

        allocator.free(frames);
    }
};

const Image = extern struct {
    format: vtf.Image.Format,
    width: u16,
    height: u16,
    // data len can be calculated from the other data
    data_ptr: [*]u8,

    pub fn fromInternal(img: vtf.Image) @This() {
        return .{
            .format = img.format,
            .width = img.width,
            .height = img.height,
            .data_ptr = img.data.ptr,
        };
    }

    pub fn free(self: @This()) void {
        var data: []u8 = undefined;
        data.ptr = self.data_ptr;
        data.len = vtf.Image.calculateDataSize(self.width, self.height, self.format);
        allocator.free(data);
    }
};

export fn osrc_vtf_get_pixel(img: Image, x: u16, y: u16) vtf.Image.Rgba {
    var data: []u8 = undefined;
    data.ptr = img.data_ptr;
    data.len = vtf.Image.calculateDataSize(img.width, img.height, img.format);
    return vtf.Image.pixelAsRgba(
        vtf.Image {
            .data = data,
            .format = img.format,
            .width = img.width,
            .height = img.height,
        },
        x, y,
    );
}

const ReadResult = extern struct {
    err: ReadError,
    result: Texture,
};

const ReadError = enum(c_int) {
    Ok,
    OutOfMemory,
    InvalidFile,
    FileNotFound,
    SomethingElse,
};

export fn osrc_vtf_read_file(path: [*c]const u8) ReadResult {
    var path_slice: []const u8 = undefined;
    path_slice.ptr = path;
    path_slice.len = std.mem.len(path);
    const internal = vtf.readFile(
        allocator,
        path_slice,
    ) catch |err| {
        return ReadResult {
            .result = undefined,
            .err = switch (err) {
                error.OutOfMemory => .OutOfMemory,
                error.FileNotFound => .FileNotFound,
                else => .SomethingElse,
            }
        };
    };
    const tex = Texture.fromInternal(internal) catch return ReadResult {
        .result = undefined,
        .err = .OutOfMemory,
    };
    return ReadResult {
        .err = .Ok,
        .result = tex,
    };
}

export fn osrc_vtf_free(tex: Texture) void {
    tex.thumbnail.free();

    var mips: []MipMap = undefined;
    mips.ptr = tex.mipmaps_ptr;
    mips.len = tex.mipmaps_len;

    for (mips) |mip| {
        mip.free();
    }

    allocator.free(mips);
}

