using System;
using System.Collections.Generic;
using System.Linq;
using System.Reactive.Concurrency;
using System.Text;
using System.Threading.Tasks;
using BankaiCore.Common;

namespace BankaiCore.Repository;

public interface Filter
{
    bool onlyLocally { get; set; }
}

public interface Identifiable
{
    string id { get; init; }
}

public interface Traceable: Identifiable
{
    DateTime? updatedAt { get; set; }
}

public interface DataSource<T, F> 
    where T: Traceable
    where F : Filter
{
    Task prepare();
}

public interface LocalDataSource<T, F>: DataSource<T, F>
    where T : Traceable
    where F : Filter
{
    Task store(List<T> items);
    Task<List<T>> retrieve(F? filter);
}

public interface RemoteDataSource<T, F> : DataSource<T, F>
    where T : Traceable
    where F : Filter
{
    static string name { get; }
    string label => name;
    Task<List<T>> pull(F? filter);
    Task push(List<T> items);
}

public interface Repository<T, F>: DataSource<T, F>
    where T : Traceable
    where F : Filter
{
    LocalDataSource<T, F> local { get; init; }
    List<RemoteDataSource<T, F>> remotes { get; }

    /// <summary>
    /// Fetch elements of type filtering by [filter]
    /// </summary>
    /// <param name="filter"></param>
    /// <param name="scheduler"></param>
    /// <returns></returns>
    RepositoryFlow<List<T>> fetch(F? filter, IScheduler? scheduler = null)
    {
        scheduler = scheduler ?? Scheduler.Default;
        var onlyLocally = filter?.onlyLocally ?? remotes.Count == 0;
        var flow = new RepositoryFlow<List<T>>(async receiver =>
        {
            List<T> snapshot = new();

            try
            {
                snapshot = await local.retrieve(filter);
                receiver.sendLocal(snapshot);
            }
            catch (Exception e)
            {
                receiver.fail(new RepoSyncException.FailedRetrieving(e));
            }

            foreach (var (index, remote) in remotes.enumerated())
            {
                try
                {
                    var remoteSnapshot = await remote.pull(filter);
                    resolveMostRecentData(ref snapshot, remoteSnapshot);
                    receiver.sendRemote(
                        remoteSnapshot,
                        remote.label,
                        shouldHold: index < remotes.Count - 1
                    );
                }
                catch (Exception e)
                {
                    receiver.fail(new RepoSyncException.FailedPulling(e));
                }
            }

        }, onlyLocalExpected: onlyLocally, scheduler: scheduler);
        
        return flow;
    }

    /// <summary>
    /// Given a local collection of N data, this function mixes and replaces
    /// as needed to be given an incoming remote collection of M data.
    /// </summary>
    /// <param name="snapshot">Reference to local snapshot of data. This value will be mutated.</param>
    /// <param name="remoteSnapshot">Collection of incoming remote values.</param>
    /// <remarks>
    /// - Any ID-matching items with a less recent update version
    ///       will be replaced.
    ///     - If no update mark is found to compare, remote will
    ///       take precedence.
    ///     - Any ID not found in the local source will be added.
    ///     - Any ID-matching item with a more recent local version will
    ///       remain the same.
    /// </remarks>
    private void resolveMostRecentData(
        ref List<T> snapshot, 
        IEnumerable<T> remoteSnapshot
    )
    {
        foreach (var traceable in remoteSnapshot)
        {
            var index = snapshot.FindIndex(it => it.id == traceable.id);
            if (index < 0)
            {
                snapshot.Add(traceable);
                continue;
            }

            if (traceable.updatedAt == null ||
                snapshot[index].updatedAt == null)
            {
                snapshot[index] = traceable;
                continue;
            }

            if (traceable.updatedAt > snapshot[index].updatedAt)
                snapshot[index] = traceable;
        }
    }

    // TODO: Provide default implementation
    Task save(IEnumerable<T> items, bool shouldAttemptToPush)
    {
        return new Task(() => { });
    }

    void addRemote(RemoteDataSource<T, F> remote)
        => remotes.Add(remote);
}