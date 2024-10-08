//
//  RepositoryFlowTests.swift
//  
//
//  Created by Sergio Daniel on 3/09/24.
//

import Combine
import Foundation
import Testing

@testable import BankaiCore

struct RepositoryFlowTests {
    
    @MainActor
    @Test
    func testLocalOnlyRepositoryFlow() async {
        let testScheduler: AnySchedulerOf<DispatchQueue> = .immediate
        var lastNumber = 0
        var remoteReceived: String?
        var hasCompleted = false
        var cancellable: AnyCancellable!
        
        // Given
        let sut = RepositoryFlow<Int>(onlyLocalExpected: true,
                                      scheduler: testScheduler) { receiver in
            try await Task.sleep(for: 0.5)
            receiver.send(local: 1)
        }
        
        // When
        await confirmation { confirmation in
            sut.onLocal {
                lastNumber = $0
            }.onRemote { data, label in
                lastNumber = data
                remoteReceived = label
            }.onCompletion {
                hasCompleted = true
                confirmation()
            }
            
            cancellable = sut.run()
            try! await Task.sleep(for: 1.seconds)
        }
        
        // Then
        #expect(lastNumber == 1)
        #expect(remoteReceived == nil)
        #expect(hasCompleted)
        #expect(sut.hasCompleted)
        
        cancellable.cancel()
    }
    
    @MainActor
    @Test
    func testRegularRepositoryFlow() async {
        let testScheduler: AnySchedulerOf<DispatchQueue> = .immediate
        var lastNumber = 0
        var remoteReceived: String?
        var hasCompleted = false
        var cancellable: AnyCancellable!
        
        // Given
        let sut = RepositoryFlow<Int>(onlyLocalExpected: false,
                                      scheduler: testScheduler) { receiver in
            try await Task.sleep(for: 0.5)
            receiver.send(local: 1)
            
            try await Task.sleep(for: 0.5)
            receiver.send(remote: 2, from: "api")
        }
        
        // When
        await confirmation { confirmation in
            sut.onLocal {
                lastNumber = $0
            }.onRemote { data, label in
                lastNumber = data
                remoteReceived = label
            }.onCompletion {
                hasCompleted = true
                confirmation()
            }
            
            cancellable = sut.run()
            try! await Task.sleep(for: 2.seconds)
        }
        
        // Then
        #expect(lastNumber == 2)
        #expect(remoteReceived == "api")
        #expect(hasCompleted)
        #expect(sut.hasCompleted)
        
        cancellable.cancel()
    }
    
    @MainActor
    @Test
    func testRegularRepositoryFlowAsPublisher() async {
        let testScheduler: AnySchedulerOf<DispatchQueue> = .immediate
        var lastNumber = 0
        var remoteReceived: String?
        var hasCompleted = false
        var cancellable: AnyCancellable!
        
        // Given
        let sut = RepositoryFlow<Int>(onlyLocalExpected: false,
                                      scheduler: testScheduler) { receiver in
            try await Task.sleep(for: 0.5)
            receiver.send(local: 1)
            
            try await Task.sleep(for: 0.5)
            receiver.send(remote: 2, from: "api")
        }
        
        // When
        await confirmation { confirmation in
            cancellable = sut
                .republish()
                .sink(receiveCompletion: { completion in
                    hasCompleted = true
                    confirmation()
                }, receiveValue: { snapshot in
                    switch snapshot {
                    case .local(let data):
                        print(">>> Flow detected incoming local data")
                        lastNumber = data
                    case .remote(let data, let remoteName):
                        lastNumber = data
                        remoteReceived = remoteName
                    }
                })
            
            try! await Task.sleep(for: 2.seconds)
        }
        
        // Then
        #expect(lastNumber == 2)
        #expect(remoteReceived == "api")
        #expect(hasCompleted)
        #expect(sut.hasCompleted)
        
        cancellable.cancel()
    }
    
}
