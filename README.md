# OpenSrc
### Portable library for Valve's Source Engine file formats.
# Usage
Check out the `examples/` directory!
## As a static library:
### Build requirements
1. Git
2. [Zig Compiler](https://ziglang.org)
3. Brain (optional)

Clone this repository (recursively, to include dependencies)
```sh
git clone https://github.com/JTurtl/opensrc --recurse
cd opensrc
```

Build the project:
```sh
zig build -Drelease-fast
```
The result is `zig-out/lib/libopensrc.a` (or `opensrc.lib`).

C and C++ header files are available in `include/`.
## As a Zig package:
Copy this repository into your project, then add to your `build.zig` file:
```zig
// const exe = b.addExecutable(...)
exe.addPackagePath("opensrc", "path/to/opensrc/src/main.zig");
```
Or whatever equivalent code is needed.

If you're not familiar with the Zig build system, check out
[this three-part series](https://zig.news/xq/zig-build-explained-part-1-59lf).
# Features
## Complete:
- **:(**
## In-progress:
- [**VPK**](https://developer.valvesoftware.com/wiki/VPK_File_Format)
(uncompressed file archive)
- [**VTF**](https://developer.valvesoftware.com/wiki/Valve_Texture_Format)
(image data)
## Planned:
- [**MDL**](https://developer.valvesoftware.com/wiki/MDL)
(model info file)
- [**VVD**](https://developer.valvesoftware.com/wiki/VVD)
(model vertex data, needed by MDL files)
- [**VTX**](https://developer.valvesoftware.com/wiki/VTX)
(model mesh structure, part of the MDL gang)
- [**PHY**](https://developer.valvesoftware.com/wiki/PHY)
(physics/collision/hitbox info for models, last of the MDL crew)
- [**KeyValues**](https://developer.valvesoftware.com/wiki/KeyValues)
(knockoff JSON)
- [**KeyValues2**](https://developer.valvesoftware.com/wiki/KeyValues2)
(Electric Boogaloo)
- [**KeyValues3**](https://developer.valvesoftware.com/wiki/Dota_2_Workshop_Tools/KeyValues3)
(*THE FORBIDDEN NUMBER*)
- [**SMD**](https://developer.valvesoftware.com/wiki/Studiomdl_Data)
(mesh data in text form, intermediate stage between modeling program and in-game)
- [**QC**](https://developer.valvesoftware.com/wiki/QC)
(extra info for the model conversion process)
- [**DMX**](https://developer.valvesoftware.com/wiki/DMX)
(successor to SMD)
- [**BSP**](https://developer.valvesoftware.com/wiki/Source_BSP_File_Format)
(compiled map)
- [**FGD**](https://developer.valvesoftware.com/wiki/FGD)
(entity info for the Hammer editor)
- [**CFG**](https://developer.valvesoftware.com/wiki/CFG)
(configuration scripts to be run in-engine)
- **More language bindings** (in this repo, or new ones?)
## Maybe:
- Stored in basic KeyValues format, might be redundant:
  - [**VMF**](https://developer.valvesoftware.com/wiki/Valve_Map_Format)
(uncompiled map, used by the Hammer editor)
  - [**VMT**](https://developer.valvesoftware.com/wiki/Material)
(material/texture descriptor)
- Nobody cares:
  - [**GCF**](https://developer.valvesoftware.com/wiki/GCF)
(VPK predecessor, used by literally no one since 2008)
  - [**VPC Scripts**](https://developer.valvesoftware.com/wiki/Valve_Project_Creator)
(needlessly complex proprietary build system)
- Possibly out-of-scope:
  - **Everything Source2 related** (separate project?)
# Name of the Library
## How does one pronounce 'OpenSrc'?
### "Open sers" [ˈoʊ.pən sɜ(ɹ)s]
Where the "ser" in "sers" sounds like the "sear" in "search".
Sounds like "open sus" (ඞ) in non-rhodic accents.
## What does the name mean?
### [You don't get it? I thought it was clever.](https://en.wikipedia.org/wiki/GoldSrc)
## But that's not how it's pronounced...
### shut