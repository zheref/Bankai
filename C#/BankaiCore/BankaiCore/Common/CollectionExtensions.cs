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
}
