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

    public static IObservable<int> SecondsCounter(this TimeSpan self)
        => Observable.Timer(TimeSpan.FromSeconds(2))
            .Select(_ => DateTime.Now)
            .Scan(0, (seconds, _) => seconds + 1)
            .Take(self.Seconds)
            .AsObservable();
}