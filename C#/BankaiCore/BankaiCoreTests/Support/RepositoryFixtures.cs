using BankaiCore.Repository;
using Microsoft.Reactive.Testing;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace BankaiCoreTests.Support;

public struct TestObject: Traceable
{
    public string id { get; init; }
    public string name { get; init; }

    public DateTime? updatedAt { get; set; }
}

struct TestFilter : Filter
{
    public bool onlyLocally { get; set; }
    public string? keywords {  get; set; }

    public static TestFilter none => new() { onlyLocally = false };
}

internal class FixtureLocal<T, F>: LocalDataSource<T, F>
    where T : Traceable
    where F : Filter
{
    event Func<List<T>, Task> storeFixture;
    event Func<F?, Task<List<T>>> retrieveFixture;

    internal FixtureLocal(
        Func<List<T>, Task> storeFixture, 
        Func<F?, Task<List<T>>> retrieveFixture
    )
    {
        this.storeFixture = storeFixture;
        this.retrieveFixture = retrieveFixture;
    }

    public Task prepare() => Task.CompletedTask;

    public Task<List<T>> retrieve(F? filter)
        => retrieveFixture(filter);

    public Task store(List<T> items)
        => storeFixture(items);
}

internal class RepositoryFixtures
{

}