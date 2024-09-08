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
    public bool? onlyLocally { get; set; }
    public string? keywords {  get; set; }

    public static TestFilter none => new() { onlyLocally = null };
}

internal class FixtureLocal<T, F>: LocalDataSource<T, F>
    where T : Traceable
    where F : Filter
{
    /// <summary>
    /// Function holding the logic to store the fixture
    /// </summary>
    event Func<List<T>, Task> storeFixture;

    /// <summary>
    /// Function holding the logic to retrieve the fixture
    /// </summary>
    event Func<F?, Task<List<T>>> retrieveFixture;

    internal FixtureLocal(
        Func<List<T>, Task> storeFixture, 
        Func<F, Task<List<T>>> retrieveFixture
    )
    {
        this.storeFixture = storeFixture;
        this.retrieveFixture = retrieveFixture;
    }

    public Task prepare() => Task.CompletedTask;

    /// <summary>
    /// Method that calls inner logic func to retrieve items given a filter
    /// </summary>
    /// <param name="filter">The filter to base</param>
    /// <returns></returns>
    public Task<List<T>> retrieve(F? filter)
        => retrieveFixture(filter);

    /// <summary>
    /// Method that calls inner logic func to store items
    /// </summary>
    /// <param name="items"></param>
    /// <returns></returns>
    public Task store(List<T> items)
        => storeFixture(items);
}

internal class FixtureRemote<T, F>: RemoteDataSource<T, F>
    where T : Traceable
    where F : Filter
{
    public static string name { get; } = "test-remote";
    public string label;

    event Func<F?, Task<List<T>>> pullFixture;
    event Func<List<T>, Task> pushFixture;

    internal FixtureRemote(
        String label,
        Func<F?, Task<List<T>>> pullFixture,
        Func<List<T>, Task> pushFixture
    )
    {
        this.label = label;
        this.pullFixture = pullFixture;
        this.pushFixture = pushFixture;
    }

    public Task prepare() => Task.CompletedTask;

    public Task<List<T>> pull(F? filter)
        => pullFixture(filter);

    public Task push(List<T> items)
        => pushFixture(items);
}