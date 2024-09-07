using System;
using System.Collections.Generic;
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
}