using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace BankaiCore.Common;

public static class DateExtensions
{
    public static DateTime oneDayOut(this DateTime self) => self.AddDays(1);

    /// <summary>
    /// Calculates the difference between the given date and this date
    /// and returns it as a TimeSpan
    /// </summary>
    /// <param name="self">The reference to this date to use as starting point</param>
    /// <param name="date">The date to be used as ending point to calculate time span</param>
    /// <returns>The </returns>
    public static TimeSpan durationSince(this DateTime self, DateTime date)
        => date.Subtract(self);

    public static String digitalDuration(this DateTime self, bool includingSeconds = false)
        => self.TimeOfDay.digitalDuration(includingSeconds);
}
