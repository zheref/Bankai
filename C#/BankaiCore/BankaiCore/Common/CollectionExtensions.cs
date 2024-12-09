using System;
using System.Collections.Generic;
using System.Linq;
using System.Runtime.CompilerServices;
using System.Text;
using System.Threading.Tasks;

namespace BankaiCore.Common;

public static class CollectionExtensions
{
    public static IEnumerable<(int, T)> enumerated<T>(this IEnumerable<T> self)
        => self.Select((item, index) => (index, item));

    public static IEnumerable<T> filter<T>(
        this IEnumerable<T> self, 
        Func<T, bool> predicate
    )
    {
        foreach (var item in self)
        {
            if (predicate(item))
            {
                yield return item;
            }
        }
    }

    public static IEnumerable<T> compactMap<T>(
        this IEnumerable<T> self,
        Func<T, T?> transform
    )
    {
        foreach (var item in self)
        {
            var transformed = transform(item);
            if (transformed is not null)
            {
                yield return transformed;
            }
        }
    }

    public static IEnumerable<U> castElements<T, U>(
        this IEnumerable<T> self
    )
    {
        foreach (var item in self)
        {
            if (item is U casted)
            {
                yield return casted;
            }
        }
    }

    public static Nullable<T> At<T>(this IEnumerable<T> self, int index) where T : struct
    {
        return self.Count() > index ? self.ElementAt(index) : null;
    }

    public static T? RefAt<T>(this IEnumerable<T> self, int index) where T : class
    {
        return self.Count() > index ? self.ElementAt(index) : default;
    }
}
