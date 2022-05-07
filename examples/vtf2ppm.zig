const std = @import("std");
const opensrc = @import("opensrc");
const qoi = @import("qoi.zig");

const file = "../test_resources/vtf/a_mess.vtf";

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    const tex = try opensrc.vtf.readFile(allocator, file);
    defer tex.free(allocator);

    std.debug.print("{} mipmaps\n", .{tex.mipmaps.len});
    
    const img = tex.mipmaps[0].frames[0];
    //std.debug.print("v7.{} ({}, {}) {}\n", .{tex.version.minor, img.width, img.height, img.format});
    //std.debug.print("{}\n{}\n", .{tex.flags, tex});

    const outfile = try std.fs.cwd().createFile("out.ppm", .{});
    defer outfile.close();

    // Writing directly to the file is noticably very slow. I mean really, really slow.
    // Write to memory instead...
    var outbuffer = try allocator.alloc(u8, 64 + 12 * @as(u32, img.width) * img.height);
    defer allocator.free(outbuffer);

    var stream = std.io.fixedBufferStream(outbuffer);
    const writer = stream.writer();

    try writer.print("P3 {} {} 255\n", .{img.width, img.height});
    var y: u16 = 0;
    while (y < img.height) : (y += 1) {
        var x: u16 = 0;
        while (x < img.width) : (x += 1) {
            const rgba = img.pixelAsRgba(x, y);
            const r = @floatToInt(u8, rgba.r*255);
            const g = @floatToInt(u8, rgba.g*255);
            const b = @floatToInt(u8, rgba.b*255);
            try writer.print("{} {} {}\n", .{r, g, b});
        }
    }

    // ...and then write to the file all at once!
    try outfile.writeAll(outbuffer);
}

