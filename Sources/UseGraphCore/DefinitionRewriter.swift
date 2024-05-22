import SwiftSyntax

final class DefinitionVisitor: SyntaxVisitor {
    var graphDependencies = [String: Set<String>]()
    private let codeBlockItemSyntaxVisitor = CodeBlockItemSyntaxVisitor()
    private let converter: SourceLocationConverter
    
    init(converter: SourceLocationConverter) {
        self.converter = converter
        super.init(viewMode: .all)
    }
    
    override func visit(_ node: CodeBlockItemSyntax) -> SyntaxVisitorContinueKind {
        codeBlockItemSyntaxVisitor.visitCode(
            node,
            graphDependencies: &graphDependencies
        )
    }
}

final class EntityVisitor: SyntaxVisitor {
    var entityName: String
    var graphDependencies = [String: Set<String>]()
    private let codeBlockItemSyntaxVisitor: CodeBlockItemSyntaxVisiting
    
    init(
        entityName: String,
        codeBlockItemSyntaxVisitor: CodeBlockItemSyntaxVisiting,
        graphDependencies: [String : Set<String>] = [String: Set<String>]()
    ) {
        self.entityName = entityName
        self.graphDependencies = graphDependencies
        self.codeBlockItemSyntaxVisitor = codeBlockItemSyntaxVisitor
        super.init(viewMode: .all)
    }
    
    override func visit(_ node: CodeBlockItemSyntax) -> SyntaxVisitorContinueKind {
        codeBlockItemSyntaxVisitor.visitCode(
            node,
            graphDependencies: &graphDependencies
        )
    }
    
    override func visit(_ node: MemberBlockItemSyntax) -> SyntaxVisitorContinueKind {
        codeBlockItemSyntaxVisitor.visitCode(
            node,
            containerName: self.entityName,
            graphDependencies: &graphDependencies
        )
    }
    
    override func visit(_ token: TokenSyntax) -> SyntaxVisitorContinueKind {
        if let firstSymbol = token.text.first,
           case .identifier = token.tokenKind,
           firstSymbol.isUppercase,
           !self.excludedTypes.contains(token.text) {
            if var set = graphDependencies[entityName] {
                set.insert(token.text)
                graphDependencies[entityName] = set
            } else {
                graphDependencies[entityName] = Set<String>().union([token.text])
            }
        }
        return .skipChildren
    }
}

extension EntityVisitor {
    var excludedTypes: [String] {
        [
            "String",
            "Int",
            "Bool",
            "URL",
            "Date",
            "Data",
            "UserDefaults",
            "NSAttributedString",
            "NSRange",
            "URLSession",
            "UUID",
            "FileManager",
            "NSError",
            "NSTimeZone",
            "NSPredicate",
            "NSLocale",
            "NSCalendar",
            "TimeInterval",
            "NSKeyedArchiver",
            "NSKeyedUnarchiver",
            "JSONDecoder",
            "JSONEncoder",
            "PropertyListDecoder",
            "PropertyListEncoder",
            "View",
            "Text",
            "Image",
            "Button",
            "HStack",
            "VStack",
            "LazyVStack",
            "ZStack",
            "ScrollView",
            "NavigationView",
            "List",
            "Toggle",
            "Slider",
            "TextField",
            "DatePicker",
            "Color",
            "LinearGradient",
            "RadialGradient",
            "AngularGradient",
            "Path",
            "Shape",
            "Gesture",
            "Environment",
            "EnvironmentObject",
            "State",
            "Binding",
            "ObservedObject",
            "GeometryReader",
            "Publisher",
            "Subscriber",
            "AnyPublisher",
            "AnySubscriber",
            "Just",
            "Future",
            "Subscribers.Demand",
            "URLSession.DataTaskPublisher",
            "PassthroughSubject",
            "CurrentValueSubject",
            "Sink",
            "Assign",
            "Cancellable",
            "Scheduler",
            "DispatchQueue",
            "RunLoop",
            "OperationQueue",
            "Timer.TimerPublisher",
            "Delay",
            "Collect",
            "Map",
            "Filter",
            "Reduce",
            "Merge",
            "CombineLatest",
            "Zip",
            "PreviewModifier",
            "ForEach",
            "EmptyView",
            "Namespace",
            "Layout",
            "PreviewModifier",
            "Double",
            "CGFloat",
            "IdentifiedArrayOf"
        ]
    }
}

