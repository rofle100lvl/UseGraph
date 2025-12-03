UseGraph
=====================
<img src="https://storage.yandexcloud.net/swift-ui-course/MonolithDestroyer.png" width="300"/>


## How To Use

### Install

```sh
mint install rofle100lvl/UseGraph
```

### Usage
If you want to use Dynamic analyse, you should call
```sh
mint run UseGraph use_graph usage_graph_dynamic
--schemes <scheme to build>
--project-path <path to your workspace/xbproj/Package.swift file>
--format <Output file format. Now available: CSV, SVG, PNG, GV, JSON (default: csv)>
--index-store <path to your index store data folder
 ~/Library/Developer/Xcode/DerivedData/<your-project>/Index.noindex/DataStore/>
```

If you want to use Monolite destroyer, you should call
```sh
mint run UseGraph use_graph usage_graph_dynamic_analyze
--schemes <scheme to build>
--project-path <path to your workspace/xbproj/Package.swift file>
--monolith-path Paths to your monolith
--index-store <path to your index store data folder
~/Library/Developer/Xcode/DerivedData/<your-project>/Index.noindex/DataStore/>
```
