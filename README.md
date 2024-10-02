Use Graph 

## How To Use

### Dynamic analyse

If you want to use Dynamic analyse, you should call
```sh
use_graph usage_graph_dynamic --schemes <scheme to build> --project-path <path to your workspace/xbproj/Package.swift file>
```

If you want to use Monolite destroyer, you should call
```sh
use_graph usage_graph_dynamic_analyze --schemes <scheme to build> --project-path <path to your workspace/xbproj/Package.swift file> --folder-paths <Paths to folder with sources - "path1,path2,path3">
```

> Guided setup only works for Xcode and SwiftPM projects, to use Periphery with non-Apple build systems such as Bazel, see [Build Systems](#build-systems).

After answering a few questions, Periphery will print out the full scan command and execute it.
