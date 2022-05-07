#ifndef _opensrc_vpk_hpp
#define _opensrc_vpk_hpp

#include <cstddef>
#include <cstdint>

namespace opensrc {
namespace vpk {
    struct Entry {
        uint32_t crc;
        uint16_t preload_bytes;
        uint16_t archive_index;
        uint32_t entry_offset;
        uint32_t entry_length;
    };

    struct File {
        char *name;
        Entry entry;
    };

    struct Path {
        char *name;
        File *files;
        size_t files_len;
    };

    struct Extension {
        char *name;
        Path *paths;
        size_t paths_len;
    };

    struct Dir {
        Extension *extensions;
        size_t extensions_len;
    };

    enum class ReadError : int {
        Ok,
        TooSmall,
        BadSignature,
        BadVersion,
        OutOfMemory,
        FileNotFound,
        SomeBullshit,
    };

    struct ReadResult {
        ReadError error;
        Dir result;
    };
}
}

extern "C" opensrc::vpk::ReadResult osrc_vpk_read(const char*);
extern "C" void osrc_vpk_free(opensrc::vpk::Dir);

namespace opensrc {
namespace vpk {
    inline ReadResult read(const char *path) {
        return osrc_vpk_read(path);
    }

    inline void free(Dir dir) {
        osrc_vpk_free(dir);
    }
}
}



#endif
