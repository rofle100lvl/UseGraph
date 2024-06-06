import XcodeProj
import Foundation

final class XcodeprojManager {
    static func getAllModules(projUrl: String) throws -> [String] {
        var targets: [String] = []
        let proj = try XCWorkspace(path: .init(projUrl))
        for element in proj.data.children {
            if URL(string: element.location.path)?.pathExtension == "xcodeproj" &&
                URL(string: element.location.path)?.lastPathComponent != "Pods.xcodeproj"
            {
                var url = URL(string: projUrl)!
                url.deleteLastPathComponent()
                url.append(path: element.location.path)
                let project = try XcodeProj(path: .init(url.path()))
                project.pbxproj.nativeTargets.forEach { targets.append($0.name) }
            }
        }
        return targets
    }
}
