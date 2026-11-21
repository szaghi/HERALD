# Changelog

All notable changes to this project are documented here.
Versions follow [Semantic Versioning](https://semver.org/).
Format follows [Keep a Changelog](https://keepachangelog.com/).

## [0.1.0] — 2026-11-21
### Added
- Scaffold HERALD, the MPI handler library for HPC codes

- **mpih**: The core of the MPI handler, on any communicator

- **timer**: Named accumulating timers, reduced over the ranks

- **memory**: The memory budget of each rank, and what the process uses

- **device**: The device of each rank, its sharers and its memory budget

- **device**: FUNDAL's device features, the OpenMP layer in CI

- **timer**: CPU time, seconds per call, misuse counts and a CSV report


### Documentation
- The quick start, compiled and run, and the handler's status

- Tutorial, cookbook, reference and API, on examples that run


### Fixed
- **timer**: Discard an interval read on two different clocks



