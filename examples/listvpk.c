#include <opensrc/vpk.h>
#include <stdio.h>
#include <unistd.h>

#define TEST_FILE "../test_resources/vpk/hl2_misc_dir.vpk"

static const char *error_to_string(enum OSrcVpkReadError);

int main(void) {
    const OSrcVpkReadResult result = osrc_vpk_read(TEST_FILE);
    if (result.error != OSRC_VPK_ERR_OK) {
        printf("Reading "TEST_FILE" failed: %s\n", error_to_string(result.error));
        return 1;
    }

    puts("Success!");

    const OSrcVpkDir dir = result.result;
    
    for (size_t ext_iter = 0; ext_iter < dir.extensions_len; ext_iter++) {
        const OSrcVpkExtension ext = dir.extensions[ext_iter];
        printf("%s\n", ext.name);

        for (size_t path_iter = 0; path_iter < ext.paths_len; path_iter++) {
            const OSrcVpkPath path = ext.paths[path_iter];
            printf("  %s\n", path.name);

            for (size_t file_iter = 0; file_iter < path.files_len; file_iter++) {
                const OSrcVpkFile file = path.files[file_iter];
                printf("    %s\n", file.name);
                sleep(1);
            }
        }
    }

    osrc_vpk_free(dir);
    return 0;
}

static const char *error_to_string(OSrcVpkReadError err) {
#define E(a) OSRC_VPK_ERR_##a
    switch (err) {
        case E(TOO_SMALL):
            return "File is too small to be a valid VPK";
        case E(BAD_SIGNATURE):
            return "File is not a VPK (bad signature)";
        case E(BAD_VERSION):
            return "Unsupported VPK version";
        case E(OUT_OF_MEMORY):
            return "Ran out of memory while reading";
        case E(FILE_NOT_FOUND):
            return "File does not exist";
        default:
            return "God once again tests my patience";
    }
#undef E
}
