using System;
using System.Collections.Generic;
using System.Linq;
using System.Reactive.Linq;
using System.Text;
using System.Threading.Tasks;

namespace BankaiCore.Common;

public static class Date
{
    public static DateTime from(int year, int month, int day)
        => new DateTime(year, month, day);

    public static DateTime todayAt(int hour, int minute, int second)
    {
        var now = DateTime.Now;
        return new DateTime(now.Year, now.Month, now.Day, hour, minute, second);
    }

    public static IObservable<DateTime> Flow(TimeSpan every)
        => Observable.Interval(every)
            .Select(_ => DateTime.Now);
}

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
        => self.Subtract(date);

    public static string DigitalTime(this DateTime self, bool includingSeconds = false)
    {
        var time = self.TimeOfDay;
        return includingSeconds ?
            $"{time.Hours:D2}:{time.Minutes:D2}:{time.Seconds:D2}"
            : $"{time.Hours:D2}:{time.Minutes:D2}";
    }

    public static String digitalDuration(this DateTime self, bool includingSeconds = false)
        => self.TimeOfDay.digitalDuration(includingSeconds);
}