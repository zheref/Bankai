//
//  RepositoryTests.swift
//  
//
//  Created by Sergio Daniel on 13/08/24.
//

import Combine
import Foundation
import Testing
import XCTest
@testable import BankaiCore

struct RepositoryTests {
    
    
    @Test
    func testOnlyLocalFetch() {
        #expect(true)
    }
    
}

class RepositoryXCTests: XCTestCase {
    
    var cancellables = Set<AnyCancellable>()
    
    // It's important to run test on MainActor to ensure the
    // flow falls back on it.
    @MainActor
    func testOnlyLocalFetch() {
        var mockedMemorySource = [TestObject]()
        var mockedLocalSource: [TestObject] = [
            .init(id: 1, name: "Dog", updatedAt: nil),
            .init(id: 2, name: "Cat", updatedAt: Date()),
            .init(id: 3, name: "Bird", updatedAt: nil),
            .init(id: 4, name: "Fish", updatedAt: Date()),
            .init(id: 5, name: "Turtle", updatedAt: nil),
        ]
        var remoteCalled = false
        
        // Given
        let repository: ARepositoryOf<
            TestObject, TestFilter, FixtureLocal, FixtureRemote
        > = .init(local: .init(storeFixture: { items in
            mockedLocalSource.append(contentsOf: items)
        }, retrieveFixture: { filter in
            guard let filter else {
                return mockedLocalSource
            }
            
            return mockedLocalSource.filter {
                $0.name.precomposedStringWithCanonicalMapping.contains(filter.keywords?.lowercased() ?? "")
            }
        }))
        
        // We don't set any remote as we intend this case to be local only
        
        // Prepare expectations
        let expectation1 = XCTestExpectation(
            description: "Local results received"
        )
        let expectation2 = XCTestExpectation(
            description: "Repository flow completed"
        )
        
        // When
        let flow = repository
            .fetch(on: .immediate)
            .onLocal { results in
                mockedMemorySource = results
                expectation1.fulfill()
            }
            .onRemote { results, label in
                remoteCalled = true
            }
            .onCompletion {
                expectation2.fulfill()
            }
        
        flow.cancellable.store(in: &cancellables)
         wait(for: [expectation1, expectation2], timeout: 1.0)
        
        // Then
        XCTAssertFalse(remoteCalled)
        XCTAssertEqual(mockedMemorySource.count, mockedLocalSource.count)
        XCTAssertEqual(mockedMemorySource.first, mockedLocalSource.first)
        XCTAssertEqual(mockedMemorySource.last, mockedLocalSource.last)
        XCTAssertTrue(flow.hasCompleted)
    }
    
    @MainActor
    func testRegularFetch() {
        let baseDate = Date.fromDateComponents(year: 2024, month: 9, day: 1)!
        let baseDateNextDay = baseDate.addingTimeInterval(86400)
        
        var mockedMemorySource = [TestObject]()
        var mockedLocalSource: [TestObject] = [
            .init(id: 1, name: "Dog", updatedAt: nil),
            .init(id: 2, name: "Cat", updatedAt: Date()),
            .init(id: 3, name: "Bird", updatedAt: nil),
            .init(id: 4, name: "Fish", updatedAt: baseDate),
            .init(id: 5, name: "Turtle", updatedAt: nil),
        ]
        var mockedRemoteSource: [TestObject] = [
            .init(id: 1, name: "Dog1", updatedAt: nil),
            .init(id: 2, name: "Cat1", updatedAt: Date()),
            .init(id: 3, name: "Bird1", updatedAt: nil),
            .init(id: 4, name: "Fish1", updatedAt: baseDateNextDay),
            .init(id: 5, name: "Turtle1", updatedAt: nil),
            .init(id: 6, name: "Plant", updatedAt: Date()),
        ]
        var remoteCalled = false
        
        // Given
        var repository: ARepositoryOf<
            TestObject, TestFilter, FixtureLocal, FixtureRemote
        > = .init(local: .init(storeFixture: { items in
            mockedLocalSource.append(contentsOf: items)
        }, retrieveFixture: { filter in
            guard let filter else {
                return mockedLocalSource
            }
            
            return mockedLocalSource.filter {
                $0.name.precomposedStringWithCanonicalMapping.contains(filter.keywords?.lowercased() ?? "")
            }
        }))
        
        // We set repository as we intend to fetch from local and remote as well
        repository.add(remote: .init(pushFixture: { items in
            mockedRemoteSource.append(contentsOf: items)
        }, pullFixture: { filter in
            guard let filter else {
                return mockedRemoteSource
            }
            
            return mockedRemoteSource.filter {
                $0.name.precomposedStringWithCanonicalMapping.contains(filter.keywords?.lowercased() ?? "")
            }
        }))
        
        // Prepare expectations
        let expectation1 = XCTestExpectation(
            description: "Local results received"
        )
        let expectation2 = XCTestExpectation(
            description: "Remote results received"
        )
        let expectation3 = XCTestExpectation(
            description: "Repository flow completed"
        )
        
        // When
        let flow = repository
            .fetch(on: .immediate)
            .onLocal { results in
                mockedMemorySource = results
                expectation1.fulfill()
            }
            .onRemote { results, label in
                print("Results received from remote(\(label ?? "unknown"))")
                mockedMemorySource = results
                remoteCalled = true
                expectation2.fulfill()
            }
            .onCompletion {
                expectation3.fulfill()
            }
        
        flow.cancellable.store(in: &cancellables)
        
        // Wait
        wait(for: [expectation1], timeout: 1.0)
        
        // Then
        XCTAssertFalse(remoteCalled)
        XCTAssertEqual(mockedMemorySource.count, mockedLocalSource.count)
        XCTAssertEqual(mockedMemorySource.first, mockedLocalSource.first)
        XCTAssertEqual(mockedMemorySource.last, mockedLocalSource.last)
        XCTAssertFalse(flow.hasCompleted)
        
        // Wait
        wait(for: [expectation2, expectation3], timeout: 3.0)
        
        // Then
        XCTAssertTrue(remoteCalled)
        XCTAssertEqual(mockedMemorySource.count, mockedRemoteSource.count)
        XCTAssertEqual(mockedMemorySource.first, mockedRemoteSource.first)
        XCTAssertEqual(mockedMemorySource.last, mockedRemoteSource.last)
        XCTAssertTrue(flow.hasCompleted)
    }
    
}
