using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Reactive;
using System.Reactive.Concurrency;
using System.Reactive.Linq;
using System.Reactive.Subjects;
using Microsoft.VisualBasic.FileIO;

namespace BankaiCore.Repository;

#region Support Types

public class RepoSyncException(string message) : Exception(message) { }

public abstract record class RepoSnapshot<T>
{
    public sealed record Local(T data) : RepoSnapshot<T>;

    public sealed record Remote(T data, string? remoteName)
        : RepoSnapshot<T>;
}

/// <summary>
/// Represents an object you can send snapshots to.
/// </summary>
/// <typeparam name="T">The type of object you expect to send</typeparam>
public interface SnapshotReceiver<in T>
{
    /// <summary>
    /// Sends a local snapshot to the flow so that subscribers are notified.
    /// </summary>
    /// <param name="value">The value to be received by the flow</param>
    void sendLocal(T value);

    /// <summary>
    /// Sends a remote snapshot to the flow so that subscribers are notified.
    /// </summary>
    /// <param name="value">The value to be received by the flow</param>
    /// <param name="remoteName">The name of the remote sending the new value</param>
    /// <param name="shouldHold">Determines whether the flow should hold its completion or not</param>
    void sendRemote(T value, string? remoteName, bool shouldHold = false);
    void giveUp();
    void fail(RepoSyncException e);
}

#endregion

/// <summary>
/// Represents a flow of snapshots of the given data type. Intended
/// to retrieve data from a local source expecting a potential remote
/// snapshot to contrast data and decide which one to keep.
/// </summary>
/// <typeparam name="Data">The type of data to manage</typeparam>
public class RepositoryFlow<Data>: SnapshotReceiver<Data>
{
    #region Subtypes
    public delegate Task Operation(SnapshotReceiver<Data> receiver);
    #endregion

    private bool onlyLocalExpected { get; set; }

    /// <summary>
    /// Subject holding flow of snapshots over time until it completes.
    /// </summary>
    private readonly ReplaySubject<RepoSnapshot<Data>> subject = new();

    /// <summary>
    /// Whether the flow has completed already or not.
    /// </summary>
    public bool hasCompleted { get; set; }

    private event Action<Data> yieldLocal = data => { };
    private event Action<Data, string?> yieldRemote = (data, s) => { };
    private event Action<RepoSyncException> yieldFailure = e => { };
    private event Action yieldCompletion = () => { };

    /// <summary>
    /// The operation block to be run when the flow is started.
    /// The body of the operation to be performed by the flow which should
    /// deliver values across time in order to flow to successfully complete.
    /// </summary>
    private event Operation body = receiver => Task.Delay(0);

    private readonly IScheduler _scheduler;
    private IDisposable _disposable;

    /// <summary>
    /// Retrieves cancellable instance of the flow and registers handlers
    /// for each snapshot type.
    /// </summary>
    public IDisposable run()
    {
        var disposable = subject
            //.ObserveOn(_scheduler ?? Scheduler.Default)
            .SubscribeOn(_scheduler ?? Scheduler.Default)
            .Subscribe(handleSnapshot, exception =>
            {
                this.yieldFailure(
                    new RepoSyncException(exception.Message)
                );
            }, () =>
            {
                Console.WriteLine($">>> Completed on Thread: {Thread.CurrentThread.Name}");
                this.hasCompleted = true;
                this.yieldCompletion();
            });
        _ = _scheduler!.Schedule(() =>
        {
            this.body(this);
        });
        this._disposable = disposable;
        return this._disposable;
    }

    private void handleSnapshot(RepoSnapshot<Data> snapshot)
    {
        Console.WriteLine($"Received new snapshot");
        switch (snapshot)
        {
            case RepoSnapshot<Data>.Local castedSnapshot:
                this.yieldLocal(castedSnapshot.data);
                break;
            case RepoSnapshot<Data>.Remote castedSnapshot:
                this.yieldRemote(
                    castedSnapshot.data,
                    castedSnapshot.remoteName
                );
                break;
        }
    }

    #region Constructors

    /// <summary>
    /// Creates a new instance of RepositoryFlow.
    /// Registers the operation to be run when the flow is started.
    /// This operation block will be responsible for emitting new snapshots
    /// or events to the flow.
    /// </summary>
    /// <param name="operation">Async operation block taking a receiver handler to send new snapshots/events with</param>
    /// <param name="onlyLocalExpected">Whether the flow will only expect a local snapshot or also expect remote snapshots</param>
    /// <param name="scheduler">The scheduler where the flow should operate</param>
    public RepositoryFlow(Operation operation, bool onlyLocalExpected = false, IScheduler? scheduler = null)
    {
        this.onlyLocalExpected = onlyLocalExpected;
        _scheduler = scheduler ?? Scheduler.Default;
        this.body = operation;
    }

    #endregion

    #region Sending values

    /// <summary>
    /// Sends a local snapshot to the flow so that subscribers are notified.
    /// </summary>
    /// <param name="value">The value to be received by the flow</param>
    public void sendLocal(Data value)
    {
        Console.WriteLine($"Received ${value} as local snapshot");
        if (hasCompleted) return;
        subject.OnNext(new RepoSnapshot<Data>.Local(value));
        if (onlyLocalExpected)
            subject.OnCompleted();
    }

    /// <summary>
    /// Sends a remote snapshot to the flow so that subscribers are notified.
    /// </summary>
    /// <param name="value">The value to be received by the flow</param>
    /// <param name="remoteName">The name of the remote sending the new value</param>
    /// <param name="shouldHold">Determines whether the flow should hold its completion or not</param>
    public void sendRemote(Data value, string? remoteName, bool shouldHold = false)
    {
        if (hasCompleted) return;
        subject.OnNext(new RepoSnapshot<Data>.Remote(value, remoteName));
        if (!shouldHold)
            subject.OnCompleted();
    }

    public void giveUp()
    {
        if (hasCompleted) return;
        subject.OnCompleted();
    }

    public void fail(RepoSyncException e)
    {
        if (hasCompleted) return;
        subject.OnError(e);
    }

    #endregion

    #region Event Subscriptions

    /// <summary>
    /// Subscribes action to be performed when a local snapshot is received.
    /// </summary>
    /// <param name="action">The action to be performed</param>
    /// <returns>The flow with the action subscribed</returns>
    public RepositoryFlow<Data> onLocal(Action<Data> action)
    {
        this.yieldLocal += action;
        return this;
    }

    public RepositoryFlow<Data> onRemote(Action<Data, string?> action)
    {
        this.yieldRemote += action;
        return this;
    }

    public RepositoryFlow<Data> onFailure(Action<RepoSyncException> action)
    {
        this.yieldFailure += action;
        return this;
    }

    public RepositoryFlow<Data> onCompletion(Action action)
    {
        this.yieldCompletion += action;
        return this;
    }

    #endregion
}
