//! Raw Image data stored in a VTF file.
//! Includes support for converting between formats

const std = @import("std");
const Allocator = std.mem.Allocator;

const todo = std.debug.todo;


pub const Format = enum(u32) {
    rgba8888 = 0,
    abgr8888 = 1,
    rgb888 = 2,
    bgr888 = 3,
    rgb565 = 4,
    @"i8" = 5,
    ia88 = 6,
    p8 = 7,
    a8 = 8,
    rgb888_bluescreen = 9,
    bgr888_bluescreen = 10,
    argb8888 = 11,
    bgra8888 = 12,
    dxt1 = 13,
    dxt3 = 14,
    dxt5 = 15,
    bgrx8888 = 16,
    bgr565 = 17,
    bgrx5551 = 18,
    bgra4444 = 19,
    dxt1_alpha = 20,
    bgra5551 = 21,
    uv88 = 22,
    uvwq8888 = 23,
    rgba16161616f = 24,
    rgba16161616 = 25,
    uvlx8888 = 26,

    pub fn bitsPerPixel(self: @This()) u8 {
        return switch (self) {
            .rgba16161616f, .rgba16161616 => 8*8,

            .rgba8888, .abgr8888, .argb8888,
            .bgra8888, .bgrx8888, .uvwq8888, .uvlx8888 => 4*8,

            .rgb888, .bgr888, .rgb888_bluescreen, .bgr888_bluescreen => 3*8,

            .rgb565, .ia88, .bgr565, .bgrx5551,
            .bgra4444,     .bgra5551,     .uv88 => 2*8,

            .@"i8", .p8, .a8 => 1*8,

            .dxt1, .dxt1_alpha => 4,
            .dxt3, .dxt5 => 8,
        };
    }

    pub fn canConvertInt(int: u32) bool {
        return int <= 26;
    }

    pub fn isDxt(self: @This()) bool {
        return switch (self) {
            .dxt1, .dxt1_alpha, .dxt3, .dxt5 => true,
            else => false,
        };
    }
};

pub fn calculateDataSize(width: u16, height: u16, format: Format) u32 {
    const total_pixels = @as(u32, width) * height;
    return (total_pixels * format.bitsPerPixel()) / 8;
}


width: u16,
height: u16,
format: Format,
data: []u8,

pub fn free(self: @This(), allocator: Allocator) void {
    allocator.free(self.data);
}

const ezdxt = @import("ezdxt");
pub const Rgba = ezdxt.Rgba;

pub fn pixelAsRgba(self: @This(), x: u16, y: u16) Rgba {
    std.debug.assert(x < self.width);
    std.debug.assert(y < self.height);

    if (self.format.isDxt()) {
        const img = ezdxt.Image {
            .data = self.data,
            .width = self.width,
            .height = self.height,
        };
        const rgba: ezdxt.Rgba = switch (self.format) {
            .dxt1 => ezdxt.dxt1.getPixelNoAlpha(img, x, y),

            .dxt1_alpha => ezdxt.dxt1.getPixel(img, x, y),

            .dxt3 => ezdxt.dxt3.getPixel(img, x, y),
            .dxt5 => ezdxt.dxt5.getPixel(img, x, y),

            else => unreachable,
        };
        return rgba;
    }

    // This code crashed the Zig compiler (latest git + v0.9 stable)
    // Keeping it here as a historical artifact
    // it's garbage and doesnt match the current API anyway
    //
    // switch (self.format) {
    //     .dxt1, .dxt1_onebitalpha => {
    //         const maybe_rgb = ezdxt.getPixelDxt1(
    //             ezdxt.Image {
    //                 .data = self.data,
    //                 .width = self.width,
    //                 .height = self.height,
    //             },
    //             x, y
    //         );
    //         const rgbf =
    //             if (maybe_rgb) |rgb|
    //                 rgb.asFloats()
    //             else
    //                 ezdxt.Rgbf {
    //                     .r = 0, .g = 0, .b = 0,
    //                     .a = if (self.format == .dxt1) 1 else 0,
    //                 };
    //         return RgbaFloat {
    //             .r = rgbf.r,
    //             .g = rgbf.g,
    //             .b = rgbf.b,
    //             .a = rgbf.a,
    //         };
    //     },
    //     .dxt3 => todo("pixelAsRgba: dxt3"),
    //     .dxt5 => todo("pixelAsRgba: dxt5"),
    //     else => {},
    // }

    const index = (@as(u32, y) * self.width + x) * (self.format.bitsPerPixel()/8);
    const data = self.data;

    // oh, wonderful.
    return switch (self.format) {
        .rgba8888 => .{
            .r = @intToFloat(f32, data[index + 0]) / 255,
            .g = @intToFloat(f32, data[index + 1]) / 255,
            .b = @intToFloat(f32, data[index + 2]) / 255,
            .a = @intToFloat(f32, data[index + 3]) / 255,
        },
        .abgr8888 => .{
            .r = @intToFloat(f32, data[index + 3]) / 255,
            .g = @intToFloat(f32, data[index + 2]) / 255,
            .b = @intToFloat(f32, data[index + 1]) / 255,
            .a = @intToFloat(f32, data[index + 0]) / 255,
        },
        .rgb888 => .{
            .r = @intToFloat(f32, data[index + 0]) / 255,
            .g = @intToFloat(f32, data[index + 1]) / 255,
            .b = @intToFloat(f32, data[index + 2]) / 255,
            .a = 1,
        },
        .bgr888 => .{
            .r = @intToFloat(f32, data[index + 2]) / 255,
            .g = @intToFloat(f32, data[index + 1]) / 255,
            .b = @intToFloat(f32, data[index + 0]) / 255,
            .a = 1,
        },
        .rgb565 => blk: {
            const word: u16 = data[index] & (@as(u16, data[index+1]) << 8);
            break :blk .{
                .r = @intToFloat(f32, @truncate(u5, word >> 11)),
                .g = @intToFloat(f32, @truncate(u6, word >> 5)),
                .b = @intToFloat(f32, @truncate(u5, word)),
                .a = 1,
            };
        },
        

        else => todo("pixelAsRgba: unimplemented format"),
    };
}

pub fn fromPixels(
    allocator: Allocator,
    width: u16,
    height: u16,
    format: Format,
    pixels: []Rgba
) !@This() {
    _ = allocator;
    _ = width;
    _ = height;
    _ = format;
    _ = pixels;
    @compileError("todo");
}
