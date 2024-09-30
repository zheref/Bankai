//
//  BankaiUDF.swift
//  BankaiCore
//
//  Created by Sergio Daniel on 9/29/24.
//

@preconcurrency import Combine
import Foundation

public protocol Feature<State, Event> where Event: Sendable, State: Equatable {
    associatedtype State
    associatedtype Event
}

@Observable
public final class StoreOf<F: Feature> {
    public var state: F.State
    public var reducer: (inout F.State, F.Event) -> Effect<F.Event>
    
    public init(
        state: F.State,
        reducer: @escaping (
            inout F.State,
            F.Event
        ) -> Effect<F.Event>
    ) {
        self.state = state
        self.reducer = reducer
    }
}

public struct Effect<Event: Sendable>: Sendable {
    let stream: AsyncStream<Event?>
    
    init(_ stream: AsyncStream<Event?>) {
        self.stream = stream
    }
    
    init(build: (AsyncStream<Event?>.Continuation) -> Void) {
        self.stream = AsyncStream(Event?.self, build)
    }
    
    // None
    public static var none: Self {
        .init { $0.finish() }
    }
    
    // Fire and Forget
    public static func fireAndForget(
        _ operation: @Sendable @escaping () async -> Void
    ) -> Self {
        .init(AsyncStream(unfolding: {
            await operation()
            return nil
        }))
    }
    
    // Sychronous One
    public static func send(_ event: Event) -> Self {
        .init {
            $0.yield(event)
            $0.finish()
        }
    }
    
    // Expect One
    public static func async(
        _ operation: @Sendable @escaping () async -> Event,
        onCancel: @escaping @Sendable () -> Void = {}
    ) -> Self {
        .init(AsyncStream(unfolding: { await operation() },
                          onCancel: onCancel))
    }
    
    // Expect Multiple
    public static func fromFlow(_ flow: some FlowOf<Event, Never>) -> Self {
        .init(
            flow
                .map { Optional<Event>.some($0) }
                .eraseToAnyPublisher()
                .stream
        )
    }
    
    public typealias EventSend = @Sendable (Event) async -> Void
    
    public static func run(_ operation: @Sendable @escaping (EventSend) async -> Void) -> Self {
        .init { continuation in
            let task = Task {
                await operation { event in
                    continuation.yield(event)
                }
            }
            
            continuation.onTermination = { continuation in
                task.cancel()
            }
        }
    }
    
    // Parallel
    public static func parallel(_ effects: [Self]) -> Self {
        guard effects.isEmpty == false else { return .none }
        
        return .init { continuation in
            let task = Task {
                await withTaskGroup(of: Void.self) { group in
                    var leftToComplete = effects.count
                    
                    for effect in effects {
                        group.addTask {
                            for await event in effect.stream {
                                continuation.yield(event)
                            }
                        }
                    }
                    
                    for await _ in group { leftToComplete -= 1 }
                }
            }
            
            continuation.onTermination = { continuation in task.cancel() }
        }
    }
    
    // Concat
    public static func serial(_ effects: [Self]) -> Self {
        guard effects.isEmpty == false else { return .none }
        
        return .init { continuation in
            let task = Task {
                for effect in effects {
                    for await event in effect.stream {
                        continuation.yield(event)
                    }
                }
            }
            
            continuation.onTermination = { continuation in task.cancel() }
        }
    }
    
}

public typealias EffectOf<F: Feature> = Effect<F.Event>

extension AnyPublisher where Failure == Never, Output: Sendable {
    
    var stream: AsyncStream<Output> {
        .init { @Sendable continuation in
            let cancellable = sink { completion in
                continuation.finish()
            } receiveValue: { output in
                continuation.yield(output)
            }

            continuation.onTermination = { continuation in
                cancellable.cancel()
            }
        }
    }
    
}
