protocol DependencyProtocol {
    func callAsFunction() -> Any
    var arguments: [Any] { get set }
}

fileprivate final class Dependency<T>: DependencyProtocol {
    let identifier: ObjectIdentifier
    var initializer: () -> T
    var arguments = [Any]()
    
    init(_ type: T.Type, _ inititializer: @escaping () -> T) {
        self.identifier = ObjectIdentifier(type)
        self.initializer = inititializer
    }
    
    convenience init<a0>(_ type: T.Type, _ initializer: @escaping (a0) -> T) {
        self.init(type, { preconditionFailure("Dependency has not been properly constructed.") })
        self.initializer = { [self] in initializer(self.arguments[0] as! a0) }
    }
    
    func callAsFunction() -> Any {
        initializer()
    }
}

protocol Registrar {
    func callAsFunction<T>(_ type: T.Type, _ inititalizer: @escaping () -> T)
    func callAsFunction<T, a0>(_ type: T.Type, _ inititalizer: @escaping (a0) -> T)
}

protocol Resolver {
    func callAsFunction<T>(_ type: T.Type) -> T?
    func callAsFunction<T>(_ type: T.Type, arguments: [Any]) -> T?
}

final class DI {
    static var register: Registrar { shared }
    static var resolve: Resolver { shared }
    static let shared = DI()
    private var dependencies = [ObjectIdentifier: DependencyProtocol]()
    
    private init() {}
}

extension DI: Registrar {
    func callAsFunction<T>(_ type: T.Type, _ inititalizer: @escaping () -> T) {
        let dependency = Dependency(type, inititalizer)
        dependencies[dependency.identifier] = dependency
    }
    
    func callAsFunction<T, a0>(_ type: T.Type, _ inititalizer: @escaping (a0) -> T) {
        let dependency = Dependency(type, inititalizer)
        dependencies[dependency.identifier] = dependency
    }
}

extension DI: Resolver {
    func callAsFunction<T>(_ type: T.Type) -> T? {
        let identifier = ObjectIdentifier(type)
        return dependencies[identifier]?() as? T
    }
    
    func callAsFunction<T>(_ type: T.Type, arguments: [Any]) -> T? {
        let identifier = ObjectIdentifier(type)
        dependencies[identifier]?.arguments = arguments
        return dependencies[identifier]?() as? T
    }
}

@propertyWrapper
struct Inject<T> {
    var wrappedValue: T?
    
    init(_ arguments: Any...) {
        wrappedValue = DI.resolve(T.self, arguments: arguments)
    }
    
    init() {
        wrappedValue = DI.resolve(T.self)
    }
}

// MARK: - Usage examples

DI.register(A.self) { arg in A.init(a: arg) }

class B {
    @Inject(44) var dependency: A?
}

let a = B()
a.dependency
a.dependency?.a

class A { var a = 42; init(a: Int) {self.a = a} }

//Task.detached {
//    await DI.register(A.self) { arg in A.init(a: arg) }
//    if let a = await DI.resolve(A.self, arguments: [43]) {
//        a.a
//    }
//}

