using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace BankaiCore.Repository;

public interface Filter
{
    bool onlyLocally { get; set; }
}

public interface Identifiable
{
    string id { get; set; }
}

public interface Traceable: Identifiable
{
    DateTime updatedAt { get; set; }
}

public interface DataSource<T, F>
{
    Task prepare();
}

public interface LocalDataSource<T, F>: DataSource<T, F>
{
    Task store(IEnumerable<T> items);
    Task<IEnumerable<T>> retrieve(F? filter);
}

public interface RemoteDataSource<T, F> : DataSource<T, F>
{
    static string name { get; }
    Task<IEnumerable<T>> pull(F? filter);
    Task push(IEnumerable<T> items);
}

public interface Repository<T, F>: DataSource<T, F>
{
    LocalDataSource<T, F> local { get; set; }
    List<RemoteDataSource<T, F>> remotes { get; set; }

    Task save(IEnumerable<T> items, bool shouldAttemptToPush);
}