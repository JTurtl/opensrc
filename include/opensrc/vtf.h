#ifndef _opensrc_vtf_h
#define _opensrc_vtf_h

#include <stdint.h>
#include <stddef.h>

typedef enum OSrcVtfFormat {
    OSRC_VTF_FMT_RGBA8888,
    OSRC_VTF_FMT_ABGR8888,
    OSRC_VTF_FMT_RGB888,
    OSRC_VTF_FMT_BGR888,
    OSRC_VTF_FMT_RGB565,
    OSRC_VTF_FMT_I8,
    OSRC_VTF_FMT_IA88,
    OSRC_VTF_FMT_P8,
    OSRC_VTF_FMT_A8,
    OSRC_VTF_FMT_RGB888_BLUESCREEN,
    OSRC_VTF_FMT_BGR888_BLUESCREEN,
    OSRC_VTF_FMT_ARGB8888,
    OSRC_VTF_FMT_BGRA8888,
    OSRC_VTF_FMT_DXT1,
    OSRC_VTF_FMT_DXT3,
    OSRC_VTF_FMT_DXT5,
    OSRC_VTF_FMT_BGRX8888,
    OSRC_VTF_FMT_BGR565,
    OSRC_VTF_FMT_BGRX5551,
    OSRC_VTF_FMT_BGRA4444,
    OSRC_VTF_FMT_DXT1_ALPHA,
    OSRC_VTF_FMT_BGRA5551,
    OSRC_VTF_FMT_UV88,
    OSRC_VTF_FMT_UVWQ8888,
    OSRC_VTF_FMT_RGBA16161616f,
    OSRC_VTF_FMT_RGBA16161616,
    OSRC_VTF_FMT_UVLX8888,
} OSrcVtfFormat;

typedef uint32_t OSrcVtfFlags;
enum {
    OSRC_VTF_FLAG_POINTSAMPLE = 0x1,
    OSRC_VTF_FLAG_TRILINEAR = 0x2,
    OSRC_VTF_FLAG_CLAMP_S = 0x4,
    OSRC_VTF_FLAG_CLAMP_T = 0x8,
    OSRC_VTF_FLAG_ANISOTROPIC = 0x10,
    OSRC_VTF_FLAG_HINT_DXT5 = 0x20,
    OSRC_VTF_FLAG_PWL_CORRECTED = 0x40,
    OSRC_VTF_FLAG_NORMAL = 0x80,
    OSRC_VTF_FLAG_NO_MIP = 0x100,
    OSRC_VTF_FLAG_NO_LOD = 0x200,
    OSRC_VTF_FLAG_ALL_MIPS = 0x400,
    OSRC_VTF_FLAG_PROCEDURAL = 0x800,
    OSRC_VTF_FLAG_ONEBITALPHA = 0x1000,
    OSRC_VTF_FLAG_EIGHTBITALPHA = 0x2000,
    OSRC_VTF_FLAG_ENVMAP = 0x4000,
    OSRC_VTF_FLAG_RENDER_TARGET = 0x8000,
    OSRC_VTF_FLAG_DEPTH_RENDER_TARGET = 0x100000,
    OSRC_VTF_FLAG_NO_DEBUG_OVERRIDE = 0x200000,
    OSRC_VTF_FLAG_SINGLE_COPY = 0x400000,
    OSRC_VTF_FLAG_PRE_SRGB = 0x800000,
    OSRC_VTF_FLAG_UNUSED0  = 0x1000000,
    OSRC_VTF_FLAG_UNUSED1  = 0x2000000,
    OSRC_VTF_FLAG_UNUSED2  = 0x4000000,
    OSRC_VTF_FLAG_NO_DEPTH_BUFFER = 0x8000000,
    OSRC_VTF_FLAG_UNUSED3 = 0x10000000,
    OSRC_VTF_FLAG_CLAMP_U = 0x20000000,
    OSRC_VTF_FLAG_VERTEX_TEXTURE = 0x40000000,
    OSRC_VTF_FLAG_SS_BUMP = 0x80000000,
    OSRC_VTF_FLAG_UNUSED4 = 0x100000000,
    OSRC_VTF_FLAG_BORDER  = 0x200000000,
    OSRC_VTF_FLAG_UNUSED5 = 0x400000000,
    OSRC_VTF_FLAG_UNUSED6 = 0x800000000,
};

typedef struct OSrcVtfImage {
    OSrcVtfFormat format;
    uint16_t width;
    uint16_t height;
    const uint8_t *data;
} OSrcVtfImage;

typedef struct OSrcVtfMipMap {
    OSrcVtfImage *frames;
    size_t frames_len;
} OSrcVtfMipMap;

typedef struct OSrcVtfTexture {
    OSrcVtfMipMap *mipmaps;
    size_t mipmaps_len;
    OSrcVtfFlags flags;
    float reflectivity[3];
    float bumpmap_scale;
    uint16_t width, height;
    OSrcVtfImage thumbnail;
    uint8_t version_minor;
} OSrcVtfTexture;

typedef enum OSrcVtfReadError {
    OSRC_VTF_ERR_OK,
    OSRC_VTF_ERR_OUT_OF_MEMORY,
    OSRC_VTF_ERR_INVALID_FILE,
    OSRC_VTF_ERR_FILE_NOT_FOUND,
    OSRC_VTF_ERR_JefferyEpsteinWasAssassinated,
} OSrcVtfReadError;

typedef struct OSrcVtfReadResult {
    OSrcVtfReadError error;
    OSrcVtfTexture result;
} OSrcVtfReadResult;

OSrcVtfReadResult osrc_vtf_read_file(const char *path);


typedef struct OSrcVtfRgba {
    float r, g, b, a;
} OSrcVtfRgba;

OSrcVtfRgba osrc_vtf_get_pixel(OSrcVtfImage, uint16_t x, uint16_t y);
void osrc_vtf_free(OSrcVtfTexture);

#endif
