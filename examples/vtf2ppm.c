#include <stdio.h>
#include <stdlib.h>
#include <opensrc/vtf.h>

#define TEST_FILE "../test_resources/vtf/you_should.vtf"

const char *error_to_string(OSrcVtfReadError);

int main(void) {
    const OSrcVtfReadResult result = osrc_vtf_read_file(TEST_FILE);
    if (result.error != OSRC_VTF_ERR_OK) {
        fprintf(stderr, "Oh no: %s\n", error_to_string(result.error));
        return 1;
    }

    const OSrcVtfTexture texture = result.result;
    fprintf(stderr, "Valve Texture Format v7.%d\n", texture.version_minor);

    const OSrcVtfImage img = texture.mipmaps[0].frames[0];
    fprintf(stderr, "(%d,%d), format=%d\n", img.width, img.height, img.format);

    const uint32_t pixel_count = (uint32_t)img.width * img.height;
    char *const buffer = malloc(20 + 12 * pixel_count);
    size_t offset = 0;
    offset += sprintf(buffer, "P3 %d %d 255\n", img.width, img.height);

    for (uint16_t y = 0; y < img.height; y++) {
        for (uint16_t x = 0; x < img.width; x++) {
            const OSrcVtfRgba rgbaf = osrc_vtf_get_pixel(img, x, y);
            const uint8_t r = (uint8_t)(rgbaf.r * 255);
            const uint8_t g = (uint8_t)(rgbaf.g * 255);
            const uint8_t b = (uint8_t)(rgbaf.b * 255);

            offset += sprintf(buffer+offset, "%d %d %d\n", r, g, b);
        }
    }

    FILE *const fp = fopen("out.ppm", "w");
    if (fp == NULL)
        return 1;

    fwrite(buffer, 1, offset, fp);
    
    fclose(fp);

    osrc_vtf_free(texture);

    return 0;
}

const char *error_to_string(OSrcVtfReadError err) {
#define E(n) OSRC_VTF_ERR_##n
    switch (err) {
        case E(OUT_OF_MEMORY):
            return "Out of memory";
        case E(INVALID_FILE):
            return "Not a valid VTF";
        case E(FILE_NOT_FOUND):
            return "File not found";
        default:
            return "You are a flesh automaton powered by neurotransmitters";
    }
#undef E
}
