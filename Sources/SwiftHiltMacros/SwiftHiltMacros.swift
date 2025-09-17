import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

@main
struct SwiftHiltPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        InjectableMacro.self,
        ProvidesMacro.self,
        ModuleMacro.self,
        ComponentMacro.self,
    ]
}

// MARK: - @Injectable

public struct InjectableMacro: MemberMacro {
    public static func expansion(of node: AttributeSyntax,
                                 providingMembersOf decl: some DeclGroupSyntax,
                                 in context: some MacroExpansionContext) throws -> [DeclSyntax] {
        guard let typeDecl = decl.as(StructDeclSyntax.self) ?? decl.as(ClassDeclSyntax.self) else {
            return []
        }
        // Find the first initializer
        guard let memberInit = decl.memberBlock.members.compactMap({ $0.decl.as(InitializerDeclSyntax.self) }).first else {
            return []
        }

        // Build parameters: for each param (name: Type), generate local let binding via resolver.resolve(Type.self)
        var paramInits: [String] = []
        var callArgs: [String] = []
        if let paramClause = memberInit.signature.input.parameterList.as(FunctionParameterListSyntax.self) {
            for p in paramClause {
                guard let firstName = p.firstName?.text, let type = p.type?.description.trimmingCharacters(in: .whitespacesAndNewlines), !firstName.isEmpty, !type.isEmpty else { continue }
                let localName = "__\(firstName)"
                // Simple: no qualifiers in micro version
                paramInits.append("let \(localName): \(type) = resolver.resolve(\(type).self)")
                callArgs.append("\(firstName): \(localName)")
            }
        }

        let access = (typeDecl.modifiers?.description.contains("public") == true) ? "public " : ""
        let body = (["\(access)init(resolver: Resolver) {" ] + paramInits.map { "    \($0)" } + ["    self.init(\(callArgs.joined(separator: ", ")))\n}" ]).joined(separator: "\n")
        let decl = try! DeclSyntax("extension \(raw: typeDecl.identifier.text) {\n\(raw: body)\n}")
        return [decl]
    }
}

// MARK: - @Provides (marker)

public struct ProvidesMacro: PeerMacro {
    public static func expansion(of node: AttributeSyntax,
                                 providingPeersOf decl: some DeclSyntaxProtocol,
                                 in context: some MacroExpansionContext) throws -> [DeclSyntax] { [] }
}

// MARK: - @Module

public struct ModuleMacro: MemberMacro {
    public static func expansion(of node: AttributeSyntax,
                                 providingMembersOf decl: some DeclGroupSyntax,
                                 in context: some MacroExpansionContext) throws -> [DeclSyntax] {
        // Find static funcs annotated with @Provides
        var registerCalls: [String] = []
        let typeName: String
        if let s = decl.as(StructDeclSyntax.self) {
            typeName = s.identifier.text
        } else if let c = decl.as(ClassDeclSyntax.self) {
            typeName = c.identifier.text
        } else { return [] }

        for member in decl.memberBlock.members {
            guard let funcDecl = member.decl.as(FunctionDeclSyntax.self) else { continue }
            guard funcDecl.modifiers?.contains(where: { $0.name.text == "static" }) == true else { continue }
            let hasProvides = funcDecl.attributes?.contains(where: { ($0.as(AttributeSyntax.self)?.attributeName.description ?? "").contains("Provides") }) == true
            guard hasProvides else { continue }
            guard let returnType = funcDecl.signature.output?.returnType.description.trimmingCharacters(in: .whitespacesAndNewlines), !returnType.isEmpty else { continue }
            // micro version: zero-parameter providers
            guard funcDecl.signature.input.parameterList.isEmpty else { continue }
            let callLine = "c.register(\(returnType).self) { _ in \(typeName).\(funcDecl.name.text)() }"
            registerCalls.append(callLine)
        }

        let access = (decl.modifiers?.description.contains("public") == true) ? "public " : ""
        let body = (["\(access)static func __register(into c: Container) {" ] + registerCalls.map { "    \($0)" } + ["}" ]).joined(separator: "\n")
        let out = try! DeclSyntax("extension \(raw: typeName) {\n\(raw: body)\n}")
        return [out]
    }
}

// MARK: - @Component

public struct ComponentMacro: MemberMacro {
    public static func expansion(of node: AttributeSyntax,
                                 providingMembersOf decl: some DeclGroupSyntax,
                                 in context: some MacroExpansionContext) throws -> [DeclSyntax] {
        // Parse modules from attribute argument list: @Component(modules: [Foo.self, Bar.self])
        var moduleTypeNames: [String] = []
        if let arguments = node.argument?.as(TupleExprElementListSyntax.self) {
            for arg in arguments {
                if arg.label?.text == "modules" {
                    if let array = arg.expression.as(ArrayExprSyntax.self) {
                        for elt in array.elements {
                            let text = elt.expression.description
                            // Expect Something.self
                            if let dot = text.firstIndex(of: ".") {
                                let name = String(text[..<dot]).trimmingCharacters(in: .whitespacesAndNewlines)
                                if !name.isEmpty { moduleTypeNames.append(name) }
                            }
                        }
                    }
                }
            }
        }

        let regCalls = moduleTypeNames.map { "\($0).__register(into: c)" }
        let access = (decl.modifiers?.description.contains("public") == true) ? "public " : ""
        let body = (["\(access)static func build() -> Container {", "    let c = Container()"] + regCalls.map { "    \($0)" } + ["    return c", "}"]).joined(separator: "\n")
        let out = try! DeclSyntax("extension \(raw: (decl.as(StructDeclSyntax.self)?.identifier.text ?? decl.as(ClassDeclSyntax.self)?.identifier.text ?? "Component")) {\n\(raw: body)\n}")
        return [out]
    }
}

