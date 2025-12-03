# UseGraph

<img src="https://storage.yandexcloud.net/swift-ui-course/MonolithDestroyer.png" width="300"/>

A powerful Swift command-line tool for analyzing and visualizing code dependencies in Swift projects. UseGraph helps you understand your codebase structure, identify dependencies, and break down monolithic architectures.

## Features

- 🔍 **Dependency Graph Generation** - Build comprehensive usage graphs of your Swift codebase
- 🏗️ **Monolith Analysis** - Identify and analyze dependencies within monolithic code structures
- 📊 **Multiple Output Formats** - Export graphs in CSV, JSON, SVG, PNG, or GraphViz formats
- 🎯 **Index Store Integration** - Leverage Xcode's index store for accurate dependency tracking
- 🧩 **Modular Architecture** - Built with clean architecture principles (Domain, Data, Presentation layers)

## Installation

### Using Mint

```sh
mint install rofle100lvl/UseGraph
```

### Manual Installation

Clone the repository and build using Swift Package Manager:

```sh
git clone https://github.com/rofle100lvl/UseGraph.git
cd UseGraph
swift build -c release
```

## Usage

UseGraph provides two main commands:

### 1. Build Usage Graph

Generate a dependency graph for your Swift project:

```sh
mint run UseGraph use_graph usage_graph \
  --schemes <scheme-name> \
  --project-path <path-to-xcodeproj-or-workspace> \
  --format <output-format> \
  --index-store <path-to-index-store>
```

**Parameters:**

- `--schemes` (required) - Comma-separated list of schemes to analyze
- `--project-path` (optional) - Path to your `.xcodeproj` or `.xcworkspace` file
- `--format` (optional) - Output format: `csv`, `json`, `svg`, `png`, or `gv` (default: `csv`)
- `--index-store` (optional) - Path to Xcode's index store data folder  
  (typically: `~/Library/Developer/Xcode/DerivedData/<your-project>/Index.noindex/DataStore/`)

**Example:**

```sh
mint run UseGraph use_graph usage_graph \
  --schemes MyApp \
  --project-path ./MyApp.xcodeproj \
  --format svg \
  --index-store ~/Library/Developer/Xcode/DerivedData/MyApp-xxx/Index.noindex/DataStore/
```

### 2. Monolith Destroyer

Analyze dependencies within a monolithic module to help break it down:

```sh
mint run UseGraph use_graph monolith_destroyer \
  --schemes <scheme-name> \
  --project-path <path-to-xcodeproj-or-workspace> \
  --monolith-path <path-to-monolith-directory> \
  --index-store <path-to-index-store>
```

**Parameters:**

- `--schemes` (required) - Comma-separated list of schemes to analyze
- `--project-path` (optional) - Path to your `.xcodeproj` or `.xcworkspace` file
- `--monolith-path` (required) - Path to the monolithic module directory you want to analyze
- `--index-store` (optional) - Path to Xcode's index store data folder

**Example:**

```sh
mint run UseGraph use_graph monolith_destroyer \
  --schemes MyApp \
  --project-path ./MyApp.xcodeproj \
  --monolith-path ./Sources/CoreModule \
  --index-store ~/Library/Developer/Xcode/DerivedData/MyApp-xxx/Index.noindex/DataStore/
```

## Output Formats

UseGraph supports multiple output formats for different use cases:

- **CSV** - Tabular format for spreadsheet analysis
- **JSON** - Structured data for programmatic processing
- **SVG** - Scalable vector graphics for web viewing
- **PNG** - Raster image format for documentation
- **GV** - GraphViz DOT format for custom rendering

## Architecture

UseGraph is built with a clean, modular architecture:

- **UseGraphCore** - Core graph building and output formatting logic
- **UseGraphPeriphery** - Integration with Periphery for advanced code analysis
- **UseGraphStaticAnalysis** - Static analysis using SwiftSyntax
- **UseGraphFrontend** - Command-line interface and argument parsing
- **Utils** - Shared utilities and helpers

## Requirements

- macOS 14.0+
- Swift 5.9+
- Xcode 15.0+ (for index store generation)

## Dependencies

- [swift-argument-parser](https://github.com/apple/swift-argument-parser) - Command-line argument parsing
- [periphery](https://github.com/rofle100lvl/periphery/) - Swift code analysis
- [swift-syntax](https://github.com/apple/swift-syntax) - Swift syntax parsing
- [GraphViz](https://github.com/SwiftDocOrg/GraphViz) - Graph visualization
- [XcodeProj](https://github.com/tuist/XcodeProj) - Xcode project file parsing
- [swift-indexstore](https://github.com/kateinoigakukun/swift-indexstore) - Index store reading

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## Author

[rofle100lvl](https://github.com/rofle100lvl)
