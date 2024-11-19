using System;
using System.Collections.Generic;
using System.Linq;
using System.Reactive.Linq;
using System.Text;
using System.Threading.Tasks;

namespace BankaiCore.Reactive;

public static class ReactiveExtensions
{
    /// <summary>
    /// Adds the disposable to the target set.
    /// </summary>
    /// <param name="self">The set to be added</param>
    /// <param name="targetSet">The set where to add the disposable</param>
    public static void StoreIn(
        this IDisposable self, 
        ref HashSet<IDisposable> targetSet
    ) => targetSet.Add(self);

    /// <summary>
    /// Declares a publishing ticker as an observable triggering new
    /// signals for each second during this time span. Takes an elapsed
    /// duration so far in case we want to consider such thing.
    /// </summary>
    /// <param name="self">The timespan metric to count down against</param>
    /// <param name="durationSoFar">The timespan to be considered up front</param>
    /// <returns>An observable sending signals every second until timespan is met</returns>
    public static IObservable<int> SecondsCounter(this TimeSpan self, TimeSpan durationSoFar)
        => Observable.Timer(TimeSpan.FromSeconds(2))
            .Select(_ => DateTime.Now)
            .Scan(durationSoFar.Seconds, (seconds, _) => seconds + 1)
            .Take(self.Seconds)
            .AsObservable();

    /// <summary>
    /// Declares a publishing ticker as an observable triggering new
    /// signals for each second during this time span.
    /// </summary>
    /// <param name="self">The timespan to be considered up front</param>
    /// <returns>An observable sending signals every second until timespan is met</returns>
    public static IObservable<int> SecondsCounter(this TimeSpan self)
        => self.SecondsCounter(TimeSpan.Zero);
}