const std = @import("std");
const Allocator = std.mem.Allocator;

pub const Image = @import("Image.zig");

pub const file_signature: u32 = 0x00465456;

pub const Flags = packed struct {
    pointsample: bool,
    trilinear: bool,
    clamp_s: bool,
    clamp_t: bool,
    anisotropic: bool,
    hint_dxt5: bool,
    pwl_corrected: bool,
    normal: bool,
    no_mip: bool,
    no_lod: bool,
    all_mips: bool,
    procedural: bool,
    onebitalpha: bool,
    eightbitalpha: bool,
    envmap: bool,
    render_target: bool,
    depth_render_target: bool,
    no_debug_override: bool,
    single_copy: bool,
    pre_srgb: bool,
    _unused0: bool,
    _unused1: bool,
    _unused2: bool,
    no_depth_buffer: bool,
    _unused3: bool,
    clamp_u: bool,
    vertex_texture: bool,
    ss_bump: bool,
    _unused4: bool,
    border: bool,
    _unused5: bool,
    _unused6: bool,
};

comptime {
    // sanity check
    std.debug.assert(@bitSizeOf(Flags) == 32);
}

pub const Texture = struct {
    version: Version,
    width: u16, height: u16,
    flags: Flags, // 4 bytes
    reflectivity: [3]f32,
    bumpmap_scale: f32,

    mipmaps: []MipMap,

    thumbnail: Image,

    pub fn free(self: @This(), allocator: Allocator) void {
        self.thumbnail.free(allocator);
        for (self.mipmaps) |mip| {
            for (mip.frames) |frame| {
                frame.free(allocator);
            }
            allocator.free(mip.frames);
        }
        allocator.free(self.mipmaps);
    }
};

pub const MipMap = struct {
    frames: []Image,
};

fn isValidImageDimension(dimension: u16) bool {
    return isPowerOfTwo(dimension);
}

fn isPowerOfTwo(a: u16) bool {
    // surely there's an easier way
    const powers_of_two = [_]u16{2,4,8,16,32,64,128,256,512,1024,2048,4096,8192,16384,32768};
    inline for (powers_of_two) |v| {
        if (a == v) return true;
    }
    return false;
}

pub const Version = struct {
    major: u32, minor: u32,
};

pub const Header = struct {
    version: Version,
    size: u32,
    width: u16,
    height: u16,
    flags: Flags,
    frame_count: u16,
    first_frame: u16,
    reflectivity: [3]f32,
    bumpmap_scale: f32,
    format: Image.Format,
    mipmap_count: u8,
    thumbnail_format: Image.Format,
    thumbnail_width: u8,
    thumbnail_height: u8,
    depth: u16,
    resource_count: u32,
};

pub fn readFile(allocator: Allocator, path: []const u8) !Texture {
    return @import("Reader.zig").readFile(allocator, path, 99999999);
}


pub const ResourceEntry = struct {
    tag: [3]u8,
    flags: u8,
    offset: u32,
};

fn readResourceEntries(allocator: Allocator, file: std.fs.File, count: u32) ![]ResourceEntry {
    const result = try allocator.alloc(ResourceEntry, count);
    errdefer allocator.free(result);

    for (result) |_, i| {
        var tag: [3]u8 = undefined;
        std.debug.assert((try file.read(&tag)) == 3);
        const flags = try file.reader().readByte();
        const offset = try file.reader().readIntLittle(u32);

        result[i] = .{ .tag = tag, .flags = flags, .offset = offset };
    }

    return result;
}

const BaseHeader = struct {
    version: [2]u32,
    width: u16,
    height: u16,
    flags: u32,
    frames: u16,
    first_frame: u16,
    //_padding0: [4]u8,
    reflectivity: [3]f32,
    //_padding1: [4]u8,
    bumpmap_scale: f32,
    format: Image.Format,
    mipmap_count: u8, // this one ruins the padding
    thumbnail_format: u32,
    thumbnail_width: u8,
    thumbnail_height: u8,
    depth: u16,
    //padding: [3]u8,
    resource_count: u32,
};

pub fn isSupportedVersion(major: u32, minor: u32) bool {
    // v7.0 -> v7.5
    return major == 7 and minor >= 0 and minor <= 5;
}
