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
    
    
    @MainActor
    @Test
    func testRegularFetch() async {
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
        repository.add(remote: .init(label: "api", pushFixture: { items in
            mockedRemoteSource.append(contentsOf: items)
        }, pullFixture: { filter in
            guard let filter else {
                return mockedRemoteSource
            }
            
            return mockedRemoteSource.filter {
                $0.name.precomposedStringWithCanonicalMapping.contains(filter.keywords?.lowercased() ?? "")
            }
        }))
        
        // When
        var flow: RepositoryFlow<[TestObject]>!
        var cancellable: AnyCancellable!
        
        await confirmation(expectedCount: 3) { confirmation in
            flow = repository
                .fetch(on: .immediate)
                .onLocal { results in
                    mockedMemorySource = results
                    confirmation()
                }
                .onRemote { results, label in
                    print("Results received from remote(\(label ?? "unknown"))")
                    mockedMemorySource = results
                    remoteCalled = true
                    confirmation()
                }
                .onCompletion {
                    confirmation()
                }
        
            cancellable = flow.run()
            try! await Task.sleep(for: 3.seconds)
        }
        
        // Then
        XCTAssertTrue(remoteCalled)
        XCTAssertEqual(mockedMemorySource.count, mockedRemoteSource.count)
        XCTAssertEqual(mockedMemorySource.first, mockedRemoteSource.first)
        XCTAssertEqual(mockedMemorySource.last, mockedRemoteSource.last)
        XCTAssertTrue(flow.hasCompleted)
        
        cancellable.cancel()
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
        
        let cancellable = flow.run()
        wait(for: [expectation1, expectation2], timeout: 1.0)
        
        // Then
        XCTAssertFalse(remoteCalled)
        XCTAssertEqual(mockedMemorySource.count, mockedLocalSource.count)
        XCTAssertEqual(mockedMemorySource.first, mockedLocalSource.first)
        XCTAssertEqual(mockedMemorySource.last, mockedLocalSource.last)
        XCTAssertTrue(flow.hasCompleted)
        
        cancellable.cancel()
    }
    
    @MainActor
    func testRegularFetch() {
        let baseDate = Date.fromDateComponents(year: 2024, month: 9, day: 1)!
        let baseDateNextDay = baseDate.oneDayOut
        
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
        repository.add(remote: .init(label: "api", pushFixture: { items in
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
        
        flow.run().store(in: &cancellables)
        
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
    
    @MainActor
    func testMultipleRemotesFetch() {
        let baseDate = Date.fromDateComponents(year: 2024, month: 9, day: 1)!
        let baseDateNextDay = baseDate.oneDayOut
        let baseDate2DaysLater = baseDate.addingTimeInterval(2.days)
        
        var mockedMemorySource = [TestObject]()
        var mockedLocalSource: [TestObject] = [
            .init(id: 1, name: "Dog", updatedAt: nil),
            .init(id: 2, name: "Cat", updatedAt: Date()),
            .init(id: 3, name: "Bird", updatedAt: nil),
            .init(id: 4, name: "Fish", updatedAt: baseDate),
            .init(id: 5, name: "Turtle", updatedAt: nil),
        ]
        var mockedRemote1Source: [TestObject] = [
            .init(id: 1, name: "Dog1", updatedAt: nil),
            .init(id: 2, name: "Cat1", updatedAt: Date()),
            .init(id: 3, name: "Bird1", updatedAt: nil),
            .init(id: 4, name: "Fish1", updatedAt: baseDateNextDay),
            .init(id: 5, name: "Turtle1", updatedAt: nil),
            .init(id: 6, name: "Plant", updatedAt: Date()),
        ]
        var mockedRemote2Source: [TestObject] = [
            .init(id: 1, name: "Dog1", updatedAt: nil),
            .init(id: 2, name: "Cat1", updatedAt: Date()),
            .init(id: 3, name: "Bird1", updatedAt: nil),
            .init(id: 4, name: "Fish1", updatedAt: baseDateNextDay),
            .init(id: 5, name: "Turtle1", updatedAt: nil),
            .init(id: 6, name: "Plant1", updatedAt: Date()),
            .init(id: 7, name: "Mushroom", updatedAt: Date()),
        ]
        var remotesCalled = 0
        
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
        
        // We set repositories as we intend to fetch from local and several
        // remotes as well
        repository.add(remote: .init(label: "api1", pushFixture: { items in
            mockedRemote1Source.append(contentsOf: items)
        }, pullFixture: { filter in
            guard let filter else {
                return mockedRemote1Source
            }
            
            return mockedRemote1Source.filter {
                $0.name.precomposedStringWithCanonicalMapping.contains(filter.keywords?.lowercased() ?? "")
            }
        }))
        repository.add(remote: .init(label: "api2", pushFixture: { items in
            mockedRemote2Source.append(contentsOf: items)
        }, pullFixture: { filter in
            guard let filter else {
                return mockedRemote2Source
            }
            
            return mockedRemote2Source.filter {
                $0.name.precomposedStringWithCanonicalMapping.contains(filter.keywords?.lowercased() ?? "")
            }
        }))
        
        // Prepare expectations
        let expectation1 = XCTestExpectation(
            description: "Local results received"
        )
        let expectation2 = XCTestExpectation(
            description: "Remote #1 results received"
        )
        let expectation3 = XCTestExpectation(
            description: "Remote #2 results received"
        )
        let expectation4 = XCTestExpectation(
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
                remotesCalled += 1
                switch label {
                case "api1":
                    expectation2.fulfill()
                case "api2":
                    expectation3.fulfill()
                default:
                    break
                }
                
            }
            .onCompletion {
                expectation4.fulfill()
            }
        
        flow.run().store(in: &cancellables)
        
        // Wait
        wait(for: [expectation1], timeout: 1.0)
        
        // Then
        XCTAssertEqual(0, remotesCalled)
        XCTAssertEqual(mockedMemorySource.count, mockedLocalSource.count)
        XCTAssertEqual(mockedMemorySource.first, mockedLocalSource.first)
        XCTAssertEqual(mockedMemorySource.last, mockedLocalSource.last)
        XCTAssertFalse(flow.hasCompleted)
        
        // Wait
        wait(for: [expectation2], timeout: 3.0)
        
        // Then
        XCTAssertEqual(1, remotesCalled)
        XCTAssertEqual(mockedMemorySource.count, mockedRemote1Source.count)
        XCTAssertEqual(mockedMemorySource.first, mockedRemote1Source.first)
        XCTAssertEqual(mockedMemorySource.last, mockedRemote1Source.last)
        XCTAssertFalse(flow.hasCompleted)
        
        // Wait
        wait(for: [expectation3, expectation4], timeout: 5.0)
        
        // Then
        XCTAssertEqual(2, remotesCalled)
        XCTAssertEqual(mockedMemorySource.count, mockedRemote2Source.count)
        XCTAssertEqual(mockedMemorySource.first, mockedRemote2Source.first)
        XCTAssertEqual(mockedMemorySource.last, mockedRemote2Source.last)
        XCTAssertTrue(flow.hasCompleted)
    }
    
}
