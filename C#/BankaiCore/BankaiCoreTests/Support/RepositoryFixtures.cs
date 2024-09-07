using BankaiCore.Repository;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace BankaiCoreTests.Support;

internal struct TestObject: Traceable
{
    public string id { get; init; }
    public string name { get; init; }

    public DateTime? updatedAt { get; set; }
}

struct TestFilter : Filter
{
    public bool onlyLocally { get; set; }
    public string? keywords {  get; set; }
}

internal class FixtureLocal<T, F>: LocalDataSource<T, F>
    where T : Traceable
    where F : Filter
{
    event Func<List<T>, Task> storeFixture = (list) => Task.CompletedTask;
    event Func<F?, Task<List<T>>> retrieveFixture 
        = (filter) => Task.FromResult(new List<T>());

    FixtureLocal(
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