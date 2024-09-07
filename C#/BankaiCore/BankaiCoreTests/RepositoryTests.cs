using System;
using System.Collections.Generic;
using System.Linq;
using System.Net.Http.Headers;
using System.Reactive.Concurrency;
using System.Text;
using System.Threading.Tasks;
using BankaiCore.Repository;
using BankaiCoreTests.Support;
using Microsoft.Reactive.Testing;

namespace BankaiCoreTests;

[TestClass]
public class RepositoryTests
{
    [TestMethod]
    public void testOnlyLocalFetch()
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
        Repository<TestObject, TestFilter> repository 
            = new ARepositoryOf<TestObject, TestFilter>(
                local: new FixtureLocal<TestObject, TestFilter>(
                    storeFixture: async (items) =>
                    {
                        mockedLocalSource.AddRange(items);
                    },
                    retrieveFixture: async filter =>
                    {
                        if (filter is TestFilter
                            {
                                keywords: String uKeywords
                            } testFilter)
                            return mockedLocalSource
                                .Where(item => 
                                    item.name
                                    .ToLower()
                                    .Contains(uKeywords.ToLower() ?? "")
                                )
                                .ToList();
                        else
                            return mockedMemorySource;
                    }
                )
            );

        // We don't set any remote as we intend this case to be local only

        // Prepare expectations


        // When
        var flow = repository.fetch(TestFilter.none, scheduler: testScheduler)
                                    .onLocal(results =>
                                    {

                                    })
                                    .onRemote((results, label) =>
                                    {
                                        remoteCalled = true;
                                    })
                                    .onCompletion(() =>
                                    {
                                    }); 
    }
}
