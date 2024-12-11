using System;
using System.Collections.Generic;
using System.Formats.Asn1;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace BankaiCore.Repository;

public class ARepositoryOf<T, F>(LocalDataSource<T, F> local) : Repository<T, F>
    where T : Traceable
    where F : Filter
{
    public LocalDataSource<T, F> local { get; init; } = local;
    public List<RemoteDataSource<T, F>> remotes { get; set; } = new();

    public async Task prepare()
    {
        await local.prepare();
        foreach (var remote in remotes)
        {
            await remote.prepare();
        }
    }

    public async Task<List<T>> Read(F? filter)
    {
        List<T> items = await local.retrieve(filter);
        return items;
    }

    public async Task Commit(T item)
    {
        await local.store([ item ]);
    }

    public async Task<List<T>> pull(F? filter)
    {
        List<T> items = await local.retrieve(filter);
        foreach (var remote in remotes)
        {
            items.AddRange(await remote.pull(filter));
        }
        return items;
    }

    public async Task push(List<T> items)
    {
        await local.store(items);
        foreach (var remote in remotes)
        {
            await remote.push(items);
        }
    }
}