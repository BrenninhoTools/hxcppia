Changelog
=========

1.1.0
-----

- Added a C++ module: header checks, FNV-1a hashes, native file stamps, script format version and a nanosecond clock.
- Invalid files are rejected before reaching hxcpp.
- Hot reload compares content hashes, so saving a file without changes does not reload it.
- Added a profiler (`Cppia.profiling`, `stats`, `profileReport`, `resetStats`).

1.0.1
-----

- The haxelib is now called `hxcppia`, because the `cppia` define it created turned the host build into a cppia build.

1.0.0
-----

- First release, moved out of Funkin' Psych.
- `Cppia`, `CppiaModule`, `CppiaGroup` and `CppiaScript`.
- Hot reload, priorities, stop values, static calls and error stacks.
- `cppia.macro.Host.setup` and the `haxelib run cppia` tool.
- End to end test on Windows, macOS and Linux.
