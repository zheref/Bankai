//
//  OpStack.swift
//  BankaiCore
//
//  Created by Sergio Daniel on 20/02/25.
//

public struct OpError: Error, Hashable {
    public let message: String
    public let recoverable: Bool
    
    public init(message: String, recoverable: Bool = false) {
        self.message = message
        self.recoverable = recoverable
    }
}

public enum OpStatus: Hashable {
    case pending
    case ongoing
    case completed
    case failed(OpError)
}

public struct Op: Hashable {
    public let name: String
    public var status: OpStatus
    public var isProgressCountable: Bool = true
    
    public static func starting(_ name: String) -> Op {
        .init(name: name, status: .ongoing)
    }
    
    public var isResolved: Bool {
        switch status {
        case .completed, .failed:
            return true
        default:
            return false
        }
    }
    
    public var isFailed: Bool {
        switch status {
        case .failed:
            return true
        default:
            return false
        }
    }
    
    public var error: OpError? {
        if case .failed(let error) = status {
            return error
        } else {
            return nil
        }
    }
}

public struct OpStack: Hashable {
    public let key: String
    var ops = [Op]()
}

// MARK: Derived

extension OpStack {
    
    public var scheduledOpsCount: Int {
        ops
            .filter { $0.isProgressCountable }
            .filter { $0.isResolved == false }
            .count
    }
    
    public var resolvedOpsCount: Int {
        ops
            .filter { $0.isProgressCountable }
            .filter(\.isResolved)
            .count
    }
    
    public var failureMessages: [String] {
        ops
            .filter(\.isFailed)
            .compactMap(\.error)
            .map(\.message)
    }
    
}

// MARK: Mutators

extension OpStack {
    public mutating func push(_ op: Op) {
        ops.append(op)
    }
    
    public mutating func failed(_ opName: String, withError error: OpError) {
        print(
            "[\(key)] Failed operation[\(opName)] with message[\(error.message)]"
        )
        print("[\(key)] Resolved \(resolvedOpsCount)/\(scheduledOpsCount)")
        
        guard let opIndex = ops.firstIndex(where: { $0.name == opName }) else {
            return
        }
        
        ops[opIndex].status = .failed(error)
        attemptReset()
    }
    
    public mutating func completed(_ opName: String) {
        print("[\(key)] Completed operation[\(opName)]")
        print("[\(key)] Resolved \(resolvedOpsCount)/\(scheduledOpsCount)")
        
        guard let opIndex = ops.firstIndex(where: { $0.name == opName }) else {
            return
        }
        
        ops[opIndex].status = .completed
        attemptReset()
    }
    
    private mutating func attemptReset() {
        if ops.allSatisfy(\.isResolved) {
            print("[\(key)] Resolved all ops!")
            print("[\(key)] Resetting Ops Stack...")
            ops = [Op]()
        }
    }
}

// MARK: Factories

extension OpStack {
    public static func idle(key: String) -> OpStack { .init(key: key) }
    
    public static func loading(op: Op, in key: String) -> OpStack {
        var stack = idle(key: key)
        stack.push(op)
        return stack
    }
}
