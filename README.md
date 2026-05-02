# YouPlot2

[![build](https://github.com/red-data-tools/YouPlot2/actions/workflows/build.yml/badge.svg)](https://github.com/red-data-tools/YouPlot2/actions/workflows/build.yml)

[YouPlot2](https://github.com/red-data-tools/YouPlot2) is an experimental [Crystal](https://github.com/crystal-lang/crystal) rewrite of [YouPlot](https://github.com/red-data-tools/YouPlot).

## Installation

Download the binary from the [GitHub Releases](https://github.com/red-data-tools/YouPlot2/releases).

- Provides prebuilt portable binaries.
- Uses statically linked builds on Linux and Windows.
- Provides portable precompiled executables on macOS.
- Intended to work in environments where additional dependencies are hard to install.

## Usage

See [YouPlot](https://github.com/red-data-tools/YouPlot).

## Development

```sh
git clone https://github.com/red-data-tools/YouPlot2
cd YouPlot2
shards build
bin/uplot2 --version
```

Dependent libraries:
[unicode_plot.cr](https://github.com/crystal-data/unicode_plot.cr)
