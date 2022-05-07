const std = @import("std");
const Allocator = std.mem.Allocator;

usingnamespace @import("tests.zig");

// KEEP vpk.h UP TO DATE!!
// IF YOU CHANGE ANY EXTERN STRUCTS, CHANGE THEM THERE TOO!


pub const file_signature: u32 = 0x55aa1234;

pub const Dir = extern struct {
    extensions_ptr: [*]Extension,
    extensions_len: usize,

    pub fn init(_extensions: []Extension) Dir {
        return .{ .extensions_ptr = _extensions.ptr, .extensions_len = _extensions.len };
    }

    pub inline fn extensions(self: @This()) []Extension {
        return self.extensions_ptr[0..self.extensions_len];
    }

    pub fn deinit(self: @This(), allocator: Allocator) void {
        for (self.extensions()) |ext| {
            ext.deinit(allocator);
        }
        allocator.free(self.extensions());
    }
};

pub const Extension = extern struct {
    name: [*:0]u8,
    paths_ptr: [*]Path,
    paths_len: usize,

    pub fn init(name: [*:0]u8, _paths: []Path) @This() {
        return .{ .name = name, .paths_ptr = _paths.ptr, .paths_len = _paths.len };
    }

    pub inline fn paths(self: @This()) []Path {
        return self.paths_ptr[0..self.paths_len];
    }

    pub inline fn nameAsSlice(self: @This()) [:0]u8 {
        return self.name[0..std.mem.len(self.name) :0];
    }

    pub inline fn deinit(self: @This(), allocator: Allocator) void {
        allocator.free(self.nameAsSlice());
        for (self.paths()) |path| {
            path.deinit(allocator);
        }
        allocator.free(self.paths());
    }
};

pub const Path = extern struct {
    name: [*:0]u8,
    files_ptr: [*]File,
    files_len: usize,

    pub fn init(name: [*:0]u8, _files: []File) @This() {
        return .{ .name = name, .files_ptr = _files.ptr, .files_len = _files.len };
    }

    pub inline fn files(self: @This()) []File {
        return self.files_ptr[0..self.files_len];
    }

    pub inline fn nameAsSlice(self: @This()) [:0]u8 {
        return self.name[0..std.mem.len(self.name):0];
    }

    pub inline fn deinit(self: @This(), allocator: Allocator) void {
        allocator.free(self.nameAsSlice());
        for (self.files()) |file| {
            file.deinit(allocator);
        }
        allocator.free(self.files());
    }
};

pub const File = extern struct {
    name: [*:0]u8,
    entry: Entry,

    pub inline fn nameAsSlice(self: @This()) [:0]u8 {
        return self.name[0..std.mem.len(self.name):0];
    }

    pub fn deinit(self: @This(), allocator: Allocator) void {
        allocator.free(self.nameAsSlice());
    }
};

pub const Entry = extern struct {
    crc: u32,
    preload_bytes: u16,
    archive_index: u16,
    entry_offset: u32,
    entry_length: u32,
};

pub fn read(allocator: Allocator, path: []const u8) !Dir {
    const file = try std.fs.cwd().openFile(path, .{});
    defer file.close();

    var first_data: [12]u8 = undefined;
    const bytes_read = try file.read(first_data[0..]);
    if (bytes_read != first_data.len) {
        return error.TooSmall;
    }
    const signature = std.mem.readIntLittle(u32, first_data[0..4]);
    if (signature != file_signature) {
        return error.BadSignature;
    }
    const version = std.mem.readIntLittle(u32, first_data[4..8]);
    if (!isSupportedVersion(version)) {
        return error.BadVersion;
    }
    if (version == 1) {
        std.log.warn("this is a version 1 VPK. God save us all.", .{});
    }

    const tree_size = std.mem.readIntLittle(u32, first_data[8..12]);
    
    const v2_header = if (version == 2) blk: {
        var rest_of_the_header: [16]u8 = undefined;
        const more_bytes_read = try file.read(rest_of_the_header[0..]);
        if (more_bytes_read != rest_of_the_header.len) {
            return error.TooSmall;
        }
        const ril = std.mem.readIntLittle;
        const h = rest_of_the_header;
        break :blk V2Header {
            .file_data_section_size = ril(u32, h[0..4]),
            .archive_md5_section_size = ril(u32, h[4..8]),
            .other_md5_section_size = ril(u32, h[8..12]),
            .signature_section_size = ril(u32, h[12..16]),
        };
    } else undefined;

    _ = v2_header;
    _ = tree_size;

    const everything_else = try file.readToEndAlloc(allocator, std.math.maxInt(i32));
    defer allocator.free(everything_else);

    var stream = std.io.FixedBufferStream([]const u8){
        .buffer = everything_else,
        .pos = 0,
    };
    const reader = stream.reader();

    var extensions = std.ArrayListUnmanaged(Extension){};
    errdefer extensions.deinit(allocator);

    while (true) {
        const extension_start = stream.pos;
        try reader.skipUntilDelimiterOrEof(0);
        const extension_end = stream.pos-1;
        if (extension_end == extension_start) {
            break;
        }

        // dupe now, the name needs to be owned later
        const extension_name = try allocator.dupeZ(u8, everything_else[extension_start..extension_end]);
        errdefer allocator.free(extension_name);

        var paths = std.ArrayListUnmanaged(Path){};
        errdefer paths.deinit(allocator);
        
        while (true) {
            const path_start = stream.pos;
            try reader.skipUntilDelimiterOrEof(0);
            const path_end = stream.pos-1;
            if (path_end == path_start) {
                break;
            }

            const path_name = try allocator.dupeZ(u8, everything_else[path_start..path_end]);
            errdefer allocator.free(path_name);

            var files = std.ArrayListUnmanaged(File){};
            errdefer files.deinit(allocator);

            while (true) {
                const file_start = stream.pos;
                try reader.skipUntilDelimiterOrEof(0);
                const file_name_end = stream.pos-1;
                if (file_name_end == file_start) {
                    break;
                }
                const file_name = try allocator.dupeZ(u8, everything_else[file_start..file_name_end]);
                errdefer allocator.free(file_name);

                const crc = try reader.readIntLittle(u32);
                const preload_bytes = try reader.readIntLittle(u16);
                const archive_index = try reader.readIntLittle(u16);
                const entry_offset = try reader.readIntLittle(u32);
                const entry_length = try reader.readIntLittle(u32);

                // every entry ends with 0xFFFF
                _ = try reader.readBytesNoEof(2);

                //TODO: preload bytes
                if (preload_bytes > 0) {
                    std.log.warn("OH NO, PRELOAD BYTES!!!", .{});
                }


                try files.append(allocator, File {
                        .name = file_name,
                        .entry = Entry {
                            .crc = crc,
                            .preload_bytes = preload_bytes,
                            .archive_index = archive_index,
                            .entry_offset = entry_offset,
                            .entry_length = entry_length,
                        },
                });

            }
            
            try paths.append(allocator, Path.init(path_name, files.toOwnedSlice(allocator)));

        }

        try extensions.append(allocator, Extension.init(extension_name, paths.toOwnedSlice(allocator)));
    }

    
    return Dir.init(extensions.toOwnedSlice(allocator));
}

const V2Header = struct {
    file_data_section_size: u32,
    archive_md5_section_size: u32,
    other_md5_section_size: u32,
    signature_section_size: u32,
};

// const Reader = struct {
//     allocator: std.mem.Allocator,
//     file: std.fs.File,

//     version: u32,
//     tree_size: u32,
//     v2_header: V2Header,

//     pub fn init(allocator: std.mem.Allocator, path: []const u8) !@This() {
//         const file = 
//     }
// };

fn isSupportedVersion(ver: u32) bool {
    return ver == 1 or ver == 2;
}
