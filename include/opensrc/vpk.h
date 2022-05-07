#ifndef _opensrc_vpk_h
#define _opensrc_vpk_h

#include <stddef.h>
#include <stdint.h>

#define VALID_SIGNATURE 0x55aa1234

typedef struct OSrcVpkEntry {
    uint32_t crc;
    uint16_t preload_bytes;
    uint16_t archive_index;
    uint32_t entry_offset;
    uint32_t entry_length;
} OSrcVpkEntry;

typedef struct OSrcVpkFile {
    char *name;
    struct OSrcVpkEntry entry;
} OSrcVpkFile;

typedef struct OSrcVpkPath {
    char *name;
    struct OSrcVpkFile *files;
    size_t files_len;
} OSrcVpkPath;

typedef struct OSrcVpkExtension {
    char *name;
    struct OSrcVpkPath *paths;
    size_t paths_len;
} OSrcVpkExtension;

typedef struct OSrcVpkDir {
    struct OSrcVpkExtension *extensions;
    size_t extensions_len;
} OSrcVpkDir;


typedef enum OSrcVpkReadError {
    OSRC_VPK_ERR_OK,
    OSRC_VPK_ERR_TOO_SMALL,
    OSRC_VPK_ERR_BAD_SIGNATURE,
    OSRC_VPK_ERR_BAD_VERSION,
    OSRC_VPK_ERR_OUT_OF_MEMORY,
    OSRC_VPK_ERR_FILE_NOT_FOUND,
    OSRC_VPK_ERR_LIFE_IS_PAIN,
} OSrcVpkReadError;

typedef struct OSrcVpkReadResult {
    enum OSrcVpkReadError error;
    struct OSrcVpkDir result;
} OSrcVpkReadResult;

OSrcVpkReadResult osrc_vpk_read(const char *path);
void osrc_vpk_free(OSrcVpkDir dir);

#endif
