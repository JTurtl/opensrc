const std = @import("std");
const Allocator = std.mem.Allocator;
const vtf = @import("vtf.zig");
const Image = vtf.Image;

const log = std.log.scoped(.@"VTF Reader");

stream: std.io.FixedBufferStream([]const u8),
allocator: Allocator,
result: vtf.Texture = undefined,
header: vtf.Header = undefined,
resources: []vtf.ResourceEntry = undefined,

pub fn readFile(allocator: Allocator, path: []const u8, max_file_size: usize) !vtf.Texture {
    const file = try std.fs.cwd().openFile(path, .{});
    defer file.close();

    const data = try file.readToEndAlloc(allocator, max_file_size);
    defer allocator.free(data);

    return readBuffer(allocator, data);
}

pub fn readBuffer(allocator: Allocator, data: []const u8) !vtf.Texture {
    var self = @This() {
        .stream = std.io.fixedBufferStream(data),
        .allocator = allocator,
    };

    try self.readHeader();
    self.result.version = self.header.version;
    self.result.width = self.header.width;
    self.result.height = self.header.height;
    self.result.flags = self.header.flags;
    self.result.reflectivity = self.header.reflectivity;
    self.result.bumpmap_scale = self.header.bumpmap_scale;

    // v7.3+ diverges from v7.2- after the header

    if (self.header.version.minor >= 3) {
        try self.readV73();
        allocator.free(self.resources);
    } else {
        try self.readV72();
    }


    return self.result;
}

fn readV73(self: *@This()) !void {
    var has_thumbnail = false;
    var has_images = false;

    // Immediately following the header is a list of Resource entries
    try self.readResources();
    for (self.resources) |rsrc| {
        if (rsrc.flags & 0x2 == 0x2) {
            // the only flag that does anything.
            // 0x2 means that there's no data with this resource
            // and the offset member is junk
            continue;
        }
        if (std.mem.eql(u8, &rsrc.tag, &[3]u8{1,0,0})) {
            // Thumbnail data
            try self.stream.seekTo(rsrc.offset);
            try self.readThumbnail();
            has_thumbnail = true;
        } else if (std.mem.eql(u8, &rsrc.tag, &[3]u8{0x30,0,0})) {
            // Image data
            try self.stream.seekTo(rsrc.offset);
            try self.readImages();
            has_images = true;
        } else {
            std.log.warn("unknown resource tag '{any}'", .{rsrc.tag});
        }
    }

    if (!has_thumbnail) {
        return error.MissingThumbnail;
    }
    if (!has_images) {
        return error.WhyMustGodTestMyPatienceLikeThis;
    }
}

fn readV72(self: *@This()) !void {
    // thumbnail immediately follows header
    try self.stream.seekTo(self.header.size);
    try self.readThumbnail();
    // and then, the important stuff
    try self.readImages();
    // ...it's really that easy? huh.
}

fn readImages(self: *@This()) !void {
    // The main data that you've all been waiting for
    // It's stored like this:
    //
    // Foreach Mipmap (lowest res to highest)
    // + Foreach Animation Frame (first to last)
    //   + Foreach Face (6 or 7 for cubemaps, 1 for everything else)
    //     + Foreach Z-slice (for 3D textures, see Header.depth)
    //       + Raw image data
    
    self.result.mipmaps = try self.allocator.alloc(vtf.MipMap, self.header.mipmap_count);
    // Count down to zero, so that higher mipmap levels
    // means lower resolution (mipmap 0 = original image)
    var mipmap_index: u8 = self.header.mipmap_count;
    while (mipmap_index > 0) {
        mipmap_index -= 1;

        self.result.mipmaps[mipmap_index].frames = try self.allocator.alloc(
            vtf.Image, self.header.frame_count
        );

        const this_mipmap_res = calculateMipmapSize(
            mipmap_index, self.header.width, self.header.height, self.header.format,
        );

        //std.debug.print("mipmap #{}/{} resolution: {}\n", .{mipmap_index+1, self.header.mipmap_count, this_mipmap_res});

        var frame_index: u16 = 0;
        while (frame_index < self.header.frame_count) : (frame_index += 1) {
            //TODO: faces and z-slices

            const image_size = Image.calculateDataSize(
                this_mipmap_res.x,
                this_mipmap_res.y,
                self.header.format,
            );

            const image_data = try self.allocator.alloc(u8, image_size);
            errdefer self.allocator.free(image_data);

            try self.stream.reader().readNoEof(image_data);

            self.result.mipmaps[mipmap_index].frames[frame_index] = Image {
                .width = this_mipmap_res.x,
                .height = this_mipmap_res.y,
                .format = self.header.format,
                .data = image_data,
            };
        }
    }
}

const Vec2u16 = struct {
    x: u16, y: u16
};
fn calculateMipmapSize(
    mipmap_level: u8,
    original_width: u16,
    original_height: u16,
    format: Image.Format,
) Vec2u16 {
    // Every mipmap level is half the size of the previous
    var result = Vec2u16 {
        .x = original_width,
        .y = original_height,
    };
    //todo: this could be one (1) expression
    // but math is hard
    var i: u8 = 0;
    while (i < mipmap_level) : (i += 1) {
        result.x /= 2;
        result.y /= 2;
    }

    // Im impressed that i found this bug as quickly as i did.
    // DXT textures *cannot* be less than 4x4.
    // Without this check, DXT images with many mipmaps would be corrupted.
    if (format.isDxt()) {
        result.x = @maximum(4, result.x);
        result.y = @maximum(4, result.y);
    }
    return result;
}


fn readThumbnail(self: *@This()) !void {
    const len = vtf.Image.calculateDataSize(
        self.header.thumbnail_width,
        self.header.thumbnail_height,
        self.header.thumbnail_format,
    );
    const data = try self.allocator.alloc(u8, len);
    errdefer self.allocator.free(data);

    try self.stream.reader().readNoEof(data);

    self.result.thumbnail = vtf.Image {
        .width = self.header.thumbnail_width,
        .height = self.header.thumbnail_height,
        .format = self.header.thumbnail_format,
        .data = data,
    };
}

fn readHeader(self: *@This()) !void {
    const reader = self.stream.reader();
    const signature = try reader.readIntLittle(u32);
    if (signature != vtf.file_signature) {
        return error.BadSignature;
    }

    var header: vtf.Header = undefined;

    const readInt = reader.readIntLittle;

    header.version.major = try readInt(u32);
    header.version.minor = try readInt(u32);
    if (!vtf.isSupportedVersion(header.version.major, header.version.minor)) {
        return error.BadVersion;
    }

    header.size = try readInt(u32);
    if (header.size > self.stream.buffer.len) {
        return error.BadHeaderSize;
    }

    //std.debug.print("headersz = {}\n", .{header.size});

    header.width = try readInt(u16);
    header.height = try readInt(u16);
    header.flags = @bitCast(vtf.Flags, try readInt(u32));
    if (header.flags.envmap) {
        log.warn("Texture has envmap flag - and envmaps aren't supported!", .{});
    }
    header.frame_count = try readInt(u16);
    header.first_frame = try readInt(u16);
    
    try reader.skipBytes(4, .{});

    header.reflectivity = [3]f32 {
        @bitCast(f32, try readInt(u32)),
        @bitCast(f32, try readInt(u32)),
        @bitCast(f32, try readInt(u32)),
    };
    
    try reader.skipBytes(4, .{});

    header.bumpmap_scale = @bitCast(f32, try readInt(u32));
    const format_int = try readInt(u32);
    if (!vtf.Image.Format.canConvertInt(format_int)) {
        return error.BadFormat;
    }
    header.format = @intToEnum(vtf.Image.Format, format_int);
    header.mipmap_count = try readInt(u8);
    header.thumbnail_format = @intToEnum(vtf.Image.Format, try readInt(u32));
    header.thumbnail_width = try readInt(u8);
    header.thumbnail_height = try readInt(u8);
    
    if (header.version.minor >= 2) {
        header.depth = try readInt(u16);
        if (header.version.minor >= 3) {
            try reader.skipBytes(3, .{});
            header.resource_count = try readInt(u32);
            try reader.skipBytes(8, .{});
        } else {
            header.resource_count = 0;
        }
    } else {
        header.depth = 1;
    }

    if (header.depth < 1) {
        log.warn("Texture has depth of {} - 3D textures aren't supported!", .{header.depth});
    }

    self.header = header;
    //std.debug.print("===HEADER===\n\n{}\n\n", .{header});
}

fn readResources(self: *@This()) !void {
    const reader = self.stream.reader();
    self.resources = try self.allocator.alloc(vtf.ResourceEntry, self.header.resource_count);
    var i: u32 = 0;
    while (i < self.header.resource_count) : (i += 1) {
        const rsrc = vtf.ResourceEntry {
            .tag = try reader.readBytesNoEof(3),
            .flags = try reader.readByte(),
            .offset = try reader.readIntLittle(u32),
        };
        self.resources[i] = rsrc;
    }
}
