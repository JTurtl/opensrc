// I needed a file format that supports alpha channels
// and the Qoi API is very easy 

const std = @import("std");
const opensrc = @import("opensrc");
const qoi = @import("qoi.zig");

const file = "../test_resources/vtf/a_mess.vtf";

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    const tex = try opensrc.vtf.readFile(allocator, file);
    defer tex.free(allocator);
    
    const img = tex.mipmaps[0].frames[0];

    const pixels = try allocator.alloc(qoi.Color, @as(u32, img.width) * img.height);
    defer allocator.free(pixels);

    var y: u16 = 0;
    while (y < img.height) : (y += 1) {
        var x: u16 = 0;
        while (x < img.width) : (x += 1) {
            const rgba = img.pixelAsRgba(x, y);
            const r = @floatToInt(u8, rgba.r*255);
            const g = @floatToInt(u8, rgba.g*255);
            const b = @floatToInt(u8, rgba.b*255);
            const a = @floatToInt(u8, rgba.a*255);

            const qcol = qoi.Color { .r = r, .g = g, .b = b, .a = a };
            pixels[@as(u32, y) * img.width + x] = qcol;
        }
    }

    const qimg = qoi.ConstImage {
        .width = img.width,
        .height = img.height,
        .pixels = pixels,
        .colorspace = qoi.Colorspace.linear,
    };
    const qoifile = try qoi.encodeBuffer(allocator, qimg);
    defer allocator.free(qoifile);

    const outfile = try std.fs.cwd().createFile("out.qoi", .{});
    defer outfile.close();

    try outfile.writeAll(qoifile);
}

