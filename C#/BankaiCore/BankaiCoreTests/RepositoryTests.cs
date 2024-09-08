using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using System.Net.Http.Headers;
using System.Reactive.Concurrency;
using System.Text;
using System.Threading.Tasks;
using BankaiCore.Common;
using BankaiCore.Repository;
using BankaiCoreTests.Support;
using Microsoft.Reactive.Testing;

namespace BankaiCoreTests;

[TestClass]
public class RepositoryTests
{
    [TestMethod]
    public async Task testOnlyLocalFetch()
    {
        var testScheduler = new TestScheduler();

        var mockedMemorySource = new List<TestObject>();
        var mockedLocalSource = new List<TestObject>()
        {
            new() { id = "1", name = "Dog" },
            new() { id = "2", name = "Cat", updatedAt = DateTime.Now },
            new() { id = "3", name = "Bird", updatedAt = null },
            new() { id = "4", name = "Fish", updatedAt = DateTime.Now },
            new() { id = "5", name = "Turtle", updatedAt = null },
        };
        var remoteCalled = false;

        // Given
        async Task<List<TestObject>> retrieveFixtureMethod(TestFilter filter)
        {
            return await Task.Run(() =>
            {
                if (filter is { keywords: { } uKeywords } testFilter)
                    return mockedLocalSource
                        .Where(item => item.name.ToLower()
                            .Contains(uKeywords.ToLower() ?? ""))
                        .ToList();
                else
                    return mockedLocalSource;
            });
        }

        Repository<TestObject, TestFilter> repository 
            = new ARepositoryOf<TestObject, TestFilter>(
                local: new FixtureLocal<TestObject, TestFilter>(
                    storeFixture: (items) =>
                    {
                        mockedLocalSource.AddRange(items);
                        return Task.CompletedTask;
                    },
                    retrieveFixture: retrieveFixtureMethod
                )
            );

        // We don't set any remote as we intend this case to be local only

        // Prepare expectations
        var localResultsReceived = false;
        var remoteResultsReceived = false;
        var completionReceived = false;

        // When
        var flow = repository.fetch(TestFilter.none, scheduler: testScheduler)
                        .onLocal(results =>
                        {
                            localResultsReceived = true;
                            mockedMemorySource.Clear();
                            mockedMemorySource.AddRange(results);
                        })
                        .onRemote((results, label) =>
                        {
                            remoteCalled = true;
                            remoteResultsReceived = true;
                        })
                        .onCompletion(() =>
                        {
                            completionReceived = true;
                        });

        var cancellable = flow.run();

        // Wait
        testScheduler.AdvanceBy(1.Seconds().Ticks);
        await Task.Delay(1.Seconds());

        // Then
        Assert.IsTrue(localResultsReceived);
        Assert.IsFalse(remoteResultsReceived);
        Assert.IsTrue(completionReceived);
        Assert.IsFalse(remoteCalled);
        Assert.AreEqual(mockedLocalSource.Count, mockedMemorySource.Count);
        Assert.AreEqual(
            mockedLocalSource.FirstOrDefault(), 
            mockedMemorySource.FirstOrDefault()
        );
        Assert.AreEqual(
            mockedLocalSource.LastOrDefault(),
            mockedMemorySource.LastOrDefault()
        );

        cancellable.Dispose();
    }

    [TestMethod]
    public async Task testRegularFetch()
    {
        var testScheduler = new TestScheduler();
        var calendar = new GregorianCalendar();
        var baseDate = new DateTime(2024, 9, 1, calendar);
        var baseDateNextDay = baseDate.oneDayOut();

        var mockedMemorySource = new List<TestObject>();
        var mockedLocalSource = new List<TestObject>()
        {
            new() { id = "1", name = "Dog" },
            new() { id = "2", name = "Cat", updatedAt = DateTime.Now },
            new() { id = "3", name = "Bird", updatedAt = null },
            new() { id = "4", name = "Fish", updatedAt = baseDate },
            new() { id = "5", name = "Turtle", updatedAt = null },
        };
        //var mockedRemoteSource = new List<TestObject>()
        //{
        //    new() { id = "6", name = "Elephant" },
        //    new() { id = "7", name = "Lion", updatedAt = DateTime.Now },
        //    new() { id = "8", name = "Tiger", updatedAt = null },
        //    new() { id = "9", name = "Bear", updatedAt = DateTime.Now },
        //    new() { id = "10", name = "Wolf", updatedAt = null },
        //};
        var mockedRemoteSource = new List<TestObject>()
        {
            new() { id = "1", name = "Dog1" },
            new() { id = "2", name = "Cat1", updatedAt = DateTime.Now },
            new() { id = "3", name = "Bird1", updatedAt = null },
            new() { id = "4", name = "Fish1", updatedAt = baseDateNextDay },
            new() { id = "5", name = "Turtle1", updatedAt = null },
            new() { id = "5", name = "Plant", updatedAt = DateTime.Now },
        };
        var remoteCalled = false;

        // Given
        async Task<List<TestObject>> retrieveFixtureMethod(TestFilter filter)
        {
            return await Task.Run(() =>
            {
                if (filter is { keywords: { } uKeywords } testFilter)
                    return mockedLocalSource
                        .Where(item => item.name.ToLower()
                            .Contains(uKeywords.ToLower() ?? ""))
                        .ToList();
                else
                    return mockedLocalSource;
            });
        }

        Repository<TestObject, TestFilter> repository
            = new ARepositoryOf<TestObject, TestFilter>(
                local: new FixtureLocal<TestObject, TestFilter>(
                    storeFixture: (items) =>
                    {
                        mockedLocalSource.AddRange(items);
                        return Task.CompletedTask;
                    },
                    retrieveFixture: retrieveFixtureMethod
                )
            );

        // We set repository as we intend to fetch from local and remote
        // as well

        repository.remotes.Add(new FixtureRemote<TestObject, TestFilter>(
            label: "api",
            pullFixture: async (filter) =>
            {
                await Task.Delay(1);
                if (filter is { keywords: { } uKeywords } testFilter)
                    return mockedLocalSource
                        .Where(item => item.name.ToLower()
                            .Contains(uKeywords.ToLower() ?? ""))
                        .ToList();
                else
                    return mockedRemoteSource;
            },
            pushFixture: async (items) =>
            {
                mockedRemoteSource.AddRange(items);
                await Task.CompletedTask;
            }
        ));

        // Prepare expectations
        var localResultsReceived = false;
        var remoteResultsReceived = false;
        var completionReceived = false;

        // When
        var flow = repository.fetch(TestFilter.none, scheduler: testScheduler)
                        .onLocal(results =>
                        {
                            localResultsReceived = true;
                            mockedMemorySource.Clear();
                            mockedMemorySource.AddRange(results);
                        })
                        .onRemote((results, label) =>
                        {
                            remoteCalled = true;
                            remoteResultsReceived = true;
                            mockedMemorySource.Clear();
                            mockedMemorySource.AddRange(results);
                        })
                        .onCompletion(() =>
                        {
                            completionReceived = true;
                        });

        var cancellable = flow.run();

        // Wait
        testScheduler.AdvanceBy(1.Seconds().Ticks);
        await Task.Delay(1.Seconds());

        // Then
        Assert.IsTrue(localResultsReceived);
        Assert.IsTrue(remoteResultsReceived);
        Assert.IsTrue(completionReceived);
        Assert.IsTrue(remoteCalled);
        Assert.AreEqual(mockedRemoteSource.Count, mockedMemorySource.Count);
        Assert.AreEqual(
            mockedRemoteSource.FirstOrDefault(),
            mockedMemorySource.FirstOrDefault()
        );
        Assert.AreEqual(
            mockedRemoteSource.LastOrDefault(),
            mockedMemorySource.LastOrDefault()
        );

        cancellable.Dispose();
    }
}
