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
        BindsMacro.self,
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
        // Find static funcs annotated with @Provides and vars annotated with @Register
        var registerCalls: [String] = []
        let typeName: String
        if let s = decl.as(StructDeclSyntax.self) {
            typeName = s.identifier.text
        } else if let c = decl.as(ClassDeclSyntax.self) {
            typeName = c.identifier.text
        } else { return [] }

        // 1) @Provides static functions (zero-parameter)
        for member in decl.memberBlock.members {
            guard let funcDecl = member.decl.as(FunctionDeclSyntax.self) else { continue }
            guard funcDecl.modifiers?.contains(where: { $0.name.text == "static" }) == true else { continue }
            let hasProvides = funcDecl.attributes?.contains(where: { ($0.as(AttributeSyntax.self)?.attributeName.description ?? "").contains("Provides") }) == true
            guard hasProvides else { continue }
            guard let returnType = funcDecl.signature.output?.returnType.description.trimmingCharacters(in: .whitespacesAndNewlines), !returnType.isEmpty else { continue }
            // micro version: only zero-parameter providers
            guard funcDecl.signature.input.parameterList.isEmpty else { continue }

            // Extract @Provides arguments if present on this function
            var lifetimeExpr: String? = nil
            var qualifierExpr: String? = nil
            if let attrs = funcDecl.attributes {
                for attr in attrs {
                    guard let a = attr.as(AttributeSyntax.self) else { continue }
                    guard (a.attributeName.description).contains("Provides") else { continue }
                    if let args = a.argument?.as(TupleExprElementListSyntax.self) {
                        for el in args {
                            let label = el.label?.text ?? ""
                            let expr = el.expression.description.trimmingCharacters(in: .whitespacesAndNewlines)
                            if label == "lifetime" { lifetimeExpr = expr }
                            if label == "qualifier" { qualifierExpr = expr }
                        }
                    }
                }
            }

            var call = "c.register(\(returnType).self"
            if let q = qualifierExpr { call += ", qualifier: \(q)" } else { call += ", qualifier: nil" }
            if let l = lifetimeExpr { call += ", lifetime: \(l)" }
            call += ") { _ in \(typeName).\(funcDecl.name.text)() }"
            let callLine = call
            registerCalls.append(callLine)
        }

        // 2) @Register static variables (metadata-only wrapper)
        for member in decl.memberBlock.members {
            guard let varDecl = member.decl.as(VariableDeclSyntax.self) else { continue }
            guard varDecl.modifiers?.contains(where: { $0.name.text == "static" }) == true else { continue }
            let hasRegisterAttr = varDecl.attributes?.contains(where: { ($0.as(AttributeSyntax.self)?.attributeName.description ?? "").contains("Register") }) == true
            guard hasRegisterAttr else { continue }
            // For each binding, get the annotated type
            for binding in varDecl.bindings {
                guard let annot = binding.typeAnnotation else { continue }
                let ty = annot.type.description.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !ty.isEmpty else { continue }
                // Extract lifetime and qualifier from the @Register attribute
                var lifetimeExpr: String? = nil
                var qualifierExpr: String? = nil
                if let attrs = varDecl.attributes {
                    for attr in attrs {
                        guard let a = attr.as(AttributeSyntax.self) else { continue }
                        guard (a.attributeName.description).contains("Register") else { continue }
                        if let args = a.argument?.as(TupleExprElementListSyntax.self) {
                            for (i, el) in args.enumerated() {
                                let label = el.label?.text
                                let expr = el.expression.description.trimmingCharacters(in: .whitespacesAndNewlines)
                                if i == 0 && label == nil { lifetimeExpr = expr }
                                if label == "lifetime" { lifetimeExpr = expr }
                                if label == "qualifier" { qualifierExpr = expr }
                            }
                        }
                    }
                }
                var call = "c.register(\(ty).self"
                if let q = qualifierExpr { call += ", qualifier: \(q)" } else { call += ", qualifier: nil" }
                if let l = lifetimeExpr { call += ", lifetime: \(l)" }
                call += ") { r in \(ty)(resolver: r) }"
                registerCalls.append(call)
            }
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

// MARK: - @Binds

public struct BindsMacro: MemberMacro {
    public static func expansion(of node: AttributeSyntax,
                                 providingMembersOf decl: some DeclGroupSyntax,
                                 in context: some MacroExpansionContext) throws -> [DeclSyntax] {
        // Usage: @Binds(ProtocolType.self, lifetime: .scoped, qualifier: Named("x")) on a concrete type
        // Generate: static func __register(into c: Container) { c.register(ProtocolType.self, qualifier: ..., lifetime: ...) { r in Self(resolver: r) } }

        // Determine implementing type name
        let typeName: String
        if let s = decl.as(StructDeclSyntax.self) { typeName = s.identifier.text }
        else if let c = decl.as(ClassDeclSyntax.self) { typeName = c.identifier.text }
        else { return [] }

        // Parse attribute arguments
        var protocolTypeExpr: String? = nil
        var lifetimeExpr: String? = nil
        var qualifierExpr: String? = nil
        if let args = node.argument?.as(TupleExprElementListSyntax.self) {
            for (i, el) in args.enumerated() {
                let label = el.label?.text
                let expr = el.expression.description.trimmingCharacters(in: .whitespacesAndNewlines)
                if i == 0 && label == nil { protocolTypeExpr = expr } // first unlabeled
                if label == "to" { protocolTypeExpr = expr }
                if label == "lifetime" { lifetimeExpr = expr }
                if label == "qualifier" { qualifierExpr = expr }
            }
        }
        guard let proto = protocolTypeExpr else { return [] }

        let access = (decl.modifiers?.description.contains("public") == true) ? "public " : ""
        var call = "\(access)static func __register(into c: Container) { c.register(\(proto)"
        if let q = qualifierExpr { call += ", qualifier: \(q)" } else { call += ", qualifier: nil" }
        if let l = lifetimeExpr { call += ", lifetime: \(l)" }
        call += ") { r in \(typeName)(resolver: r) } }"
        let out = try! DeclSyntax("extension \(raw: typeName) {\n\(raw: call)\n}")
        return [out]
    }
}
