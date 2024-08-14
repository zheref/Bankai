//
//  TimedData.swift
//  
//
//  Created by Sergio Daniel on 13/08/24.
//

import Combine

// Closure Based: Promise
// RX Based: Future
// Concurrency Based: Task

public enum ZEvent<T, E> {
    case value(T)
    case failure(E)
    case complete
}

// Void to void ONCE
public typealias ZBlock = (Error?) -> Void
public typealias ZTask = AnyPublisher<Void, Error>
public typealias ZJob = () async throws -> Void

// Void to 1 value
public typealias ZPromised<T, E: Error> = Future<T, E>
public typealias ZFuture<T> = () async throws -> T

// Void to 1..* values
public typealias ZYielderOf<T, E: Error> = ((Result<T, E>) -> Void) -> Void

// Void to * values
public typealias ZFlowOf<T, E: Error> = AnyPublisher<T, E>
public typealias ZSubjectOf<T, E: Error> = PassthroughSubject<T, E>
public typealias ZStreamOf<T, E: Error> = AsyncThrowingStream<T, E>

extension PassthroughSubject {
    func eraseToAnySubscriber() -> AnySubscriber<Output, Failure> {
        return AnySubscriber(self)
    }
}

extension AnyPublisher {
    static func create1<T, E: Error>(_ collector: @escaping ((ZEvent<T, E>) -> Void) -> AnyCancellable) -> AnyPublisher<T, E> {
        let subject = PassthroughSubject<T, E>()
        var cancellable: Cancellable?
        
        return subject.handleEvents { subscription in
            cancellable = collector { result in
                let receiver = subject.eraseToAnySubscriber()
                switch result {
                case .value(let val):
                    let _ = receiver.receive(val)
                case .complete:
                    receiver.receive(completion: .finished)
                case .failure(let error):
                    receiver.receive(completion: .failure(error))
                }
            }
        } receiveCompletion: { completion in }
        receiveCancel: {
            cancellable?.cancel()
        }.eraseToAnyPublisher()
    }
    
    static func create2<T, E: Error>(_ collector: @escaping ((ZEvent<T, E>) -> Void) -> AnyCancellable) -> AnyPublisher<T, E> {
        let subject = PassthroughSubject<T, E>()
        
        let cancellable = collector { result in
            switch result {
            case .value(let val):
                subject.send(val)
            case .complete:
                subject.send(completion: .finished)
            case .failure(let error):
                subject.send(completion: .failure(error))
            }
        }
        
        return subject
            .handleEvents(receiveCancel: {
                cancellable.cancel()
            })
            .eraseToAnyPublisher()
    }
}

let testPublisher: AnyPublisher<Int, Error> = .create1 { send in
    for n in 0..<7 {
        send(.value(n))
    }
    
    send(.complete)
    
    return AnyCancellable {}
}
