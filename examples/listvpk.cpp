#include <opensrc/vpk.hpp>
#include <iostream>

constexpr const char *test_file = "../test_resources/vpk/hl2_misc_dir.vpk";

using namespace opensrc;

const char *error_to_string(vpk::ReadError);

int main() {
    const vpk::ReadResult result = vpk::read(test_file);
    if (result.error != vpk::ReadError::Ok) {
        std::cout << "Couldn't read " << test_file << ": "
            << error_to_string(result.error) << "\n";
        return 1;
    }

    std::cout << "All good.\n";

    const vpk::Dir dir = result.result;

    vpk::free(dir);

    return 0;
}

const char *error_to_string(vpk::ReadError err) {
    using e = vpk::ReadError;
    switch (err) {
        case e::BadSignature:
            return "File is not a VPK (bad signature)";
        case e::TooSmall:
            return "File is too small to be valid VPK";
        case e::BadVersion:
            return "Unsupported VPK version";
        case e::OutOfMemory:
            return "Ran out of memory while reading";
        case e::FileNotFound:
            return "File does not exist";
        default:
            return "Life is a circus, and we are the clowns.";
    }
}
